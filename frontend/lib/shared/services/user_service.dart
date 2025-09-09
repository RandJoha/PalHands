import 'package:flutter/foundation.dart';

import 'base_api_service.dart';
import 'auth_service.dart';
import '../../core/constants/api_config.dart';

class UserService with BaseApiService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Get authentication token from AuthService
  Map<String, String> get _authHeaders {
    // Try to get AuthService from Provider context first
    try {
      final authService = AuthService();
      final token = authService.token;
      
      if (kDebugMode) {
      }
      
      if (token != null) {
        return {
          'Authorization': 'Bearer $token',
          ...ApiConfig.defaultHeaders,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not get AuthService from Provider: $e');
      }
    }
    
    if (kDebugMode) {
      print('⚠️ No auth token available, using default headers only');
    }
    return ApiConfig.defaultHeaders;
  }

  /// Get all users with filtering and pagination (admin only)
  Future<Map<String, dynamic>> getAllUsers({
    String? search,
    String? role,
    String? status,
    int? page,
    int? limit,
    AuthService? authService,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (role != null && role != 'all') queryParams['role'] = role;
      if (status != null && status != 'all') queryParams['status'] = status;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      
      // Exclude admin users - only show regular users and providers
      queryParams['excludeRole'] = 'admin';

      final endpoint = '${ApiConfig.adminEndpoint}/users${queryParams.isNotEmpty 
              ? '?${Uri(queryParameters: queryParams).query}' 
              : ''}';

      // Use provided authService or fall back to default
      final headers = authService != null 
          ? {
              'Authorization': 'Bearer ${authService.token}',
              ...ApiConfig.defaultHeaders,
            }
          : _authHeaders;
      
      // if (kDebugMode) {
      //   print('🌐 Making API call to: $endpoint');
      //   print('🔍 Query parameters: $queryParams');
      // }
      
      final response = await get(endpoint, headers: headers);

      // if (kDebugMode) {
      //   print('👥 Fetched users: ${response['data']?['users']?.length ?? 0} items');
      // }

      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Error fetching users: $e');
      // }
      rethrow;
    }
  }

  /// Update user status (admin only)
  Future<Map<String, dynamic>> updateUserStatus({
    required String userId,
    bool? isActive,
    String? role,
    bool? isVerified,
    String? deactivationReason,
    AuthService? authService,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (isActive != null) body['isActive'] = isActive;
      if (role != null) body['role'] = role;
      if (isVerified != null) body['isVerified'] = isVerified;
      if (deactivationReason != null) body['deactivationReason'] = deactivationReason;

      // Use provided authService or fall back to default
      final headers = authService != null 
          ? {
              'Authorization': 'Bearer ${authService.token}',
              ...ApiConfig.defaultHeaders,
            }
          : _authHeaders;

      // if (kDebugMode) {
      //   print('🔄 Updating user status for ID: $userId');
      //   print('📝 Request body: $body');
      // }

      final response = await put(
        '${ApiConfig.adminEndpoint}/users/$userId',
        body: body,
        headers: headers,
      );

      // if (kDebugMode) {
      //   print('✅ User status updated: $response');
      // }

      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Error updating user status: $e');
      // }
      rethrow;
    }
  }
}
