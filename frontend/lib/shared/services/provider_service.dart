import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/provider.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import '../../core/constants/api_config.dart';

class ProviderService with BaseApiService {
  // Frontend-only mode control for backward compatibility
  // Set to false to use real backend APIs
  static bool frontendOnly = false; // Changed to false to use backend by default
  static void useFrontendMocks([bool value = true]) => frontendOnly = value;

  // Get authentication token from AuthService
  Map<String, String> get _authHeaders {
    final token = AuthService().token;
    if (token != null) {
      return {
        'Authorization': 'Bearer $token',
        ...ApiConfig.defaultHeaders,
      };
    }
    return ApiConfig.defaultHeaders;
  }

  // Fetch providers matching any of the selected services and optional city
  Future<List<ProviderModel>> fetchProviders({
    required List<String> servicesAny,
    String? city,
    String? sortBy, // 'rating' or 'price'
    String? sortOrder, // 'asc' | 'desc'
    int? page,
    int? limit,
    String emergencyFilter = 'both', // 'both' | 'emergency' | 'normal'
  }) async {
    // 1. Frontend mock mode
    if (frontendOnly) {
      final items = _mockProviders();
      var filtered = items.where((p) {
        final matchesServices = servicesAny.isEmpty || p.services.any((s) => servicesAny.contains(s));
        final matchesCity = city == null || city.isEmpty || p.city.toLowerCase() == city.toLowerCase();
        return matchesServices && matchesCity;
      }).toList();
      _applySorting(filtered, sortBy, sortOrder);
      return filtered;
    }

    try {
      List<ProviderModel> providers = [];

      if (servicesAny.isNotEmpty) {
        // 2. Prefer expanded endpoint for detailed per-service linkage
        final endpoint = '/provider-services/public/providers-by-services-expanded?serviceIds=${servicesAny.join(',')}';
        final response = await get(endpoint, headers: _authHeaders);
        dynamic raw = response['data'] ?? response['providers'] ?? response['results'];
        if (raw is Map<String, dynamic>) {
          raw = raw['data'] ?? raw['items'] ?? raw['providers'] ?? raw['results'] ?? [];
        }
        final rawList = (raw is List) ? raw : <dynamic>[];
        providers = rawList.map((j) => ProviderModel.fromJson(j)).toList();

        // if (kDebugMode) {
        //   print('🏢 providers-by-services-expanded => ${providers.length} providers (selected=${servicesAny.length})');
        // }

        // Optional city filter (backend endpoint might not support city yet)
        if (city != null && city.isNotEmpty) {
          providers = providers.where((p) => p.city.toLowerCase() == city.toLowerCase()).toList();
        }
      } else {
        // 3. Generic /providers listing (no service filter)
        final qp = <String, String>{};
        if (city != null && city.isNotEmpty) qp['city'] = city;
        if (page != null) qp['page'] = page.toString();
        if (limit != null) qp['limit'] = limit.toString();
        if (sortBy != null) qp['sortBy'] = sortBy;
        if (sortOrder != null) qp['sortOrder'] = sortOrder;
        final endpoint = '/providers${qp.isNotEmpty ? '?${Uri(queryParameters: qp).query}' : ''}';
        final response = await get(endpoint, headers: _authHeaders);
        dynamic raw = response['data'] ?? response['providers'] ?? response['results'];
        if (raw is Map<String, dynamic>) {
          raw = raw['data'] ?? raw['items'] ?? raw['providers'] ?? raw['results'] ?? [];
        }
        final rawList = (raw is List) ? raw : <dynamic>[];
        providers = rawList.map((j) => ProviderModel.fromJson(j)).toList();
        // if (kDebugMode) {
        //   print('🏢 /providers => ${providers.length} providers (no service filter)');
        // }
      }

      // 4. Emergency filter placeholder (currently pass-through)
      if (emergencyFilter != 'both') {
        // Future: refine when provider emergency capabilities exposed.
      }

      // 5. Secondary service verification (only if backend returned a superset – should not be needed now)
      // We trust backend; only apply if we detect provider.services missing or looks broader.
      if (servicesAny.isNotEmpty) {
        final hasObjectIds = servicesAny.any((s) => RegExp(r'^[a-f0-9]{24}$', caseSensitive: false).hasMatch(s));
        if (!hasObjectIds) {
          final selectedNorm = servicesAny.map(_normalizeServiceKey).toSet();
          providers = providers.where((p) => p.services.map(_normalizeServiceKey).toSet().intersection(selectedNorm).isNotEmpty).toList();
        }
      }

      // 6. Sorting (fallback if backend didn't sort)
      _applySorting(providers, sortBy, sortOrder);
      return providers;
    } catch (e) {
      if (kDebugMode) {
        print('❌ fetchProviders error: $e');
      }
      return [];
    }
  }

