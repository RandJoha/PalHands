const Notification = require('../models/Notification');
const User = require('../models/User');
const Admin = require('../models/Admin');

class NotificationService {
  /**
   * Create a notification for all admin users
   */
  static async notifyAllAdmins(notificationData) {
    try {
      // Get all admin users
      const adminUsers = await Admin.find().populate('user', '_id firstName lastName email');
      
      if (!adminUsers || adminUsers.length === 0) {
        console.log('No admin users found for notification');
        return;
      }

      const notifications = adminUsers.map(admin => ({
        recipient: admin.user._id,
        type: notificationData.type,
        title: notificationData.title,
        message: notificationData.message,
        data: notificationData.data || {},
        priority: notificationData.priority || 'medium'
      }));

      await Notification.insertMany(notifications);
      
      console.log(`✅ Notifications created for ${adminUsers.length} admin users`);
      
      // Return notification count for potential real-time updates
      return {
        success: true,
        count: adminUsers.length,
        notifications: notifications
      };
    } catch (error) {
      console.error('❌ Error creating admin notifications:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Create notification for new report
   */
  static async notifyNewReport(report) {
    try {
      const reporterName = report.contactName || 
        (report.reporter ? `${report.reporter.firstName || ''} ${report.reporter.lastName || ''}`.trim() : 'Anonymous');
      
      const categoryDisplay = this.getCategoryDisplayName(report.reportCategory);
      
      const notificationData = {
        type: 'new_report',
        title: 'New Report Submitted',
        message: `A new ${categoryDisplay} report has been submitted by ${reporterName}`,
        data: {
          reportId: report._id,
          reporterId: report.reporter,
          reporterName: reporterName,
          reportCategory: report.reportCategory,
          status: report.status
        },
        priority: this.getPriorityForCategory(report.reportCategory)
      };

      return await this.notifyAllAdmins(notificationData);
    } catch (error) {
      console.error('❌ Error creating new report notification:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Create notification for report status update
   */
  static async notifyReportUpdate(report, oldStatus, newStatus, updatedBy) {
    try {
      const reporterName = report.contactName || 
        (report.reporter ? `${report.reporter.firstName || ''} ${report.reporter.lastName || ''}`.trim() : 'Anonymous');
      
      const categoryDisplay = this.getCategoryDisplayName(report.reportCategory);
      const statusDisplay = this.getStatusDisplayName(newStatus);
      
      const notificationData = {
        type: 'report_updated',
        title: 'Report Status Updated',
        message: `Report #${report._id.toString().slice(-6)} status changed from ${this.getStatusDisplayName(oldStatus)} to ${statusDisplay}`,
        data: {
          reportId: report._id,
          reporterId: report.reporter,
          reporterName: reporterName,
          reportCategory: report.reportCategory,
          status: newStatus
        },
        priority: 'medium'
      };

      return await this.notifyAllAdmins(notificationData);
    } catch (error) {
      console.error('❌ Error creating report update notification:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get notifications for a specific user
   */
  static async getUserNotifications(userId, options = {}) {
    try {
      const { page = 1, limit = 20, unreadOnly = false } = options;
      const skip = (page - 1) * limit;

      const filter = { recipient: userId };
      if (unreadOnly) {
        filter.read = false;
      }

      const notifications = await Notification.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit);

      const total = await Notification.countDocuments(filter);
      const unreadCount = await Notification.countDocuments({ 
        recipient: userId, 
        read: false 
      });

      return {
        success: true,
        data: {
          notifications,
          pagination: {
            current: page,
            total: Math.ceil(total / limit),
            totalRecords: total
          },
          unreadCount
        }
      };
    } catch (error) {
      console.error('❌ Error fetching user notifications:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Mark notification as read
   */
  static async markAsRead(notificationId, userId) {
    try {
      const notification = await Notification.findOneAndUpdate(
        { _id: notificationId, recipient: userId },
        { read: true, readAt: new Date() },
        { new: true }
      );

      if (!notification) {
        return {
          success: false,
          message: 'Notification not found or access denied'
        };
      }

      return {
        success: true,
        data: notification
      };
    } catch (error) {
      console.error('❌ Error marking notification as read:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Mark all notifications as read for a user
   */
  static async markAllAsRead(userId) {
    try {
      const result = await Notification.updateMany(
        { recipient: userId, read: false },
        { read: true, readAt: new Date() }
      );

      return {
        success: true,
        data: {
          updatedCount: result.modifiedCount
        }
      };
    } catch (error) {
      console.error('❌ Error marking all notifications as read:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Delete notification
   */
  static async deleteNotification(notificationId, userId) {
    try {
      const notification = await Notification.findOneAndDelete({
        _id: notificationId,
        recipient: userId
      });

      if (!notification) {
        return {
          success: false,
          message: 'Notification not found or access denied'
        };
      }

      return {
        success: true,
        data: notification
      };
    } catch (error) {
      console.error('❌ Error deleting notification:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Helper methods
  static getCategoryDisplayName(category) {
    const categories = {
      'user_issue': 'User Issue',
      'technical_issue': 'Technical Issue',
      'feature_suggestion': 'Feature Suggestion',
      'service_category_request': 'Service Category Request',
      'other': 'Other'
    };
    return categories[category] || category;
  }

  static getStatusDisplayName(status) {
    const statuses = {
      'pending': 'Pending',
      'under_review': 'Under Review',
      'awaiting_user': 'Awaiting User',
      'investigating': 'Investigating',
      'resolved': 'Resolved',
      'dismissed': 'Dismissed'
    };
    return statuses[status] || status;
  }

  static getPriorityForCategory(category) {
    const priorities = {
      'user_issue': 'high',
      'technical_issue': 'high',
      'feature_suggestion': 'medium',
      'service_category_request': 'medium',
      'other': 'low'
    };
    return priorities[category] || 'medium';
  }
}

module.exports = NotificationService;
