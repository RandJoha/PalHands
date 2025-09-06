import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/widgets/app_toast.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    }

    if (!_hasMore && !refresh) return;

    try {
      setState(() {
        if (refresh) {
          _isLoading = true;
          _error = null;
        }
      });

      final response = await _notificationService.getNotifications(
        page: _currentPage,
        limit: 20,
      );

      if (response['success'] == true) {
        final newNotifications = List<Map<String, dynamic>>.from(
          response['data']['notifications'] ?? [],
        );

        setState(() {
          if (refresh) {
            _notifications = newNotifications;
          } else {
            _notifications.addAll(newNotifications);
          }
          _isLoading = false;
          _hasMore = newNotifications.length == 20;
          if (_hasMore) _currentPage++;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load notifications';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await _notificationService.markAsRead(notificationId);
      if (response['success'] == true) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n['_id'] == notificationId,
          );
          if (index != -1) {
            _notifications[index]['read'] = true;
          }
        });
      }
    } catch (e) {
      AppToast.show(
        context,
        message: 'Failed to mark notification as read',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final response = await _notificationService.markAllAsRead();
      if (response['success'] == true) {
        setState(() {
          for (var notification in _notifications) {
            notification['read'] = true;
          }
        });
        AppToast.show(
          context,
          message: 'All notifications marked as read',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      AppToast.show(
        context,
        message: 'Failed to mark all notifications as read',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final response = await _notificationService.deleteNotification(notificationId);
      if (response['success'] == true) {
        setState(() {
          _notifications.removeWhere((n) => n['_id'] == notificationId);
        });
        AppToast.show(
          context,
          message: 'Notification deleted',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      AppToast.show(
        context,
        message: 'Failed to delete notification',
        type: AppToastType.error,
      );
    }
  }

  String _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return '#FF4444';
      case 'medium':
        return '#FF8800';
      case 'low':
        return '#00C851';
      default:
        return '#2196F3';
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notifications',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                if (_notifications.isNotEmpty)
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: Text(
                      'Mark all as read',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadNotifications(refresh: true),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No notifications',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You\'re all caught up!',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadNotifications(refresh: true),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _notifications.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _notifications.length) {
                                  return _hasMore
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }

                                final notification = _notifications[index];
                                final isRead = notification['read'] ?? false;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: isRead ? 1 : 3,
                                  color: isRead ? Colors.white : Colors.blue[50],
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(
                                          _getPriorityColor(notification['priority'] ?? 'medium')
                                              .replaceAll('#', '0xFF'),
                                        )),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    title: Text(
                                      notification['title'] ?? 'Notification',
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                        color: isRead ? Colors.grey[600] : AppColors.textDark,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          notification['message'] ?? '',
                                          style: GoogleFonts.cairo(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatDate(notification['createdAt'] ?? ''),
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'read':
                                            if (!isRead) {
                                              _markAsRead(notification['_id']);
                                            }
                                            break;
                                          case 'delete':
                                            _deleteNotification(notification['_id']);
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        if (!isRead)
                                          const PopupMenuItem(
                                            value: 'read',
                                            child: Row(
                                              children: [
                                                Icon(Icons.done, size: 18),
                                                SizedBox(width: 8),
                                                Text('Mark as read'),
                                              ],
                                            ),
                                          ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, size: 18),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