  void _applySorting(List<ProviderModel> list, String? sortBy, String? sortOrder) {
    if (list.isEmpty || sortBy == null) return;
    if (sortBy == 'price') {
      list.sort((a, b) => (sortOrder == 'desc') ? b.hourlyRate.compareTo(a.hourlyRate) : a.hourlyRate.compareTo(b.hourlyRate));
    } else if (sortBy == 'rating') {
      list.sort((a, b) => (sortOrder == 'desc') ? b.ratingAverage.compareTo(a.ratingAverage) : a.ratingAverage.compareTo(b.ratingAverage));
    }
  }

  String _normalizeServiceKey(String v) => v.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');


  /// Get a specific provider by ID
  Future<ProviderModel?> getProviderById(String providerId) async {
    if (frontendOnly) {
      final providers = _mockProviders();
      try {
        return providers.firstWhere((p) => p.id == providerId);
      } catch (e) {
        return null;
      }
    }

    try {
      final response = await get(
        '/providers/$providerId',
        headers: _authHeaders,
      );

      if (kDebugMode && ApiConfig.enableLogging) {
        print('🏢 Fetched provider: $providerId');
      }

      final providerData = response['data'] ?? response;
      return ProviderModel.fromJson(providerData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching provider $providerId: $e');
      }
      return null;
    }
  }

  /// Get providers by category
  Future<List<ProviderModel>> getProvidersByCategory(
    String category, {
    String? city,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) async {
    if (frontendOnly) {
      final items = _mockProviders();
      return items.where((p) {
        final matchesCategory = p.services.any((s) => s.toLowerCase().contains(category.toLowerCase()));
        final matchesCity = city == null || city.isEmpty || p.city.toLowerCase() == city.toLowerCase();
        return matchesCategory && matchesCity;
      }).toList();
    }

    try {
      final queryParams = <String, String>{
        'category': category,
      };
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final endpoint = '/providers/category/$category${queryParams.length > 1 
              ? '?${Uri(queryParameters: queryParams..remove('category')).query}' 
              : ''}';

      final response = await get(endpoint, headers: _authHeaders);

      // Extract providers array from various backend shapes
      dynamic raw = response['data'] ?? response['providers'] ?? response['results'];
      if (raw is Map<String, dynamic>) {
        raw = raw['data'] ?? raw['providers'] ?? raw['items'] ?? raw['results'] ?? [];
      }
      final List<dynamic> providersData = (raw is List) ? raw : <dynamic>[];

      if (kDebugMode && ApiConfig.enableLogging) {
        print('🏢 Fetched providers for category $category: ${providersData.length} items');
      }
      return providersData
          .map((json) => ProviderModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching providers for category $category: $e');
      }
      return [];
    }
  }

