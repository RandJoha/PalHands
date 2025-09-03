require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');

// Connect to MongoDB
mongoose.connect('mongodb://localhost:27017/palhands', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

async function checkProviders() {
  try {
    console.log('🔍 Checking providers in database...');
    
    // Find all users with role 'provider'
    const providers = await User.find({ role: 'provider' }).select('_id firstName lastName email services');
    
    console.log(`📋 Found ${providers.length} providers:`);
    
    providers.forEach((provider, index) => {
      console.log(`\n${index + 1}. ${provider.firstName} ${provider.lastName}`);
      console.log(`   ID: ${provider._id}`);
      console.log(`   Email: ${provider.email}`);
      console.log(`   Services: ${provider.services?.join(', ') || 'No services'}`);
    });
    
    // Also check for any existing chats
    const Chat = require('./src/models/Chat');
    const chats = await Chat.find({}).populate('participants', 'firstName lastName');
    
    console.log(`\n💬 Found ${chats.length} chats:`);
    
    chats.forEach((chat, index) => {
      console.log(`\n${index + 1}. Chat ID: ${chat._id}`);
      console.log(`   Participants: ${chat.participants.map(p => `${p.firstName} ${p.lastName}`).join(', ')}`);
      console.log(`   Last Message: ${chat.lastMessage?.content || 'No message'}`);
      console.log(`   Service: ${chat.serviceName || 'No service'}`);
      console.log(`   Updated: ${chat.updatedAt}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    mongoose.connection.close();
  }
}

checkProviders();
