require('dotenv').config();
const { connectDB, mongoose } = require('./src/config/database');
const Provider = require('./src/models/Provider');

async function testSearch() {
  await connectDB();

  try {
    // Test search for kitchenCleaning
    console.log('🔍 Testing search for "kitchenCleaning":');
    const kitchenProviders = await Provider.find({
      isActive: true,
      services: { $in: ['kitchenCleaning'] }
    });
    console.log(`Found ${kitchenProviders.length} providers with kitchenCleaning`);
    kitchenProviders.forEach(p => console.log(`- ${p.firstName} ${p.lastName}`));

    // Test search for bathroomCleaning
    console.log('\n🔍 Testing search for "bathroomCleaning":');
    const bathroomProviders = await Provider.find({
      isActive: true,
      services: { $in: ['bathroomCleaning'] }
    });
    console.log(`Found ${bathroomProviders.length} providers with bathroomCleaning`);
    bathroomProviders.forEach(p => console.log(`- ${p.firstName} ${p.lastName}`));

    // Test search for both
    console.log('\n🔍 Testing search for both "kitchenCleaning" and "bathroomCleaning":');
    const bothProviders = await Provider.find({
      isActive: true,
      services: { $in: ['kitchenCleaning', 'bathroomCleaning'] }
    });
    console.log(`Found ${bothProviders.length} providers with either service`);
    bothProviders.forEach(p => console.log(`- ${p.firstName} ${p.lastName}: ${p.services.join(', ')}`));

  } catch (error) {
    console.error('❌ Error testing search:', error);
  } finally {
    await mongoose.connection.close();
  }
}

testSearch();
