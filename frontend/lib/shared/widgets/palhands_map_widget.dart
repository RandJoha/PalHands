import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/map_models.dart';
import '../services/map_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';

class PalHandsMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final MapFilters? initialFilters;
  final Function(MapMarker)? onMarkerTap;
  final Function(LatLng)? onLocationChanged;
  final bool showUserLocation;
  final bool showLocationToggle;
  final double? height;
  final EdgeInsets? padding;

  const PalHandsMapWidget({
    Key? key,
    this.initialLocation,
    this.initialFilters,
    this.onMarkerTap,
    this.onLocationChanged,
    this.showUserLocation = true,
    this.showLocationToggle = true,
    this.height,
    this.padding,
  }) : super(key: key);

  @override
  State<PalHandsMapWidget> createState() => _PalHandsMapWidgetState();
}

class _PalHandsMapWidgetState extends State<PalHandsMapWidget> {
  late GoogleMapController _mapController;
  final MapService _mapService = MapService();
  final LocationService _locationService = LocationService();
  
  // Map state
  MapState _mapState = const MapState();
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  bool _userLocationApprox = true;
  bool _isLoading = false;
  String? _error;
  
  // Location permission
  bool _isLocationPermissionGranted = false;
  bool _isLocationSharingEnabled = false;
  
  // Stream subscription for GPS state changes
  StreamSubscription<bool>? _gpsStateSubscription;
  
