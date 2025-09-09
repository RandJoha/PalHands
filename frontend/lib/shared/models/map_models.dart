import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Map marker types for different actors
enum MapMarkerType {
  provider,
  client,
  admin,
}

/// Indicates the origin of the resolved user location
enum LocationSource {
  gps,
  address,
  cityCentroid,
}

/// Simple address structure used during geocode/reverse-geocode coupling
class AddressInfo {
  final String? city;
  final String? street;
  final String? area;
  final LatLng? coordinates;
  final bool isApproximate;
  final LocationSource source;

  const AddressInfo({
    this.city,
    this.street,
    this.area,
    this.coordinates,
    this.isApproximate = true,
    this.source = LocationSource.cityCentroid,
  });

  AddressInfo copyWith({
    String? city,
    String? street,
    String? area,
    LatLng? coordinates,
    bool? isApproximate,
    LocationSource? source,
  }) {
    return AddressInfo(
      city: city ?? this.city,
      street: street ?? this.street,
      area: area ?? this.area,
      coordinates: coordinates ?? this.coordinates,
      isApproximate: isApproximate ?? this.isApproximate,
      source: source ?? this.source,
    );
  }
}

/// Map marker data model
class MapMarker {
  final String id;
  final String name;
  final LatLng position;
  final MapMarkerType type;
  final String? category;
  final double? rating;
  final int? reviewCount;
  final String? description;
  final String? phone;
  final String? email;
  final bool isAvailable;
  final DateTime? lastSeenAt;
  final double? distanceFromUser; // in kilometers
  final Map<String, dynamic>? additionalData;

  const MapMarker({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    this.category,
    this.rating,
    this.reviewCount,
    this.description,
    this.phone,
    this.email,
    this.isAvailable = true,
    this.lastSeenAt,
    this.distanceFromUser,
    this.additionalData,
  });

