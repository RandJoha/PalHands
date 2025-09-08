import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/map_service.dart';
import '../models/map_models.dart';

// Re-export LatLng so importing this file provides the type where needed
export 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

/// Minimal, cross-platform location permission helper
class LocationPermissionHelper {
  /// Requests location permission from the user.
  /// Returns true if granted, false otherwise.
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // Phase 1: keep it simple – simulate granted on web/dev, integrate real perms later
    if (kIsWeb) {
      return true;
    }
    // For mobile, integrate with permission_handler/location later.
    // Return false by default to avoid unintended permission assumptions.
    return false;
  }
}

/// Minimal LocationService used by category/map widgets
class LocationService {
  LatLng? _currentLatLng;
  bool _sharingEnabled = false;
  final MapService _mapService = MapService();
  
  // Stream controller for GPS state changes
  static final _gpsStateController = StreamController<bool>.broadcast();
  static Stream<bool> get gpsStateStream => _gpsStateController.stream;

  LatLng? get currentLatLng => _currentLatLng;
  bool get isSharingEnabled => _sharingEnabled;

  /// Attempts to get current device location (LatLng).
  /// In Phase 1 (web/dev), this returns null (no GPS); later wire real providers.
  Future<LatLng?> getCurrentLocation() async {
    // TODO: Integrate with `location` or `geolocator` packages for mobile
    // and browser geolocation for web (via `geolocator_web`).
    return _currentLatLng;
  }

  /// Compatibility alias for legacy calls
  Future<LatLng?> getCurrentPosition() => getCurrentLocation();

  /// Stub: load persisted preferences (no-op for now)
  Future<void> loadLocationPreferences() async {
    // Keep defaults; later read from storage/backend
    return;
  }

  /// Stores user location sharing preference remotely or locally (stub).
  Future<bool> setLocationSharingEnabled(bool enabled) async {
    _sharingEnabled = enabled;
    return true;
  }

  /// Update the cached current location (e.g., from map selection)
  void setCurrentLatLng(LatLng? latLng) {
    _currentLatLng = latLng;
  }

  /// Simulate a GPS position that is consistent with a given city and optional street hint.
  /// If city is unknown, falls back to Palestine default center.
  Future<UserLocation> simulateGpsForAddress({
    String? city,
    String? street,
  }) async {
    final base = _mapService.getCityCentroid(city) ?? MapUtils.defaultPalestineCenter;
    // Small deterministic jitter tied to street hash to keep stable per street
    final int seed = (street ?? city ?? 'palhands').hashCode;
    final double jitterLat = ((seed % 1000) / 1000.0 - 0.5) * 0.004;
    final double jitterLng = (((seed ~/ 1000) % 1000) / 1000.0 - 0.5) * 0.004;
    final pos = LatLng(base.latitude + jitterLat, base.longitude + jitterLng);
    _currentLatLng = pos;
    return UserLocation(
      position: pos,
      accuracy: 120.0,
      timestamp: DateTime.now(),
      isApproximate: true,
    );
  }

  /// Given a (simulated) GPS position, derive a consistent address (reverse-coupled).
  /// Uses reverse-geocoding endpoint if available; otherwise snaps to nearest known city.
  Future<AddressInfo> coupleAddressFromGps(LatLng position) async {
    final String? full = await _mapService.reverseGeocode(position);
    if (full != null && full.isNotEmpty) {
      // naive parse: city is last token after comma; street is the first
      final parts = full.split(',').map((e) => e.trim()).toList();
      final street = parts.isNotEmpty ? parts.first : null;
      final city = parts.isNotEmpty ? parts.last : null;
      return AddressInfo(
        city: city,
        street: street,
        coordinates: position,
        isApproximate: true,
        source: LocationSource.gps,
      );
    }
    // Fallback to nearest city centroid
    final nearest = _mapService.findNearestCity(position);
    return AddressInfo(
      city: nearest.key,
      street: null,
      coordinates: nearest.value,
      isApproximate: true,
      source: LocationSource.cityCentroid,
    );
  }

  /// Notify all listeners that GPS state has changed
  static void notifyGpsStateChanged(bool gpsEnabled) {
    _gpsStateController.add(gpsEnabled);
  }

  /// Dispose the stream controller (call this in app disposal if needed)
  static void dispose() {
    _gpsStateController.close();
  }
}

 