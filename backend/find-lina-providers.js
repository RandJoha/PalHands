const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

async function findLinaProviders() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB connected');

    // Find all Lina providers
    const linaProviders = await Provider.find({
      $or: [
        { firstName: { $regex: /lina/i } },
        { lastName: { $regex: /lina/i } },
        { email: { $regex: /lina/i } }
      ]
    });

    console.log(`\n📋 Found ${linaProviders.length} Lina provider(s):`);
    
    for (const provider of linaProviders) {
      console.log(`\n🔸 Provider: ${provider.firstName} ${provider.lastName}`);
      console.log(`  ID: ${provider._id}`);
      console.log(`  Email: ${provider.email}`);
      console.log(`  Services: ${provider.services}`);
      console.log(`  Hourly Rate: ₪${provider.hourlyRate}`);
      console.log(`  Experience: ${provider.experienceYears} years`);

      // Check Service documents for this provider
      const services = await Service.find({ provider: provider._id });
      console.log(`  📄 Service Documents: ${services.length}`);
      for (const service of services) {
        console.log(`    - ${service.title} (${service.subcategory}) - ₪${service.hourlyRate}/hour`);
      }

      // Check ProviderService documents for this provider
      const providerServices = await ProviderService.find({ provider: provider._id });
      console.log(`  🔗 ProviderService Documents: ${providerServices.length}`);
      for (const ps of providerServices) {
        const serviceName = ps.service ? 
          (await Service.findById(ps.service))?.title || 'Service Not Found' : 
          'undefined';
        console.log(`    - Service: ${serviceName} (${ps.service}), Rate: ₪${ps.hourlyRate}/hour, Experience: ${ps.experienceYears} years`);
      }
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔚 Connection closed');
  }
}

findLinaProviders();