  factory MapMarker.fromJson(Map<String, dynamic> json) {
    return MapMarker(
      id: json['id'] as String,
      name: json['name'] as String,
      position: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      type: MapMarkerType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MapMarkerType.provider,
      ),
      category: json['category'] as String?,
      rating: json['rating'] as double?,
      reviewCount: json['reviewCount'] as int?,
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      lastSeenAt: json['lastSeenAt'] != null 
          ? DateTime.parse(json['lastSeenAt'] as String)
          : null,
      distanceFromUser: json['distanceFromUser'] as double?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'type': type.name,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'description': description,
      'phone': phone,
      'email': email,
      'isAvailable': isAvailable,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
      'distanceFromUser': distanceFromUser,
      'additionalData': additionalData,
    };
  }

  MapMarker copyWith({
    String? id,
    String? name,
    LatLng? position,
    MapMarkerType? type,
    String? category,
    double? rating,
    int? reviewCount,
    String? description,
    String? phone,
    String? email,
    bool? isAvailable,
    DateTime? lastSeenAt,
    double? distanceFromUser,
    Map<String, dynamic>? additionalData,
  }) {
    return MapMarker(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      type: type ?? this.type,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isAvailable: isAvailable ?? this.isAvailable,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

/// Map bounds for filtering markers
class MapBounds {
  final LatLng northeast;
  final LatLng southwest;

  const MapBounds({
    required this.northeast,
    required this.southwest,
  });

  factory MapBounds.fromJson(Map<String, dynamic> json) {
    return MapBounds(
      northeast: LatLng(
        json['northeast']['latitude'] as double,
        json['northeast']['longitude'] as double,
      ),
      southwest: LatLng(
        json['southwest']['latitude'] as double,
        json['southwest']['longitude'] as double,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'northeast': {
        'latitude': northeast.latitude,
        'longitude': northeast.longitude,
      },
      'southwest': {
        'latitude': southwest.latitude,
        'longitude': southwest.longitude,
      },
    };
  }
}

/// Map filter options
class MapFilters {
  final String? category; // legacy single category/service slug (kept for backward compatibility)
  final double? minRating;
  final double? maxDistance; // in kilometers
  final bool? isAvailable;
  final MapMarkerType? markerType;
  final String? searchQuery;
  // NEW: list of service slugs; providers offering ANY of these should be shown
  final List<String>? servicesAny;

  const MapFilters({
    this.category,
    this.minRating,
    this.maxDistance,
    this.isAvailable,
    this.markerType,
    this.searchQuery,
    this.servicesAny,
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (category != null) params['category'] = category;
    if (minRating != null) params['minRating'] = minRating;
    if (maxDistance != null) params['maxDistance'] = maxDistance;
    if (isAvailable != null) params['isAvailable'] = isAvailable;
    if (markerType != null) params['type'] = markerType!.name;
    if (searchQuery != null) params['search'] = searchQuery;
    if (servicesAny != null && servicesAny!.isNotEmpty) {
      params['services'] = servicesAny!.join(',');
    }
    
    return params;
  }

  MapFilters copyWith({
    String? category,
    double? minRating,
    double? maxDistance,
    bool? isAvailable,
    MapMarkerType? markerType,
    String? searchQuery,
    List<String>? servicesAny,
  }) {
    return MapFilters(
      category: category ?? this.category,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      isAvailable: isAvailable ?? this.isAvailable,
      markerType: markerType ?? this.markerType,
      searchQuery: searchQuery ?? this.searchQuery,
      servicesAny: servicesAny ?? this.servicesAny,
    );
  }
}

/// User location data
class UserLocation {
  final LatLng position;
  final double accuracy; // in meters
  final DateTime timestamp;
  final bool isApproximate;

  const UserLocation({
    required this.position,
    required this.accuracy,
    required this.timestamp,
    this.isApproximate = false,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      position: LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      ),
      accuracy: json['accuracy'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isApproximate: json['isApproximate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'isApproximate': isApproximate,
    };
  }
}

/// Map state for managing map view
class MapState {
  final List<MapMarker> markers;
  final LatLng? userLocation;
  final MapBounds? visibleBounds;
  final MapFilters filters;
  final bool isLoading;
  final String? error;
  final MapMarker? selectedMarker;
  final bool isLocationPermissionGranted;
  final bool isLocationSharingEnabled;

  const MapState({
    this.markers = const [],
    this.userLocation,
    this.visibleBounds,
    this.filters = const MapFilters(),
    this.isLoading = false,
    this.error,
    this.selectedMarker,
    this.isLocationPermissionGranted = false,
    this.isLocationSharingEnabled = false,
  });

  MapState copyWith({
    List<MapMarker>? markers,
    LatLng? userLocation,
    MapBounds? visibleBounds,
    MapFilters? filters,
    bool? isLoading,
    String? error,
    MapMarker? selectedMarker,
    bool? isLocationPermissionGranted,
    bool? isLocationSharingEnabled,
  }) {
    return MapState(
      markers: markers ?? this.markers,
      userLocation: userLocation ?? this.userLocation,
      visibleBounds: visibleBounds ?? this.visibleBounds,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedMarker: selectedMarker ?? this.selectedMarker,
      isLocationPermissionGranted: isLocationPermissionGranted ?? this.isLocationPermissionGranted,
      isLocationSharingEnabled: isLocationSharingEnabled ?? this.isLocationSharingEnabled,
    );
  }
}

/// Distance calculation utilities
class MapUtils {
  /// Calculate distance between two points using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double lat1Rad = point1.latitude * (3.14159265359 / 180);
    final double lat2Rad = point2.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    final double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  /// Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  /// Get default map center for Palestine
  static LatLng get defaultPalestineCenter => const LatLng(31.9522, 35.2332); // Ramallah

  /// Get bounds for Palestine
  static MapBounds get palestineBounds => const MapBounds(
    northeast: LatLng(33.2774, 35.5739), // Northern border
    southwest: LatLng(31.2201, 34.2187), // Southern border
  );

  /// Check if coordinates are within Palestine bounds
  static bool isWithinPalestine(LatLng position) {
    final bounds = palestineBounds;
    return position.latitude >= bounds.southwest.latitude &&
           position.latitude <= bounds.northeast.latitude &&
           position.longitude >= bounds.southwest.longitude &&
           position.longitude <= bounds.northeast.longitude;
  }
}
