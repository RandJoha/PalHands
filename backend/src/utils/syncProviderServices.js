require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Service = require('../models/Service');

// Canonical categories/services (mirrors restoreFrontendData.js)
const CATEGORIES = [
  { id: 'cleaning',     services: ['bedroomCleaning','livingRoomCleaning','kitchenCleaning','bathroomCleaning','windowCleaning','doorCabinetCleaning','floorCleaning','carpetCleaning','furnitureCleaning','gardenCleaning','entranceCleaning','stairCleaning','garageCleaning','postEventCleaning','postConstructionCleaning','apartmentCleaning','regularCleaning'] },
  { id: 'organizing',   services: ['bedroomOrganizing','kitchenOrganizing','closetOrganizing','storageOrganizing','livingRoomOrganizing','postPartyOrganizing','fullHouseOrganizing','childrenOrganizing'] },
  { id: 'cooking',      services: ['mainDishes','desserts','specialRequests'] },
  { id: 'childcare',    services: ['homeBabysitting','schoolAccompaniment','homeworkHelp','educationalActivities','childrenMealPrep','sickChildCare'] },
  { id: 'elderly',      services: ['homeElderlyCare','medicalTransport','healthMonitoring','medicationAssistance','emotionalSupport','mobilityAssistance'] },
  { id: 'maintenance',  services: ['electricalWork','plumbingWork','aluminumWork','carpentryWork','painting','hangingItems','satelliteInstallation','applianceMaintenance'] },
  { id: 'newhome',      services: ['furnitureMoving','packingUnpacking','furnitureWrapping','newHomeArrangement','newApartmentCleaning','preOccupancyRepairs','kitchenSetup','applianceInstallation'] },
  { id: 'miscellaneous',services: ['documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup'] },
];

function categoryOf(serviceKey){
  const c = CATEGORIES.find(cat => cat.services.includes(serviceKey));
  return c ? c.id : 'miscellaneous';
}

function prettyServiceName(key) {
  return String(key)
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, c => c.toUpperCase())
    .trim();
}

async function syncAllProviders() {
  await connectDB();
  const providers = await Provider.find({ isActive: true }).lean();
  let created = 0, updated = 0;
  for (const p of providers) {
    const city = (p.addresses && p.addresses[0] && p.addresses[0].city) || 'Ramallah';
    const services = Array.isArray(p.services) ? p.services : [];
    for (const sKey of services) {
      const filter = { provider: p._id, subcategory: sKey };
      const exists = await Service.findOne(filter).select('_id');
      const base = {
        title: prettyServiceName(sKey),
        description: `Professional ${prettyServiceName(sKey)} service`,
        provider: p._id,
        category: categoryOf(sKey),
        subcategory: sKey,
        price: { amount: p.hourlyRate || 50, type: 'hourly', currency: 'ILS' },
        duration: { estimated: 120, flexible: true },
        availability: { days: ['monday','tuesday','wednesday','thursday','friday'], timeSlots: [{ start: '09:00', end: '17:00' }], flexible: true },
        location: { serviceArea: city ? (city[0].toUpperCase()+city.slice(1)) : 'Ramallah', radius: 20, onSite: true, remote: false },
        isActive: true,
        featured: false,
      };
      if (!exists) {
        await Service.create(base);
        created++;
      } else {
        await Service.updateOne({ _id: exists._id }, { $set: base });
        updated++;
      }
    }
  }
  console.log(`Sync complete: created ${created}, updated ${updated}`);
  await mongoose.connection.close();
}

syncAllProviders().catch(err => { console.error('❌ Sync failed:', err); process.exit(1); });
