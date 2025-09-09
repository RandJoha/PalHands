import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:provider/provider.dart';
import '../models/map_models.dart';
import '../models/provider.dart';
import '../services/map_service.dart';
import '../services/map_provider_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import 'map_provider_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

/// Unified map widget that uses OpenStreetMap for both web and mobile platforms
/// This replaces the need for separate Google Maps and OSM implementations
class PalHandsUnifiedMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final MapFilters? initialFilters;
  final Function(MapMarker)? onMarkerTap;
  final Function(LatLng)? onLocationChanged;
  final bool showUserLocation;
  final bool showLocationToggle;
  final double? height;
  final EdgeInsets? padding;

  const PalHandsUnifiedMapWidget({
    super.key,
    this.initialLocation,
    this.initialFilters,
    this.onMarkerTap,
    this.onLocationChanged,
    this.showUserLocation = true,
    this.showLocationToggle = true,
    this.height,
    this.padding,
  });

  @override
  State<PalHandsUnifiedMapWidget> createState() => _PalHandsUnifiedMapWidgetState();
}

class _PalHandsUnifiedMapWidgetState extends State<PalHandsUnifiedMapWidget> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  final MapProviderService _mapProviderService = MapProviderService();
  final LocationService _locationService = LocationService();
  
  // Map state
  List<MapMarker> _markers = [];
  LatLng? _userLocation;
  bool _userLocationApprox = true;
  bool _isLoading = false;
  String? _error;
  
  // Provider data
  MapProviderData? _providerData;
  
  // Location permission
  bool _isLocationPermissionGranted = false;
  bool _isLocationSharingEnabled = false;
  
  // Stream subscription for GPS state changes
  StreamSubscription<bool>? _gpsStateSubscription;
  
  // Provider card state
  ProviderModel? _pinnedProvider;
  
  // Map settings
  static const ll.LatLng _defaultPosition = ll.LatLng(31.9522, 35.2332);
  static const double _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    
    // Listen to GPS state changes for immediate updates
    _gpsStateSubscription = LocationService.gpsStateStream.listen((gpsEnabled) {
      if (mounted) {
        _updateUserLocationFromProfile();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for auth service changes to update user location immediately
    _updateUserLocationFromProfile();
  }

  // Helper to convert latlong2 -> google_maps LatLng used by MapBounds
  static LatLng llToGm(ll.LatLng p) => LatLng(p.latitude, p.longitude);

  // Check if user location should be shown based on GPS preference
  bool _shouldShowUserLocation() {
    if (!mounted) return false;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      // Only show blue dot if user has GPS enabled in their profile
      final useGpsLocation = user?['useGpsLocation'] ?? false;
      return useGpsLocation == true;
    } catch (e) {
      // If we can't access auth service, don't show user location
      return false;
    }
  }

  // Update user location based on current profile GPS setting
  Future<void> _updateUserLocationFromProfile() async {
    if (!mounted) return;
    
    final shouldShow = _shouldShowUserLocation();
    
    if (shouldShow && _userLocation == null) {
      // GPS is ON but no user location set - get GPS address from profile
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        // Try to get GPS coordinates from user's profile address
        LatLng? profileCoordinates;
        
        if (user['address'] is Map) {
          final addressMap = user['address'] as Map;
          final coordinates = addressMap['coordinates'];
          if (coordinates is Map) {
            final lat = coordinates['latitude'];
            final lng = coordinates['longitude'];
            if (lat != null && lng != null) {
              profileCoordinates = LatLng(lat.toDouble(), lng.toDouble());
            }
          }
        }
        
        if (profileCoordinates != null) {
          // Use GPS coordinates from profile
          _userLocation = profileCoordinates;
          _userLocationApprox = false; // More accurate since it's from profile
        } else {
          // Fallback to simulated GPS if no profile coordinates
          final simulated = await _locationService.simulateGpsForAddress(city: null);
          _userLocation = simulated.position;
          _userLocationApprox = simulated.isApproximate;
        }
        
        if (mounted) setState(() {});
      }
    } else if (!shouldShow) {
      // GPS is OFF - remove user marker immediately
      setState(() {
        _userLocation = null;
      });
    } else if (shouldShow && _userLocation != null) {
      // GPS is ON and we have location - ensure marker is shown
      if (mounted) setState(() {});
    }
  }

  Marker _buildMarker(MapMarker m) {
    final pos = ll.LatLng(m.position.latitude, m.position.longitude);
    
    // Check if this marker belongs to the current user (provider viewing their own marker)
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final currentUserId = currentUser?['_id'] ?? currentUser?['id'];
    final isCurrentUserProvider = currentUser?['role'] == 'provider';
    
    // If current user is a provider and this marker is theirs, make it blue
    Color color = Colors.green; // Default green for all markers
    if (isCurrentUserProvider && currentUserId != null && m.id == currentUserId) {
      color = Colors.blue; // Blue for provider's own marker
    }
    
    return Marker(
      point: pos,
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => _onMarkerTap(m),
        child: Icon(Icons.location_pin, color: color, size: 34),
      ),
    );
  }

  Marker _buildUserMarker() {
    final pos = _userLocation != null 
        ? ll.LatLng(_userLocation!.latitude, _userLocation!.longitude)
        : _defaultPosition;
    final color = _userLocationApprox ? Colors.lightBlue : Colors.blue;
    return Marker(
      point: pos,
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: Icon(Icons.my_location, color: color, size: 28),
    );
  }

  Future<void> _loadMarkers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final center = widget.initialLocation != null 
          ? ll.LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude)
          : _defaultPosition;
      final latDelta = 0.1; // ~11km
      final lngDelta = 0.1;
      final bounds = MapBounds(
        northeast: llToGm(ll.LatLng(center.latitude + latDelta / 2, center.longitude + lngDelta / 2)),
        southwest: llToGm(ll.LatLng(center.latitude - latDelta / 2, center.longitude - lngDelta / 2)),
      );
      
      final providerData = await _mapProviderService.getProvidersForMap(
        bounds: bounds,
        filters: widget.initialFilters,
      );
      
      if (!mounted) return;
      
      setState(() {
        _providerData = providerData;
        _markers = providerData.markers;
        _isLoading = false;
      });
      
      // Inject user location from profile if GPS is enabled
      if (_shouldShowUserLocation()) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;
        
        if (user != null) {
          // Try to get GPS coordinates from user's profile address
          LatLng? profileCoordinates;
          
          if (user['address'] is Map) {
            final addressMap = user['address'] as Map;
            final coordinates = addressMap['coordinates'];
            if (coordinates is Map) {
              final lat = coordinates['latitude'];
              final lng = coordinates['longitude'];
              if (lat != null && lng != null) {
                profileCoordinates = LatLng(lat.toDouble(), lng.toDouble());
              }
            }
          }
          
          if (profileCoordinates != null) {
            // Use GPS coordinates from profile
            _userLocation = profileCoordinates;
            _userLocationApprox = false; // More accurate since it's from profile
          } else {
            // Fallback to simulated GPS if no profile coordinates
            final simulated = await _locationService.simulateGpsForAddress(city: null);
            _userLocation = simulated.position;
            _userLocationApprox = simulated.isApproximate;
          }
          
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onMarkerTap(MapMarker marker) {
    // Get the real provider data for this marker
    final provider = _providerData?.getProviderByMarkerId(marker.id);
    if (provider == null) return;
    
    // Toggle pinned card
    if (_pinnedProvider?.id == provider.id) {
      _closePinnedCard();
    } else {
      _pinProviderCard(provider, marker);
    }
    
    // Still call the original callback
    widget.onMarkerTap?.call(marker);
  }

  void _onMapTap(ll.LatLng position) {
    // Close any open pinned cards when tapping on the map
    if (_pinnedProvider != null) {
      _closePinnedCard();
    }
    
    if (widget.onLocationChanged != null) {
      widget.onLocationChanged!(LatLng(position.latitude, position.longitude));
    }
  }

  void _pinProviderCard(ProviderModel provider, MapMarker marker) {
    // For OSM, we need to estimate the screen position from the map position
    final screenSize = MediaQuery.of(context).size;
    // Simple approximation - center the card on screen for now
    // In a real implementation, you'd convert lat/lng to screen coordinates
    final position = Offset(screenSize.width * 0.5, screenSize.height * 0.3);
    
    setState(() {
      _pinnedProvider = provider;
    });
  }

  void _closePinnedCard() {
    setState(() {
      _pinnedProvider = null;
    });
  }

  Future<void> _requestLocationPermission() async {
    // TODO: Implement actual location permission request
    setState(() {
      _isLocationPermissionGranted = true;
    });
    
    // Move to user location
    if (_userLocation != null) {
      _mapController.move(
        ll.LatLng(_userLocation!.latitude, _userLocation!.longitude),
        _defaultZoom,
      );
    }
  }

  Future<void> _toggleLocationSharing() async {
    final newValue = !_isLocationSharingEnabled;
    
    try {
      final success = await _mapService.updateLocationSharingPreference(newValue);
      if (success) {
        setState(() {
          _isLocationSharingEnabled = newValue;
        });
        if (_isLocationSharingEnabled) {
          final simulated = await _locationService.simulateGpsForAddress(city: null);
          _userLocation = simulated.position;
          _userLocationApprox = simulated.isApproximate;
          await _mapService.updateUserLocation(
            position: simulated.position,
            accuracy: simulated.accuracy,
            isApproximate: true,
          );
          _mapController.move(
            ll.LatLng(simulated.position.latitude, simulated.position.longitude),
            _defaultZoom,
          );
        } else {
          setState(() {
            _userLocation = null;
          });
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Widget _buildLocationPermissionBanner() {
    if (_isLocationPermissionGranted) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Enable location to see your position and find nearby providers',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _requestLocationPermission,
            child: const Text(
              'Enable',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationToggle() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: _toggleLocationSharing,
          icon: Icon(
            _isLocationSharingEnabled ? Icons.location_on : Icons.location_off,
            color: _isLocationSharingEnabled ? AppColors.primary : Colors.grey,
          ),
          tooltip: _isLocationSharingEnabled ? 'Disable location sharing' : 'Enable location sharing',
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    if (_error == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadMarkers,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Trigger location update when auth service changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateUserLocationFromProfile();
        });
        
        final center = widget.initialLocation != null 
            ? ll.LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude)
            : _defaultPosition;
        
        return Column(
          children: [
            // Map section
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _defaultZoom,
                      onTap: (_, position) => _onMapTap(position),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.palhands.app',
                      ),
                      MarkerLayer(
                        markers: _markers.map((m) => _buildMarker(m)).toList(),
                      ),
                      // User location marker layer - only show if GPS is enabled
                      if (_userLocation != null && _shouldShowUserLocation())
                        MarkerLayer(
                          markers: [_buildUserMarker()],
                        ),
                    ],
                  ),
                  
                  // Location permission banner
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildLocationPermissionBanner(),
                  ),
                  
                  // Location toggle button
                  if (widget.showLocationToggle) _buildLocationToggle(),
                  
                  // Loading overlay
                  _buildLoadingOverlay(),
                  
                  // Error overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildErrorOverlay(),
                  ),
                ],
              ),
            ),
            
            // Provider card below map
            if (_pinnedProvider != null)
              MapProviderCard(
                provider: _pinnedProvider!,
                onClose: _closePinnedCard,
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _gpsStateSubscription?.cancel();
    super.dispose();
  }
}
