require('dotenv').config();
const { connectDB, mongoose } = require('./src/config/database');
const Provider = require('./src/models/Provider');

async function checkProviders() {
  try {
    await connectDB();
    console.log('🔍 Checking providers in database...');
    
    // Find all providers in Provider collection
    const providers = await Provider.find({}).select('_id firstName lastName email services');
    
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
