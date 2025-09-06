import 'package:flutter/foundation.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import 'services_service.dart';
import '../../core/constants/api_config.dart';

class ServiceCategoryModel {
  final String id;
  final String name;
  final String nameKey;
  final String description;
  final String icon;
  final String color;
  final List<String> services;
  final int? serviceCount;
  final List<ServiceModel>? actualServices;
  final bool? isDynamic;

  const ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.description,
    required this.icon,
    required this.color,
    required this.services,
    this.serviceCount,
    this.actualServices,
    this.isDynamic,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('?? Parsing category: ${json['name']} - actualServices: ${json['actualServices']?.length ?? 0}');
    }
    
    return ServiceCategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameKey: json['nameKey'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#000000',
      services: (json['services'] as List?)?.map((e) => e.toString()).toList() ?? [],
      serviceCount: json['serviceCount'],
      actualServices: (json['actualServices'] as List?)
          ?.map((e) {
            try {
              return ServiceModel.fromJson(e);
            } catch (error) {
              if (kDebugMode) {
                print('? Error parsing service: $error');
                print('? Service data: $e');
              }
              return null;
            }
          })
          .where((service) => service != null)
          .cast<ServiceModel>()
          .toList(),
      isDynamic: json['isDynamic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameKey': nameKey,
      'description': description,
      'icon': icon,
      'color': color,
      'services': services,
      if (serviceCount != null) 'serviceCount': serviceCount,
      if (actualServices != null) 'actualServices': actualServices!.map((e) => e.toJson()).toList(),
      if (isDynamic != null) 'isDynamic': isDynamic,
    };
  }
}

class ServiceCategoriesService with BaseApiService {
  static final ServiceCategoriesService _instance = ServiceCategoriesService._internal();
  factory ServiceCategoriesService() => _instance;
  ServiceCategoriesService._internal();

  // Cache for categories to avoid repeated API calls
  List<ServiceCategoryModel>? _cachedCategories;
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(hours: 1);

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

  /// Get all service categories
  Future<List<ServiceCategoryModel>> getCategories({bool forceRefresh = false}) async {
    // Return cached data if available and not expired
    if (!forceRefresh && 
        _cachedCategories != null && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheExpiry) {
      return _cachedCategories!;
    }

    try {
      final response = await get('/servicecategories', headers: _authHeaders);

      if (kDebugMode) {
        print('?? Fetched service categories: ${response['categories']?.length ?? 0} items');
      }

      final List<dynamic> categoriesData = response['categories'] ?? response['data'] ?? [];
      final categories = categoriesData
          .map((json) => ServiceCategoryModel.fromJson(json))
          .toList();

      // Cache the results
      _cachedCategories = categories;
      _lastFetch = DateTime.now();

      return categories;
    } catch (e) {
      if (kDebugMode) {
        print('? Error fetching service categories: $e');
        print('?? Falling back to hardcoded categories');
      }
      
      // Fallback to hardcoded categories if API fails
      return _getHardcodedCategories();
    }
  }

  /// Get categories with service counts
  Future<List<ServiceCategoryModel>> getCategoriesWithCounts({bool forceRefresh = false}) async {
    try {
      final response = await get('/servicecategories/counts', headers: _authHeaders);

      if (kDebugMode) {
        print('?? Fetched service categories with counts: ${response['categories']?.length ?? 0} items');
      }

      final List<dynamic> categoriesData = response['categories'] ?? response['data'] ?? [];
      final categories = categoriesData
          .map((json) => ServiceCategoryModel.fromJson(json))
          .toList();

      return categories;
    } catch (e) {
      if (kDebugMode) {
        print('? Error fetching service categories with counts: $e');
      }
      
      // Fallback to regular categories without counts
      return getCategories(forceRefresh: forceRefresh);
    }
  }

