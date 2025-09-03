const mongoose = require('mongoose');
require('dotenv').config();

// Import the Provider model
const Provider = require('./src/models/Provider');

async function migrateProviderIds() {
  try {
    // Connect to database
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/palhands');
    console.log('✅ Connected to database');
    
    // Get all providers that don't have a providerId
    const providersWithoutId = await Provider.find({ providerId: { $exists: false } });
    console.log(`📋 Found ${providersWithoutId.length} providers without providerId`);
    
    if (providersWithoutId.length === 0) {
      console.log('✅ All providers already have IDs');
      return;
    }
    
    // Get the highest existing providerId to start from
    const highestProvider = await Provider.findOne({ providerId: { $exists: true } }, { providerId: 1 })
      .sort({ providerId: -1 })
      .limit(1);
    
    let nextId = (highestProvider && highestProvider.providerId) ? highestProvider.providerId + 1 : 1000;
    
    console.log(`🚀 Starting provider ID assignment from: ${nextId}`);
    
    // Update each provider with a sequential ID
    for (const provider of providersWithoutId) {
      try {
        await Provider.updateOne(
          { _id: provider._id },
          { $set: { providerId: nextId } }
        );
        
        console.log(`✅ Assigned ID ${nextId} to provider: ${provider.firstName} ${provider.lastName} (${provider.email})`);
        nextId++;
        
        // Check if we're approaching the limit
        if (nextId > 9999) {
          console.error('❌ Maximum provider ID limit reached (9999)');
          break;
        }
      } catch (error) {
        console.error(`❌ Failed to assign ID to provider ${provider.email}:`, error.message);
      }
    }
    
    console.log(`✅ Migration completed. Next available ID: ${nextId}`);
    
    // Verify the migration
    const totalProviders = await Provider.countDocuments();
    const providersWithId = await Provider.countDocuments({ providerId: { $exists: true } });
    
    console.log(`📊 Migration verification:`);
    console.log(`   Total providers: ${totalProviders}`);
    console.log(`   Providers with ID: ${providersWithId}`);
    console.log(`   Providers without ID: ${totalProviders - providersWithId}`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('✅ Disconnected from database');
  }
}

// Run the migration
migrateProviderIds();
