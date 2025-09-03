const express = require('express');
const cors = require('cors');
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Mock data for testing
let mockNotifications = [
  {
    id: '1',
    recipient: '68aa1bb6b9925e01fb1388fe',
    type: 'new_message',
    title: 'New Message',
    message: 'You have a new message from حور ضياء',
    read: false,
    createdAt: new Date(),
    data: {
      chatId: 'test-chat-1',
      senderId: 'test-sender',
      senderName: 'حور ضياء',
      messageContent: 'Hello, how are you?',
      messageType: 'text'
    }
  }
];

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'PalHands API is running' });
});

// Mock notification endpoints
app.get('/api/notifications/unread-count', (req, res) => {
  try {
    // Simulate authentication check
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }

    // Count unread notifications
    const unreadCount = mockNotifications.filter(n => !n.read).length;
    
    console.log('🔔 Mock unread count request - Count:', unreadCount);
    
    res.json({
      success: true,
      data: { unreadCount: unreadCount }
    });
  } catch (error) {
    console.error('❌ Mock unread count error:', error);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch unread count' 
    });
  }
});

app.get('/api/notifications', (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }

    res.json({
      success: true,
      data: mockNotifications
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Failed to fetch notifications' 
    });
  }
});

app.put('/api/notifications/read-by-type', (req, res) => {
  try {
    const { type } = req.body;
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false, 
        message: 'Authentication required' 
      });
    }

    // Mark notifications as read by type
    mockNotifications.forEach(notification => {
      if (notification.type === type) {
        notification.read = true;
      }
    });

    console.log('🔔 Mock mark as read by type:', type);

    res.json({
      success: true,
      message: `Marked ${type} notifications as read`
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Failed to mark notifications as read' 
    });
  }
});

// Add a test notification endpoint
app.post('/api/test/add-notification', (req, res) => {
  try {
    const newNotification = {
      id: Date.now().toString(),
      recipient: '68aa1bb6b9925e01fb1388fe',
      type: 'new_message',
      title: 'Test Message',
      message: 'This is a test notification',
      read: false,
      createdAt: new Date(),
      data: {
        chatId: 'test-chat-' + Date.now(),
        senderId: 'test-sender',
        senderName: 'Test User',
        messageContent: 'Test message content',
        messageType: 'text'
      }
    };

    mockNotifications.push(newNotification);
    
    console.log('🔔 Added test notification:', newNotification.id);
    
    res.json({
      success: true,
      message: 'Test notification added',
      notification: newNotification
    });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      message: 'Failed to add test notification' 
    });
  }
});

const PORT = 3001;
const HOST = '127.0.0.1';

app.listen(PORT, HOST, () => {
  console.log(`🚀 PalHands TEST server running on http://${HOST}:${PORT}`);
  console.log(`📍 This is a TEST server - no database required`);
  console.log(`🌐 Health check: http://${HOST}:${PORT}/api/health`);
  console.log(`🔔 Test notification: POST http://${HOST}:${PORT}/api/test/add-notification`);
  console.log(`🔔 Unread count: GET http://${HOST}:${PORT}/api/notifications/unread-count`);
  console.log(`🎯 Running on port 3001 to avoid conflicts`);
});
