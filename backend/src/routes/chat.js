const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { auth } = require('../middleware/auth');

// Test endpoint (no auth required)
router.get('/test', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Chat API is working!',
    timestamp: new Date().toISOString()
  });
});

// Test endpoint to check current chats (requires auth)
router.get('/test-chats', auth, async (req, res) => {
  try {
    const Chat = require('../models/Chat');
    const User = require('../models/User');
    
    const userId = req.user._id;
    const chats = await Chat.find({
      participants: userId,
      isActive: true
    }).populate('participants', 'firstName lastName');
    
    res.json({
      success: true,
      message: 'Current chats retrieved',
      userId: userId.toString(),
      chatCount: chats.length,
      chats: chats.map(chat => ({
        id: chat._id,
        participants: chat.participants.map(p => `${p.firstName} ${p.lastName}`),
        lastMessage: chat.lastMessage?.content || 'No message',
        serviceName: chat.serviceName,
        updatedAt: chat.updatedAt
      }))
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error retrieving chats',
      error: error.message
    });
  }
});

// All chat routes require authentication
router.use(auth);

// Get user's chat list
router.get('/', chatController.getUserChats);

// Create or get existing chat
router.post('/', chatController.createOrGetChat);

// Get chat messages
router.get('/:chatId/messages', chatController.getChatMessages);

// Send a message
router.post('/:chatId/messages', chatController.sendMessage);

// Mark messages as read
router.put('/:chatId/read', chatController.markMessagesAsRead);

module.exports = router;
