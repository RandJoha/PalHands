import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';
import 'auth_service.dart';

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool read;
  final String priority;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.read,
    required this.priority,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
      read: json['read'] ?? false,
      priority: json['priority']?.toString() ?? 'medium',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      readAt: json['readAt'] != null 
          ? DateTime.tryParse(json['readAt']?.toString() ?? '') 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'read': read,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }
}

class NotificationService {
  static String get _baseUrl => ApiConfig.currentApiBaseUrl;
  
  final AuthService? _authService;
  
  NotificationService([this._authService]);

  // Get user notifications
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        if (unreadOnly) 'unreadOnly': 'true',
      };

      final uri = Uri.parse('$_baseUrl/notifications')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get unread count
  Future<Map<String, dynamic>> getUnreadCount() async {
    final uri = Uri.parse('$_baseUrl/notifications/unread-count');
    final response = await http.get(
      uri,
      headers: _authHeaders,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch unread count: ${response.statusCode}');
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final uri = Uri.parse('$_baseUrl/notifications/$notificationId/read');

      final response = await http.put(
        uri,
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final uri = Uri.parse('$_baseUrl/notifications/read-all');

      final response = await http.put(
        uri,
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Mark notifications as read by type
  Future<Map<String, dynamic>> markAsReadByType(String type) async {
    try {
      final uri = Uri.parse('$_baseUrl/notifications/read-by-type');

      final response = await http.put(
        uri,
        headers: _authHeaders,
        body: json.encode({'type': type}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to mark notifications as read by type: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final uri = Uri.parse('$_baseUrl/notifications/$notificationId');

      final response = await http.delete(
        uri,
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get authentication headers
  Map<String, String> get _authHeaders {
    // Use provided AuthService instance or create new one
    final authService = _authService ?? AuthService();
    final token = authService.token;

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}
