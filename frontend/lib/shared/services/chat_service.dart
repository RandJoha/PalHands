import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import 'auth_service.dart';

class ChatService {
  static String get _baseUrl => ApiConfig.currentApiBaseUrl;

  // Get authentication headers with better debugging
  Map<String, String> _getAuthHeaders(AuthService authService) {
    final token = authService.token;
    
    if (kDebugMode) {
      print('🔑 Chat service - Auth check:');
      print('  - Auth service instance: ${authService.hashCode}');
      print('  - Is authenticated: ${authService.isAuthenticated}');
      print('  - Token present: ${token != null}');
      print('  - Token length: ${token?.length ?? 0}');
      print('  - Current user: ${authService.currentUser?['email'] ?? 'None'}');
      if (token != null) {
        print('  - Token preview: ${token!.substring(0, min(30, token.length))}...');
      } else {
        print('  - ⚠️ NO TOKEN AVAILABLE - This will cause 401 errors!');
      }
    }
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      if (kDebugMode) {
        print('✅ Chat service - Authorization header added');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ Chat service - No token available, request will fail with 401');
      }
    }
    
    return headers;
  }

  // Fallback getter for backward compatibility
  Map<String, String> get _authHeaders {
    return _getAuthHeaders(AuthService());
  }

  /// Get user's chat list
  Future<Map<String, dynamic>> getUserChats({AuthService? authService}) async {
    try {
      // Use provided authService or create a new one (fallback)
      final auth = authService ?? AuthService();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/chat'),
        headers: _getAuthHeaders(auth),
      );

      if (kDebugMode) {
        print('📱 Chat service - Get user chats response: ${response.statusCode}');
        print('📱 Chat service - Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to get chats: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Chat service - Get user chats error: $e');
      }
      rethrow;
    }
  }

  /// Get chat messages
  Future<Map<String, dynamic>> getChatMessages(String chatId, {int page = 1, int limit = 50, AuthService? authService}) async {
    try {
      // Use provided authService or create a new one (fallback)
      final auth = authService ?? AuthService();
      
      if (kDebugMode) {
        print('🔍 Chat service - Getting messages for chat: $chatId');
        print('  - Page: $page, Limit: $limit');
        print('  - URL: $_baseUrl/chat/$chatId/messages');
      }
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/$chatId/messages?${Uri(queryParameters: queryParams).query}'),
        headers: _getAuthHeaders(auth),
      );

      if (kDebugMode) {
        print('📱 Chat service - Get messages response: ${response.statusCode}');
        print('  - Response body length: ${response.body.length}');
        if (response.statusCode == 200) {
          print('  - Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('  - Parsed data keys: ${data.keys.toList()}');
          if (data['data'] != null && data['data']['messages'] != null) {
            print('  - Messages count in response: ${(data['data']['messages'] as List).length}');
          }
        }
        return data;
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Chat service - Get messages error: $e');
      }
      rethrow;
    }
  }

  /// Send a message
  Future<Map<String, dynamic>> sendMessage(String chatId, String content, {String messageType = 'text', Map<String, dynamic>? attachment, AuthService? authService}) async {
    try {
      // Use provided authService or create a new one (fallback)
      final auth = authService ?? AuthService();
      
      final body = {
        'content': content,
        'messageType': messageType,
        if (attachment != null) 'attachment': attachment,
      };

      if (kDebugMode) {
        print('📱 Chat service - Sending message:');
        print('  - Chat ID: $chatId');
        print('  - Content: $content');
        print('  - Auth service provided: ${authService != null}');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/$chatId/messages'),
        headers: _getAuthHeaders(auth),
        body: json.encode(body),
      );

      if (kDebugMode) {
        print('📱 Chat service - Send message response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        // Try to parse error response for better error messages
        try {
          final errorData = json.decode(response.body);
          if (kDebugMode) {
            print('❌ Chat service - Send message failed:');
            print('  - Status: ${response.statusCode}');
            print('  - Error data: $errorData');
          }
          throw Exception('Failed to send message: ${errorData['message'] ?? response.statusCode}');
        } catch (parseError) {
          if (kDebugMode) {
            print('❌ Chat service - Send message failed (could not parse error):');
            print('  - Status: ${response.statusCode}');
            print('  - Raw body: ${response.body}');
          }
          throw Exception('Failed to send message: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Chat service - Send message error: $e');
      }
      rethrow;
    }
  }

  /// Create or get existing chat
  Future<Map<String, dynamic>> createOrGetChat(String participantId, {String? bookingId, String? serviceName, AuthService? authService}) async {
    try {
      // Use provided authService or create a new one (fallback)
      final auth = authService ?? AuthService();
      
      final body = {
        'participantId': participantId,
        if (bookingId != null) 'bookingId': bookingId,
        if (serviceName != null) 'serviceName': serviceName,
      };

      if (kDebugMode) {
        print('📱 Chat service - Creating/getting chat:');
        print('  - Participant ID: $participantId');
        print('  - Service name: $serviceName');
        print('  - Request body: $body');
        print('  - Auth service provided: ${authService != null}');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: _getAuthHeaders(auth),
        body: json.encode(body),
      );

      if (kDebugMode) {
        print('📱 Chat service - Create/get chat response: ${response.statusCode}');
        print('📱 Chat service - Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          print('❌ Chat service - Authentication failed (401)');
          print('  - Response body: ${response.body}');
        }
        throw Exception('Authentication failed. Please login again.');
      } else {
        if (kDebugMode) {
          print('❌ Chat service - Request failed with status: ${response.statusCode}');
          print('  - Response body: ${response.body}');
        }
        throw Exception('Failed to create/get chat: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Chat service - Create/get chat error: $e');
      }
      rethrow;
    }
  }

  /// Test authentication status
  Future<bool> testAuthentication() async {
    try {
      final authService = AuthService();
      
      if (kDebugMode) {
        print('🔍 Chat service - Testing authentication:');
        print('  - Is authenticated: ${authService.isAuthenticated}');
        print('  - Token present: ${authService.token != null}');
        print('  - Current user: ${authService.currentUser?['email'] ?? 'None'}');
      }
      
      if (!authService.isAuthenticated || authService.token == null) {
        if (kDebugMode) {
          print('❌ Chat service - Not authenticated');
        }
        return false;
      }
      
      // Try to make a simple request to test the token
      final response = await http.get(
        Uri.parse('$_baseUrl/chat'),
        headers: _authHeaders,
      );
      
      if (kDebugMode) {
        print('🔍 Chat service - Auth test response: ${response.statusCode}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Chat service - Auth test failed: $e');
      }
      return false;
    }
  }

  /// Mark messages as read
  Future<Map<String, dynamic>> markMessagesAsRead(String chatId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/chat/$chatId/read'),
        headers: _authHeaders,
      );

      if (kDebugMode) {
        print('📱 Chat service - Mark as read response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to mark messages as read: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Chat service - Mark as read error: $e');
      }
      rethrow;
    }
  }
}
