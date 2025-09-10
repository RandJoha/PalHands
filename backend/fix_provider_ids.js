const mongoose = require('mongoose');
const Provider = require('./src/models/Provider');

async function fixProviderIds() {
  try {
    // Connect to MongoDB
    await mongoose.connect('mongodb://127.0.0.1:27017/palhands-dev');
    console.log('Connected to MongoDB');

    // Find all providers without providerId
    const providersWithoutId = await Provider.find({ 
      $or: [
        { providerId: { $exists: false } },
        { providerId: null },
        { providerId: undefined }
      ]
    }).select('_id firstName lastName email providerId');

    console.log(`Found ${providersWithoutId.length} providers without providerId`);

    if (providersWithoutId.length > 0) {
      // Find the highest existing provider ID
      const lastProvider = await Provider.findOne({}, { providerId: 1 })
        .sort({ providerId: -1 })
        .limit(1);
      
      let nextId = lastProvider ? lastProvider.providerId + 1 : 1000;

      console.log(`Starting from providerId: ${nextId}`);

      // Assign providerIds to providers without them
      for (const provider of providersWithoutId) {
        if (nextId > 9999) {
          console.error('❌ Maximum provider ID limit reached (9999)');
          break;
        }

        provider.providerId = nextId;
        await provider.save();
        
        console.log(`✅ Assigned providerId ${nextId} to ${provider.firstName} ${provider.lastName} (${provider._id})`);
        nextId++;
      }
    }

    // Verify all providers now have providerIds
    const allProviders = await Provider.find({}).select('_id firstName lastName providerId');
    const withoutId = allProviders.filter(p => !p.providerId);
    
    if (withoutId.length === 0) {
      console.log('\n✅ All providers now have providerIds!');
    } else {
      console.log(`\n⚠️ ${withoutId.length} providers still without providerId:`);
      withoutId.forEach(p => {
        console.log(`  - ${p.firstName} ${p.lastName} (${p._id})`);
      });
    }

    // Check for duplicate providerIds
    const providerIds = allProviders.map(p => p.providerId).filter(id => id != null);
    const uniqueIds = [...new Set(providerIds)];
    
    if (providerIds.length !== uniqueIds.length) {
      console.log('\n⚠️ WARNING: Duplicate providerIds found!');
      const duplicates = providerIds.filter((id, index) => providerIds.indexOf(id) !== index);
      duplicates.forEach(id => {
        const providers = allProviders.filter(p => p.providerId === id);
        console.log(`  ProviderId ${id} used by:`);
        providers.forEach(p => {
          console.log(`    - ${p.firstName} ${p.lastName} (${p._id})`);
        });
      });
    } else {
      console.log('\n✅ No duplicate providerIds found!');
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

fixProviderIds();
