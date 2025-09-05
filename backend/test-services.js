require('dotenv').config();
const { connectDB, mongoose } = require('./src/config/database');
const Provider = require('./src/models/Provider');

async function testServices() {
  await connectDB();

  try {
    console.log('🔍 Testing search for selected services:');
    const services = ['bathroomCleaning', 'floorCleaning', 'windowCleaning', 'doorCabinetCleaning'];
    
    for (const service of services) {
      const providers = await Provider.find({
        isActive: true,
        services: { $in: [service] }
      });
      console.log(`${service}: Found ${providers.length} providers`);
      providers.forEach(p => console.log(`  - ${p.firstName} ${p.lastName}`));
    }

    // Test combined search
    console.log('\n🔍 Testing combined search for all selected services:');
    const combinedProviders = await Provider.find({
      isActive: true,
      services: { $in: services }
    });
    console.log(`Combined search: Found ${combinedProviders.length} providers`);
    combinedProviders.forEach(p => console.log(`  - ${p.firstName} ${p.lastName}: ${p.services.join(', ')}`));

  } catch (error) {
    console.error('❌ Error testing services:', error);
  } finally {
    await mongoose.connection.close();
  }
}

testServices();
