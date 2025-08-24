import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'base_api_service.dart';

class Service {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? subcategory;
  final Map<String, dynamic> price;
  final bool isActive;
  final Map<String, dynamic>? rating;
  final int? bookings;
  final String? providerId;
  final Map<String, dynamic>? provider;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.subcategory,
    required this.price,
    required this.isActive,
    this.rating,
    this.bookings,
    this.providerId,
    this.provider,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      subcategory: json['subcategory'],
      price: json['price'],
      isActive: json['isActive'] ?? true,
      rating: json['rating'],
      bookings: json['bookings'],
      providerId: json['provider'] is String ? json['provider'] : json['provider']?['_id'],
      provider: json['provider'] is Map ? json['provider'] : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'price': price,
      'isActive': isActive,
      'rating': rating,
      'bookings': bookings,
      'providerId': providerId,
      'provider': provider,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ServicesResponse {
  final List<Service> services;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  ServicesResponse({
    required this.services,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory ServicesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final List<dynamic> servicesData = data['services'] ?? [];
    final pagination = data['pagination'] ?? {};
    
    return ServicesResponse(
      services: servicesData.map((service) => Service.fromJson(service)).toList(),
      total: pagination['totalRecords'] ?? 0,
      page: pagination['current'] ?? 1,
      limit: 10, // Default limit
      totalPages: pagination['total'] ?? 1,
      hasNext: (pagination['current'] ?? 1) < (pagination['total'] ?? 1),
      hasPrev: (pagination['current'] ?? 1) > 1,
    );
  }
}

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final String? color;
  final bool isActive;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    this.color,
    required this.isActive,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
      color: json['color'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class Booking {
  final String id;
  final String bookingId;
  final String clientId;
  final String providerId;
  final String serviceId;
  final Map<String, dynamic> serviceDetails;
  final Map<String, dynamic> schedule;
  final Map<String, dynamic> location;
  final Map<String, dynamic> pricing;
  final String status;
  final Map<String, dynamic>? payment;
  final Map<String, dynamic> notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.providerId,
    required this.serviceId,
    required this.serviceDetails,
    required this.schedule,
    required this.location,
    required this.pricing,
    required this.status,
    this.payment,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'],
      bookingId: json['bookingId'],
      clientId: json['client'] is String ? json['client'] : json['client']?['_id'],
      providerId: json['provider'] is String ? json['provider'] : json['provider']?['_id'],
      serviceId: json['service'] is String ? json['service'] : json['service']?['_id'],
      serviceDetails: json['serviceDetails'] ?? {},
      schedule: json['schedule'] ?? {},
      location: json['location'] ?? {},
      pricing: json['pricing'] ?? {},
      status: json['status'] ?? 'pending',
      payment: json['payment'],
      notes: json['notes'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'clientId': clientId,
      'providerId': providerId,
      'serviceId': serviceId,
      'serviceDetails': serviceDetails,
      'schedule': schedule,
      'location': location,
      'pricing': pricing,
      'status': status,
      'payment': payment,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ServicesApiService with BaseApiService {
  // Get all services with search, pagination, and filters
  Future<ServicesResponse> getServices({
    String? searchQuery,
    int? page = 1,
    int? limit = 10,
    String? category,
    String? location,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['q'] = searchQuery;
      }
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (category != null) queryParams['category'] = category;
      if (location != null) queryParams['location'] = location;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final queryString = queryParams.isNotEmpty 
          ? '?${Uri(queryParameters: queryParams).query}' 
          : '';

      final response = await get('/api/services$queryString', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        return ServicesResponse.fromJson(response);
      }
      
      throw ApiException('Failed to fetch services', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching services: $e');
      }
      rethrow;
    }
  }

  // Search services
  Future<ServicesResponse> searchServices(String query, {
    int? page = 1,
    int? limit = 10,
  }) async {
    return getServices(
      searchQuery: query,
      page: page,
      limit: limit,
    );
  }

  // Get service categories
  Future<List<ServiceCategory>> getServiceCategories() async {
    try {
      final response = await get('/api/services/categories', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> categoriesData = response['data'];
        return categoriesData.map((category) => ServiceCategory.fromJson(category)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching service categories: $e');
      }
      return [];
    }
  }

  // List services with filters and improved search
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
    try {
      // Validate search query
      if (query != null && query.trim().length < 2) {
        return {
          'services': [],
          'pagination': {
            'current': page,
            'total': 0,
            'totalRecords': 0,
          },
          'error': 'Search query must be at least 2 characters long'
        };
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (area != null) 'area': area,
        if (providerId != null) 'providerId': providerId,
        if (near != null) 'near': near,
        if (maxDistanceKm != null) 'maxDistanceKm': maxDistanceKm.toString(),
      };

      final queryString = queryParams.isNotEmpty 
          ? '?${Uri(queryParameters: queryParams).query}' 
          : '';

      final response = await get('/api/services$queryString');
      
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
      if (kDebugMode) {
        print('❌ Error listing services: $e');
      }
      return {
        'services': [],
        'pagination': {
          'current': page,
          'total': 0,
          'totalRecords': 0,
        },
        'error': 'Failed to load services. Please try again.'
      };
    }
  }

  // Get service by ID
  Future<Service?> getServiceById(String serviceId) async {
    try {
      final response = await get('/api/services/$serviceId');
      
      if (response['success'] == true && response['data'] != null) {
        return Service.fromJson(response['data']);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching service: $e');
      }
      return null;
    }
  }

  // Get my services (provider only)
  Future<List<Service>> getMyServices() async {
    try {
      final response = await get('/api/services/my-services');
      
      if (response['success'] == true && response['data'] != null) {
        final servicesData = response['data']['services'] as List;
        return servicesData.map((data) => Service.fromJson(data)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching my services: $e');
      }
      return [];
    }
  }

  // Create a new service
  Future<Service> createService({
    required String title,
    required String description,
    required String category,
    required double price,
    required String currency,
    String? location,
    String? subcategory,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await post('/api/services/provider', 
        body: {
          'title': title,
          'description': description,
          'category': category,
          'price': {
            'amount': price,
            'type': 'hourly',
            'currency': currency,
          },
          if (subcategory != null) 'subcategory': subcategory,
          if (location != null) 'location': {
            'serviceArea': location,
            'radius': 10,
            'onSite': true,
            'remote': false,
          },
          if (metadata != null) 'metadata': metadata,
        },
        headers: _getAuthHeaders(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return Service.fromJson(response['data']);
      }
      
      throw ApiException('Failed to create service', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating service: $e');
      }
      rethrow;
    }
  }

  // Update an existing service
  Future<Service> updateService({
    required String serviceId,
    String? title,
    String? description,
    String? category,
    double? price,
    String? currency,
    String? location,
    String? subcategory,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (price != null) updateData['price'] = {
        'amount': price,
        'type': 'hourly',
        'currency': currency ?? 'ILS',
      };
      if (subcategory != null) updateData['subcategory'] = subcategory;
      if (location != null) updateData['location'] = {
        'serviceArea': location,
        'radius': 10,
        'onSite': true,
        'remote': false,
      };
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await put('/api/services/$serviceId/provider', 
        body: updateData,
        headers: _getAuthHeaders(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return Service.fromJson(response['data']);
      }
      
      throw ApiException('Failed to update service', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating service: $e');
      }
      rethrow;
    }
  }

  // Delete a service
  Future<bool> deleteService(String serviceId) async {
    try {
      final response = await delete('/api/services/$serviceId', headers: _getAuthHeaders());
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting service: $e');
      }
      return false;
    }
  }

  // Update service price
  Future<bool> updateServicePrice({
    required String serviceId,
    required Map<String, dynamic> price,
  }) async {
    try {
      final response = await put('/api/services/$serviceId/provider', 
        body: {'price': price},
        headers: _getAuthHeaders(),
      );
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating service price: $e');
      }
      return false;
    }
  }

  // Activate services
  Future<bool> activateServices(List<String> serviceIds) async {
    try {
      final response = await put('/api/services/bulk-activate', 
        body: {'serviceIds': serviceIds},
        headers: _getAuthHeaders(),
      );
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error activating services: $e');
      }
      return false;
    }
  }

  // Deactivate services
  Future<bool> deactivateServices(List<String> serviceIds) async {
    try {
      final response = await put('/api/services/bulk-deactivate', 
        body: {'serviceIds': serviceIds},
        headers: _getAuthHeaders(),
      );
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deactivating services: $e');
      }
      return false;
    }
  }

  // Upload service images with improved validation
  Future<bool> uploadServiceImages(String serviceId, List<String> imagePaths) async {
    try {
      // Validate file types and sizes before upload
      for (final path in imagePaths) {
        final validationResult = _validateImageFile(path);
        if (!validationResult['valid']) {
          throw ApiException('Image validation failed', 400, validationResult['error']);
        }
      }

      final response = await post('/api/services/$serviceId/images', 
        body: {
          'images': imagePaths.map((path) => {'url': path, 'alt': ''}).toList(),
        },
        headers: _getAuthHeaders(),
      );
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading service images: $e');
      }
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
    try {
      final response = await post('/api/services/custom-requests', 
        body: {
          'title': title,
          'description': description,
          'fieldDescription': fieldDescription,
          'category': category,
          'subcategory': subcategory,
          'price': price,
          'status': 'pending_approval',
        },
        headers: _getAuthHeaders(),
      );
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting custom service request: $e');
      }
      return false;
    }
  }

  // Create a booking
  Future<Booking> createBooking({
    required String serviceId,
    required String date,
    required String startTime,
    required String endTime,
    required String address,
    String? notes,
    Map<String, double>? coordinates,
    String? instructions,
    String timezone = 'Asia/Jerusalem',
  }) async {
    try {
      final response = await post('/api/bookings', 
        body: {
          'serviceId': serviceId,
          'schedule': {
            'date': date,
            'startTime': startTime,
            'endTime': endTime,
            'timezone': timezone,
          },
          'location': {
            'address': address,
            if (coordinates != null) 'coordinates': coordinates,
            if (instructions != null) 'instructions': instructions,
          },
          if (notes != null) 'notes': notes,
        },
        headers: _getAuthHeaders(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return Booking.fromJson(response['data']);
      }
      
      throw ApiException('Failed to create booking', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating booking: $e');
      }
      rethrow;
    }
  }

  // Get my bookings
  Future<List<Booking>> getMyBookings() async {
    try {
      final response = await get('/api/bookings');
      
      if (response['success'] == true && response['data'] != null) {
        final bookingsData = response['data']['bookings'] as List;
        return bookingsData.map((data) => Booking.fromJson(data)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching my bookings: $e');
      }
      return [];
    }
  }

  // Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await get('/api/bookings/$bookingId');
      
      if (response['success'] == true && response['data'] != null) {
        return Booking.fromJson(response['data']);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching booking: $e');
      }
      return null;
    }
  }

  // Update booking status (provider only)
  Future<bool> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      final response = await put('/api/bookings/$bookingId/status', 
        body: {'status': status},
        headers: _getAuthHeaders(),
      );
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating booking status: $e');
      }
      return false;
    }
  }

  // Validate image file
  Map<String, dynamic> _validateImageFile(String filePath) {
    // Check file extension
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    final extension = filePath.toLowerCase().substring(filePath.lastIndexOf('.'));
    
    if (!allowedExtensions.contains(extension)) {
      return {
        'valid': false,
        'error': 'Invalid file type. Only JPG, PNG, WebP, and GIF files are allowed.'
      };
    }

    // Note: File size validation would require actual file access
    // This is a placeholder for client-side validation
    return {'valid': true};
  }

  // Get auth headers
  Map<String, String> _getAuthHeaders() {
    // TODO: Implement proper auth token retrieval
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token',
    };
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String details;

  ApiException(this.message, this.statusCode, this.details);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
