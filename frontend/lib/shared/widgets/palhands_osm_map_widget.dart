import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../models/map_models.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../services/map_service.dart';
import '../services/location_service.dart' as locsvc;
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

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
  final locsvc.LocationService _locationService = locsvc.LocationService();
  List<MapMarker> _markers = const [];
  bool _loading = false;
  String? _error;
  ll.LatLng? _userLocation;
  bool _userLocationApprox = true;
  
  // Stream subscription for GPS state changes
  StreamSubscription<bool>? _gpsStateSubscription;

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
      // GPS is ON but no user location set - simulate and add marker
      final simulated = await _locationService.simulateGpsForAddress(city: null);
      _userLocation = ll.LatLng(simulated.position.latitude, simulated.position.longitude);
      _userLocationApprox = simulated.isApproximate;
      if (mounted) setState(() {});
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
    // Use a uniform color for all providers (as requested)
    final color = m.type == MapMarkerType.provider
        ? Colors.green
        : (m.type == MapMarkerType.client ? Colors.green : Colors.green);
    return Marker(
      point: pos,
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => widget.onMarkerTap?.call(m),
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
      final markers = await _mapService.getProvidersInBounds(
        bounds: bounds,
        filters: widget.initialFilters,
      );
      if (!mounted) return;
      setState(() {
        _markers = markers;
        _loading = false;
      });
      // Inject a simulated user location only if GPS is enabled
      if (_shouldShowUserLocation()) {
        final simulated = await _locationService.simulateGpsForAddress(city: null);
        _userLocation = ll.LatLng(simulated.position.latitude, simulated.position.longitude);
        _userLocationApprox = simulated.isApproximate;
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Trigger location update when auth service changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateUserLocationFromProfile();
        });
        
        final center = widget.initialLocation ?? ll.LatLng(31.9522, 35.2332);
        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12,
                onTap: (_, __) {},
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