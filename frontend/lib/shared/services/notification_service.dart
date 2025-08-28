import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';
import '../../shared/services/auth_service.dart';

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
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AuthService _authService = AuthService();

  Map<String, String> get _authHeaders {
    final token = _authService.token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get user notifications
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (unreadOnly) 'unreadOnly': 'true',
      };

      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/notifications')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _authHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final notifications = (data['data']['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();

          return {
            'success': true,
            'data': {
              'notifications': notifications,
              'pagination': data['data']['pagination'],
              'unreadCount': data['data']['unreadCount'],
            },
          };
        }
        return data;
      }

      return {
        'success': false,
        'message': 'Failed to fetch notifications (Status: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get notifications failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get unread count
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/notifications/unread-count');
      final response = await http.get(uri, headers: _authHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': {
              'unreadCount': data['data']['unreadCount'],
            },
          };
        }
        return data;
      }

      return {
        'success': false,
        'message': 'Failed to get unread count (Status: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get unread count failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/notifications/$notificationId/read');
      final response = await http.put(uri, headers: _authHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': NotificationModel.fromJson(data['data']),
          };
        }
        return data;
      }

      return {
        'success': false,
        'message': 'Failed to mark notification as read (Status: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mark as read failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/notifications/read-all');
      final response = await http.put(uri, headers: _authHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': data['data'],
          };
        }
        return data;
      }

      return {
        'success': false,
        'message': 'Failed to mark all notifications as read (Status: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mark all as read failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/notifications/$notificationId');
      final response = await http.delete(uri, headers: _authHeaders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': NotificationModel.fromJson(data['data']),
          };
        }
        return data;
      }

      return {
        'success': false,
        'message': 'Failed to delete notification (Status: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Delete notification failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
