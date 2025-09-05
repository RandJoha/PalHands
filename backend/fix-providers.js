require('dotenv').config();
const { connectDB, mongoose } = require('./src/config/database');
const Provider = require('./src/models/Provider');

async function fixProviders() {
  await connectDB();

  try {
  // Get all providers (providers collection)
  const providers = await Provider.find({});
    console.log(`Found ${providers.length} providers`);

    // Define services for each provider
    const servicesToAdd = [
      ['homeCleaning', 'bedroomCleaning', 'kitchenCleaning', 'bathroomCleaning'],
      ['elderlyCare', 'childcare', 'homeCooking'],
      ['homeMaintenance', 'carpentry', 'electricalWork'],
      ['plumbingWork', 'painting', 'hangingItems'],
      ['furnitureMoving', 'packingUnpacking', 'newHomeArrangement'],
      ['documentDelivery', 'shoppingDelivery', 'specialErrands'],
      ['homeCleaning', 'floorCleaning', 'bathroomCleaning', 'windowCleaning'],
      ['elderlyCare', 'medicalTransport', 'healthMonitoring'],
      ['homeMaintenance', 'aluminumWork', 'satelliteInstallation'],
      ['applianceMaintenance', 'applianceInstallation', 'kitchenSetup'],
      ['childcare', 'sickChildCare', 'homeCooking'],
      ['elderlyCare', 'mobilityAssistance', 'emotionalSupport'],
      ['homeCleaning', 'newApartmentCleaning', 'preOccupancyRepairs', 'doorCabinetCleaning'],
      ['homeMaintenance', 'carpentryWork', 'painting', 'livingRoomCleaning']
    ];

    // Update each provider with services
    for (let i = 0; i < providers.length; i++) {
      const provider = providers[i];
      const services = servicesToAdd[i % servicesToAdd.length];
      
  const updateResult = await Provider.updateOne(
        { _id: provider._id },
        {
          $set: {
            services: services,
            experienceYears: Math.floor(Math.random() * 10) + 1,
            languages: ['Arabic', 'English'],
            hourlyRate: 50 + Math.floor(Math.random() * 50),
            rating: {
              average: 3.5 + Math.random() * 1.5,
              count: Math.floor(Math.random() * 50) + 5
            }
          }
        }
      );
      
      console.log(`✅ Updated ${provider.firstName} ${provider.lastName} with services: ${services.join(', ')} (Modified: ${updateResult.modifiedCount})`);
    }

    // Verify the updates
    console.log('\n🔍 Verifying updates...');
  const updatedProviders = await Provider.find({});
    
    for (const provider of updatedProviders) {
      console.log(`📋 ${provider.firstName} ${provider.lastName}:`);
      console.log(`   Services: ${provider.services ? provider.services.join(', ') : 'NONE'}`);
      console.log(`   Experience: ${provider.experienceYears || 'NONE'}`);
      console.log(`   Hourly Rate: ${provider.hourlyRate || 'NONE'}`);
    }

    // Test search for kitchenCleaning
    console.log('\n🔍 Testing search for "kitchenCleaning":');
  const kitchenProviders = await Provider.find({
      isActive: true,
      services: { $in: ['kitchenCleaning'] }
    });
    console.log(`Found ${kitchenProviders.length} providers with kitchenCleaning`);

    // Test search for bathroomCleaning
    console.log('\n🔍 Testing search for "bathroomCleaning":');
  const bathroomProviders = await Provider.find({
      isActive: true,
      services: { $in: ['bathroomCleaning'] }
    });
    console.log(`Found ${bathroomProviders.length} providers with bathroomCleaning`);

    console.log('\n🎯 All providers updated with services!');
    console.log('📱 Providers are now searchable by service type');

  } catch (error) {
    console.error('❌ Error updating providers:', error);
  } finally {
    await mongoose.connection.close();
  }
}

fixProviders();
