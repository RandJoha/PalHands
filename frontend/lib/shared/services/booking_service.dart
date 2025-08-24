import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/booking.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import '../../core/constants/api_config.dart';

class BookingService with BaseApiService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

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

  /// Create a new booking
  Future<BookingModel> createBooking(CreateBookingRequest request) async {
    try {
      final response = await post(
        ApiConfig.bookingsEndpoint,
        body: request.toJson(),
        headers: _authHeaders,
      );

      if (kDebugMode) {
        print('📝 Booking created: ${response['data'] ?? response}');
      }

      final bookingData = response['data'] ?? response;
      return BookingModel.fromJson(bookingData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating booking: $e');
      }
      rethrow;
    }
  }

  /// Get list of user's bookings
  Future<List<BookingModel>> getMyBookings({
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final endpoint = ApiConfig.bookingsEndpoint +
          (queryParams.isNotEmpty 
              ? '?${Uri(queryParameters: queryParams).query}' 
              : '');

      final response = await get(endpoint, headers: _authHeaders);

      if (kDebugMode) {
        print('📋 Fetched bookings: ${response['data']?.length ?? 0} items');
      }

      final List<dynamic> bookingsData = response['data'] ?? response['bookings'] ?? [];
      return bookingsData
          .map((json) => BookingModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching bookings: $e');
      }
      rethrow;
    }
  }

  /// Get a specific booking by ID
  Future<BookingModel> getBookingById(String bookingId) async {
    try {
      final response = await get(
        '${ApiConfig.bookingsEndpoint}/$bookingId',
        headers: _authHeaders,
      );

      if (kDebugMode) {
        print('📋 Fetched booking: $bookingId');
      }

      final bookingData = response['data'] ?? response;
      return BookingModel.fromJson(bookingData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching booking $bookingId: $e');
      }
      rethrow;
    }
  }

  /// Update booking status
  Future<BookingModel> updateBookingStatus(
    String bookingId, 
    String status,
  ) async {
    try {
      final request = UpdateBookingStatusRequest(status: status);
      final response = await put(
        '${ApiConfig.bookingsEndpoint}/$bookingId/status',
        body: request.toJson(),
        headers: _authHeaders,
      );

      if (kDebugMode) {
        print('✅ Updated booking $bookingId status to $status');
      }

      final bookingData = response['data'] ?? response;
      return BookingModel.fromJson(bookingData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating booking $bookingId status: $e');
      }
      rethrow;
    }
  }

  /// Cancel a booking
  Future<BookingModel> cancelBooking(String bookingId) async {
    return updateBookingStatus(bookingId, 'cancelled');
  }

  /// Confirm a booking (provider action)
  Future<BookingModel> confirmBooking(String bookingId) async {
    return updateBookingStatus(bookingId, 'confirmed');
  }

  /// Mark booking as in progress
  Future<BookingModel> startBooking(String bookingId) async {
    return updateBookingStatus(bookingId, 'in_progress');
  }

  /// Complete a booking
  Future<BookingModel> completeBooking(String bookingId) async {
    return updateBookingStatus(bookingId, 'completed');
  }

  /// Get booking status color for UI
  static Map<String, dynamic> getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'color': const Color(0xFFFF9800), // Orange
          'label': 'Pending',
          'description': 'Waiting for provider confirmation',
        };
      case 'confirmed':
        return {
          'color': const Color(0xFF4CAF50), // Green
          'label': 'Confirmed',
          'description': 'Provider confirmed the booking',
        };
      case 'in_progress':
        return {
          'color': const Color(0xFF2196F3), // Blue
          'label': 'In Progress',
          'description': 'Service is being performed',
        };
      case 'completed':
        return {
          'color': const Color(0xFF607D8B), // Blue Grey
          'label': 'Completed',
          'description': 'Service has been completed',
        };
      case 'cancelled':
        return {
          'color': const Color(0xFFF44336), // Red
          'label': 'Cancelled',
          'description': 'Booking was cancelled',
        };
      case 'disputed':
        return {
          'color': const Color(0xFF9C27B0), // Purple
          'label': 'Disputed',
          'description': 'There is a dispute for this booking',
        };
      default:
        return {
          'color': const Color(0xFF757575), // Grey
          'label': 'Unknown',
          'description': 'Unknown status',
        };
    }
  }

  /// Get allowed actions for a booking based on status and user role
  static List<String> getAllowedActions(
    String status, 
    String userRole, 
    bool isProvider,
  ) {
    final actions = <String>[];

    switch (status.toLowerCase()) {
      case 'pending':
        if (isProvider) {
          actions.addAll(['confirm', 'cancel']);
        } else {
          actions.addAll(['cancel']);
        }
        break;
      case 'confirmed':
        if (isProvider) {
          actions.addAll(['start', 'cancel']);
        } else {
          actions.addAll(['cancel']);
        }
        break;
      case 'in_progress':
        if (isProvider) {
          actions.addAll(['complete']);
        }
        break;
      case 'completed':
        // No actions available for completed bookings
        break;
      case 'cancelled':
        // No actions available for cancelled bookings
        break;
      case 'disputed':
        // Disputed bookings require admin intervention
        break;
    }

    return actions;
  }

  /// Format booking time for display
  static String formatBookingTime(Schedule schedule) {
    try {
      final date = DateTime.parse(schedule.date);
      final startTime = schedule.startTime;
      final endTime = schedule.endTime;
      
      final dateStr = '${date.day}/${date.month}/${date.year}';
      return '$dateStr, $startTime - $endTime';
    } catch (e) {
      return '${schedule.date}, ${schedule.startTime} - ${schedule.endTime}';
    }
  }

  /// Calculate booking duration in hours
  static double calculateDuration(Schedule schedule) {
    try {
      final startParts = schedule.startTime.split(':');
      final endParts = schedule.endTime.split(':');
      
      final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
      
      return (endMinutes - startMinutes) / 60.0;
    } catch (e) {
      return schedule.duration?.toDouble() ?? 1.0;
    }
  }
}
