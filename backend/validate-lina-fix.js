const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

async function validateLinaFix() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');

    // Test both Lina providers
    const linaeProviders = [
      { email: 'provider.lina.33@palhands.com', expectedServices: 3 },
      { email: 'provider.lina.8@palhands.com', expectedServices: 2 }
    ];

    for (const target of linaeProviders) {
      const provider = await Provider.findOne({ email: target.email });
      if (!provider) {
        console.log(`❌ Provider not found: ${target.email}`);
        continue;
      }

      console.log(`\n🔍 Validating: ${provider.firstName} ${provider.lastName} (${target.email})`);
      console.log(`   Provider services array: [${provider.services.join(', ')}]`);

      // Get ProviderService records
      const providerServices = await ProviderService.find({ provider: provider._id })
        .populate('service', 'title subcategory');

      console.log(`\n📋 ProviderService records (${providerServices.length}):`);
      
      if (providerServices.length === target.expectedServices) {
        console.log(`   ✅ Perfect match! Expected ${target.expectedServices}, got ${providerServices.length}`);
      } else {
        console.log(`   ❌ Mismatch! Expected ${target.expectedServices}, got ${providerServices.length}`);
      }

      // List each service with pricing
      for (const ps of providerServices) {
        if (ps.service) {
          const subcategory = ps.service.subcategory;
          const isInArray = provider.services.includes(subcategory);
          const statusIcon = isInArray ? '✅' : '❌';
          
          console.log(`   ${statusIcon} ${ps.service.title} (${subcategory})`);
          console.log(`      Rate: ₪${ps.hourlyRate}/hour`);
          console.log(`      Experience: ${ps.experienceYears} years`);
          console.log(`      Status: ${ps.status}`);
          console.log(`      In provider.services: ${isInArray}`);
        } else {
          console.log(`   ❌ ORPHANED: Service reference is null/undefined`);
          console.log(`      Rate: ₪${ps.hourlyRate}/hour`);
          console.log(`      Experience: ${ps.experienceYears} years`);
        }
        console.log(`      ---`);
      }

      // Final assessment
      const allValid = providerServices.every(ps => 
        ps.service && provider.services.includes(ps.service.subcategory)
      );
      
      if (allValid && providerServices.length === target.expectedServices) {
        console.log(`\n🎉 ${provider.firstName} ${provider.lastName}: PERFECT! All services match and count is correct.`);
      } else {
        console.log(`\n⚠️  ${provider.firstName} ${provider.lastName}: Issues detected.`);
      }
    }

    console.log('\n🔚 Validation complete!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('🔚 Connection closed');
  }
}

validateLinaFix();
