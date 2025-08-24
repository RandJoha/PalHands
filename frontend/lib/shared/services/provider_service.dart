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
  }) async {
    // Use mock data if frontend-only mode is enabled
    if (frontendOnly) {
      final items = _mockProviders();
      return items.where((p) {
        final matchesServices = servicesAny.isEmpty || p.services.any((s) => servicesAny.contains(s));
        final matchesCity = city == null || city.isEmpty || p.city.toLowerCase() == city.toLowerCase();
        return matchesServices && matchesCity;
      }).toList()
        ..sort((a, b) {
          if (sortBy == 'price') {
            return sortOrder == 'asc' ? a.hourlyRate.compareTo(b.hourlyRate) : b.hourlyRate.compareTo(a.hourlyRate);
          } else if (sortBy == 'rating') {
            // Weighted rating using Bayesian average to consider review count
            // score = (v/(v+C))*R + (C/(v+C))*m, where m is global mean and C is prior weight
            final m = items.isEmpty ? 0.0 : items.map((e) => e.ratingAverage).reduce((x, y) => x + y) / items.length;
            const C = 20.0;
            double score(ProviderModel p) {
              final v = p.ratingCount.toDouble();
              final R = p.ratingAverage;
              return (v / (v + C)) * R + (C / (v + C)) * m;
            }
            final sA = score(a);
            final sB = score(b);
            return sortOrder == 'asc' ? sA.compareTo(sB) : sB.compareTo(sA);
          }
          return 0;
        });
    }

    // Use real backend API
    try {
      final queryParams = <String, String>{};
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      
      // Add services filter if any services are selected
      if (servicesAny.isNotEmpty) {
        queryParams['services'] = servicesAny.join(',');
      }

      final endpoint = '/providers${queryParams.isNotEmpty 
              ? '?${Uri(queryParameters: queryParams).query}' 
              : ''}';

      final response = await get(endpoint, headers: _authHeaders);

      if (kDebugMode) {
        print('🏢 Fetched providers: ${response['data']?.length ?? 0} items');
      }

      final List<dynamic> providersData = response['data'] ?? response['providers'] ?? [];
      return providersData
          .map((json) => ProviderModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching providers from backend: $e');
        print('🔄 Falling back to mock data');
      }
      
      // Fallback to mock data if backend fails
      final items = _mockProviders();
      return items.where((p) {
        final matchesServices = servicesAny.isEmpty || p.services.any((s) => servicesAny.contains(s));
        final matchesCity = city == null || city.isEmpty || p.city.toLowerCase() == city.toLowerCase();
        return matchesServices && matchesCity;
      }).toList();
    }
  }

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

      if (kDebugMode) {
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

      if (kDebugMode) {
        print('🏢 Fetched providers for category $category: ${response['data']?.length ?? 0} items');
      }

      final List<dynamic> providersData = response['data'] ?? response['providers'] ?? [];
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
      providers.add(ProviderModel(
        id: 'svc_$i',
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
      providers.add(ProviderModel(
        id: 'pro_$j',
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
