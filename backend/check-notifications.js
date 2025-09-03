const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Notification = require('./src/models/Notification');
const User = require('./src/models/User');

async function checkNotifications() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/palhands');
    console.log('✅ Connected to database');
    
    // Check for admin users
    const adminUsers = await User.find({ role: 'admin', isActive: true });
    console.log(`👥 Found ${adminUsers.length} active admin users`);
    
    if (adminUsers.length === 0) {
      console.log('❌ No admin users found - notifications cannot be created');
      return;
    }
    
    // Check for notifications
    const notifications = await Notification.find({});
    console.log(`🔔 Found ${notifications.length} total notifications`);
    
    // Check for unread notifications
    const unreadNotifications = await Notification.find({ read: false });
    console.log(`🔔 Found ${unreadNotifications.length} unread notifications`);
    
    // Show notification details
    if (notifications.length > 0) {
      console.log('\n📋 Notification details:');
      notifications.forEach((notification, index) => {
        console.log(`${index + 1}. Type: ${notification.type}`);
        console.log(`   Title: ${notification.title}`);
        console.log(`   Message: ${notification.message}`);
        console.log(`   Recipient: ${notification.recipient}`);
        console.log(`   Read: ${notification.read}`);
        console.log(`   Created: ${notification.createdAt}`);
        console.log('');
      });
    }
    
    // Check notifications for each admin
    for (const admin of adminUsers) {
      const adminNotifications = await Notification.find({ recipient: admin._id });
      console.log(`👤 Admin ${admin.email}: ${adminNotifications.length} notifications`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('✅ Disconnected from database');
  }
}

checkNotifications();
