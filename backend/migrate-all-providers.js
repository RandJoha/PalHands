const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

async function migrateAllProviders() {
  try {
    // Connect to MongoDB Atlas
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB Atlas');

    // Step 1: Remove problematic indexes if they exist
    try {
      const collection = mongoose.connection.db.collection('providerservices');
      const indexes = await collection.indexes();
      
      for (const index of indexes) {
        if (index.name === 'provider_1_serviceKey_1' || index.name === 'serviceKey_1') {
          await collection.dropIndex(index.name);
          console.log(`✅ Dropped old index: ${index.name}`);
        }
      }
    } catch (indexError) {
      console.log('ℹ️  Index cleanup: Some indexes may not exist, continuing...');
    }

    // Step 2: Get all providers
    const allProviders = await Provider.find({}).select('_id firstName lastName email services hourlyRate experienceYears');
    console.log(`\n📋 Found ${allProviders.length} providers to migrate`);

    let successCount = 0;
    let errorCount = 0;

    for (const provider of allProviders) {
      try {
        console.log(`\n🔧 Migrating: ${provider.firstName} ${provider.lastName} (${provider.email})`);
        console.log(`   Services: [${provider.services.join(', ')}]`);

        // Step 2.1: Remove orphaned ProviderService records
        const orphanedCount = await ProviderService.countDocuments({ 
          provider: provider._id, 
          $or: [
            { service: null },
            { service: undefined },
            { service: { $exists: false } }
          ]
        });

        if (orphanedCount > 0) {
          await ProviderService.deleteMany({ 
            provider: provider._id, 
            $or: [
              { service: null },
              { service: undefined },
              { service: { $exists: false } }
            ]
          });
          console.log(`   🗑️  Removed ${orphanedCount} orphaned ProviderService records`);
        }

        // Step 2.2: Ensure Service documents exist for each service in provider.services
        const existingServices = await Service.find({ provider: provider._id });
        const existingSubcategories = existingServices.map(s => s.subcategory);

        for (const serviceKey of provider.services) {
          if (!existingSubcategories.includes(serviceKey)) {
            // Create missing Service document
            const baseRate = provider.hourlyRate || 50;
            const variation = Math.floor(Math.random() * 20) - 10; // -10 to +10
            const serviceRate = Math.max(20, baseRate + variation);

            await Service.create({
              title: prettyServiceName(serviceKey),
              description: `Professional ${prettyServiceName(serviceKey)} service`,
              provider: provider._id,
              category: categoryOf(serviceKey),
              subcategory: serviceKey,
              price: { amount: serviceRate, type: 'hourly', currency: 'ILS' },
              hourlyRate: serviceRate,
              experienceYears: provider.experienceYears || 1,
              duration: { estimated: 120, flexible: true },
              availability: { 
                days: ['monday','tuesday','wednesday','thursday','friday'], 
                timeSlots: [{ start: '09:00', end: '17:00' }], 
                flexible: true 
              },
              location: { 
                serviceArea: 'Ramallah', 
                radius: 20, 
                onSite: true, 
                remote: false 
              },
              isActive: true,
              featured: false
            });

            console.log(`   📄 Created Service document for: ${serviceKey}`);
          }
        }

        // Step 2.3: Get all current Service documents for this provider
        const allServices = await Service.find({ provider: provider._id });

        // Step 2.4: Fix Service documents with undefined hourlyRate
        for (const service of allServices) {
          if (!service.hourlyRate || service.hourlyRate === undefined || isNaN(service.hourlyRate)) {
            const baseRate = provider.hourlyRate || 50;
            const variation = Math.floor(Math.random() * 20) - 10;
            const newRate = Math.max(20, baseRate + variation);
            
            await Service.findByIdAndUpdate(service._id, {
              hourlyRate: newRate,
              experienceYears: provider.experienceYears || 1
            });
            
            console.log(`   💰 Fixed ${service.title}: ₪${newRate}/hour`);
          }
        }

        // Step 2.5: Ensure ProviderService records exist for all services
        const existingPS = await ProviderService.find({ provider: provider._id }).populate('service');
        const existingServiceIds = existingPS
          .filter(ps => ps.service && ps.service._id)
          .map(ps => ps.service._id.toString());

        let createdPS = 0;
        for (const service of allServices) {
          if (!existingServiceIds.includes(service._id.toString())) {
            // Create missing ProviderService record
            const baseRate = service.hourlyRate || provider.hourlyRate || 50;
            const variation = Math.floor(Math.random() * 15) - 7;
            const psRate = Math.max(20, baseRate + variation);
            
            await ProviderService.create({
              provider: provider._id,
              service: service._id,
              hourlyRate: psRate,
              experienceYears: provider.experienceYears || 1,
              emergencyEnabled: true,
              status: 'active',
              publishable: true
            });
            
            createdPS++;
            console.log(`   🔗 Created ProviderService for ${service.title}: ₪${psRate}/hour`);
          }
        }

        // Step 2.6: Final verification
        const finalPS = await ProviderService.find({ provider: provider._id }).populate('service');
        const expectedCount = provider.services.length;
        const actualCount = finalPS.length;

        if (actualCount === expectedCount) {
          console.log(`   ✅ SUCCESS: ${expectedCount} services correctly configured`);
          successCount++;
        } else {
          console.log(`   ⚠️  MISMATCH: Expected ${expectedCount}, got ${actualCount}`);
          errorCount++;
        }

      } catch (providerError) {
        console.error(`   ❌ ERROR for ${provider.email}:`, providerError.message);
        errorCount++;
      }
    }

    console.log(`\n📊 Migration Summary:`);
    console.log(`   ✅ Successfully migrated: ${successCount} providers`);
    console.log(`   ❌ Errors encountered: ${errorCount} providers`);
    console.log(`   📈 Total processed: ${allProviders.length} providers`);

    if (successCount === allProviders.length) {
      console.log(`\n🎉 PERFECT! All providers successfully migrated!`);
    } else {
      console.log(`\n⚠️  Some providers need attention. Check errors above.`);
    }

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
  } finally {
    await mongoose.connection.close();
    console.log('\n🔚 Connection to MongoDB Atlas closed');
  }
}

