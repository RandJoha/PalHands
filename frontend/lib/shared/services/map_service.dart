import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/api_config.dart';
import '../models/map_models.dart';
import 'base_api_service.dart';

class MapService with BaseApiService {
  static const String _tag = 'MapService';

  /// Get providers within map bounds
  Future<List<MapMarker>> getProvidersInBounds({
    required MapBounds bounds,
    MapFilters? filters,
  }) async {
    try {
      final queryParams = <String, String>{
        'northeast_lat': bounds.northeast.latitude.toString(),
        'northeast_lng': bounds.northeast.longitude.toString(),
        'southwest_lat': bounds.southwest.latitude.toString(),
        'southwest_lng': bounds.southwest.longitude.toString(),
      };

      // Add filter parameters
      if (filters != null) {
        queryParams.addAll(filters.toQueryParams().map(
          (key, value) => MapEntry(key, value.toString()),
        ));
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/map/providers').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> markersJson = data['markers'] ?? [];
        
        return markersJson
            .map((json) => MapMarker.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        // Fallback: generate dummy markers inside given bounds
        return _generateDummyProvidersInBounds(bounds, filters);
      } else {
        throw Exception('Failed to load providers: ${response.statusCode}');
      }
    } catch (e) {
      logError('getProvidersInBounds', e);
      rethrow;
    }
  }

  /// Get nearest providers to user location
  Future<List<MapMarker>> getNearestProviders({
    required LatLng userLocation,
    int limit = 10,
    MapFilters? filters,
  }) async {
    try {
      final queryParams = <String, String>{
        'lat': userLocation.latitude.toString(),
        'lng': userLocation.longitude.toString(),
        'limit': limit.toString(),
      };

      // Add filter parameters
      if (filters != null) {
        queryParams.addAll(filters.toQueryParams().map(
          (key, value) => MapEntry(key, value.toString()),
        ));
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/map/nearest').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> markersJson = data['markers'] ?? [];
        
        return markersJson
            .map((json) => MapMarker.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        // Fallback to generated nearby markers
        return _generateDummyNearest(userLocation, limit, filters);
      } else {
        throw Exception('Failed to load nearest providers: ${response.statusCode}');
      }
    } catch (e) {
      logError('getNearestProviders', e);
      rethrow;
    }
  }

  /// Update user's current location
  Future<bool> updateUserLocation({
    required LatLng position,
    double accuracy = 0.0,
    bool isApproximate = false,
  }) async {
    try {
      final body = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': accuracy,
        'isApproximate': isApproximate,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.usersUrl}/location'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      logError('updateUserLocation', e);
      return false;
    }
  }

  /// Get user's saved location preferences
  Future<Map<String, dynamic>> getUserLocationPreferences() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usersUrl}/location-preferences'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'isLocationSharingEnabled': false,
          'lastKnownLocation': null,
        };
      }
    } catch (e) {
      logError('getUserLocationPreferences', e);
      return {
        'isLocationSharingEnabled': false,
        'lastKnownLocation': null,
      };
    }
  }

  /// Update user's location sharing preference
  Future<bool> updateLocationSharingPreference(bool enabled) async {
    try {
      final body = {
        'isLocationSharingEnabled': enabled,
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.usersUrl}/location-preferences'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      logError('updateLocationSharingPreference', e);
      return false;
    }
  }

  /// Get provider details for map marker
  Future<Map<String, dynamic>?> getProviderDetails(String providerId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.providersUrl}/$providerId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      logError('getProviderDetails', e);
      return null;
    }
  }

  /// Search providers by text query
  Future<List<MapMarker>> searchProviders({
    required String query,
    LatLng? userLocation,
    MapFilters? filters,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
      };

      if (userLocation != null) {
        queryParams['lat'] = userLocation.latitude.toString();
        queryParams['lng'] = userLocation.longitude.toString();
      }

      // Add filter parameters
      if (filters != null) {
        queryParams.addAll(filters.toQueryParams().map(
          (key, value) => MapEntry(key, value.toString()),
        ));
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/map/search').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> markersJson = data['markers'] ?? [];
        
        return markersJson
            .map((json) => MapMarker.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 404) {
        // Fallback: generate a small list filtered by query (client-side contains)
        final dummy = _generateDummyNearest(
          userLocation ?? MapUtils.defaultPalestineCenter,
          10,
          filters,
        );
        return (await dummy)
            .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      } else {
        throw Exception('Failed to search providers: ${response.statusCode}');
      }
    } catch (e) {
      logError('searchProviders', e);
      rethrow;
    }
  }

  /// Get map statistics (total providers, categories, etc.)
  Future<Map<String, dynamic>> getMapStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/map/statistics'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        // Fallback: synthetic stats
        return {
          'totalProviders': 20,
          'categories': <String>['cleaning','organizing','elderly','maintenance'],
          'averageRating': 4.5,
        };
      } else {
        return {
          'totalProviders': 0,
          'categories': <String>[],
          'averageRating': 0.0,
        };
      }
    } catch (e) {
      logError('getMapStatistics', e);
      return {
        'totalProviders': 0,
        'categories': <String>[],
        'averageRating': 0.0,
      };
    }
  }

  /// Get available service categories for filtering
  Future<List<String>> getServiceCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.servicesUrl}/categories'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['categories'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      logError('getServiceCategories', e);
      return [];
    }
  }

  /// Geocode address to coordinates
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final queryParams = <String, String>{
        'address': address,
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/map/geocode').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          return LatLng(lat, lng);
        }
      }
      return null;
    } catch (e) {
      logError('geocodeAddress', e);
      return null;
    }
  }

  /// Reverse geocode coordinates to address
  Future<String?> reverseGeocode(LatLng position) async {
    try {
      final queryParams = <String, String>{
        'lat': position.latitude.toString(),
        'lng': position.longitude.toString(),
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}/map/reverse-geocode').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['address'] as String?;
      }
      return null;
    } catch (e) {
      logError('reverseGeocode', e);
      return null;
    }
  }

  @override
  void logError(String method, dynamic error) {
    if (ApiConfig.enableLogging) {
      print('[$_tag] Error in $method: $error');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    // TODO: Inject auth token if available
    return ApiConfig.defaultHeaders;
  }

  // -------- Dummy data helpers (404 fallbacks) --------
  static final List<MapEntry<String, LatLng>> _palestineCityCenters = [
    MapEntry('Ramallah', LatLng(31.9026, 35.1959)),
    MapEntry('Jerusalem', LatLng(31.7683, 35.2137)),
    MapEntry('Hebron', LatLng(31.5326, 35.0998)),
    MapEntry('Bethlehem', LatLng(31.7054, 35.2024)),
    MapEntry('Nablus', LatLng(32.2211, 35.2544)),
    MapEntry('Jenin', LatLng(32.4637, 35.2956)),
    MapEntry('Tulkarm', LatLng(32.3116, 35.0260)),
    MapEntry('Qalqilya', LatLng(32.1897, 34.9720)),
    MapEntry('Salfit', LatLng(32.0850, 35.1809)),
    MapEntry('Tubas', LatLng(32.3215, 35.3699)),
    MapEntry('Jericho', LatLng(31.8560, 35.4590)),
    MapEntry('Gaza City', LatLng(31.5204, 34.4536)),
    MapEntry('Khan Younis', LatLng(31.3402, 34.3063)),
    MapEntry('Rafah', LatLng(31.2972, 34.2436)),
    MapEntry('Deir al-Balah', LatLng(31.4170, 34.3567)),
    MapEntry('Beit Lahia', LatLng(31.5464, 34.4951)),
    MapEntry('Beit Hanoun', LatLng(31.5361, 34.5356)),
    MapEntry('Yatta', LatLng(31.4460, 35.0989)),
    MapEntry('Dura', LatLng(31.5071, 35.0654)),
    MapEntry('Halhul', LatLng(31.5803, 35.1015)),
    MapEntry('Beit Jala', LatLng(31.7154, 35.1879)),
    MapEntry('Beit Sahour', LatLng(31.7050, 35.2296)),
    MapEntry('Qabatiya', LatLng(32.4097, 35.2806)),
    MapEntry('Azzun', LatLng(32.1752, 35.0566)),
    MapEntry('Abu Dis', LatLng(31.7627, 35.2619)),
    MapEntry('Al-Bireh', LatLng(31.9100, 35.2167)),
    MapEntry('Anabta', LatLng(32.3081, 35.1010)),
    MapEntry('Birzeit', LatLng(31.9731, 35.2097)),
    MapEntry('Beitunia', LatLng(31.9022, 35.1675)),
    MapEntry('Jabalia', LatLng(31.5329, 34.4884)),
    MapEntry('Nuseirat', LatLng(31.4475, 34.3925)),
    MapEntry('Bani Suheila', LatLng(31.3436, 34.3233)),
    MapEntry('Al-Zahra', LatLng(31.4697, 34.4228)),
  ];

  /// Expose a centroid for a known city name (case-insensitive); null if unknown
  LatLng? getCityCentroid(String? cityName) {
    if (cityName == null) return null;
    final lower = cityName.toLowerCase();
    for (final entry in _palestineCityCenters) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }

  /// Find the nearest known city centroid to the given position
  MapEntry<String, LatLng> findNearestCity(LatLng position) {
    MapEntry<String, LatLng>? best;
    double bestDist = double.infinity;
    for (final entry in _palestineCityCenters) {
      final d = MapUtils.calculateDistance(entry.value, position);
      if (d < bestDist) {
        bestDist = d;
        best = entry;
      }
    }
    return best ?? _palestineCityCenters.first;
  }

  Future<List<MapMarker>> _generateDummyProvidersInBounds(
    MapBounds bounds,
    MapFilters? filters,
  ) async {
    // Spread broadly across Palestine regardless of current bounds.
    // Generate at least 34 providers distributed over many cities.
    return _generateFromCities(_palestineCityCenters, math.max(34, 40), filters);
  }

  Future<List<MapMarker>> _generateDummyNearest(
    LatLng center,
    int limit,
    MapFilters? filters,
  ) async {
    // Sort all cities by distance from center, then take 'limit'
    final sorted = [..._palestineCityCenters]..sort((a, b) {
      final da = MapUtils.calculateDistance(a.value, center);
      final db = MapUtils.calculateDistance(b.value, center);
      return da.compareTo(db);
    });
    return _generateFromCities(sorted.take(math.max(limit, 34)).toList(), math.max(limit, 34), filters);
  }

  Future<List<MapMarker>> _generateFromCities(
    List<MapEntry<String, LatLng>> cities,
    int count,
    MapFilters? filters,
  ) async {
    final rnd = math.Random(42);
    final categories = <String>['cleaning','organizing','elderly','maintenance'];
    final List<MapMarker> markers = [];
    int i = 0;
    for (final entry in cities) {
      if (markers.length >= count) break;
      final base = entry.value;
      // Small jitter within ~200–500 meters to avoid exact overlap, staying within inhabited areas
      final jitterLat = (rnd.nextDouble() - 0.5) * 0.006; // ~0.66km max
      final jitterLng = (rnd.nextDouble() - 0.5) * 0.006;
      final pos = LatLng(base.latitude + jitterLat, base.longitude + jitterLng);
      if (!MapUtils.isWithinPalestine(pos)) {
        // fallback to base if jitter goes out of bounds
        markers.add(_buildDummyMarker(entry.key, base, i, categories, filters));
      } else {
        markers.add(_buildDummyMarker(entry.key, pos, i, categories, filters));
      }
      i++;
    }
    // Ensure at least 34
    while (markers.length < 34 && cities.isNotEmpty) {
      final entry = cities[markers.length % cities.length];
      final base = entry.value;
      final jitterLat = (rnd.nextDouble() - 0.5) * 0.008;
      final jitterLng = (rnd.nextDouble() - 0.5) * 0.008;
      final pos = LatLng(base.latitude + jitterLat, base.longitude + jitterLng);
      markers.add(_buildDummyMarker(entry.key, pos, markers.length, categories, filters));
    }
    return markers;
  }

  MapMarker _buildDummyMarker(
    String cityName,
    LatLng pos,
    int index,
    List<String> categories,
    MapFilters? filters,
  ) {
    // Single uniform color category for markers (logic keeps a category string but UI will color uniformly)
    final cat = filters?.category ?? 'general';
    final rating = 4.0 + (index % 10) / 10.0;
    return MapMarker(
      id: 'prov_${cityName.toLowerCase().replaceAll(' ', '_')}_$index',
      name: 'Provider ${index + 1} – $cityName',
      position: pos,
      type: MapMarkerType.provider,
      category: cat,
      rating: rating,
      reviewCount: 5 + (index % 30),
      description: 'Trusted $cat services in $cityName',
      isAvailable: (index % 3) != 0,
      lastSeenAt: DateTime.now().subtract(Duration(minutes: (index % 60))),
      distanceFromUser: null,
    );
  }
}
