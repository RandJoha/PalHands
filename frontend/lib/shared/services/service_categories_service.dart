import 'package:flutter/foundation.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
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

  const ServiceCategoryModel({
    required this.id,
    required this.name,
    required this.nameKey,
    required this.description,
    required this.icon,
    required this.color,
    required this.services,
    this.serviceCount,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      // Backend stores i18n key under 'name'; legacy clients used 'nameKey'
      nameKey: (json['nameKey'] ?? json['name'] ?? '') as String,
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#000000',
      services: (json['services'] as List?)?.map((e) => e.toString()).toList() ?? [],
      serviceCount: json['serviceCount'],
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

      // Backend uses unified ok({ data: ... }) wrapper
      final dynamic dataBlock = response['data'] ?? response;
      final List<dynamic> categoriesData = () {
        if (dataBlock is Map<String, dynamic> && dataBlock['categories'] is List) {
          return List<dynamic>.from(dataBlock['categories']);
        }
        if (dataBlock is List) return dataBlock;
        return <dynamic>[];
      }();
      if (kDebugMode) {
        print('📂 Fetched service categories: ${categoriesData.length} items');
      }
      final categories = categoriesData.map((json) => ServiceCategoryModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();

      // Cache the results
      _cachedCategories = categories;
      _lastFetch = DateTime.now();

      return categories;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching service categories: $e');
        print('🔄 Falling back to hardcoded categories');
      }
      
      // Fallback to hardcoded categories if API fails
      return _getHardcodedCategories();
    }
  }

  /// Get categories with service counts
  Future<List<ServiceCategoryModel>> getCategoriesWithCounts({bool forceRefresh = false}) async {
    try {
      final response = await get('/servicecategories/counts', headers: _authHeaders);
      final dynamic dataBlock = response['data'] ?? response;
      final List<dynamic> categoriesData = () {
        if (dataBlock is Map<String, dynamic> && dataBlock['categories'] is List) {
          return List<dynamic>.from(dataBlock['categories']);
        }
        if (dataBlock is List) return dataBlock;
        return <dynamic>[];
      }();
      if (kDebugMode) {
        print('📂 Fetched service categories with counts: ${categoriesData.length} items');
      }
      final categories = categoriesData.map((json) => ServiceCategoryModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();

      return categories;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching service categories with counts: $e');
      }
      
      // Fallback to regular categories without counts
      return getCategories(forceRefresh: forceRefresh);
    }
  }

  /// Get a specific category by ID
  Future<ServiceCategoryModel?> getCategoryById(String categoryId) async {
    try {
      final response = await get('/servicecategories/$categoryId', headers: _authHeaders);

      if (kDebugMode) {
        print('📂 Fetched service category: $categoryId');
      }

  final categoryData = response['data'] ?? response;
  return ServiceCategoryModel.fromJson(Map<String, dynamic>.from(categoryData as Map));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching service category $categoryId: $e');
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

  /// Get distinct service keys for a category from backend services collection
  Future<List<String>> getServicesForCategory(String categoryId) async {
    try {
      final response = await get('/servicecategories/$categoryId/services', headers: _authHeaders);
      final dynamic dataBlock = response['data'] ?? response;
      final List<dynamic> list = () {
        if (dataBlock is Map<String, dynamic> && dataBlock['services'] is List) {
          return List<dynamic>.from(dataBlock['services']);
        }
        if (dataBlock is List) return dataBlock;
        return <dynamic>[];
      }();
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching services for category $categoryId: $e');
      }
      return <String>[];
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
