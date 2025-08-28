import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/app_toast.dart';

class NotificationWidget extends StatefulWidget {
  const NotificationWidget({super.key});

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  static const int _pageLimit = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _notificationService.getNotifications(
        page: _currentPage,
        limit: _pageLimit,
      );

      if (response['success'] == true) {
        final notifications = response['data']['notifications'] as List<NotificationModel>;
        final pagination = response['data']['pagination'] as Map<String, dynamic>;

        setState(() {
          _notifications = notifications;
          _totalPages = pagination['total'];
          _totalRecords = pagination['totalRecords'];
          _isLoading = false;
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

  Future<void> _loadUnreadCount() async {
    if (!mounted) return;

    try {
      final response = await _notificationService.getUnreadCount();
      if (response['success'] == true) {
        setState(() {
          _unreadCount = response['data']['unreadCount'];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load unread count: $e');
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await _notificationService.markAsRead(notificationId);
      if (response['success'] == true) {
        // Update the notification in the list
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            _notifications[index] = response['data'];
          }
        });
        _loadUnreadCount(); // Refresh unread count
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to mark notification as read: $e');
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final response = await _notificationService.markAllAsRead();
      if (response['success'] == true) {
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            _notifications[i] = NotificationModel(
              id: _notifications[i].id,
              type: _notifications[i].type,
              title: _notifications[i].title,
              message: _notifications[i].message,
              data: _notifications[i].data,
              read: true,
              priority: _notifications[i].priority,
              createdAt: _notifications[i].createdAt,
              readAt: DateTime.now(),
            );
          }
        });
        _loadUnreadCount(); // Refresh unread count
        AppToast.show(context, message: 'All notifications marked as read', type: AppToastType.success);
      }
    } catch (e) {
      AppToast.show(context, message: 'Failed to mark all as read', type: AppToastType.error);
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final response = await _notificationService.deleteNotification(notificationId);
      if (response['success'] == true) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notificationId);
        });
        _loadUnreadCount(); // Refresh unread count
        AppToast.show(context, message: 'Notification deleted', type: AppToastType.success);
      }
    } catch (e) {
      AppToast.show(context, message: 'Failed to delete notification', type: AppToastType.error);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Icon _getTypeIcon(String type) {
    switch (type) {
      case 'new_report':
        return const Icon(Icons.report_problem, color: Colors.red);
      case 'report_updated':
        return const Icon(Icons.update, color: Colors.blue);
      case 'report_resolved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'report_dismissed':
        return const Icon(Icons.cancel, color: Colors.grey);
      case 'system_alert':
        return const Icon(Icons.warning, color: Colors.orange);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (!authService.isAuthenticated || !authService.isAdmin) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    if (_unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_unreadCount',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    if (_unreadCount > 0)
                      TextButton(
                        onPressed: _markAllAsRead,
                        child: Text(
                          'Mark all read',
                          style: GoogleFonts.cairo(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.notifications_none, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),

              // Pagination
              if (_totalPages > 1) _buildPagination(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and priority indicator
          Stack(
            children: [
              _getTypeIcon(notification.type),
              if (!notification.read)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: GoogleFonts.cairo(
                          fontWeight: notification.read ? FontWeight.w500 : FontWeight.bold,
                          fontSize: 14,
                          color: notification.read ? Colors.grey[600] : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(notification.priority).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notification.priority.toUpperCase(),
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(notification.priority),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _formatTimeAgo(notification.createdAt),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    if (!notification.read)
                      TextButton(
                        onPressed: () => _markAsRead(notification.id),
                        child: Text(
                          'Mark read',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () => _deleteNotification(notification.id),
                      icon: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${((_currentPage - 1) * _pageLimit) + 1}-${(_currentPage * _pageLimit).clamp(1, _totalRecords)} of $_totalRecords notifications',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: const Color(0xFF6C757D),
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1 ? () {
                  setState(() {
                    _currentPage--;
                  });
                  _loadNotifications();
                } : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage > 1 ? Colors.white : Colors.grey.shade100,
                  foregroundColor: _currentPage > 1 ? const Color(0xFF495057) : const Color(0xFF6C757D),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_currentPage',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _currentPage < _totalPages ? () {
                  setState(() {
                    _currentPage++;
                  });
                  _loadNotifications();
                } : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: _currentPage < _totalPages ? Colors.white : Colors.grey.shade100,
                  foregroundColor: _currentPage < _totalPages ? const Color(0xFF495057) : const Color(0xFF6C757D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
