import 'package:flutter/foundation.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import '../../core/constants/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderServiceItem {
  final String id;
  final String serviceKey;
  final String serviceTitle;
  final String category;
  final double hourlyRate;
  final int experienceYears;
  final String status; // active | inactive | deleted
  final bool isPublished;
  final bool emergencyEnabled;

  const ProviderServiceItem({
    required this.id,
    required this.serviceKey,
    required this.serviceTitle,
    required this.category,
    required this.hourlyRate,
    required this.experienceYears,
    required this.status,
    required this.isPublished,
    required this.emergencyEnabled,
  });

  factory ProviderServiceItem.fromJson(Map<String, dynamic> json) {
    return ProviderServiceItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      serviceKey: (json['serviceKey'] ?? '').toString(),
      serviceTitle: (json['serviceTitle'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'inactive').toString(),
      isPublished: (json['isPublished'] ?? false) as bool,
      emergencyEnabled: (json['emergencyEnabled'] ?? false) as bool,
    );
  }
}

class MyServicesService with BaseApiService {
  static final MyServicesService _instance = MyServicesService._internal();
  factory MyServicesService() => _instance;
  MyServicesService._internal();

  Future<Map<String, String>> _getAuthHeaders() async {
    // Try in-memory token first (singleton AuthService)
    final token = AuthService().token;
    if (token != null && token.isNotEmpty) {
      return {
        'Authorization': 'Bearer $token',
        ...ApiConfig.defaultHeaders,
      };
    }
    // Fallback: try persisted token to avoid 401 on app cold start before initialize() completes
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('auth_token');
      if (saved != null && saved.isNotEmpty) {
        return {
          'Authorization': 'Bearer $saved',
          ...ApiConfig.defaultHeaders,
        };
      }
    } catch (_) {}
    return ApiConfig.defaultHeaders;
  }

  Future<List<ProviderServiceItem>> list(String providerId) async {
    try {
      final headers = await _getAuthHeaders();
      final res = await get('/providers/$providerId/my-services', headers: headers);
      dynamic raw = res['data'] ?? res['items'] ?? res['results'] ?? [];
      final List<dynamic> arr = (raw is List) ? raw : <dynamic>[];
      return arr.map((e) => ProviderServiceItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('❌ list my-services error: $e');
      return [];
    }
  }

  Future<ProviderServiceItem?> add(String providerId, {
    required String serviceKey,
    String? serviceTitle,
    String? category,
    required double hourlyRate,
    required int experienceYears,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final res = await post(
        '/providers/$providerId/my-services',
        body: {
          'serviceKey': serviceKey,
          if (serviceTitle != null) 'serviceTitle': serviceTitle,
          if (category != null) 'category': category,
          'hourlyRate': hourlyRate,
          'experienceYears': experienceYears,
        },
        headers: headers,
      );
      final data = res['data'] ?? res;
      return ProviderServiceItem.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ add my-service error: $e');
      return null;
    }
  }

  Future<ProviderServiceItem?> update(String providerId, String id, Map<String, dynamic> patch) async {
    try {
  // Use PUT as our BaseApiService doesn't expose PATCH; backend accepts partials
  final headers = await _getAuthHeaders();
  final res = await put('/providers/$providerId/my-services/$id', body: patch, headers: headers);
      final data = res['data'] ?? res;
      return ProviderServiceItem.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ update my-service error: $e');
      return null;
    }
  }

  Future<bool> remove(String providerId, String id) async {
    try {
  final headers = await _getAuthHeaders();
  await delete('/providers/$providerId/my-services/$id', headers: headers);
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ delete my-service error: $e');
      return false;
    }
  }

  Future<ProviderServiceItem?> publish(String providerId, String id) async {
    try {
  final headers = await _getAuthHeaders();
  final res = await post('/providers/$providerId/my-services/$id/publish', headers: headers);
      final data = res['data'] ?? res;
      return ProviderServiceItem.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ publish my-service error: $e');
      return null;
    }
  }

  Future<ProviderServiceItem?> unpublish(String providerId, String id) async {
    try {
  final headers = await _getAuthHeaders();
  final res = await post('/providers/$providerId/my-services/$id/unpublish', headers: headers);
      final data = res['data'] ?? res;
      return ProviderServiceItem.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('❌ unpublish my-service error: $e');
      return null;
    }
  }
}
