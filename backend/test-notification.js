const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function testNotificationSystem() {
  try {
    console.log('🧪 Testing notification system...');
    
    // Step 1: Submit a test report
    console.log('📝 Submitting test report...');
    const reportResponse = await axios.post(`${BASE_URL}/reports`, {
      reportCategory: 'other',
      description: 'Test notification report',
      contactEmail: 'test@example.com',
      contactName: 'Test User'
    });
    
    console.log('✅ Report submitted:', reportResponse.data);
    
    // Step 2: Check if notifications were created
    console.log('🔍 Checking for notifications...');
    
    // First, let's check if there are any admin users
    const adminResponse = await axios.get(`${BASE_URL}/admin/users`, {
      headers: {
        'Authorization': 'Bearer YOUR_ADMIN_TOKEN_HERE' // You'll need to replace this with a real admin token
      }
    });
    
    console.log('👥 Admin users:', adminResponse.data);
    
    // Step 3: Check notifications for admin users
    if (adminResponse.data.success && adminResponse.data.data.length > 0) {
      const adminId = adminResponse.data.data[0]._id;
      
      const notificationResponse = await axios.get(`${BASE_URL}/notifications/unread-count`, {
        headers: {
          'Authorization': 'Bearer YOUR_ADMIN_TOKEN_HERE' // You'll need to replace this with a real admin token
        }
      });
      
      console.log('🔔 Unread notifications:', notificationResponse.data);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testNotificationSystem();
