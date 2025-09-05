const mongoose = require('mongoose');
const Notification = require('./src/models/Notification');
const User = require('./src/models/User');
const Provider = require('./src/models/Provider');
require('dotenv').config();

async function testChatNotification() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to database');

  // Find a provider from providers collection
  const provider = await Provider.findOne({});
    if (!provider) {
      console.log('❌ No provider found');
      return;
    }
    console.log('👤 Found provider:', provider.email, 'ID:', provider._id.toString());

    // Find a regular user
  const user = await User.findOne({ role: 'client' });
    if (!user) {
      console.log('❌ No user found');
      return;
    }
    console.log('👤 Found user:', user.email, 'ID:', user._id.toString());

    // Create a test notification
    const notification = new Notification({
      recipient: provider._id,
      type: 'new_message',
      title: 'Test Message',
      message: `You have a new message from ${user.firstName} ${user.lastName}`,
      data: {
        chatId: 'test-chat-id',
        senderId: user._id,
        senderName: `${user.firstName} ${user.lastName}`,
        messageContent: 'This is a test message',
        messageType: 'text'
      },
      priority: 'medium'
    });

    await notification.save();
    console.log('✅ Test notification created');

    // Check if notification exists
    const savedNotification = await Notification.findById(notification._id);
    console.log('🔍 Saved notification:', {
      id: savedNotification._id,
      recipient: savedNotification.recipient,
      type: savedNotification.type,
      title: savedNotification.title,
      read: savedNotification.read
    });

    // Test getting unread count for provider
    const unreadCount = await Notification.countDocuments({
      recipient: provider._id,
      read: false
    });
    console.log('📊 Unread count for provider:', unreadCount);

    // Clean up test notification
    await Notification.findByIdAndDelete(notification._id);
    console.log('🧹 Test notification cleaned up');

  } catch (error) {
    console.error('❌ Test failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('✅ Disconnected from database');
  }
}

testChatNotification();
