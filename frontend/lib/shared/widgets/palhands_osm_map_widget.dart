import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../models/map_models.dart';
import '../models/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../services/map_service.dart';
import '../services/map_provider_service.dart';
import '../services/location_service.dart' as locsvc;
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'map_provider_card.dart';

class PalHandsOsmMapWidget extends StatefulWidget {
  final ll.LatLng? initialLocation;
  final MapFilters? initialFilters;
  final Function(MapMarker)? onMarkerTap;

  const PalHandsOsmMapWidget({
    Key? key,
    this.initialLocation,
    this.initialFilters,
    this.onMarkerTap,
  }) : super(key: key);

  @override
  State<PalHandsOsmMapWidget> createState() => _PalHandsOsmMapWidgetState();
}

class _PalHandsOsmMapWidgetState extends State<PalHandsOsmMapWidget> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  final MapProviderService _mapProviderService = MapProviderService();
  final locsvc.LocationService _locationService = locsvc.LocationService();
  List<MapMarker> _markers = const [];
  bool _loading = false;
  String? _error;
  ll.LatLng? _userLocation;
  bool _userLocationApprox = true;
  
  // Provider data
  MapProviderData? _providerData;
  
  // Stream subscription for GPS state changes
  StreamSubscription<bool>? _gpsStateSubscription;
  
  // Hover card state
  ProviderModel? _hoveredProvider;
  ProviderModel? _pinnedProvider;
  Offset? _hoverPosition;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    
    // Listen to GPS state changes for immediate updates
    _gpsStateSubscription = locsvc.LocationService.gpsStateStream.listen((gpsEnabled) {
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
          _userLocation = ll.LatLng(profileCoordinates.latitude, profileCoordinates.longitude);
          _userLocationApprox = false; // More accurate since it's from profile
        } else {
          // Fallback to simulated GPS if no profile coordinates
          final simulated = await _locationService.simulateGpsForAddress(city: null);
          _userLocation = ll.LatLng(simulated.position.latitude, simulated.position.longitude);
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
    final pos = _userLocation ?? ll.LatLng(31.9522, 35.2332);
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
      _loading = true;
      _error = null;
    });
    try {
      final center = widget.initialLocation ?? ll.LatLng(31.9522, 35.2332);
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
        _loading = false;
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
            _userLocation = ll.LatLng(profileCoordinates.latitude, profileCoordinates.longitude);
            _userLocationApprox = false; // More accurate since it's from profile
          } else {
            // Fallback to simulated GPS if no profile coordinates
            final simulated = await _locationService.simulateGpsForAddress(city: null);
            _userLocation = ll.LatLng(simulated.position.latitude, simulated.position.longitude);
            _userLocationApprox = simulated.isApproximate;
          }
          
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }


  void _onMarkerTap(MapMarker marker) {
    // Get the real provider data for this marker
    final provider = _providerData?.getProviderByMarkerId(marker.id);
    if (provider == null) return;
    
    // For mobile/touch: toggle pinned card
    if (_pinnedProvider?.id == provider.id) {
      _closePinnedCard();
    } else {
      _pinProviderCard(provider, marker);
    }
    
    // Still call the original callback
    widget.onMarkerTap?.call(marker);
  }

  void _pinProviderCard(ProviderModel provider, MapMarker marker) {
    // For OSM, we need to estimate the screen position from the map position
    final screenSize = MediaQuery.of(context).size;
    // Simple approximation - center the card on screen for now
    // In a real implementation, you'd convert lat/lng to screen coordinates
    final position = Offset(screenSize.width * 0.5, screenSize.height * 0.3);
    
    setState(() {
      _pinnedProvider = provider;
      _hoveredProvider = null; // Clear hover when pinning
      _hoverPosition = position;
    });
  }

  void _closePinnedCard() {
    setState(() {
      _pinnedProvider = null;
      _hoveredProvider = null;
      _hoverPosition = null;
    });
  }

  // Hover card method removed - now using MapProviderCard below the map

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Trigger location update when auth service changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateUserLocationFromProfile();
        });
        
        final center = widget.initialLocation ?? ll.LatLng(31.9522, 35.2332);
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
                      initialZoom: 12,
                      onTap: (_, __) {
                        // Close any open cards when tapping on the map
                        if (_pinnedProvider != null) {
                          _closePinnedCard();
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
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
                  
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Material(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      ),
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