const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const ProviderService = require('./src/models/ProviderService');

async function checkIndexes() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');

    // Get collection
    const collection = mongoose.connection.db.collection('providerservices');
    
    // Get all indexes
    const indexes = await collection.indexes();
    console.log('\n📋 ProviderService collection indexes:');
    console.log(JSON.stringify(indexes, null, 2));

    // Get all ProviderService records for Lina to see what's in the collection
    const lina33Records = await collection.find({ provider: new mongoose.Types.ObjectId('68b5e24da7a595958f91a621') }).toArray();
    console.log(`\n📋 Current ProviderService records for Lina 33 (${lina33Records.length}):`);
    for (const record of lina33Records) {
      console.log(`  - ID: ${record._id}`);
      console.log(`    service: ${record.service}`);
      console.log(`    serviceKey: ${record.serviceKey}`);
      console.log(`    status: ${record.status}`);
      console.log(`    ---`);
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔚 Connection closed');
  }
}

checkIndexes();