  /// Get categories with their actual services from the database
  Future<List<ServiceCategoryModel>> getCategoriesWithServices({bool forceRefresh = false}) async {
    try {
      final response = await get('/servicecategories/with-services', headers: _authHeaders);

      if (kDebugMode) {
        print('?? Fetched service categories with services: ${response['categories']?.length ?? 0} items');
        print('?? Response keys: ${response.keys}');
      }

      // Handle different response structures
      List<dynamic> categoriesData = [];
      if (response['data'] != null && response['data']['categories'] != null) {
        categoriesData = response['data']['categories'];
      } else if (response['categories'] != null) {
        categoriesData = response['categories'];
      } else if (response['data'] != null && response['data'] is List) {
        categoriesData = response['data'];
      }
      
      if (kDebugMode) {
        print('?? Raw categories data length: ${categoriesData.length}');
        if (categoriesData.isNotEmpty) {
          print('?? First category keys: ${categoriesData.first.keys}');
        }
      }
      
      final categories = categoriesData
          .map((json) => ServiceCategoryModel.fromJson(json))
          .toList();

      // If we got categories but they don't have services, try to fetch services separately
      if (categories.isNotEmpty && categories.every((cat) => cat.actualServices?.isEmpty ?? true)) {
        if (kDebugMode) {
          print('🔄 Categories found but no services linked, fetching services separately...');
        }
        return await _fetchCategoriesWithServicesFromDatabase(authService: null);
      }

      return categories;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching service categories with services: $e');
        print('🔄 Falling back to fetching services from database...');
      }
      
      // Fallback: fetch categories and services separately, then link them
      return await _fetchCategoriesWithServicesFromDatabase(authService: null);
    }
  }

  /// Get a specific category by ID
  Future<ServiceCategoryModel?> getCategoryById(String categoryId) async {
    try {
      final response = await get('/servicecategories/$categoryId', headers: _authHeaders);

      if (kDebugMode) {
        print('?? Fetched service category: $categoryId');
      }

      final categoryData = response['data'] ?? response;
      return ServiceCategoryModel.fromJson(categoryData);
    } catch (e) {
      if (kDebugMode) {
        print('? Error fetching service category $categoryId: $e');
      }
      
      // Try to find in cached categories
      if (_cachedCategories != null) {
        try {
          return _cachedCategories!.firstWhere((cat) => cat.id == categoryId);
        } catch (e) {
          return null;
        }
      }
      
      return null;
    }
  }

  /// Clear cache to force refresh on next request
  void clearCache() {
    _cachedCategories = null;
    _lastFetch = null;
  }

  /// Force refresh categories with services (bypasses any caching)
  Future<List<ServiceCategoryModel>> refreshCategoriesWithServices() async {
    return getCategoriesWithServices(forceRefresh: true);
  }

  /// Fallback method to fetch categories and services separately, then link them
  Future<List<ServiceCategoryModel>> _fetchCategoriesWithServicesFromDatabase({AuthService? authService}) async {
    try {
      // Get basic categories first
      final categories = await getCategories(forceRefresh: true);
      
      // Get all services from the database
      final servicesService = ServicesService();
      final allServices = await servicesService.getServices(
        limit: 1000, // Get a large number of services
        authService: authService ?? AuthService(), // Use provided authService or create new one
      );

      if (kDebugMode) {
        print('🛠️ Fetched ${allServices.length} services from database');
        print('📂 Categories: ${categories.length}');
        
        // Debug: Show all services and their categories
        for (final service in allServices) {
          print('🔍 Service: "${service.title}" -> Category: "${service.category}"');
          if (service.title.toLowerCase().contains('clean all')) {
            print('🎯 Found "clean all" service: "${service.title}" with category: "${service.category}"');
          }
        }
      }

      // Group services by category with improved matching logic
      final Map<String, List<ServiceModel>> servicesByCategory = {};
      for (final service in allServices) {
        final categoryId = service.category;
        if (categoryId.isNotEmpty) {
          // Try to match the service category with existing category IDs
          String matchedCategoryId = categoryId;
          
          // Check if the service category matches any existing category ID
          final matchingCategory = categories.firstWhere(
            (cat) => cat.id == categoryId || 
                     cat.id.toLowerCase() == categoryId.toLowerCase() ||
                     cat.name.toLowerCase() == categoryId.toLowerCase(),
            orElse: () => ServiceCategoryModel(
              id: '', name: '', nameKey: '', description: '', 
              icon: '', color: '', services: []
            ),
          );
          
          if (matchingCategory.id.isNotEmpty) {
            matchedCategoryId = matchingCategory.id;
          } else {
            // If no exact match, try to infer the category from the service name
            if (categoryId.toLowerCase().contains('clean') || 
                service.title.toLowerCase().contains('clean') ||
                service.title.toLowerCase().contains('clean all')) {
              matchedCategoryId = 'cleaning';
              if (kDebugMode && service.title.toLowerCase().contains('clean all')) {
                print('🎯 "Clean all" service matched to cleaning category');
              }
            } else if (categoryId.toLowerCase().contains('organiz') || 
                       service.title.toLowerCase().contains('organiz')) {
              matchedCategoryId = 'organizing';
            } else if (categoryId.toLowerCase().contains('cook') || 
                       service.title.toLowerCase().contains('cook')) {
              matchedCategoryId = 'cooking';
            } else if (categoryId.toLowerCase().contains('child') || 
                       service.title.toLowerCase().contains('child')) {
              matchedCategoryId = 'childcare';
            } else if (categoryId.toLowerCase().contains('elderly') || 
                       service.title.toLowerCase().contains('elderly')) {
              matchedCategoryId = 'elderly';
            } else if (categoryId.toLowerCase().contains('maintenance') || 
                       service.title.toLowerCase().contains('maintenance')) {
              matchedCategoryId = 'maintenance';
            } else if (categoryId.toLowerCase().contains('new home') || 
                       service.title.toLowerCase().contains('new home')) {
              matchedCategoryId = 'newhome';
            } else {
              matchedCategoryId = 'miscellaneous';
            }
          }
          
          servicesByCategory.putIfAbsent(matchedCategoryId, () => []).add(service);
        }
      }

      if (kDebugMode) {
        print('📂 Services grouped by category:');
        servicesByCategory.forEach((categoryId, services) {
          print('  - $categoryId: ${services.length} services');
          for (final service in services) {
            print('    * "${service.title}" (original category: "${service.category}")');
          }
        });
      }

      // Create new category models with the fetched services
      final categoriesWithServices = categories.map((category) {
        final categoryServices = servicesByCategory[category.id] ?? [];
        return ServiceCategoryModel(
          id: category.id,
          name: category.name,
          nameKey: category.nameKey,
          description: category.description,
          icon: category.icon,
          color: category.color,
          services: category.services,
          serviceCount: categoryServices.length,
          actualServices: categoryServices,
          isDynamic: category.isDynamic, 
        );
      }).toList();

      if (kDebugMode) {
        print('✅ Successfully linked services to categories');
        for (final cat in categoriesWithServices) {
          print('  - ${cat.name}: ${cat.actualServices?.length ?? 0} services');
        }
      }

      return categoriesWithServices;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in fallback method: $e');
      }
      
      // Final fallback to regular categories without services
      return getCategories(forceRefresh: true);
    }
  }

  /// Debug method to check if a specific service exists in the database
  Future<bool> checkServiceExists(String serviceTitle, {AuthService? authService}) async {
    try {
      final servicesService = ServicesService();
      final allServices = await servicesService.getServices(
        limit: 1000,
        authService: authService ?? AuthService(),
      );
      
      final serviceExists = allServices.any((service) => 
        service.title.toLowerCase().contains(serviceTitle.toLowerCase()));
      
      if (kDebugMode) {
        print('🔍 Service "$serviceTitle" exists: $serviceExists');
        if (serviceExists) {
          final matchingService = allServices.firstWhere((service) => 
            service.title.toLowerCase().contains(serviceTitle.toLowerCase()));
          print('🔍 Found service: "${matchingService.title}" with category: "${matchingService.category}"');
        }
      }
      
      return serviceExists;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking service existence: $e');
      }
      return false;
    }
  }

  /// Force add a service to a specific category (for debugging)
  Future<void> forceAddServiceToCategory(String serviceTitle, String categoryId, {AuthService? authService}) async {
    try {
      final servicesService = ServicesService();
      final allServices = await servicesService.getServices(
        limit: 1000,
        authService: authService ?? AuthService(),
      );
      
      final matchingService = allServices.firstWhere(
        (service) => service.title.toLowerCase().contains(serviceTitle.toLowerCase()),
        orElse: () => throw Exception('Service not found'),
      );
      
      if (kDebugMode) {
        print('🔧 Force adding service "${matchingService.title}" to category "$categoryId"');
        print('🔧 Original category: "${matchingService.category}"');
      }
      
      // Clear cache to force refresh
      clearCache();
      
      // Force refresh categories
      await refreshCategoriesWithServices();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error force adding service to category: $e');
      }
    }
  }

  /// Create a new service category (admin only)
  Future<ServiceCategoryModel?> createCategory({
    required String name,
    String? description,
    String? icon,
    String? color,
    required AuthService authService,
  }) async {
    try {
      final requestBody = {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        if (icon != null && icon.isNotEmpty) 'icon': icon,
        if (color != null && color.isNotEmpty) 'color': color,
      };

      // Use the authService parameter instead of _authHeaders
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
      };

      final response = await post(
        '/servicecategories',
        body: requestBody,
        headers: headers,
      );

      if (kDebugMode) {
        print('✅ Category created successfully: $name');
        print('📋 Response: $response');
      }

      final categoryData = response['data'] ?? response;
      final category = ServiceCategoryModel.fromJson(categoryData);
      
      // Clear cache to force refresh
      clearCache();
      
      return category;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating category: $e');
      }
      rethrow;
    }
  }

  /// Convert color string to Color object
  static int getColorFromString(String colorString) {
    // Remove # if present
    String hexColor = colorString.replaceAll('#', '');
    
    // Add alpha channel if not present
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    
    // Parse as integer
    return int.parse(hexColor, radix: 16);
  }

  /// Hardcoded fallback categories (matching backend structure)
  List<ServiceCategoryModel> _getHardcodedCategories() {
    return [
      const ServiceCategoryModel(
        id: 'cleaning',
        name: 'Cleaning Services',
        nameKey: 'cleaningServices',
        description: 'Professional cleaning services for your home',
        icon: 'cleaning_services',
        color: '#4CAF50',
        services: [
          'bedroomCleaning', 'livingRoomCleaning', 'kitchenCleaning', 'bathroomCleaning',
          'windowCleaning', 'doorCabinetCleaning', 'floorCleaning', 'carpetCleaning',
          'furnitureCleaning', 'gardenCleaning', 'entranceCleaning', 'stairCleaning',
          'garageCleaning', 'postEventCleaning', 'postConstructionCleaning', 
          'apartmentCleaning', 'regularCleaning'
        ],
      ),
      const ServiceCategoryModel(
        id: 'organizing',
        name: 'Organizing Services',
        nameKey: 'organizingServices',
        description: 'Professional organizing services for your home',
        icon: 'folder_open',
        color: '#2196F3',
        services: [
          'bedroomOrganizing', 'kitchenOrganizing', 'closetOrganizing', 'storageOrganizing',
          'livingRoomOrganizing', 'postPartyOrganizing', 'fullHouseOrganizing', 'childrenOrganizing'
        ],
      ),
      const ServiceCategoryModel(
        id: 'cooking',
        name: 'Home Cooking Services',
        nameKey: 'homeCookingServices',
        description: 'Professional cooking services for your home',
        icon: 'restaurant',
        color: '#FF9800',
        services: [
          'mainDishes', 'desserts', 'specialRequests'
        ],
      ),
      const ServiceCategoryModel(
        id: 'childcare',
        name: 'Child Care Services',
        nameKey: 'childCareServices',
        description: 'Professional childcare services',
        icon: 'child_care',
        color: '#E91E63',
        services: [
          'homeBabysitting', 'schoolAccompaniment', 'homeworkHelp', 
          'educationalActivities', 'childrenMealPrep', 'sickChildCare'
        ],
      ),
      const ServiceCategoryModel(
        id: 'elderly',
        name: 'Personal & Elderly Care',
        nameKey: 'personalElderlyCareServices',
        description: 'Compassionate care for elderly individuals',
        icon: 'elderly',
        color: '#9C27B0',
        services: [
          'personalCare', 'companionship', 'medicationReminders', 
          'lightHousekeeping', 'mealPreparation', 'transportationAssistance'
        ],
      ),
      const ServiceCategoryModel(
        id: 'maintenance',
        name: 'Home Maintenance',
        nameKey: 'homeMaintenanceServices',
        description: 'Professional home maintenance and repair services',
        icon: 'handyman',
        color: '#795548',
        services: [
          'generalRepairs', 'plumbing', 'electrical', 'painting',
          'furnitureAssembly', 'applianceInstallation'
        ],
      ),
      const ServiceCategoryModel(
        id: 'newhome',
        name: 'New Home Setup',
        nameKey: 'newHomeSetupServices',
        description: 'Complete setup services for your new home',
        icon: 'home',
        color: '#607D8B',
        services: [
          'movingIn', 'unpacking', 'organizing', 'deepCleaning',
          'furnitureArrangement', 'kitchenSetup'
        ],
      ),
      const ServiceCategoryModel(
        id: 'miscellaneous',
        name: 'Miscellaneous Services',
        nameKey: 'miscellaneousServices',
        description: 'Various other helpful services',
        icon: 'miscellaneous_services',
        color: '#9E9E9E',
        services: [
          'petCare', 'gardenWork', 'eventPreparation', 'specialProjects'
        ],
      ),
    ];
  }
}
