const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

async function analyzeLinaData() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');

    // Find both Lina providers
    const linaProviders = await Provider.find({
      email: { $in: ['provider.lina.8@palhands.com', 'provider.lina.33@palhands.com'] }
    });

    for (const provider of linaProviders) {
      console.log(`\n🔍 Analyzing: ${provider.firstName} ${provider.lastName} (${provider.email})`);
      console.log(`   Provider ID: ${provider._id}`);
      console.log(`   Services in array: ${provider.services}`);

      // Get all ProviderService records (including broken ones)
      const allPS = await ProviderService.find({ provider: provider._id });
      console.log(`\n📋 All ProviderService records (${allPS.length}):`);
      
      for (const ps of allPS) {
        console.log(`   - ID: ${ps._id}`);
        console.log(`     Service: ${ps.service} (${typeof ps.service})`);
        console.log(`     Rate: ₪${ps.hourlyRate || 0}`);
        console.log(`     Experience: ${ps.experienceYears || 0} years`);
        console.log(`     Status: ${ps.status}`);
        console.log(`     ---`);
      }

      // Get Service documents
      const services = await Service.find({ provider: provider._id });
      console.log(`\n📄 Service documents (${services.length}):`);
      
      for (const service of services) {
        console.log(`   - ID: ${service._id}`);
        console.log(`     Title: ${service.title}`);
        console.log(`     Subcategory: ${service.subcategory}`);
        console.log(`     Rate: ₪${service.hourlyRate || 'undefined'}`);
        console.log(`     ---`);
      }
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔚 Connection closed');
  }
}

analyzeLinaData();
