import 'package:flutter/foundation.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import '../../core/constants/api_config.dart';

class ProviderServiceItem {
  final String id;
  final String serviceId;
  final String serviceTitle;
  final String category;
  final double hourlyRate;
  final int experienceYears;
  final bool emergencyEnabled;
  final String status; // draft|active|inactive
  final bool publishable;
  final Map<String, List<Map<String, String>>> weeklyOverrides; // { day: [{start,end}] }
  final List<Map<String, dynamic>> exceptionOverrides; // [{date, windows:[{start,end}]}]
  final Map<String, List<Map<String, String>>> emergencyWeeklyOverrides;
  final List<Map<String, dynamic>> emergencyExceptionOverrides;

  const ProviderServiceItem({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.category,
    required this.hourlyRate,
    required this.experienceYears,
    required this.emergencyEnabled,
    required this.status,
    required this.publishable,
  this.weeklyOverrides = const {},
  this.exceptionOverrides = const [],
  this.emergencyWeeklyOverrides = const {},
  this.emergencyExceptionOverrides = const [],
  });

  factory ProviderServiceItem.fromJson(Map<String, dynamic> json) {
    final service = json['service'] is Map<String, dynamic> ? (json['service'] as Map<String, dynamic>) : {};
    return ProviderServiceItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      serviceId: (service['_id'] ?? service['id'] ?? json['service'] ?? '').toString(),
      serviceTitle: (service['title'] ?? '').toString(),
      category: (service['category'] ?? '').toString(),
      hourlyRate: ((json['hourlyRate'] as num?)?.toDouble() ?? 0.0),
      experienceYears: ((json['experienceYears'] as num?)?.toInt() ?? 0),
      emergencyEnabled: (json['emergencyEnabled'] ?? false) as bool,
      status: (json['status'] ?? 'draft').toString(),
      publishable: (json['publishable'] ?? false) as bool,
  weeklyOverrides: _coerceWeekly(json['weeklyOverrides']),
  exceptionOverrides: _coerceExceptions(json['exceptionOverrides']),
  emergencyWeeklyOverrides: _coerceWeekly(json['emergencyWeeklyOverrides']),
  emergencyExceptionOverrides: _coerceExceptions(json['emergencyExceptionOverrides']),
    );
  }
}

class ProviderServicesApi with BaseApiService {
  static final ProviderServicesApi _instance = ProviderServicesApi._internal();
  factory ProviderServicesApi() => _instance;
  ProviderServicesApi._internal();

  Map<String, String> _getAuthHeaders(AuthService? authService) {
    // Try to get token from passed authService first, then from singleton
    String? token;
    if (authService != null) {
      token = authService.token;
    } else {
      token = AuthService().token;
    }
    
    if (token != null && token.isNotEmpty) {
      return {'Authorization': 'Bearer $token', ...ApiConfig.defaultHeaders};
    }
    return ApiConfig.defaultHeaders;
  }

  bool _hasAuth(AuthService? authService) {
    final t = authService?.token ?? AuthService().token;
    return t != null && t.isNotEmpty;
  }

  // Public aggregated read for offerings shown on provider cards (no auth required)
  Future<List<Map<String, dynamic>>> listPublic(String providerId) async {
    try {
      final resp = await get('/provider-services/public?providerId=$providerId', headers: ApiConfig.defaultHeaders);
      final raw = resp['data'] ?? resp['items'] ?? resp['services'] ?? [];
      return (raw is List) ? raw.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
    } catch (e) {
      if (kDebugMode) print('Failed to load public provider services: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<ProviderServiceItem>> list(String providerId, {AuthService? authService}) async {
    try {
      // Avoid making authenticated calls without a token (prevents 401 spikes in public flows)
      if (!_hasAuth(authService)) {
        if (kDebugMode) print('Skipping ProviderServicesApi.list: no auth token');
        return [];
      }
      final resp = await get('/provider-services/$providerId', headers: _getAuthHeaders(authService));
      final raw = (resp['data']?['items']) ?? resp['items'] ?? [];
      final list = (raw is List) ? raw : <dynamic>[];
      return list.map((e) => ProviderServiceItem.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) print('Failed to load provider services: $e');
      return [];
    }
  }

  Future<bool> deactivateMonth(String providerId, String id, {AuthService? authService}) async {
    try {
      await post(
        '/provider-services/$providerId/$id/deactivate-month',
        body: const {},
        headers: _getAuthHeaders(authService),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }
  Future<bool> activateMonth(String providerId, String id, {AuthService? authService}) async {
    try {
      await post(
        '/provider-services/$providerId/$id/activate-month',
        body: const {},
        headers: _getAuthHeaders(authService),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }
  Future<bool> remove(String providerId, String id, {AuthService? authService}) async {
    try { await delete('/provider-services/$providerId/$id', headers: _getAuthHeaders(authService)); return true; } catch (e) { if (kDebugMode) print(e); return false; }
  }

  Future<bool> update(String providerId, String id, Map<String, dynamic> body, {AuthService? authService}) async {
    try {
      await patch(
        '/provider-services/$providerId/$id',
        body: body,
        headers: _getAuthHeaders(authService),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Failed to update provider service: $e');
      return false;
    }
  }

  Future<bool> add(String providerId, Map<String, dynamic> body, {AuthService? authService}) async {
    try {
      await post(
        '/provider-services/$providerId',
        body: body,
        headers: _getAuthHeaders(authService),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Failed to add provider service: $e');
      return false;
    }
  }
}

// Helpers for loose JSON coercion from API
Map<String, List<Map<String, String>>> _coerceWeekly(dynamic value) {
  final out = <String, List<Map<String, String>>>{};
  if (value is Map) {
    value.forEach((key, v) {
      final list = <Map<String, String>>[];
      if (v is List) {
        for (final w in v) {
          if (w is Map) {
            final m = Map<String, dynamic>.from(w);
            final s = (m['start'] ?? '').toString();
            final e = (m['end'] ?? '').toString();
            if (s.isNotEmpty && e.isNotEmpty) list.add({'start': s, 'end': e});
          }
        }
      }
      out[key.toString()] = list;
    });
  }
  return out;
}

List<Map<String, dynamic>> _coerceExceptions(dynamic value) {
  final out = <Map<String, dynamic>>[];
  if (value is List) {
    for (final item in value) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final date = (m['date'] ?? '').toString();
        final wins = <Map<String, String>>[];
        if (m['windows'] is List) {
          for (final w in (m['windows'] as List)) {
            if (w is Map) {
              final wm = Map<String, dynamic>.from(w);
              final s = (wm['start'] ?? '').toString();
              final e = (wm['end'] ?? '').toString();
              if (s.isNotEmpty && e.isNotEmpty) wins.add({'start': s, 'end': e});
            }
          }
        }
        out.add({'date': date, 'windows': wins});
      }
    }
  }
  return out;
}