  List<ProviderModel> _mockProviders() {
    // Curated, realistic mock providers ensuring at least one provider per service
    final rnd = Random(3);
    final cities = ['Ramallah', 'Nablus', 'Jerusalem', 'Hebron', 'Bethlehem', 'Gaza'];
    final languagePools = [
      ['Arabic'],
      ['Arabic', 'English'],
      ['Arabic', 'Hebrew'],
      ['Arabic', 'Turkish'],
    ];

    // All service keys used in categories UI
    final allServices = <String>[
      // Cleaning
      'bedroomCleaning','livingRoomCleaning','kitchenCleaning','bathroomCleaning','windowCleaning','doorCabinetCleaning','floorCleaning','carpetCleaning','furnitureCleaning','gardenCleaning','entranceCleaning','stairCleaning','garageCleaning','postEventCleaning','postConstructionCleaning','apartmentCleaning','regularCleaning',
      // Organizing
      'bedroomOrganizing','kitchenOrganizing','closetOrganizing','storageOrganizing','livingRoomOrganizing','postPartyOrganizing','fullHouseOrganizing','childrenOrganizing',
      // Cooking
      'mainDishes','desserts','specialRequests',
      // Childcare
      'homeBabysitting','schoolAccompaniment','homeworkHelp','educationalActivities','childrenMealPrep','sickChildCare',
      // Elderly
      'homeElderlyCare','medicalTransport','healthMonitoring','medicationAssistance','emotionalSupport','mobilityAssistance',
      // Maintenance
      'electricalWork','plumbingWork','aluminumWork','carpentryWork','painting','hangingItems','satelliteInstallation','applianceMaintenance',
      // New Home
      'furnitureMoving','packingUnpacking','furnitureWrapping','newHomeArrangement','newApartmentCleaning','preOccupancyRepairs','kitchenSetup','applianceInstallation',
      // Misc
      'documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup',
    ];

    final names = <String>[
      // English
      'Rami Services','Maya Haddad','Omar Khalil','Sara Nasser','Khaled Mansour','Yara Saleh','Hadi Suleiman','Noor Ali','Lina Faris','Osama T.',
      'Adam Q.', 'Layla Z.', 'Sami R.', 'Dana M.', 'Fares K.',
      // Arabic
      'محمد العابد','سارة يوسف','ليلى حسن','أحمد درويش','نور الهدى','مريم خليل','رامي ناصر','عمر عوض','هالة سمير','رنا أحمد',
    ];

    final List<ProviderModel> providers = [];

    // Ensure coverage: create one provider per service at minimum
    for (var i = 0; i < allServices.length; i++) {
      final name = names[i % names.length];
      final city = cities[i % cities.length];
      final langs = languagePools[i % languagePools.length];
      final baseRate = 45 + (i % 50) + rnd.nextInt(20);
      // Generate ObjectId-like strings for realistic mock data  
      final objectIdHex = (1000000 + i).toRadixString(16).padLeft(24, '6');
      providers.add(ProviderModel(
        id: objectIdHex,
        providerId: 1000 + i, // Add provider ID starting from 1000
        name: name,
        city: city,
        phone: '+97059${rnd.nextInt(9999999).toString().padLeft(7, '0')}',
        experienceYears: 1 + (i % 10),
        languages: List<String>.from(langs),
        hourlyRate: baseRate.toDouble(),
        services: [allServices[i], if (i + 1 < allServices.length) allServices[i + 1]],
        ratingAverage: 3.8 + (rnd.nextDouble() * 1.2),
        ratingCount: 8 + (i % 90),
        avatarUrl: null,
      ));
    }

    // Add some multi-service, higher-review providers
    for (var j = 0; j < 18; j++) {
      final s = <String>{};
      for (var k = 0; k < 5; k++) {
        s.add(allServices[(j * 3 + k * 7) % allServices.length]);
      }
      // Generate ObjectId-like strings for multi-service providers
      final objectIdHex = (2000000 + j).toRadixString(16).padLeft(24, '6');
      providers.add(ProviderModel(
        id: objectIdHex,
        providerId: 1100 + j, // Add provider ID starting from 1100 for multi-service providers
        name: names[(j + 7) % names.length],
        city: cities[(j + 3) % cities.length],
        phone: '+97059${rnd.nextInt(9999999).toString().padLeft(7, '0')}',
        experienceYears: 3 + (j % 12),
        languages: List<String>.from(languagePools[(j + 1) % languagePools.length]),
        hourlyRate: 60 + rnd.nextInt(100).toDouble(),
        services: s.toList(),
        ratingAverage: 4.2 + (rnd.nextDouble() * 0.7),
        ratingCount: 40 + rnd.nextInt(260),
        avatarUrl: null,
      ));
    }

    return providers;
  }
}
