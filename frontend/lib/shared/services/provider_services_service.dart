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
  Future<List<Map<String, dynamic>>> listPublic(String providerId, {bool forceRefresh = false}) async {
    try {
      // Try the public endpoint first with includeAll to bypass publishable filter
      String endpoint = '/provider-services/public?providerId=$providerId&includeAll=true';
      if (forceRefresh) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        endpoint += '&_t=$timestamp';
      }
      
      print('🔍 ProviderServicesApi.listPublic: Calling endpoint: $endpoint');
      final resp = await get(endpoint, headers: ApiConfig.defaultHeaders);
      print('🔍 ProviderServicesApi.listPublic: Raw response: $resp');
      
      final raw = resp['data'] ?? resp['items'] ?? resp['services'] ?? [];
      print('🔍 ProviderServicesApi.listPublic: Extracted raw data: $raw');
      
      // Handle nested data structure: {data: {data: [...]}}
      List<dynamic> itemsList = [];
      if (raw is Map<String, dynamic>) {
        // If raw is a Map, check if it has a 'data' field
        final nestedData = raw['data'];
        if (nestedData is List) {
          itemsList = nestedData;
        } else {
          // If no nested data, treat the map itself as a single item
          itemsList = [raw];
        }
      } else if (raw is List) {
        itemsList = raw;
      }
      
      final result = itemsList.cast<Map<String, dynamic>>();
      print('🔍 ProviderServicesApi.listPublic: Final result: ${result.length} services');
      
      // Log each service for debugging
      for (int i = 0; i < result.length; i++) {
        final service = result[i];
        print('🔍 Service $i:');
        print('  - title: ${service['title']}');
        print('  - pricing: ${service['pricing']}');
        print('  - experienceYears: ${service['experienceYears']}');
        print('  - publishable: ${service['publishable']}');
        print('  - category: ${service['category']}');
        print('  - subcategory: ${service['subcategory']}');
        print('  - emergency: ${service['emergency']}');
      }
      
      return result;
    } catch (e) {
      print('❌ Public endpoint failed: $e');
      
      // Fallback: try to get services from the provider's own services
      try {
        print('🔍 Trying fallback: getting services from provider dashboard...');
        final authService = AuthService();
        if (authService.token != null) {
          final fallbackResult = await list(providerId, authService: authService);
          print('🔍 Fallback result: ${fallbackResult.length} services');
          
          // Convert ProviderServiceItem to the expected format
          final converted = fallbackResult.map((item) => {
            'title': item.serviceTitle,
            'pricing': {'amount': item.hourlyRate, 'type': 'hourly', 'currency': 'ILS'},
            'experienceYears': item.experienceYears,
            'publishable': item.publishable,
            'category': item.category,
            'emergency': {'enabled': item.emergencyEnabled},
          }).toList();
          
          return converted;
        }
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
      }
      
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
      
      print('🔍 ProviderServicesApi.list: Calling /provider-services/$providerId');
      final resp = await get('/provider-services/$providerId', headers: _getAuthHeaders(authService));
      print('🔍 ProviderServicesApi.list: Raw response: $resp');
      
      final raw = (resp['data']?['items']) ?? resp['items'] ?? [];
      print('🔍 ProviderServicesApi.list: Raw items: $raw');
      print('🔍 ProviderServicesApi.list: Raw items length: ${raw.length}');
      
      final list = (raw is List) ? raw : <dynamic>[];
      print('🔍 ProviderServicesApi.list: Final list length: ${list.length}');
      
      final result = list.map((e) => ProviderServiceItem.fromJson(e)).toList();
      print('🔍 ProviderServicesApi.list: Converted to ProviderServiceItem: ${result.length} items');
      
      // Log each service
      for (int i = 0; i < result.length; i++) {
        final item = result[i];
        print('🔍 ProviderServicesApi.list Service $i: ${item.serviceTitle} (${item.status}) - ₪${item.hourlyRate}/hour');
      }
      
      return result;
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
      print('🔍 ProviderServicesApi.add: Adding service for provider $providerId');
      print('🔍 ProviderServicesApi.add: Request body: $body');
      print('🔍 ProviderServicesApi.add: Headers: ${_getAuthHeaders(authService)}');
      print('🔍 ProviderServicesApi.add: Endpoint: /provider-services/$providerId');
      print('🔍 ProviderServicesApi.add: Full URL: ${ApiConfig.currentApiBaseUrl}/provider-services/$providerId');
      
      final response = await post(
        '/provider-services/$providerId',
        body: body,
        headers: _getAuthHeaders(authService),
      );
      
      print('🔍 ProviderServicesApi.add: Response: $response');
      print('🔍 ProviderServicesApi.add: Response type: ${response.runtimeType}');
      print('🔍 ProviderServicesApi.add: Response keys: ${response.keys}');
      
      // Check if the response indicates success
      if (response.containsKey('success') && response['success'] == true) {
        print('✅ ProviderServicesApi.add: Success confirmed in response');
        print('✅ ProviderServicesApi.add: Response data: ${response['data']}');
        return true;
      } else {
        print('❌ ProviderServicesApi.add: No success indicator in response');
        print('❌ ProviderServicesApi.add: Full response: $response');
        return false;
      }
    } catch (e) {
      print('❌ ProviderServicesApi.add: Failed to add provider service: $e');
      print('❌ ProviderServicesApi.add: Error type: ${e.runtimeType}');
      if (e is Map && e.containsKey('message')) {
        print('❌ Error message: ${e['message']}');
        // Check for duplicate service error
        if (e['message'].toString().contains('already added')) {
          print('❌ Duplicate service detected');
        }
      }
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
