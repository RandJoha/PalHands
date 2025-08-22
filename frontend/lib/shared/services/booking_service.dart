import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

// Core imports
import '../../core/constants/api_config.dart';
import 'base_api_service.dart';

/// Service for managing booking-related API calls
class BookingService extends ChangeNotifier with BaseApiService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final _random = Random();

  /// Create a new booking
  /// 
  /// Returns the created booking data or throws an exception
  Future<Map<String, dynamic>> createBooking({
    required String serviceId,
    required Map<String, dynamic> schedule,
    required Map<String, dynamic> location,
    String? notes,
    String? clientId,
    String? idempotencyKey,
  }) async {
    try {
      // Generate idempotency key if not provided
      final effectiveIdempotencyKey = idempotencyKey ?? _generateIdempotencyKey();
      
      final body = {
        'serviceId': serviceId,
        'schedule': schedule,
        'location': location,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (clientId != null) 'clientId': clientId,
        'idempotencyKey': effectiveIdempotencyKey,
      };

      final headers = <String, String>{
        'Idempotency-Key': effectiveIdempotencyKey,
      };

      if (kDebugMode) {
        print('🔄 Creating booking with data: $body');
      }

      final response = await post('/api/bookings', body: body, headers: headers);
      
      if (kDebugMode) {
        print('✅ Booking created successfully: ${response['data']}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to create booking: $e');
      }
      rethrow;
    }
  }

  /// Get list of current user's bookings
  /// 
  /// For clients: returns bookings where user is the client
  /// For providers: returns bookings where user is the provider
  /// Supports filtering by status and pagination
  Future<List<Map<String, dynamic>>> getMyBookings({
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (page != null) {
        queryParams['page'] = page.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final endpoint = '/api/bookings${_buildQueryString(queryParams)}';
      
      if (kDebugMode) {
        print('🔄 Fetching my bookings from: $endpoint');
      }

      final response = await get(endpoint);
      
      // Handle both array response and paginated response
      final bookings = response['data'] is List 
          ? List<Map<String, dynamic>>.from(response['data'])
          : List<Map<String, dynamic>>.from(response['data']['bookings'] ?? []);
      
      if (kDebugMode) {
        print('✅ Fetched ${bookings.length} bookings');
      }

      return bookings;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch my bookings: $e');
      }
      rethrow;
    }
  }

  /// Get specific booking by ID
  /// 
  /// Only accessible to booking participants (client, provider) or admin
  Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    try {
      if (kDebugMode) {
        print('🔄 Fetching booking details for ID: $bookingId');
      }

      final response = await get('/api/bookings/$bookingId');
      
      if (kDebugMode) {
        print('✅ Booking details fetched: ${response['data']['bookingId']}');
      }

      return response['data'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch booking $bookingId: $e');
      }
      rethrow;
    }
  }

  /// Update booking status
  /// 
  /// Status transitions are validated by the backend FSM
  /// Different roles have different allowed transitions
  Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String status,
    String? reason,
  }) async {
    try {
      final body = {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      if (kDebugMode) {
        print('🔄 Updating booking $bookingId status to: $status');
      }

      final response = await put('/api/bookings/$bookingId/status', body: body);
      
      if (kDebugMode) {
        print('✅ Booking status updated successfully');
      }

      notifyListeners(); // Notify UI to refresh booking lists
      return response['data'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to update booking status: $e');
      }
      rethrow;
    }
  }

  /// Cancel a booking
  /// 
  /// Convenience method for updating status to cancelled
  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: 'cancelled',
      reason: reason,
    );
  }

  /// Confirm a booking (provider action)
  /// 
  /// Convenience method for updating status to confirmed
  Future<Map<String, dynamic>> confirmBooking(String bookingId) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: 'confirmed',
    );
  }

  /// Start a booking (provider action)
  /// 
  /// Convenience method for updating status to in_progress
  Future<Map<String, dynamic>> startBooking(String bookingId) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: 'in_progress',
    );
  }

  /// Complete a booking
  /// 
  /// Convenience method for updating status to completed
  Future<Map<String, dynamic>> completeBooking(String bookingId) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: 'completed',
    );
  }

  /// Mark booking as disputed
  /// 
  /// Convenience method for updating status to disputed
  Future<Map<String, dynamic>> disputeBooking({
    required String bookingId,
    required String reason,
  }) async {
    return updateBookingStatus(
      bookingId: bookingId,
      status: 'disputed',
      reason: reason,
    );
  }

  /// Get available services for booking
  /// 
  /// Used in booking creation flow to select services
  Future<List<Map<String, dynamic>>> getAvailableServices({
    String? query,
    String? category,
    String? area,
    String? providerId,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }
      if (providerId != null && providerId.isNotEmpty) {
        queryParams['providerId'] = providerId;
      }
      if (page != null) {
        queryParams['page'] = page.toString();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final endpoint = '/api/services${_buildQueryString(queryParams)}';
      
      if (kDebugMode) {
        print('🔄 Fetching available services from: $endpoint');
      }

      final response = await get(endpoint);
      
      final services = response['data'] is List 
          ? List<Map<String, dynamic>>.from(response['data'])
          : List<Map<String, dynamic>>.from(response['data']['services'] ?? []);
      
      if (kDebugMode) {
        print('✅ Fetched ${services.length} available services');
      }

      return services;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch available services: $e');
      }
      rethrow;
    }
  }

  /// Helper method to build query string from parameters
  String _buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    
    final queryString = params.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
        .join('&');
    
    return queryString.isNotEmpty ? '?$queryString' : '';
  }

  /// Get booking status color for UI
  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'warning';
      case 'confirmed':
        return 'success';
      case 'in_progress':
        return 'info';
      case 'completed':
        return 'primary';
      case 'cancelled':
      case 'disputed':
        return 'error';
      default:
        return 'grey';
    }
  }

  /// Get user-friendly status display text
  static String getStatusDisplayText(String status, String language) {
    // This would typically use the AppStrings system
    // For now, returning the status as-is
    return status;
  }

  /// Validate booking schedule format
  static bool isValidSchedule(Map<String, dynamic> schedule) {
    if (!schedule.containsKey('date') || 
        !schedule.containsKey('startTime') || 
        !schedule.containsKey('endTime') ||
        !schedule.containsKey('timezone')) {
      return false;
    }

    // Basic validation for required fields
    final date = schedule['date'] as String?;
    final startTime = schedule['startTime'] as String?;
    final endTime = schedule['endTime'] as String?;
    final timezone = schedule['timezone'] as String?;

    return date != null && date.isNotEmpty &&
           startTime != null && startTime.isNotEmpty &&
           endTime != null && endTime.isNotEmpty &&
           timezone != null && timezone.isNotEmpty;
  }

  /// Validate booking location format
  static bool isValidLocation(Map<String, dynamic> location) {
    return location.containsKey('address') && 
           location['address'] != null && 
           (location['address'] as String).isNotEmpty;
  }

  /// Generate a simple idempotency key
  String _generateIdempotencyKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(100000).toString().padLeft(5, '0');
    return 'booking_${timestamp}_$randomSuffix';
  }
}
