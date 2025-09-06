const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

async function dropOldIndexAndFix() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');

    // Get collection
    const collection = mongoose.connection.db.collection('providerservices');
    
    // Drop the problematic index
    try {
      await collection.dropIndex('provider_1_serviceKey_1');
      console.log('✅ Dropped old index: provider_1_serviceKey_1');
    } catch (e) {
      console.log('ℹ️  Index provider_1_serviceKey_1 not found or already dropped');
    }

    // Also drop serviceKey_1 index if it exists
    try {
      await collection.dropIndex('serviceKey_1');
      console.log('✅ Dropped old index: serviceKey_1');
    } catch (e) {
      console.log('ℹ️  Index serviceKey_1 not found or already dropped');
    }

    // Now fix the data safely
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
          const baseRate = provider.hourlyRate || 50;
          const variation = Math.floor(Math.random() * 20) - 10;
          const newRate = Math.max(20, baseRate + variation);
          
          await Service.findByIdAndUpdate(service._id, {
            hourlyRate: newRate,
            experienceYears: provider.experienceYears || 1
          });
          
          console.log(`     ✅ Updated ${service.title}: ₪${newRate}/hour`);
        }
      }

      // Step 3: Ensure each service has a corresponding ProviderService record
      console.log(`  🔗 Creating missing ProviderService records...`);
      
      const existingPS = await ProviderService.find({ provider: provider._id }).populate('service');
      const existingServiceIds = existingPS
        .filter(ps => ps.service && ps.service._id)
        .map(ps => ps.service._id.toString());
      
      let created = 0;
      for (const service of services) {
        if (!existingServiceIds.includes(service._id.toString())) {
          const baseRate = service.hourlyRate || provider.hourlyRate || 50;
          const variation = Math.floor(Math.random() * 15) - 7;
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
        console.log(`     ⚠️  Mismatch: Expected ${target.expectedServices}, got ${finalPS.length}`);
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

dropOldIndexAndFix();
