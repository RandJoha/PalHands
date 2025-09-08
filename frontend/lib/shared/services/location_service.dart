import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
}

 