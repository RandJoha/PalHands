const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

async function cleanupLinaData() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');

    // Find both Lina providers
    const linaProviders = await Provider.find({
      $or: [
        { firstName: { $regex: /lina/i } },
        { lastName: { $regex: /lina/i } },
        { email: { $regex: /lina/i } }
      ]
    });

    console.log(`\n📋 Processing ${linaProviders.length} Lina provider(s):`);
    
    for (const provider of linaProviders) {
      console.log(`\n🔧 Cleaning up: ${provider.firstName} ${provider.lastName} (${provider.email})`);
      
      // Step 1: Remove orphaned ProviderService records with undefined service
      const orphanedRecords = await ProviderService.find({ 
        provider: provider._id, 
        service: { $in: [null, undefined] }
      });
      
      if (orphanedRecords.length > 0) {
        console.log(`  🗑️  Removing ${orphanedRecords.length} orphaned ProviderService records...`);
        await ProviderService.deleteMany({ 
          provider: provider._id, 
          service: { $in: [null, undefined] }
        });
      }

      // Step 2: Fix Service documents hourlyRate
      const services = await Service.find({ provider: provider._id });
      console.log(`  📄 Fixing ${services.length} Service documents...`);
      
      for (const service of services) {
        if (!service.hourlyRate || service.hourlyRate === undefined) {
          // Use provider's base rate with slight variation
          const baseRate = provider.hourlyRate || 50;
          const variation = Math.floor(Math.random() * 20) - 10; // -10 to +10
          const newRate = Math.max(20, baseRate + variation);
          
          await Service.findByIdAndUpdate(service._id, {
            hourlyRate: newRate,
            experienceYears: provider.experienceYears || 1
          });
          
          console.log(`    - Updated ${service.title}: ₪${newRate}/hour, ${provider.experienceYears} years experience`);
        }
      }

      // Step 3: Ensure each service has a corresponding ProviderService record
      const providerServices = await ProviderService.find({ provider: provider._id }).populate('service');
      const existingServiceIds = providerServices
        .filter(ps => ps.service)
        .map(ps => ps.service._id.toString());
      
      for (const service of services) {
        if (!existingServiceIds.includes(service._id.toString())) {
          // Create missing ProviderService record
          const baseRate = provider.hourlyRate || 50;
          const variation = Math.floor(Math.random() * 20) - 10;
          const newRate = Math.max(20, baseRate + variation);
          
          await ProviderService.create({
            provider: provider._id,
            service: service._id,
            hourlyRate: newRate,
            experienceYears: provider.experienceYears || 1,
            emergencyEnabled: true,
            status: 'active',
            publishable: true
          });
          
          console.log(`    + Created ProviderService for ${service.title}: ₪${newRate}/hour`);
        }
      }

      // Step 4: Verify final state
      const finalProviderServices = await ProviderService.find({ provider: provider._id }).populate('service');
      console.log(`  ✅ Final state: ${finalProviderServices.length} ProviderService records`);
      
      for (const ps of finalProviderServices) {
        if (ps.service) {
          console.log(`    - ${ps.service.title}: ₪${ps.hourlyRate}/hour, ${ps.experienceYears} years`);
        } else {
          console.log(`    - ⚠️  Still has undefined service reference!`);
        }
      }
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔚 Connection closed');
  }
}

cleanupLinaData();
