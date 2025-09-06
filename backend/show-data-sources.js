const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

async function showDataSources() {
  try {
    // Connect to MongoDB Atlas
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas');

    // Show collection counts
    const providerCount = await Provider.countDocuments();
    const serviceCount = await Service.countDocuments();
    const providerServiceCount = await ProviderService.countDocuments();

    console.log('\n📊 Current Data Sources in MongoDB Atlas:');
    console.log(`   👥 providers collection: ${providerCount} documents`);
    console.log(`   📋 services collection: ${serviceCount} documents`);
    console.log(`   🔗 providerservices collection: ${providerServiceCount} documents ⭐ MAIN SOURCE`);

    // Show sample data flow for one provider
    console.log('\n🔍 Sample Data Flow (Lina Faris):');
    
    const provider = await Provider.findOne({ email: 'provider.lina.33@palhands.com' });
    if (provider) {
      console.log('\n1️⃣ PROVIDERS Collection:');
      console.log(`   Services array: [${provider.services.join(', ')}]`);
      console.log(`   Base hourly rate: ₪${provider.hourlyRate}`);
      console.log(`   Base experience: ${provider.experienceYears} years`);

      console.log('\n2️⃣ SERVICES Collection:');
      const services = await Service.find({ provider: provider._id });
      for (const service of services) {
        console.log(`   - ${service.title} (${service.subcategory}): ₪${service.hourlyRate}/hour`);
      }

      console.log('\n3️⃣ PROVIDERSERVICES Collection ⭐ MAIN SOURCE:');
      const providerServices = await ProviderService.find({ provider: provider._id })
        .populate('service', 'title subcategory');
      
      for (const ps of providerServices) {
        console.log(`   - ${ps.service.title}: ₪${ps.hourlyRate}/hour, ${ps.experienceYears} years, status: ${ps.status}`);
      }

      console.log('\n✨ Frontend Usage:');
      console.log('   📱 "My Services Management" → reads from PROVIDERSERVICES');
      console.log('   🌐 "Our Services" tab → reads from PROVIDERSERVICES');
      console.log('   💰 Individual pricing → stored in PROVIDERSERVICES');
      console.log('   📊 Per-service experience → stored in PROVIDERSERVICES');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔚 Connection closed');
  }
}

showDataSources();