// Helper functions
function prettyServiceName(serviceKey) {
  const names = {
    'emotionalSupport': 'Emotional Support',
    'preOccupancyRepairs': 'Pre Occupancy Repairs', 
    'prescriptionPickup': 'Prescription Pickup',
    'childrenOrganizing': 'Children Organizing',
    'bedroomCleaning': 'Bedroom Cleaning',
    'kitchenCleaning': 'Kitchen Cleaning',
    'bathroomCleaning': 'Bathroom Cleaning',
    'livingRoomCleaning': 'Living Room Cleaning',
    'windowCleaning': 'Window Cleaning',
    'deepCleaning': 'Deep Cleaning',
    'laundryService': 'Laundry Service',
    'ironingService': 'Ironing Service',
    'groceryShopping': 'Grocery Shopping',
    'mealPreparation': 'Meal Preparation',
    'medicationReminders': 'Medication Reminders',
    'companionship': 'Companionship',
    'transportationAssistance': 'Transportation Assistance',
    'doctorAppointments': 'Doctor Appointments',
    'petCare': 'Pet Care',
    'gardenMaintenance': 'Garden Maintenance'
  };
  return names[serviceKey] || serviceKey.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase());
}

function categoryOf(serviceKey) {
  const categories = {
    'emotionalSupport': 'Personal Care',
    'preOccupancyRepairs': 'Home Maintenance',
    'prescriptionPickup': 'Health Support',
    'childrenOrganizing': 'Household Management',
    'bedroomCleaning': 'Cleaning Services',
    'kitchenCleaning': 'Cleaning Services',
    'bathroomCleaning': 'Cleaning Services',
    'livingRoomCleaning': 'Cleaning Services',
    'windowCleaning': 'Cleaning Services',
    'deepCleaning': 'Cleaning Services',
    'laundryService': 'Household Management',
    'ironingService': 'Household Management',
    'groceryShopping': 'Errands & Shopping',
    'mealPreparation': 'Cooking & Nutrition',
    'medicationReminders': 'Health Support',
    'companionship': 'Personal Care',
    'transportationAssistance': 'Transportation',
    'doctorAppointments': 'Health Support',
    'petCare': 'Pet Services',
    'gardenMaintenance': 'Home Maintenance'
  };
  return categories[serviceKey] || 'General Services';
}

migrateAllProviders();
