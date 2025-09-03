require('dotenv').config();
const { connectDB, mongoose } = require('./src/config/database');
const User = require('./src/models/User');

async function addServicesToProviders() {
  await connectDB();

  try {
    // Get all providers
    const providers = await User.find({ role: 'provider' });
    console.log(`Found ${providers.length} providers`);

    // Define services for each provider
    const servicesToAdd = [
      ['homeCleaning', 'bedroomCleaning', 'kitchenCleaning'],
      ['elderlyCare', 'childcare', 'homeCooking'],
      ['homeMaintenance', 'carpentry', 'electricalWork'],
      ['plumbingWork', 'painting', 'hangingItems'],
      ['furnitureMoving', 'packingUnpacking', 'newHomeArrangement'],
      ['documentDelivery', 'shoppingDelivery', 'specialErrands'],
      ['homeCleaning', 'floorCleaning', 'bathroomCleaning'],
      ['elderlyCare', 'medicalTransport', 'healthMonitoring'],
      ['homeMaintenance', 'aluminumWork', 'satelliteInstallation'],
      ['applianceMaintenance', 'applianceInstallation', 'kitchenSetup'],
      ['childcare', 'sickChildCare', 'homeCooking'],
      ['elderlyCare', 'mobilityAssistance', 'emotionalSupport'],
      ['homeCleaning', 'newApartmentCleaning', 'preOccupancyRepairs'],
      ['homeMaintenance', 'carpentryWork', 'painting']
    ];

    // Update each provider with services
    for (let i = 0; i < providers.length; i++) {
      const provider = providers[i];
      const services = servicesToAdd[i % servicesToAdd.length];
      
      await User.findByIdAndUpdate(provider._id, {
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
      });
      
      console.log(`✅ Updated ${provider.firstName} ${provider.lastName} with services: ${services.join(', ')}`);
    }

    console.log('\n🎯 All providers updated with services!');
    console.log('📱 Providers are now searchable by service type');

  } catch (error) {
    console.error('❌ Error updating providers:', error);
  } finally {
    await mongoose.connection.close();
  }
}

addServicesToProviders();
