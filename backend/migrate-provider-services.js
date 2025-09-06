require('dotenv').config();
const { connectDB, mongoose } = require('./src/config/database');
const Provider = require('./src/models/Provider');
const Service = require('./src/models/Service');
const ProviderService = require('./src/models/ProviderService');

// Canonical categories/services mapping
const CATEGORIES = [
  { id: 'cleaning', services: ['bedroomCleaning','livingRoomCleaning','kitchenCleaning','bathroomCleaning','windowCleaning','doorCabinetCleaning','floorCleaning','carpetCleaning','furnitureCleaning','gardenCleaning','entranceCleaning','stairCleaning','garageCleaning','postEventCleaning','postConstructionCleaning','apartmentCleaning','regularCleaning'] },
  { id: 'organizing', services: ['bedroomOrganizing','kitchenOrganizing','closetOrganizing','storageOrganizing','livingRoomOrganizing','postPartyOrganizing','fullHouseOrganizing','childrenOrganizing'] },
  { id: 'cooking', services: ['mainDishes','desserts','specialRequests'] },
  { id: 'childcare', services: ['homeBabysitting','schoolAccompaniment','homeworkHelp','educationalActivities','childrenMealPrep','sickChildCare'] },
  { id: 'elderly', services: ['homeElderlyCare','medicalTransport','healthMonitoring','medicationAssistance','emotionalSupport','mobilityAssistance'] },
  { id: 'maintenance', services: ['electricalWork','plumbingWork','aluminumWork','carpentryWork','painting','hangingItems','satelliteInstallation','applianceMaintenance'] },
  { id: 'newhome', services: ['furnitureMoving','packingUnpacking','furnitureWrapping','newHomeArrangement','newApartmentCleaning','preOccupancyRepairs','kitchenSetup','applianceInstallation'] },
  { id: 'miscellaneous', services: ['documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup'] },
];

function categoryOf(serviceKey) {
  const c = CATEGORIES.find(cat => cat.services.includes(serviceKey));
  return c ? c.id : 'miscellaneous';
}

function prettyServiceName(key) {
  return String(key).replace(/([A-Z])/g, ' $1').replace(/^./, c => c.toUpperCase()).trim();
}

async function migrateProviderServices() {
  console.log('🚀 Starting provider services migration...');
  
  await connectDB();
  
  const providers = await Provider.find({ isActive: true }).lean();
  console.log(`📊 Found ${providers.length} active providers`);
  
  let processedProviders = 0;
  let createdServices = 0;
  let createdProviderServices = 0;
  
  for (const provider of providers) {
    const providerId = provider._id;
    const serviceKeys = Array.isArray(provider.services) ? provider.services : [];
    
    if (serviceKeys.length === 0) {
      console.log(`⏭️  Skipping provider ${provider.email} - no services`);
      continue;
    }
    
    console.log(`🔄 Processing provider ${provider.email} with ${serviceKeys.length} services: ${serviceKeys.join(', ')}`);
    
    // Step 1: Ensure Service documents exist
    const city = (provider.addresses && provider.addresses[0] && provider.addresses[0].city) || 'Ramallah';
    const serviceOps = [];
    
    for (const sKey of serviceKeys) {
      const existing = await Service.findOne({ provider: providerId, subcategory: sKey });
      if (!existing) {
        serviceOps.push({
          title: prettyServiceName(sKey),
          description: `Professional ${prettyServiceName(sKey)} service`,
          provider: providerId,
          category: categoryOf(sKey),
          subcategory: sKey,
          price: { amount: provider.hourlyRate || 50, type: 'hourly', currency: 'ILS' },
          duration: { estimated: 120, flexible: true },
          availability: { 
            days: ['monday','tuesday','wednesday','thursday','friday'], 
            timeSlots: [{ start: '09:00', end: '17:00' }], 
            flexible: true 
          },
          location: { 
            serviceArea: city ? (city[0].toUpperCase() + city.slice(1)) : 'Ramallah', 
            radius: 20, 
            onSite: true, 
            remote: false 
          },
          isActive: true,
          featured: false,
          emergencyEnabled: false, // Will be set per-service in ProviderService
          updatedAt: new Date(),
        });
      }
    }
    
    if (serviceOps.length > 0) {
      try {
        await Service.insertMany(serviceOps, { ordered: false });
        createdServices += serviceOps.length;
        console.log(`  ✅ Created ${serviceOps.length} Service documents`);
      } catch (e) {
        console.log(`  ⚠️  Some Service documents may already exist (${e.message})`);
      }
    }
    
    // Step 2: Get all services for this provider
    const ownedServices = await Service.find({ provider: providerId }).select('_id price emergencyEnabled isActive');
    
    // Step 3: Ensure ProviderService documents exist
    const existing = await ProviderService.find({ provider: providerId }).select('service');
    const existingSet = new Set(existing.map(e => String(e.service)));
    const psOps = [];
    
    for (const service of ownedServices) {
      const sid = String(service._id);
      if (!existingSet.has(sid)) {
        // Add some randomization for variety while keeping reasonable defaults
        const baseRate = provider.hourlyRate || 50;
        const rateVariation = Math.random() * 20 - 10; // ±10
        const hourlyRate = Math.max(25, Math.round(baseRate + rateVariation));
        
        const baseExp = provider.experienceYears || 0;
        const expVariation = Math.random() * 2 - 1; // ±1 year
        const experienceYears = Math.max(0, Math.round(baseExp + expVariation));
        
        psOps.push({
          provider: providerId,
          service: service._id,
          hourlyRate,
          experienceYears,
          emergencyEnabled: !!service.emergencyEnabled,
          status: service.isActive ? 'active' : 'inactive' // Make active if publishable
        });
      }
    }
    
    if (psOps.length > 0) {
      try {
        await ProviderService.insertMany(psOps, { ordered: false });
        createdProviderServices += psOps.length;
        console.log(`  ✅ Created ${psOps.length} ProviderService documents`);
      } catch (e) {
        console.log(`  ⚠️  Some ProviderService documents may already exist (${e.message})`);
      }
    }
    
    processedProviders++;
  }
  
  console.log('\n🎉 Migration completed!');
  console.log(`📊 Summary:`);
  console.log(`  - Processed providers: ${processedProviders}`);
  console.log(`  - Created Service documents: ${createdServices}`);
  console.log(`  - Created ProviderService documents: ${createdProviderServices}`);
  
  await mongoose.connection.close();
}

migrateProviderServices().catch(err => {
  console.error('❌ Migration failed:', err);
  process.exit(1);
});
