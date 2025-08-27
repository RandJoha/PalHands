import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import '../../core/constants/api_config.dart';

class BookingService with BaseApiService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  // Build auth headers from persisted token (avoids relying on a new AuthService instance)
  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        return {
          'Authorization': 'Bearer $token',
          ...ApiConfig.defaultHeaders,
        };
      }
    } catch (_) {}
    return ApiConfig.defaultHeaders;
  }

  /// Create a new booking
  Future<BookingModel> createBooking(CreateBookingRequest request) async {
    try {
      final response = await post(
        ApiConfig.bookingsEndpoint,
        body: request.toJson(),
  headers: await _getAuthHeaders(),
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

  final response = await get(endpoint, headers: await _getAuthHeaders());

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

  /// Admin: list all bookings (paginated)
  Future<List<BookingModel>> getAllBookingsAdmin({
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final endpoint = '${ApiConfig.bookingsEndpoint}/admin/all' +
          (queryParams.isNotEmpty
              ? '?${Uri(queryParameters: queryParams).query}'
              : '');

      final response = await get(endpoint, headers: await _getAuthHeaders());

      if (kDebugMode) {
        print('📊 Admin fetched bookings: ${response['data']?.length ?? response['bookings']?.length ?? 0} items');
      }

      final List<dynamic> bookingsData = response['data'] ?? response['bookings'] ?? [];
      return bookingsData.map((json) => BookingModel.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching admin bookings: $e');
      }
      rethrow;
    }
  }

  /// Get a specific booking by ID
  Future<BookingModel> getBookingById(String bookingId) async {
    try {
      final response = await get(
        '${ApiConfig.bookingsEndpoint}/$bookingId',
  headers: await _getAuthHeaders(),
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
  headers: await _getAuthHeaders(),
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

  /// Cancel a booking with threshold-aware backend handling.
  /// Returns a map:
  /// - { 'booking': BookingModel } on direct cancel (200)
  /// - { 'request': Map } on 202 pending cancellation request
  Future<Map<String, dynamic>> cancelBookingAction(String bookingId, { String? reason }) async {
    final response = await post(
      '${ApiConfig.bookingsEndpoint}/$bookingId/cancel',
      body: { if (reason != null) 'reason': reason },
      headers: await _getAuthHeaders(),
    );
    if (response is Map && response['data'] is Map && (response['data'] as Map).containsKey('request')) {
      return { 'request': response['data']['request'] };
    }
    final data = response['data'] ?? response;
    return { 'booking': BookingModel.fromJson(data) };
  }

  /// Confirm a booking (provider action)
  Future<BookingModel> confirmBooking(String bookingId) async {
    final response = await post(
      '${ApiConfig.bookingsEndpoint}/$bookingId/confirm',
      headers: await _getAuthHeaders(),
    );
    final data = response['data'] ?? response;
    return BookingModel.fromJson(data);
  }

  /// Complete a booking (provider action)
  Future<BookingModel> completeBooking(String bookingId) async {
    final response = await post(
      '${ApiConfig.bookingsEndpoint}/$bookingId/complete',
      headers: await _getAuthHeaders(),
    );
    final data = response['data'] ?? response;
    return BookingModel.fromJson(data);
  }

  /// Respond to a cancellation request (provider or client counterparty)
  Future<BookingModel> respondCancellationRequest(String bookingId, String requestId, String action) async {
    final response = await post(
      '${ApiConfig.bookingsEndpoint}/$bookingId/cancellation-requests/$requestId/respond',
      body: { 'action': action },
      headers: await _getAuthHeaders(),
    );
    final data = response['data'] ?? response;
    return BookingModel.fromJson(data);
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
