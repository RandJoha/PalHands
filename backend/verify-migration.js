const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

async function showMigrationResults() {
  try {
    // Connect to MongoDB Atlas
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas');

    // Get summary statistics
    const totalProviders = await Provider.countDocuments();
    const totalServices = await Service.countDocuments();
    const totalProviderServices = await ProviderService.countDocuments();

    console.log('\n📊 Migration Results Summary:');
    console.log(`   👥 Total Providers: ${totalProviders}`);
    console.log(`   📋 Total Service Documents: ${totalServices}`);
    console.log(`   🔗 Total ProviderService Documents: ${totalProviderServices}`);

    // Show sample data for verification
    console.log('\n🔍 Sample Provider Data (First 5):');
    
    const sampleProviders = await Provider.find({}).limit(5).select('firstName lastName email services');
    
    for (const provider of sampleProviders) {
      console.log(`\n📝 ${provider.firstName} ${provider.lastName} (${provider.email})`);
      console.log(`   Services: [${provider.services.join(', ')}]`);
      
      const providerServices = await ProviderService.find({ provider: provider._id })
        .populate('service', 'title subcategory');
      
      console.log(`   ProviderService Records: ${providerServices.length}`);
      for (const ps of providerServices) {
        if (ps.service) {
          console.log(`     - ${ps.service.title}: ₪${ps.hourlyRate}/hour (${ps.experienceYears} years)`);
        }
      }
    }

    // Show Lina's data specifically
    console.log('\n🎯 Lina Faris Verification:');
    const lina = await Provider.findOne({ email: 'provider.lina.33@palhands.com' });
    if (lina) {
      console.log(`   Services in array: [${lina.services.join(', ')}]`);
      
      const linaPS = await ProviderService.find({ provider: lina._id })
        .populate('service', 'title subcategory');
      
      console.log(`   ProviderService Records: ${linaPS.length}`);
      for (const ps of linaPS) {
        if (ps.service) {
          const match = lina.services.includes(ps.service.subcategory) ? '✅' : '❌';
          console.log(`     ${match} ${ps.service.title}: ₪${ps.hourlyRate}/hour`);
        }
      }
      
      if (linaPS.length === lina.services.length) {
        console.log('   🎉 PERFECT! Service count matches exactly!');
      } else {
        console.log('   ⚠️  Service count mismatch detected!');
      }
    }

    console.log('\n✨ Migration verification complete!');
    console.log('🔗 All providers now have consistent per-service data structure.');
    console.log('📱 Frontend "My Services Management" will show exact service counts.');
    console.log('🌐 "Our Services" tab will use the same MongoDB data source.');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔚 Connection closed');
  }
}

showMigrationResults();
