import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/provider.dart';
import 'base_api_service.dart';
import 'auth_service.dart';

class ProviderService with BaseApiService {
  // Front-end-only mode to bypass backend calls for Our Services tab.
  // Intentionally hard-disabled backend usage to keep the UI snappy.
  static bool frontendOnly = false; // Enable backend calls for service persistence
  static void useFrontendMocks([bool value = true]) => frontendOnly = value;
  
  // Static AuthService instance
  static AuthService? _authServiceInstance;
  static void setAuthService(AuthService authService) {
    _authServiceInstance = authService;
  }

  // Shared mock data that can be updated
  static List<Map<String, dynamic>> _mockServices = [
    // Empty list - new users start with no services
  ];

  // Fetch providers matching any of the selected services and optional city
  Future<List<ProviderModel>> fetchProviders({
    required List<String> servicesAny,
    String? city,
    String? sortBy, // 'rating' or 'price'
    String? sortOrder, // 'asc' | 'desc'
  }) async {
    // Always use mock data to avoid any backend latency on the Our Services tab
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 300));
      
      // Combine mock providers with real providers who have created services
      final mockProviders = _generateMockProviders();
      final realProviders = _generateProvidersFromCreatedServices(servicesAny);
      
      // Combine and return all providers
      final allProviders = [...mockProviders, ...realProviders];
      
      // Filter by city if specified
      if (city != null && city.isNotEmpty) {
        allProviders.removeWhere((provider) => 
          !provider.city.toLowerCase().contains(city.toLowerCase()));
      }
      
      // Sort if specified
      if (sortBy != null) {
        allProviders.sort((a, b) {
          switch (sortBy) {
            case 'rating':
              return sortOrder == 'desc' 
                ? b.ratingAverage.compareTo(a.ratingAverage)
                : a.ratingAverage.compareTo(b.ratingAverage);
            case 'price':
              return sortOrder == 'desc'
                ? b.hourlyRate.compareTo(a.hourlyRate)
                : a.hourlyRate.compareTo(b.hourlyRate);
            default:
              return 0;
          }
        });
      }
      
      return allProviders;
    }

    try {
      final queryParams = <String, String>{
        'services': servicesAny.join(','),
        if (city != null) 'city': city,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
      };

      final queryString = queryParams.isNotEmpty 
          ? '?${Uri(queryParameters: queryParams).query}' 
          : '';

      final response = await get('/providers$queryString');
      
      if (response['success'] == true && response['data'] != null) {
        final providersData = response['data']['providers'] as List;
        return providersData.map((data) => ProviderModel.fromJson(data)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error fetching providers: $e');
      return [];
    }
  }

  // Update service price
  Future<bool> updateServicePrice({
    required String serviceId,
    required Map<String, dynamic> price,
  }) async {
    if (frontendOnly) {
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 500));
      
      // Update the service price in mock data
      final serviceIndex = _mockServices.indexWhere((service) => service['_id'] == serviceId);
      if (serviceIndex != -1) {
        _mockServices[serviceIndex]['price'] = price;
      }
      
      return true; // Mock success
    }

    try {
      final response = await put('/services/$serviceId/provider', body: {
        'price': price,
      });
      
      // The response is a Map<String, dynamic> from base_api_service
      return response['success'] == true;
    } catch (e) {
      print('Error updating service price: $e');
      return false;
    }
  }

  // Create new service
  Future<bool> createService({
    required String title,
    required String description,
    required String category,
    required String subcategory,
    required Map<String, dynamic> price,
  }) async {
    if (frontendOnly) {
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 800));
      
      // Add the new service to mock data
      final newId = (_mockServices.length + 1).toString();
      final newService = {
        '_id': newId,
        'title': title,
        'description': description,
        'category': category,
        'subcategory': subcategory,
        'price': price,
        'isActive': true,
        'rating': {
          'average': 0.0,
        },
        'bookings': 0,
      };
      
      _mockServices.add(newService);
      return true; // Mock success
    }

    try {
      print('🔍 Debug: Creating service in backend...');
      print('🔍 Debug: Service data: {title: $title, category: $category, subcategory: $subcategory}');
      print('🔍 Debug: AuthService token: ${_authServiceInstance?.token != null ? 'Present' : 'Missing'}');
      if (_authServiceInstance?.token != null) {
        print('🔍 Debug: Token preview: ${_authServiceInstance!.token!.substring(0, 20)}...');
      }
      
      final response = await post('/services/provider', body: {
        'title': title,
        'description': description,
        'category': category,
        'subcategory': subcategory,
        'price': price,
        'location': {
          'serviceArea': 'Default Area',
          'radius': 10,
          'onSite': true,
          'remote': false,
        },
      }, headers: _getAuthHeaders());
      
      print('🔍 Debug: Backend response: $response');
      
      // The response is a Map<String, dynamic> from base_api_service
      return response['success'] == true;
    } catch (e) {
      print('🔍 Debug: Error creating service: $e');
      return false;
    }


  }

  // Get user's services
  // For new users, this should return an empty list since they haven't added any services yet
  Future<List<Map<String, dynamic>>> getUserServices() async {
    if (frontendOnly) {
      // Return mock services (including newly created ones)
      await Future.delayed(Duration(milliseconds: 300));
      return List.from(_mockServices); // Return mock services so newly created services appear
    }

    try {
      print('🔍 Debug: Fetching user services from backend...');
      final response = await get('/services/my-services', headers: _getAuthHeaders());
      print('🔍 Debug: Backend response: $response');
      
      // The response is a Map<String, dynamic> from base_api_service
      if (response['success'] == true) {
        final data = response['data'];
        final services = List<Map<String, dynamic>>.from(data['services'] ?? []);
        print('🔍 Debug: Found ${services.length} services in database');
        return services;
      }
      print('🔍 Debug: Backend returned success: false');
      return [];
    } catch (e) {
      print('🔍 Debug: Error fetching user services: $e');
      return [];
    }
  }

  // Activate services
  Future<bool> activateServices(List<String> serviceIds) async {
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 500));
      
      for (final serviceId in serviceIds) {
        final serviceIndex = _mockServices.indexWhere((service) => service['_id'] == serviceId);
        if (serviceIndex != -1) {
          _mockServices[serviceIndex]['isActive'] = true;
        }
      }
      
      return true;
    }

    try {
      final response = await put('/services/bulk-activate', body: {
        'serviceIds': serviceIds,
      }, headers: _getAuthHeaders());
      
      return response['success'] == true;
    } catch (e) {
      print('Error activating services: $e');
      return false;
    }
  }

  // Deactivate services
  Future<bool> deactivateServices(List<String> serviceIds) async {
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 500));
      
      for (final serviceId in serviceIds) {
        final serviceIndex = _mockServices.indexWhere((service) => service['_id'] == serviceId);
        if (serviceIndex != -1) {
          _mockServices[serviceIndex]['isActive'] = false;
        }
      }
      
      return true;
    }

    try {
      final response = await put('/services/bulk-deactivate', body: {
        'serviceIds': serviceIds,
      }, headers: _getAuthHeaders());
      
      return response['success'] == true;
    } catch (e) {
      print('Error deactivating services: $e');
      return false;
    }
  }

  // Delete service
  Future<bool> deleteService(String serviceId) async {
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 500));
      
      _mockServices.removeWhere((service) => service['_id'] == serviceId);
      return true;
    }

    try {
      final response = await delete('/services/$serviceId/provider', headers: _getAuthHeaders());
      return response['success'] == true;
    } catch (e) {
      print('Error deleting service: $e');
      return false;
    }
  }

  // Delete services (bulk)
  Future<bool> deleteServices(List<String> serviceIds) async {
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 500));
      
      _mockServices.removeWhere((service) => serviceIds.contains(service['_id']));
      return true;
    }

    try {
      final response = await post('/services/bulk-delete', body: {
        'serviceIds': serviceIds,
      });
      return response['success'] == true;
    } catch (e) {
      print('Error deleting services: $e');
      return false;
    }
  }

  // Update service
  Future<bool> updateService({
    required String serviceId,
    String? title,
    String? description,
    String? category,
    String? subcategory,
    Map<String, dynamic>? price,
    bool? isActive,
  }) async {
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 500));
      
      final serviceIndex = _mockServices.indexWhere((service) => service['_id'] == serviceId);
      if (serviceIndex != -1) {
        if (title != null) _mockServices[serviceIndex]['title'] = title;
        if (description != null) _mockServices[serviceIndex]['description'] = description;
        if (category != null) _mockServices[serviceIndex]['category'] = category;
        if (subcategory != null) _mockServices[serviceIndex]['subcategory'] = subcategory;
        if (price != null) _mockServices[serviceIndex]['price'] = price;
        if (isActive != null) _mockServices[serviceIndex]['isActive'] = isActive;
      }
      
      return true;
    }

    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (subcategory != null) updateData['subcategory'] = subcategory;
      if (price != null) updateData['price'] = price;
      if (isActive != null) updateData['isActive'] = isActive;

      final response = await put('/services/$serviceId/provider', body: updateData, headers: _getAuthHeaders());
      return response['success'] == true;
    } catch (e) {
      print('Error updating service: $e');
      return false;
    }
  }

  // Get service by ID
  Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 300));
      
      final service = _mockServices.firstWhere(
        (service) => service['_id'] == serviceId,
        orElse: () => <String, dynamic>{},
      );
      
      return service.isNotEmpty ? service : null;
    }

    try {
      final response = await get('/services/$serviceId', headers: _getAuthHeaders());
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching service: $e');
      return null;
    }
  }

  // List services with filters
  Future<Map<String, dynamic>> listServices({
    String? category,
    String? query,
    String? area,
    String? providerId,
    String? near,
    double? maxDistanceKm,
    int page = 1,
    int limit = 20,
  }) async {
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 300));
      
      // Simple mock filtering
      List<Map<String, dynamic>> filteredServices = List.from(_mockServices);
      
      if (category != null) {
        filteredServices = filteredServices.where((service) => service['category'] == category).toList();
      }
      
      if (query != null) {
        filteredServices = filteredServices.where((service) => 
          service['title'].toString().toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
      
      return {
        'services': filteredServices,
        'pagination': {
          'current': page,
          'total': 1,
          'totalRecords': filteredServices.length,
        }
      };
    }

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (query != null) 'q': query,
        if (area != null) 'area': area,
        if (providerId != null) 'providerId': providerId,
        if (near != null) 'near': near,
        if (maxDistanceKm != null) 'maxDistanceKm': maxDistanceKm.toString(),
      };

      final queryString = queryParams.isNotEmpty 
          ? '?${Uri(queryParameters: queryParams).query}' 
          : '';

      final response = await get('/services$queryString');
      
      if (response['success'] == true) {
        return response['data'];
      }
      
      return {
        'services': [],
        'pagination': {
          'current': page,
          'total': 0,
          'totalRecords': 0,
        }
      };
    } catch (e) {
      print('Error listing services: $e');
      return {
        'services': [],
        'pagination': {
          'current': page,
          'total': 0,
          'totalRecords': 0,
        }
      };
    }
  }

  // Upload service images
  Future<bool> uploadServiceImages(String serviceId, List<String> imagePaths) async {
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 1000));
      return true; // Mock success
    }

    try {
      // For now, we'll use a simple approach
      // In production, you'd want to implement proper file upload
      final response = await post('/services/$serviceId/images', body: {
        'images': imagePaths.map((path) => {'url': path, 'alt': ''}).toList(),
      });
      
      return response['success'] == true;
    } catch (e) {
      print('Error uploading service images: $e');
      return false;
    }
  }

  // Submit custom service request for admin approval
  Future<bool> submitCustomServiceRequest({
    required String title,
    required String description,
    required String fieldDescription,
    required String category,
    required String subcategory,
    required Map<String, dynamic> price,
  }) async {
    if (frontendOnly) {
      await Future.delayed(Duration(milliseconds: 800));
      return true; // Mock success
    }

    try {
      final response = await post('/services/custom-requests', body: {
        'title': title,
        'description': description,
        'fieldDescription': fieldDescription,
        'category': category,
        'subcategory': subcategory,
        'price': price,
        'status': 'pending_approval',
      }, headers: _getAuthHeaders());
      
      return response['success'] == true;
    } catch (e) {
      print('Error submitting custom service request: $e');
      return false;
    }
  }

  // Generate providers from created services
  List<ProviderModel> _generateProvidersFromCreatedServices(List<String> searchServices) {
    final List<ProviderModel> providers = [];
    final rnd = Random();
    
    // Get current user info to create a provider for them
    final authService = AuthService();
    final currentUser = authService.currentUser;
    
    if (currentUser != null && _mockServices.isNotEmpty) {
      // Create a provider for the current user with their created services
      final userServices = <String>[];
      double totalRate = 0;
      int totalBookings = 0;
      
      for (final service in _mockServices) {
        final serviceKey = _mapServiceTitleToKey(service['title']);
        if (serviceKey != null) {
          userServices.add(serviceKey);
          totalRate += (service['price']['amount'] as num).toDouble();
          totalBookings += service['bookings'] as int;
        }
      }
      
      // Check if any of the user's services match the search criteria
      final hasMatchingService = userServices.any((service) => 
        searchServices.contains(service));
      
      if (hasMatchingService && userServices.isNotEmpty) {
        final avgRate = totalRate / userServices.length;
        final avgRating = 4.0 + (rnd.nextDouble() * 1.0); // Random rating between 4.0-5.0
        
        providers.add(ProviderModel(
          id: 'user_${currentUser['_id']}',
          name: '${currentUser['firstName']} ${currentUser['lastName']}',
          city: 'Ramallah', // Default city
          phone: currentUser['phone'] ?? '+970590000000',
          experienceYears: 2 + rnd.nextInt(8),
          languages: ['Arabic', 'English'],
          hourlyRate: avgRate,
          services: userServices,
          ratingAverage: avgRating,
          ratingCount: totalBookings + rnd.nextInt(20),
          avatarUrl: null,
        ));
      }
    }
    
    return providers;
  }
  
  // Map service title to service key for search
  String? _mapServiceTitleToKey(String title) {
    final titleLower = title.toLowerCase();
    
    // Map common service titles to service keys
    if (titleLower.contains('cleaning')) return 'bedroomCleaning';
    if (titleLower.contains('cooking')) return 'mainDishes';
    if (titleLower.contains('babysitting') || titleLower.contains('childcare')) return 'homeBabysitting';
    if (titleLower.contains('elderly') || titleLower.contains('care')) return 'homeElderlyCare';
    if (titleLower.contains('maintenance')) return 'electricalWork';
    if (titleLower.contains('organizing')) return 'bedroomOrganizing';
    if (titleLower.contains('moving')) return 'furnitureMoving';
    
    // Default mapping
    return 'bedroomCleaning';
  }

  // Mock data generation for providers
  List<ProviderModel> _generateMockProviders() {
    final rnd = Random();
    
    final cities = [
      'Ramallah', 'Bethlehem', 'Nablus', 'Hebron', 'Jenin', 'Tulkarm', 'Qalqilya', 'Salfit', 'Tubas', 'Jericho'
    ];
    
    final languagePools = [
      ['Arabic', 'English'],
      ['Arabic', 'Hebrew'],
      ['Arabic', 'English', 'Hebrew'],
      ['Arabic'],
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
        id: 'pro_${j}',
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

  // Get auth headers
  Map<String, String> _getAuthHeaders() {
    final authService = _authServiceInstance ?? AuthService();
    final token = authService.token;
    
    print('🔍 Debug: AuthService token: ${token != null ? "Present" : "Missing"}');
    if (token != null) {
      print('🔍 Debug: Token preview: ${token.substring(0, 20)}...');
    }
    
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    print('🔍 Debug: Auth headers: $headers');
    return headers;
  }
}
