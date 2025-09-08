import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/map_models.dart';
import '../services/map_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class PalHandsMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final MapFilters? initialFilters;
  final Function(MapMarker)? onMarkerTap;
  final Function(LatLng)? onLocationChanged;
  final bool showUserLocation;
  final bool showLocationPermissionBanner;

  const PalHandsMapWidget({
    Key? key,
    this.initialLocation,
    this.initialFilters,
    this.onMarkerTap,
    this.onLocationChanged,
    this.showUserLocation = true,
    this.showLocationPermissionBanner = true,
  }) : super(key: key);

  @override
  State<PalHandsMapWidget> createState() => _PalHandsMapWidgetState();
}

class _PalHandsMapWidgetState extends State<PalHandsMapWidget> {
  late GoogleMapController _mapController;
  final MapService _mapService = MapService();
  
  // Map state
  MapState _mapState = const MapState();
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  bool _isLoading = false;
  String? _error;
  
  // Location permission
  bool _isLocationPermissionGranted = false;
  bool _isLocationSharingEnabled = false;
  
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
  }

  Future<void> _loadUserLocationPreferences() async {
    try {
      final preferences = await _mapService.getUserLocationPreferences();
      setState(() {
        _isLocationSharingEnabled = preferences['isLocationSharingEnabled'] ?? false;
        if (preferences['lastKnownLocation'] != null) {
          final loc = preferences['lastKnownLocation'];
          _userLocation = LatLng(loc['latitude'], loc['longitude']);
        }
      });
    } catch (e) {
      // Handle error silently
    }
  }

  MapBounds _getCurrentBounds() {
    // Calculate bounds based on current map view
    final zoom = _currentPosition.zoom;
    final lat = _currentPosition.target.latitude;
    final lng = _currentPosition.target.longitude;
    
    // Approximate bounds calculation
    final latDelta = 180 / math.pow(2, zoom);
    final lngDelta = 360 / math.pow(2, zoom);
    
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
      }
    } catch (e) {
      // Handle error
    }
  }

  Widget _buildLocationPermissionBanner() {
    if (!widget.showLocationPermissionBanner || _isLocationPermissionGranted) {
      return const SizedBox.shrink();
    }

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
            color: _isLocationSharingEnabled ? AppColors.primary : AppColors.textSecondary,
          ),
          tooltip: _isLocationSharingEnabled ? 'Disable location sharing' : 'Enable location sharing',
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    if (!_isLoading) return const SizedBox.shrink();

    return Container(
      color: Colors.white.withOpacity(0.8),
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
          myLocationEnabled: widget.showUserLocation && _isLocationPermissionGranted,
          myLocationButtonEnabled: false, // We'll add custom button
          mapType: MapType.normal,
          zoomControlsEnabled: false, // We'll add custom controls
          compassEnabled: true,
          mapToolbarEnabled: false,
        ),
        
        // Location permission banner
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildLocationPermissionBanner(),
        ),
        
        // Location toggle button
        _buildLocationToggle(),
        
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
  }

  @override
  void dispose() {
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
          // Header with close button
          Row(
            children: [
              Expanded(
                child: Text(
                  marker.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onClosePressed != null)
                IconButton(
                  onPressed: onClosePressed,
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Category and rating
          Row(
            children: [
              if (marker.category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    marker.category!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (marker.rating != null) ...[
                Icon(
                  Icons.star,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  marker.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (marker.reviewCount != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${marker.reviewCount})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Description
          if (marker.description != null) ...[
            Text(
              marker.description!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          // Distance
          if (marker.distanceFromUser != null) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  MapUtils.formatDistance(marker.distanceFromUser!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBookPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Book Service'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // TODO: Implement call functionality
                },
                icon: const Icon(Icons.phone),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
