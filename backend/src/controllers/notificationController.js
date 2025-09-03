const NotificationService = require('../services/notificationService');

// GET /api/notifications
const getNotifications = async (req, res) => {
  try {
    const { page = 1, limit = 20, unreadOnly = false } = req.query;
    const userId = req.user._id;

    const result = await NotificationService.getUserNotifications(userId, {
      page: parseInt(page),
      limit: parseInt(limit),
      unreadOnly: unreadOnly === 'true'
    });

    res.json(result);
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch notifications' });
  }
};

// GET /api/notifications/unread-count
const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user._id;
    console.log('🔔 Get unread count request for user:', userId.toString());
    console.log('🔔 User role:', req.user.role);
    
    const result = await NotificationService.getUnreadCount(userId);
    console.log('🔔 Unread count result:', result);
    
    res.json(result);
  } catch (error) {
    console.error('Get unread count error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch unread count' });
  }
};

// PUT /api/notifications/:notificationId/read
const markAsRead = async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.user._id;

    const result = await NotificationService.markAsRead(notificationId, userId);
    res.json(result);
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ success: false, message: 'Failed to mark notification as read' });
  }
};

// PUT /api/notifications/read-all
const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user._id;
    const result = await NotificationService.markAllAsRead(userId);
    res.json(result);
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({ success: false, message: 'Failed to mark all notifications as read' });
  }
};

// PUT /api/notifications/read-by-type
const markAsReadByType = async (req, res) => {
  try {
    const { type } = req.body;
    const userId = req.user._id;

    if (!type) {
      return res.status(400).json({ success: false, message: 'Notification type is required' });
    }

    const result = await NotificationService.markAsReadByType(type, userId);
    res.json(result);
  } catch (error) {
    console.error('Mark as read by type error:', error);
    res.status(500).json({ success: false, message: 'Failed to mark notifications as read by type' });
  }
};

// DELETE /api/notifications/:notificationId
const deleteNotification = async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.user._id;

    const result = await NotificationService.deleteNotification(notificationId, userId);
    res.json(result);
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({ success: false, message: 'Failed to delete notification' });
  }
};

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  markAsReadByType,
  deleteNotification
};
