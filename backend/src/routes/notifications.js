const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
// Use the unified auth middleware re-exported from ../middleware/auth
const { auth } = require('../middleware/auth');

// All routes require authentication
router.use(auth);

// Get user notifications
router.get('/', notificationController.getNotifications);

// Get unread count
router.get('/unread-count', notificationController.getUnreadCount);

// Mark notification as read
router.put('/:notificationId/read', notificationController.markAsRead);

// Mark all notifications as read
router.put('/read-all', notificationController.markAllAsRead);

// Mark notifications as read by type
router.put('/read-by-type', notificationController.markAsReadByType);

// Delete notification
router.delete('/:notificationId', notificationController.deleteNotification);

module.exports = router;
