const Notification = require('../models/Notification');
const User = require('../models/User');

class NotificationService {
  // Notify all admins about a new report
  static async notifyNewReport(report) {
    try {
      // Find all admin users
      const admins = await User.find({ role: 'admin', isActive: true });
      
      if (admins.length === 0) {
        console.log('No active admin users found for notifications');
        return;
      }

      // Determine notification priority based on report category
      const priority = this.getNotificationPriority(report.reportCategory);

      // Create notifications for all admins
      const notifications = admins.map(admin => ({
        recipient: admin._id,
        type: 'new_report',
        title: 'New Report Submitted',
        message: `A new ${report.reportCategory.replace('_', ' ')} report has been submitted`,
        data: {
          reportId: report._id,
          reporterId: report.reporter,
          reportCategory: report.reportCategory,
          status: report.status
        },
        priority: priority,
        read: false
      }));

      await Notification.insertMany(notifications);
      console.log(`✅ Notified ${admins.length} admins about new report`);
    } catch (error) {
      console.error('Failed to notify admins about new report:', error);
      throw error;
    }
  }

  // Notify about report status updates
  static async notifyReportUpdate(report, oldStatus, newStatus, updatedBy) {
    try {
      // Find all admin users
      const admins = await User.find({ role: 'admin', isActive: true });
      
      if (admins.length === 0) {
        console.log('No active admin users found for notifications');
        return;
      }

      const notifications = admins.map(admin => ({
        recipient: admin._id,
        type: 'report_update',
        title: 'Report Status Updated',
        message: `Report status changed from ${oldStatus} to ${newStatus}`,
        data: {
          reportId: report._id,
          oldStatus: oldStatus,
          newStatus: newStatus,
          updatedBy: updatedBy
        },
        priority: 'medium',
        read: false
      }));

      await Notification.insertMany(notifications);
      console.log(`✅ Notified ${admins.length} admins about report update`);
    } catch (error) {
      console.error('Failed to notify admins about report update:', error);
      throw error;
    }
  }

  // Get user notifications
  static async getUserNotifications(userId, options = {}) {
    try {
      const { page = 1, limit = 20, unreadOnly = false } = options;
      const skip = (page - 1) * limit;

      const filter = { recipient: userId };
      if (unreadOnly) {
        filter.read = false;
      }

      const [notifications, total] = await Promise.all([
        Notification.find(filter)
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit),
        Notification.countDocuments(filter)
      ]);

      return {
        success: true,
        data: {
          notifications,
          pagination: {
            current: page,
            total: Math.ceil(total / limit),
            totalRecords: total
          }
        }
      };
    } catch (error) {
      console.error('Failed to get user notifications:', error);
      throw error;
    }
  }

  // Mark notification as read
  static async markAsRead(notificationId, userId) {
    try {
      const notification = await Notification.findOneAndUpdate(
        { _id: notificationId, recipient: userId },
        { read: true, readAt: new Date() },
        { new: true }
      );

      if (!notification) {
        throw new Error('Notification not found');
      }

      return { success: true, data: notification };
    } catch (error) {
      console.error('Failed to mark notification as read:', error);
      throw error;
    }
  }

  // Mark all notifications as read for a user
  static async markAllAsRead(userId) {
    try {
      const result = await Notification.updateMany(
        { recipient: userId, read: false },
        { read: true, readAt: new Date() }
      );

      return { success: true, data: { updatedCount: result.modifiedCount } };
    } catch (error) {
      console.error('Failed to mark all notifications as read:', error);
      throw error;
    }
  }

  // Mark notifications as read by type for a user
  static async markAsReadByType(type, userId) {
    try {
      const result = await Notification.updateMany(
        { recipient: userId, type: type, read: false },
        { read: true, readAt: new Date() }
      );

      return { success: true, data: { updatedCount: result.modifiedCount } };
    } catch (error) {
      console.error('Failed to mark notifications as read by type:', error);
      throw error;
    }
  }

  // Delete a notification
  static async deleteNotification(notificationId, userId) {
    try {
      const notification = await Notification.findOneAndDelete({
        _id: notificationId,
        recipient: userId
      });

      if (!notification) {
        throw new Error('Notification not found');
      }

      return { success: true, data: notification };
    } catch (error) {
      console.error('Failed to delete notification:', error);
      throw error;
    }
  }

  // Get unread count for a user
  static async getUnreadCount(userId) {
    try {
      
      const count = await Notification.countDocuments({
        recipient: userId,
        read: false
      });

      return { success: true, data: { unreadCount: count } };
    } catch (error) {
      console.error('Failed to get unread count:', error);
      throw error;
    }
  }

  // Helper method to determine notification priority
  static getNotificationPriority(reportCategory) {
    switch (reportCategory) {
      case 'user_issue':
        return 'high';
      case 'technical_issue':
        return 'high';
      case 'feature_suggestion':
        return 'medium';
      case 'service_category_request':
        return 'medium';
      case 'other':
        return 'low';
      default:
        return 'medium';
    }
  }
}

module.exports = NotificationService;