  // Map settings
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(31.9522, 35.2332),
    zoom: 10,
  );
  
  CameraPosition _currentPosition = _defaultPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    
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

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load initial markers
      await _loadMarkers();
      
      // Check location permissions
      await _checkLocationPermissions();
      
      // Load user location preferences
      await _loadUserLocationPreferences();
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMarkers() async {
    try {
      final bounds = _getCurrentBounds();
      final markers = await _mapService.getProvidersInBounds(
        bounds: bounds,
        filters: _mapState.filters,
      );
      
      setState(() {
        _mapState = _mapState.copyWith(markers: markers);
        _markers = _createMarkers(markers);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load providers: $e';
      });
    }
  }

  Future<void> _checkLocationPermissions() async {
    // TODO: Implement actual location permission checking
    // For now, simulate permission check
    setState(() {
      _isLocationPermissionGranted = true;
    });

    // Show blue marker only if user has GPS enabled in their profile
    if (_isLocationSharingEnabled && _shouldShowUserLocation()) {
      final simulated = await _locationService.simulateGpsForAddress(city: null);
      _userLocation = simulated.position;
      _userLocationApprox = simulated.isApproximate;
      // Add blue marker for current user
      _injectUserMarker();
    }
  }

  Future<void> _loadUserLocationPreferences() async {
    try {
      final preferences = await _mapService.getUserLocationPreferences();
      setState(() {
        _isLocationSharingEnabled = preferences['isLocationSharingEnabled'] ?? false;
        if (preferences['lastKnownLocation'] != null) {
          final loc = preferences['lastKnownLocation'];
          _userLocation = LatLng(loc['latitude'], loc['longitude']);
          _userLocationApprox = loc['isApproximate'] == true;
        }
      });
      if (_isLocationSharingEnabled && _userLocation != null && _shouldShowUserLocation()) {
        _injectUserMarker();
      }
    } catch (e) {
      // Handle error silently
    }
  }

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
      // GPS is ON but no user location set - simulate and add marker
      final simulated = await _locationService.simulateGpsForAddress(city: null);
      _userLocation = simulated.position;
      _userLocationApprox = simulated.isApproximate;
      _injectUserMarker();
    } else if (!shouldShow) {
      // GPS is OFF - remove user marker immediately
      setState(() {
        _markers = _markers.where((m) => m.markerId.value != 'me').toSet();
        _userLocation = null;
      });
    } else if (shouldShow && _userLocation != null) {
      // GPS is ON and we have location - ensure marker is shown
      _injectUserMarker();
    }
  }

  void _injectUserMarker() {
    final loc = _userLocation;
    if (loc == null || !_shouldShowUserLocation()) return;
    final Marker userMarker = Marker(
      markerId: const MarkerId('me'),
      position: loc,
      infoWindow: const InfoWindow(title: 'You'),
      icon: _userLocationApprox
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)
          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    setState(() {
      _markers = {..._markers.where((m) => m.markerId.value != 'me'), userMarker};
    });
  }

  MapBounds _getCurrentBounds() {
    // Calculate bounds based on current map view
    final zoom = _currentPosition.zoom;
    final lat = _currentPosition.target.latitude;
    final lng = _currentPosition.target.longitude;
    
    // Calculate approximate bounds based on zoom level
    final latDelta = 180.0 / math.pow(2, zoom);
    final lngDelta = 360.0 / math.pow(2, zoom);
    
    return MapBounds(
      northeast: LatLng(lat + latDelta / 2, lng + lngDelta / 2),
      southwest: LatLng(lat - latDelta / 2, lng - lngDelta / 2),
    );
  }

  Set<Marker> _createMarkers(List<MapMarker> markers) {
    return markers.map((marker) {
      return Marker(
        markerId: MarkerId(marker.id),
        position: marker.position,
        infoWindow: InfoWindow(
          title: marker.name,
          snippet: marker.description ?? marker.category ?? '',
        ),
        icon: _getMarkerIcon(marker),
        onTap: () => _onMarkerTap(marker),
      );
    }).toSet();
  }

  BitmapDescriptor _getMarkerIcon(MapMarker marker) {
    // Return different icons based on marker type and availability
    // Uniform color for all marker types per request
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }

  void _onMarkerTap(MapMarker marker) {
    if (widget.onMarkerTap != null) {
      widget.onMarkerTap!(marker);
    }
  }

  void _onMapTap(LatLng position) {
    if (widget.onLocationChanged != null) {
      widget.onLocationChanged!(position);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentPosition = position;
  }

  Future<void> _onCameraIdle() async {
    // Load markers for new bounds
    await _loadMarkers();
  }

  Future<void> _requestLocationPermission() async {
    // TODO: Implement actual location permission request
    setState(() {
      _isLocationPermissionGranted = true;
    });
    
    // Move to user location
    if (_userLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_userLocation!),
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
          _injectUserMarker();
          if (_mapController != null) {
            _mapController.animateCamera(CameraUpdate.newLatLng(simulated.position));
          }
        } else {
          setState(() {
            _markers = _markers.where((m) => m.markerId.value != 'me').toSet();
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
          Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
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
            child: Text(
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
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _initializeMap,
            child: Text(
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
        
        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: widget.initialLocation != null
                  ? CameraPosition(target: widget.initialLocation!, zoom: 15)
                  : _defaultPosition,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onTap: _onMapTap,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              markers: _markers,
              myLocationEnabled: false, // We handle this manually
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
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
        );
      },
    );
  }

  @override
  void dispose() {
    _gpsStateSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}

/// Map marker info widget
class MapMarkerInfoWidget extends StatelessWidget {
  final MapMarker marker;
  final VoidCallback? onBookPressed;
  final VoidCallback? onClosePressed;

  const MapMarkerInfoWidget({
    Key? key,
    required this.marker,
    this.onBookPressed,
    this.onClosePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and close button
          Row(
            children: [
              Expanded(
                child: Text(
                  marker.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onClosePressed != null)
                IconButton(
                  onPressed: onClosePressed,
                  icon: const Icon(Icons.close),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Category
          if (marker.category != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                marker.category!,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Rating
          if (marker.rating != null) ...[
            Row(
              children: [
                ...List.generate(5, (index) {
                  return Icon(
                    index < marker.rating!.floor()
                        ? Icons.star
                        : (index < marker.rating! ? Icons.star_half : Icons.star_border),
                    color: Colors.amber,
                    size: 16,
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  marker.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (marker.reviewCount != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${marker.reviewCount})',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Description
          if (marker.description != null) ...[
            Text(
              marker.description!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          
          // Distance
          if (marker.distanceFromUser != null) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  MapUtils.formatDistance(marker.distanceFromUser!),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Book button
          if (onBookPressed != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBookPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Book Now'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Utility class for map-related functions
class MapUtils {
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }
}