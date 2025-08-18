import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Core imports
import '../../core/constants/api_config.dart';

mixin BaseApiService {
  // HTTP GET request with retry mechanism
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) async {
    return _executeWithRetry(() => _get(endpoint, headers: headers));
  }

  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, String>? headers}) async {
    final url = '${ApiConfig.currentApiBaseUrl}$endpoint';
    final requestHeaders = {...ApiConfig.defaultHeaders, ...?headers};
    
    _logRequest('GET', url, headers: requestHeaders);
    
    try {
      final response = await http
          .get(Uri.parse(url), headers: requestHeaders)
          .timeout(ApiConfig.connectionTimeout);

      _logResponse('GET', url, response);
      return _handleResponse(response);
    } catch (e) {
      _logError('GET', url, e);
      throw _handleError(e);
    }
  }

  // HTTP POST request with retry mechanism
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() => _post(endpoint, body: body, headers: headers));
  }

  Future<Map<String, dynamic>> _post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = '${ApiConfig.currentApiBaseUrl}$endpoint';
    final requestHeaders = {...ApiConfig.defaultHeaders, ...?headers};
    final requestBody = body != null ? json.encode(body) : null;
    
    _logRequest('POST', url, headers: requestHeaders, body: body);
    
    try {
      final response = await http
          .post(Uri.parse(url), headers: requestHeaders, body: requestBody)
          .timeout(ApiConfig.connectionTimeout);

      _logResponse('POST', url, response);
      return _handleResponse(response);
    } catch (e) {
      _logError('POST', url, e);
      throw _handleError(e);
    }
  }

  // HTTP PUT request with retry mechanism
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    return _executeWithRetry(() => _put(endpoint, body: body, headers: headers));
  }

  Future<Map<String, dynamic>> _put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = '${ApiConfig.currentApiBaseUrl}$endpoint';
    final requestHeaders = {...ApiConfig.defaultHeaders, ...?headers};
    final requestBody = body != null ? json.encode(body) : null;
    
    _logRequest('PUT', url, headers: requestHeaders, body: body);
    
    try {
      final response = await http
          .put(Uri.parse(url), headers: requestHeaders, body: requestBody)
          .timeout(ApiConfig.connectionTimeout);

      _logResponse('PUT', url, response);
      return _handleResponse(response);
    } catch (e) {
      _logError('PUT', url, e);
      throw _handleError(e);
    }
  }

  // HTTP DELETE request with retry mechanism
  Future<Map<String, dynamic>> delete(String endpoint, {Map<String, String>? headers}) async {
    return _executeWithRetry(() => _delete(endpoint, headers: headers));
  }

  Future<Map<String, dynamic>> _delete(String endpoint, {Map<String, String>? headers}) async {
    final url = '${ApiConfig.currentApiBaseUrl}$endpoint';
    final requestHeaders = {...ApiConfig.defaultHeaders, ...?headers};
    
    _logRequest('DELETE', url, headers: requestHeaders);
    
    try {
      final response = await http
          .delete(Uri.parse(url), headers: requestHeaders)
          .timeout(ApiConfig.connectionTimeout);

      _logResponse('DELETE', url, response);
      return _handleResponse(response);
    } catch (e) {
      _logError('DELETE', url, e);
      throw _handleError(e);
    }
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    // Try to parse response body
    Map<String, dynamic> responseData;
    try {
      if (response.body.isEmpty) {
        responseData = {'success': true};
      } else {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      responseData = {
        'success': false,
        'message': 'Invalid response format',
      };
    }

    // For authentication endpoints, return the response body even for error status codes
    // and attach the HTTP status code for UX decisions (e.g., rate limit messaging)
    if (response.request?.url.path.contains('/auth/') == true) {
      try {
        // Non-destructive augmentation
        responseData['statusCode'] = response.statusCode;
      } catch (_) {}
      return responseData;
    }

    // For other endpoints, throw exception for error status codes
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw ApiException(
        responseData['message'] ?? 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        response.statusCode,
        response.body,
      );
    }
  }

  // Retry mechanism
  Future<Map<String, dynamic>> _executeWithRetry(
    Future<Map<String, dynamic>> Function() operation,
  ) async {
    int attempts = 0;
    while (attempts < ApiConfig.maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= ApiConfig.maxRetries) {
          rethrow;
        }
        
        if (kDebugMode) {
          print('⚠️ Request failed, retrying... (Attempt $attempts/${ApiConfig.maxRetries})');
        }
        
        await Future.delayed(ApiConfig.retryDelay);
      }
    }
    throw ApiException('Max retries exceeded', 0, '');
  }

  // Logging methods
  void _logRequest(String method, String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    if (!ApiConfig.enableLogging) return;
    
    if (kDebugMode) {
      print('🌐 $method $url');
      if (headers != null) print('📋 Headers: $headers');
      if (body != null) print('📦 Body: $body');
    }
  }

  void _logResponse(String method, String url, http.Response response) {
    if (!ApiConfig.enableLogging) return;
    
    if (kDebugMode) {
      print('✅ $method $url - ${response.statusCode}');
      if (response.body.isNotEmpty) {
        try {
          final data = json.decode(response.body);
          print('📥 Response: $data');
        } catch (e) {
          print('📥 Response: ${response.body}');
        }
      }
    }
  }

  void _logError(String method, String url, dynamic error) {
    if (!ApiConfig.enableLogging) return;
    
    if (kDebugMode) {
      print('❌ $method $url - Error: $error');
    }
  }

  // Handle network errors
  ApiException _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    
    String message;
    if (error.toString().contains('SocketException')) {
      message = 'Unable to connect to server. Please check your internet connection.';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'Connection timeout. Server might be down or slow to respond.';
    } else if (error.toString().contains('Connection refused')) {
      message = 'Server is not running. Please try again later.';
    } else {
      message = 'Network error: ${error.toString()}';
    }
    
    return ApiException(message, 0, '');
  }
}

// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  ApiException(this.message, this.statusCode, this.responseBody);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
} 