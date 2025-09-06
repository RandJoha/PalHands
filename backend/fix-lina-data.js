const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

async function fixLinaDataSafely() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');

    // Target specific Lina providers
    const targetProviders = [
      { email: 'provider.lina.33@palhands.com', expectedServices: 3 },
      { email: 'provider.lina.8@palhands.com', expectedServices: 2 }
    ];

    for (const target of targetProviders) {
      const provider = await Provider.findOne({ email: target.email });
      if (!provider) {
        console.log(`❌ Provider not found: ${target.email}`);
        continue;
      }

      console.log(`\n🔧 Fixing: ${provider.firstName} ${provider.lastName} (${target.email})`);

      // Step 1: Remove orphaned ProviderService records with undefined service
      console.log('  🗑️  Removing orphaned ProviderService records...');
      const deleteResult = await ProviderService.deleteMany({ 
        provider: provider._id, 
        $or: [
          { service: null },
          { service: undefined },
          { service: { $exists: false } }
        ]
      });
      console.log(`     Deleted ${deleteResult.deletedCount} orphaned records`);

      // Step 2: Fix Service documents hourlyRate
      const services = await Service.find({ provider: provider._id });
      console.log(`  📄 Fixing ${services.length} Service documents...`);
      
      for (const service of services) {
        if (!service.hourlyRate || service.hourlyRate === undefined || isNaN(service.hourlyRate)) {
          // Use provider's base rate with slight variation
          const baseRate = provider.hourlyRate || 50;
          const variation = Math.floor(Math.random() * 20) - 10; // -10 to +10
          const newRate = Math.max(20, baseRate + variation);
          
          await Service.findByIdAndUpdate(service._id, {
            hourlyRate: newRate,
            experienceYears: provider.experienceYears || 1
          });
          
          console.log(`     ✅ Updated ${service.title}: ₪${newRate}/hour`);
        } else {
          console.log(`     ℹ️  ${service.title} already has rate: ₪${service.hourlyRate}/hour`);
        }
      }

      // Step 3: Ensure each service has a corresponding ProviderService record
      console.log(`  🔗 Ensuring ProviderService records exist...`);
      
      const existingPS = await ProviderService.find({ provider: provider._id }).populate('service');
      const existingServiceIds = existingPS
        .filter(ps => ps.service && ps.service._id)
        .map(ps => ps.service._id.toString());
      
      let created = 0;
      for (const service of services) {
        if (!existingServiceIds.includes(service._id.toString())) {
          // Create missing ProviderService record
          const baseRate = service.hourlyRate || provider.hourlyRate || 50;
          const variation = Math.floor(Math.random() * 15) - 7; // slight variation
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
          
          created++;
          console.log(`     ✅ Created ProviderService for ${service.title}: ₪${newRate}/hour`);
        } else {
          console.log(`     ℹ️  ProviderService for ${service.title} already exists`);
        }
      }
      
      console.log(`     Created ${created} new ProviderService records`);

      // Step 4: Verify final state
      const finalPS = await ProviderService.find({ provider: provider._id }).populate('service');
      console.log(`  ✅ Final verification:`);
      console.log(`     Expected: ${target.expectedServices} services`);
      console.log(`     Got: ${finalPS.length} ProviderService records`);
      
      if (finalPS.length === target.expectedServices) {
        console.log(`     ✅ Perfect match!`);
        for (const ps of finalPS) {
          if (ps.service) {
            console.log(`       - ${ps.service.title}: ₪${ps.hourlyRate}/hour, ${ps.experienceYears} years`);
          }
        }
      } else {
        console.log(`     ⚠️  Mismatch detected!`);
      }
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error.stack);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔚 Connection closed');
  }
}

fixLinaDataSafely();
