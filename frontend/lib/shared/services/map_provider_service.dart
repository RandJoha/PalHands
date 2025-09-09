import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/provider.dart';
import '../models/map_models.dart';
import 'base_api_service.dart';
import 'provider_service.dart';

/// Service that fetches real provider data and converts it for map usage
/// Uses the same data source as "Our Services" to ensure consistency
class MapProviderService with BaseApiService {
  static const String _tag = 'MapProviderService';
  final ProviderService _providerService = ProviderService();

  // Normalize service key: lowercase alphanumerics only
  String _normalize(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');

  /// Get providers from the same source as "Our Services" and convert to map format
  Future<MapProviderData> getProvidersForMap({
    required MapBounds bounds,
    MapFilters? filters,
  }) async {
    try {
      // Use ProviderService to get the exact same data as "Our Services"
      // This ensures both the map and "Our Services" show identical provider information
      final providers = await _providerService.fetchProviders(
        servicesAny: (filters?.servicesAny != null && filters!.servicesAny!.isNotEmpty)
            ? filters.servicesAny!
            : <String>[],
        city: null, // City filter currently handled at page level
        sortBy: null,
        sortOrder: null,
        limit: 100,
      );
      
      // if (kDebugMode) {
      //   print('🗺️ MapProviderService: Using same data source as "Our Services"');
      //   print('🗺️ Total providers loaded: ${providers.length}');
      //   final lilaProviders = providers.where((p) => p.name.contains('ليلى')).toList();
      //   if (lilaProviders.isNotEmpty) {
      //     final lila = lilaProviders.first;
      //     print('🗺️ ليلى حسن - ID: ${lila.id}, Provider ID: ${lila.providerId}, Services: ${lila.services.join(', ')}');
      //   }
      // }
      
    // Apply service filtering (ANY match) if servicesAny provided
    final serviceFiltered = (filters?.servicesAny != null && filters!.servicesAny!.isNotEmpty)
      ? providers.where((p) {
          final sel = filters.servicesAny!;
          final selNorm = sel.map(_normalize).toSet();
          final provNorm = p.services.map(_normalize).toSet();
          final matches = provNorm.intersection(selNorm).isNotEmpty;
          if (!matches && kDebugMode) {
            print('🗺️ Filtering out provider ${p.id} (${p.name}) - services: ${p.services}');
          }
          return matches;
        }).toList()
      : providers;

    // Bounds filter (currently pass-through; keep for future geo filtering)
    final filteredProviders = serviceFiltered.where((provider) => _isProviderInBounds(provider, bounds)).toList();
      
      // Convert ProviderModels to MapMarkers with GPS coordinates using the same GPS override system
      final markers = filteredProviders.map((provider) => _providerToMapMarker(provider)).toList();

      return MapProviderData(
        providers: filteredProviders,
        markers: markers,
      );
    } catch (e) {
      // Fallback to dummy data on error
      return _generateDummyProviderData(bounds, filters);
    }
  }

  /// Get a specific provider by marker ID using the same data source as "Our Services"
  Future<ProviderModel?> getProviderByMarkerId(String markerId) async {
    try {
      // Use ProviderService to get provider by ID - same as "Our Services"
      return await _providerService.getProviderById(markerId);
    } catch (e) {
      // Fallback to dummy provider for old marker IDs
      return _generateDummyProviderFromMarkerId(markerId);
    }
  }

  /// Check if provider is within map bounds
  bool _isProviderInBounds(ProviderModel provider, MapBounds bounds) {
    // For now, include all providers since we don't have precise coordinates
    // In a real implementation, you'd check provider.addresses for coordinates
    return true;
  }

  /// Convert ProviderModel to MapMarker
  MapMarker _providerToMapMarker(ProviderModel provider) {
    // Use the same GPS override system as provider cards to ensure consistency
    final String gpsCity = _getProviderGpsCity(provider);
    LatLng coordinates = _generateProviderGpsCoordinates(gpsCity, provider.id);
    
    return MapMarker(
      id: provider.id,
      name: provider.name,
      position: coordinates,
      type: MapMarkerType.provider,
      category: provider.services.isNotEmpty ? provider.services.first : 'general',
      rating: provider.ratingAverage,
      reviewCount: provider.ratingCount,
      description: 'Professional ${provider.services.join(', ')} services',
      isAvailable: true, // Assume available for now
      lastSeenAt: DateTime.now(),
      distanceFromUser: null,
    );
  }

  /// Get the GPS-derived city name for a provider (same logic as category widgets)
  String _getProviderGpsCity(ProviderModel provider) {
    // Same GPS override mapping as used in category widgets
    final Map<String, String> providerGpsOverrides = {
      // Provider name -> actual GPS city (different from manual city)
      'ليلى حسن': 'hebron',        // Manual: Gaza -> GPS: Hebron  
      'رند 2': 'nablus',           // Manual: Tulkarm -> GPS: Nablus
      'rand 2': 'nablus',          // Manual: Tulkarm -> GPS: Nablus (English version)
      'أحمد علي': 'jerusalem',     // Manual: Ramallah -> GPS: Jerusalem
      'فاطمة محمد': 'bethlehem',   // Manual: Hebron -> GPS: Bethlehem
      'سارة يوسف': 'jenin',        // Manual: Nablus -> GPS: Jenin
      'محمد أحمد': 'ramallah',     // Manual: Gaza -> GPS: Ramallah
      'علياء سليم': 'tulkarm',     // Manual: Jenin -> GPS: Tulkarm
    };

    // Check if this provider has a GPS override (different GPS vs manual location)
    String gpsCity = providerGpsOverrides[provider.name] ?? provider.city.toLowerCase();
    
    // Ensure the GPS city is valid, fallback to ramallah if not found
    final validCities = ['ramallah', 'nablus', 'jerusalem', 'hebron', 'bethlehem', 'gaza', 'jenin', 'tulkarm', 'birzeit', 'qalqilya', 'salfit'];
    if (!validCities.contains(gpsCity)) {
      gpsCity = 'ramallah';
    }
    
    return gpsCity;
  }

  /// Generate realistic GPS coordinates for a provider within their city
  LatLng _generateProviderGpsCoordinates(String city, String providerId) {
    final cityCenter = _getCityCoordinates(city);
    
    // Use provider ID to generate consistent but varied coordinates
    final hash = providerId.hashCode.abs();
    final random = hash % 1000;
    
    // Generate offset within ~3km radius of city center for better separation
    final latOffset = ((random % 300) - 150) * 0.00018; // ~±3km in latitude
    final lngOffset = (((hash ~/ 1000) % 300) - 150) * 0.00018; // ~±3km in longitude
    
    return LatLng(
      cityCenter.latitude + latOffset,
      cityCenter.longitude + lngOffset,
    );
  }

  /// Get coordinates for Palestinian cities
  LatLng _getCityCoordinates(String city) {
    final cityCoordinates = {
      'ramallah': const LatLng(31.9522, 35.2332),
      'nablus': const LatLng(32.2211, 35.2544),
      'jerusalem': const LatLng(31.7683, 35.2137),
      'hebron': const LatLng(31.5326, 35.0998),
      'bethlehem': const LatLng(31.7054, 35.2024),
      'gaza': const LatLng(31.3547, 34.3088),
      'jenin': const LatLng(32.4615, 35.2969),
      'tulkarm': const LatLng(32.3128, 35.0273),
      'birzeit': const LatLng(31.9667, 35.1833), // Near Ramallah
      'qalqilya': const LatLng(32.1896, 34.9706),
      'salfit': const LatLng(32.0833, 35.1833),
    };

    return cityCoordinates[city.toLowerCase()] ?? const LatLng(31.9522, 35.2332);
  }

  /// Generate dummy provider data with real names from database (37 providers)
  MapProviderData _generateDummyProviderData(MapBounds bounds, MapFilters? filters) {
  final providers = <ProviderModel>[];
    final markers = <MapMarker>[];

    // Generate 37 dummy providers using real names and data from the database
    for (int i = 0; i < 37; i++) {
      final provider = _generateDummyProvider(i);
      final marker = _providerToMapMarker(provider);
      
      providers.add(provider);
      markers.add(marker);
    }

    // Apply servicesAny filter if present
    List<ProviderModel> filteredProviders = providers;
    if (filters?.servicesAny != null && filters!.servicesAny!.isNotEmpty) {
      final selNorm = filters.servicesAny!.map(_normalize).toSet();
      filteredProviders = providers.where((p) {
        final provNorm = p.services.map(_normalize).toSet();
        return provNorm.intersection(selNorm).isNotEmpty;
      }).toList();
    }
    final filteredMarkers = markers.where((m) {
      if (filters?.servicesAny == null || filters!.servicesAny!.isEmpty) return true;
      // marker.category holds first provider service; treat as match if in list
  final cat = m.category ?? '';
  return filters.servicesAny!.map(_normalize).contains(_normalize(cat));
    }).toList();

    return MapProviderData(
      providers: filteredProviders,
      markers: filteredMarkers,
    );
  }

  /// Generate a realistic dummy provider
  ProviderModel _generateDummyProvider(int index) {
    // Real cities from database for each provider (in order by providerId)
    final cities = [
      'ramallah', 'gaza', 'jerusalem', 'nablus', 'jerusalem',
      'bethlehem', 'jerusalem', 'hebron', 'jerusalem', 'ramallah',
      'ramallah', 'nablus', 'bethlehem', 'bethlehem', 'gaza',
      'gaza', 'nablus', 'nablus', 'gaza', 'hebron',
      'ramallah', 'hebron', 'tulkarm', 'hebron', 'gaza',
      'bethlehem', 'birzeit', 'hebron', 'hebron', 'jerusalem',
      'jerusalem', 'jerusalem', 'nablus', 'bethlehem', 'ramallah',
      'nablus', 'ramallah'
    ];
    final serviceCategories = [
      ['cleaning', 'housekeeping', 'deep cleaning'],
      ['organizing', 'home organizing', 'decluttering'],
      ['elderly care', 'companionship', 'assistance'],
      ['maintenance', 'repairs', 'handyman'],
    ];
    final names = [
      // All 37 real provider names from the database (sorted by providerId)
      'Sami R', 'Yara Saleh', 'Maya Haddad', 'Rami Services', 'Lina Faris',
      'ليلى حسن', 'Omar Khalil', 'Omar Khalil', 'مريم خليل', 'رنا أحمد',
      'Hadi Suleiman', 'Dana M', 'عمر عوض', 'Khaled Mansour', 'هالة سمير',
      'Layla Z', 'Noor Ali', 'Hadi Suleiman', 'Khaled Mansour', 'Osama T',
      'Rami Services', 'Lina Faris', 'rand 2', 'أحمد درويش', 'نور الهدى',
      'Adam Q', 'ahmad a', 'Sara Nasser', 'رامي ناصر', 'Fares K',
      'Test Provider', 'Noor Ali', 'نور الهدى', 'Sara Nasser', 'Yara Saleh',
      'Maya Haddad', 'أحمد درويش'
    ];

    final cityIndex = index < cities.length ? index : index % cities.length;
    final serviceIndex = index % serviceCategories.length;
    final nameIndex = index < names.length ? index : index % names.length;

    return ProviderModel(
      id: 'provider_${1000 + index}',
      providerId: 1000 + index,
      name: names[nameIndex],
      city: cities[cityIndex],
      phone: '+970${590000000 + index}',
      experienceYears: 2 + (index % 8),
      languages: ['Arabic', if (index % 3 == 0) 'English', if (index % 5 == 0) 'Hebrew'],
      hourlyRate: (50 + (index % 10) * 10).toDouble(),
      services: serviceCategories[serviceIndex],
      ratingAverage: 4.0 + (index % 10) / 10.0,
      ratingCount: 5 + (index % 50),
      avatarUrl: null,
    );
  }

  /// Generate dummy provider from marker ID
  ProviderModel _generateDummyProviderFromMarkerId(String markerId) {
    final hash = markerId.hashCode.abs();
    final index = hash % 37; // Match the 37 providers
    return _generateDummyProvider(index);
  }
}

/// Data class that holds both providers and their corresponding map markers
class MapProviderData {
  final List<ProviderModel> providers;
  final List<MapMarker> markers;

  const MapProviderData({
    required this.providers,
    required this.markers,
  });

  /// Get provider by marker ID
  ProviderModel? getProviderByMarkerId(String markerId) {
    try {
      return providers.firstWhere((p) => p.id == markerId);
    } catch (e) {
      return null;
    }
  }
}
