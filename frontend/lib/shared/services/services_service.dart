import 'package:flutter/foundation.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import '../../core/constants/api_config.dart';
import 'provider_services_service.dart';

// Private cache entry with absolute expiry time
class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  _CacheEntry({required this.value, Duration ttl = const Duration(minutes: 1)})
      : expiresAt = DateTime.now().add(ttl);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class ProviderInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final RatingModel? rating;

  const ProviderInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.rating,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    return ProviderInfo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      rating: json['rating'] != null ? RatingModel.fromJson(json['rating']) : null,
    );
  }

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      if (rating != null) 'rating': rating!.toJson(),
    };
  }
}

class ServiceModel {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String category;
  final String? subcategory;
  final String providerId;
  // Optional years of experience specific to this service (per provider-service)
  final int? experienceYears;
  final ProviderInfo? provider;
  final PriceModel price;
  final LocationModel location;
  final List<String> images;
  final List<String> requirements;
  final List<String> equipment;
  final RatingModel rating;
  final int totalBookings;
  final bool isActive;
  final bool featured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool emergencyEnabled;
  final int emergencyLeadTimeMinutes;
  final String emergencySurchargeType; // flat | percent
  final double emergencySurchargeAmount;
  final double emergencyRateMultiplier;

  const ServiceModel({
    required this.id,
    this.slug = '',
    required this.title,
    required this.description,
    required this.category,
    this.subcategory,
    required this.providerId,
    this.experienceYears,
    this.provider,
    required this.price,
    required this.location,
    required this.images,
    required this.requirements,
    required this.equipment,
    required this.rating,
    required this.totalBookings,
    required this.isActive,
    required this.featured,
    required this.createdAt,
    required this.updatedAt,
    this.emergencyEnabled = false,
    this.emergencyLeadTimeMinutes = 120,
    this.emergencySurchargeType = 'flat',
    this.emergencySurchargeAmount = 0,
    this.emergencyRateMultiplier = 1.5,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
  slug: (json['slug'] ?? json['code'] ?? '')?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'],
      providerId: () {
        final p = json['provider'];
        if (p is Map<String, dynamic>) {
          return (p['_id'] ?? p['id'] ?? '').toString();
        }
        return p?.toString() ?? '';
      }(),
      // Prefer explicit per-service experience if provided; fallback-compatible with 'experience'
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? (json['experience'] as num?)?.toInt(),
      provider: json['provider'] is Map<String, dynamic> 
          ? ProviderInfo.fromJson(json['provider']) 
          : null,
      price: PriceModel.fromJson(json['price'] ?? {}),
      location: LocationModel.fromJson(json['location'] ?? {}),
      images: (json['images'] as List?)?.map((e) => e['url']?.toString() ?? '').toList() ?? [],
      requirements: (json['requirements'] as List?)?.map((e) => e.toString()).toList() ?? [],
      equipment: (json['equipment'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: RatingModel.fromJson(json['rating'] ?? {}),
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? true,
      featured: json['featured'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    emergencyEnabled: (json['emergencyEnabled'] ?? false) as bool,
    emergencyLeadTimeMinutes: (json['emergencyLeadTimeMinutes'] as num?)?.toInt() ?? 120,
    emergencySurchargeType: (json['emergencySurcharge'] is Map)
      ? ((json['emergencySurcharge']['type'] ?? 'flat').toString())
      : 'flat',
    emergencySurchargeAmount: (json['emergencySurcharge'] is Map)
      ? (((json['emergencySurcharge']['amount']) as num?)?.toDouble() ?? 0.0)
      : 0.0,
  emergencyRateMultiplier: (json['emergencyRateMultiplier'] as num?)?.toDouble() ?? 1.5,
    );
  }

  // Generate a simple slug from a title (fallback when backend doesn't provide one)
  static String generateSlug(String input) {
    final ascii = input
        .toLowerCase()
        // replace non-word characters with spaces
        .replaceAll(RegExp(r"[^\w\s-]"), '')
        // replace whitespace and dashes with single underscore
        .replaceAll(RegExp(r"[\s-]+"), '_')
        .trim();
    return ascii;
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      'provider': providerId,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (provider != null) 'providerInfo': provider!.toJson(),
      'price': price.toJson(),
      'location': location.toJson(),
      'images': images.map((url) => {'url': url}).toList(),
      'requirements': requirements,
      'equipment': equipment,
      'rating': rating.toJson(),
      'totalBookings': totalBookings,
      'isActive': isActive,
      'featured': featured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
  'emergencyEnabled': emergencyEnabled,
  'emergencyLeadTimeMinutes': emergencyLeadTimeMinutes,
  'emergencySurcharge': { 'type': emergencySurchargeType, 'amount': emergencySurchargeAmount },
  'emergencyRateMultiplier': emergencyRateMultiplier,
    };
  }
}

class PriceModel {
  final double amount;
  final String type;
  final String currency;

  const PriceModel({
    required this.amount,
    required this.type,
    required this.currency,
  });

  factory PriceModel.fromJson(Map<String, dynamic> json) {
    return PriceModel(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? 'hourly',
      currency: json['currency'] ?? 'ILS',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type,
      'currency': currency,
    };
  }
}

class LocationModel {
  final String serviceArea;
  final double radius;
  final bool onSite;
  final bool remote;

  const LocationModel({
    required this.serviceArea,
    required this.radius,
    required this.onSite,
    required this.remote,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      serviceArea: json['serviceArea'] ?? '',
      radius: (json['radius'] as num?)?.toDouble() ?? 10.0,
      onSite: json['onSite'] ?? true,
      remote: json['remote'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceArea': serviceArea,
      'radius': radius,
      'onSite': onSite,
      'remote': remote,
    };
  }
}

class RatingModel {
  final double average;
  final int count;

  const RatingModel({
    required this.average,
    required this.count,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average': average,
      'count': count,
    };
  }
}

class ServicesService with BaseApiService {
  static final ServicesService _instance = ServicesService._internal();
  factory ServicesService() => _instance;
  ServicesService._internal();

  // Notifier to trigger UI refreshes (e.g., Our Services cards) when provider
  // services data changes (availability/emergency flags/rates etc.).
  static final ValueNotifier<int> providerServicesVersion = ValueNotifier<int>(0);

  // Simple in-memory cache for per-provider services to reduce duplicate requests
  static const Duration _providerCacheTTL = Duration(seconds: 60);
  final Map<String, _CacheEntry<List<ServiceModel>>> _providerServicesCache = {};
  // Track in-flight requests to avoid issuing multiple identical GETs concurrently
  final Map<String, Future<List<ServiceModel>>> _inflightProviderRequests = {};

  // Get authentication headers from provided AuthService instance
  Map<String, String> _getAuthHeaders(AuthService authService) {
    final token = authService.token;
    if (token != null) {
      return {
        'Authorization': 'Bearer $token',
        ...ApiConfig.defaultHeaders,
      };
    }
    return ApiConfig.defaultHeaders;
  }

  /// Get list of services with filtering and pagination
  Future<List<ServiceModel>> getServices({
    String? category,
    String? q,
    String? area,
    String? providerId,
    String? near,
    double? maxDistanceKm,
    int? page,
    int? limit,
    AuthService? authService,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (category != null) queryParams['category'] = category;
      if (q != null && q.isNotEmpty) queryParams['q'] = q;
      if (area != null && area.isNotEmpty) queryParams['area'] = area;
      if (providerId != null) queryParams['providerId'] = providerId;
      if (near != null) queryParams['near'] = near;
      if (maxDistanceKm != null) queryParams['maxDistanceKm'] = maxDistanceKm.toString();
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final endpoint = ApiConfig.servicesEndpoint +
          (queryParams.isNotEmpty 
              ? '?${Uri(queryParameters: queryParams).query}' 
              : '');

      final response = await get(endpoint, headers: authService != null ? _getAuthHeaders(authService) : ApiConfig.defaultHeaders);

      dynamic raw = response['services'] ?? response['data'];
      if (raw is Map<String, dynamic>) {
        raw = raw['services'] ?? raw['data'] ?? raw['items'] ?? [];
      }
      final List<dynamic> servicesData = (raw is List) ? raw : <dynamic>[];

      // if (kDebugMode && ApiConfig.enableLogging) {
      //   print('🛠️ Fetched services: ${servicesData.length} items');
      // }
      return servicesData
          .map((json) => ServiceModel.fromJson(json))
          .toList();
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Error fetching services: $e');
      // }
      return [];
    }
  }

  /// Get a specific service by ID
  Future<ServiceModel?> getServiceById(String serviceId, {AuthService? authService}) async {
    try {
      final response = await get(
        '${ApiConfig.servicesEndpoint}/$serviceId',
        headers: authService != null ? _getAuthHeaders(authService) : ApiConfig.defaultHeaders,
      );

      // if (kDebugMode && ApiConfig.enableLogging) {
      //   print('🛠️ Fetched service: $serviceId');
      // }

      final serviceData = response['data'] ?? response;
      return ServiceModel.fromJson(serviceData);
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Error fetching service $serviceId: $e');
      // }
      return null;
    }
  }

  /// Get services by category
  Future<List<ServiceModel>> getServicesByCategory(
    String category, {
    String? area,
    String? q,
    int? page,
    int? limit,
    AuthService? authService,
  }) async {
    return getServices(
      category: category,
      area: area,
      q: q,
      page: page,
      limit: limit,
      authService: authService,
    );
  }

  /// Get services by provider
  Future<List<ServiceModel>> getServicesByProvider(
    String providerId, {
    int? page,
    int? limit,
    bool forceRefresh = false,
    AuthService? authService,
  }) async {
    // Serve from cache if present and not expired
    if (!forceRefresh) {
      final cached = _providerServicesCache[providerId];
      if (cached != null && !cached.isExpired) {
        return cached.value;
      }
    }

    // Deduplicate in-flight request for same provider
    final inflight = _inflightProviderRequests[providerId];
    if (inflight != null) {
      return inflight;
    }

    final future = () async {
      // 1) Try new public aggregated endpoint first
      try {
        final publicItems = await ProviderServicesApi().listPublic(providerId);
        if (publicItems.isNotEmpty) {
          final mapped = publicItems.map((e) {
            // Map flattened provider-service to ServiceModel-compatible shape
            final pricing = (e['pricing'] as Map?) ?? const {};
            final serviceId = (e['serviceId'] ?? e['id'] ?? '').toString();
            return ServiceModel(
              id: serviceId.isNotEmpty ? serviceId : (e['providerServiceId']?.toString() ?? ''),
              slug: ServiceModel.generateSlug((e['title'] ?? '').toString()),
              title: (e['title'] ?? '').toString(),
              description: (e['description'] ?? '').toString(),
              category: (e['category'] ?? '').toString(),
              subcategory: (e['subcategory'] as String?),
              providerId: providerId,
              experienceYears: (e['experienceYears'] as num?)?.toInt(),
              price: PriceModel.fromJson({
                'amount': (pricing['amount'] as num?)?.toDouble() ?? 0.0,
                'type': (pricing['type'] ?? 'hourly').toString(),
                'currency': (pricing['currency'] ?? 'ILS').toString(),
              }),
              location: const LocationModel(serviceArea: '', radius: 10, onSite: true, remote: false),
              images: const <String>[],
              requirements: const <String>[],
              equipment: const <String>[],
              rating: const RatingModel(average: 0, count: 0),
              totalBookings: 0,
              isActive: true,
              featured: false,
              createdAt: DateTime.tryParse((e['createdAt'] ?? '').toString()) ?? DateTime.now(),
              updatedAt: DateTime.tryParse((e['updatedAt'] ?? '').toString()) ?? DateTime.now(),
              emergencyEnabled: ((e['emergency'] is Map) ? (e['emergency']['enabled'] ?? false) : false) as bool,
              emergencyLeadTimeMinutes: ((e['emergency'] is Map) ? ((e['emergency']['leadTimeMinutes'] as num?)?.toInt() ?? 120) : 120),
              emergencySurchargeType: ((e['emergency'] is Map) ? ((e['emergency']['surcharge']?['type'] ?? 'flat').toString()) : 'flat'),
              emergencySurchargeAmount: ((e['emergency'] is Map) ? (((e['emergency']['surcharge']?['amount']) as num?)?.toDouble() ?? 0.0) : 0.0),
              emergencyRateMultiplier: ((e['emergency'] is Map) ? ((e['emergency']['rateMultiplier'] as num?)?.toDouble() ?? 1.5) : 1.5),
            );
          }).toList();
          // Cache and return
          _providerServicesCache[providerId] = _CacheEntry(value: mapped, ttl: _providerCacheTTL);
          return mapped;
        }
      } catch (_) {}

      // 2) Fallback to legacy /services?providerId overlay endpoint
      final list = await getServices(providerId: providerId, page: page, limit: limit, authService: authService);
      if (list.isNotEmpty) {
        _providerServicesCache[providerId] = _CacheEntry(value: list, ttl: _providerCacheTTL);
      }
      return list;
    }().whenComplete(() {
      _inflightProviderRequests.remove(providerId);
    });

    _inflightProviderRequests[providerId] = future;
    return future;
  }

  // Optional: allow clearing the cache, for example after mutations
  void clearProviderServicesCache([String? providerId]) {
    if (providerId == null) {
      _providerServicesCache.clear();
    } else {
      _providerServicesCache.remove(providerId);
    }
  // Signal listeners (UI) to refetch
  providerServicesVersion.value = providerServicesVersion.value + 1;
  }
  /// Search services with text query
  Future<List<ServiceModel>> searchServices(
    String query, {
    String? category,
    String? area,
    int? page,
    int? limit,
    AuthService? authService,
  }) async {
    return getServices(
      q: query,
      category: category,
      area: area,
      page: page,
      limit: limit,
      authService: authService,
    );
  }

  /// Get featured services
  Future<List<ServiceModel>> getFeaturedServices({
    int? limit,
    AuthService? authService,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();

      final endpoint = ApiConfig.servicesEndpoint +
          (queryParams.isNotEmpty 
              ? '?${Uri(queryParameters: queryParams).query}' 
              : '');

      final response = await get(endpoint, headers: authService != null ? _getAuthHeaders(authService) : ApiConfig.defaultHeaders);

      dynamic raw = response['services'] ?? response['data'];
      if (raw is Map<String, dynamic>) {
        raw = raw['services'] ?? raw['data'] ?? raw['items'] ?? [];
      }
      final List<dynamic> servicesData = (raw is List) ? raw : <dynamic>[];

      // if (kDebugMode && ApiConfig.enableLogging) {
      //   print('🛠️ Fetched featured services: ${servicesData.length} items');
      // }
      final services = servicesData
          .map((json) => ServiceModel.fromJson(json))
          .toList();

      // Filter featured services on client side since backend returns all
      return services.where((service) => service.featured).toList();
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Error fetching featured services: $e');
      // }
      return [];
    }
  }

  /// Create a new service (admin only)
  Future<ServiceModel?> createService({
    required String title,
    required String description,
    required String category,
    String? subcategory,
    String? providerId,
    required AuthService authService,
  }) async {
    try {
      final requestBody = {
        'title': title,
        'description': description,
        'category': category,
        if (subcategory != null && subcategory.isNotEmpty) 'subcategory': subcategory,
        if (providerId != null && providerId.isNotEmpty) 'provider': providerId,
      };

      final response = await post(
        '${ApiConfig.servicesEndpoint}/simple',
        body: requestBody,
        headers: _getAuthHeaders(authService),
      );

      // if (kDebugMode) {
      //   print('✅ Service created successfully');
      //   print('📂 Service category: $category');
      // }

      final serviceData = response['data'] ?? response;
      return ServiceModel.fromJson(serviceData);
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Error creating service: $e');
      // }
      rethrow;
    }
  }

  /// Delete a service (admin only)
  Future<bool> deleteService({
    required String serviceId,
    required AuthService authService,
  }) async {
    try {
      await delete(
        '${ApiConfig.servicesEndpoint}/$serviceId',
        headers: _getAuthHeaders(authService),
      );

      // if (kDebugMode) {
      //   print('✅ Service deleted successfully: $serviceId');
      // }

      return true;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Error deleting service: $e');
      // }
      rethrow;
    }
  }
}
