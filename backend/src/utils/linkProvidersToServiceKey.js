const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Service = require('../models/Service');

/**
 * Link all providers that already advertise a given subcategory key (string in Provider.services)
 * to a Service document for that subcategory. If a Service doesn't exist for the provider/key,
 * create it. This restores the FE expectation that each service has at least one provider.
 *
 * Usage:
 *   node src/utils/linkProvidersToServiceKey.js <serviceKey>
 * Example:
 *   node src/utils/linkProvidersToServiceKey.js billPayment
 */
async function main() {
  const key = process.argv[2];
  if (!key) {
    console.error('Usage: node src/utils/linkProvidersToServiceKey.js <serviceKey>');
    process.exit(1);
  }

  await connectDB();

  // Helper: map subcategory key to canonical category id
  const CATEGORY_MAP = {
    cleaning: ['bedroomCleaning','livingRoomCleaning','kitchenCleaning','bathroomCleaning','windowCleaning','doorCabinetCleaning','floorCleaning','carpetCleaning','furnitureCleaning','gardenCleaning','entranceCleaning','stairCleaning','garageCleaning','postEventCleaning','postConstructionCleaning','apartmentCleaning','regularCleaning'],
    organizing: ['bedroomOrganizing','kitchenOrganizing','closetOrganizing','storageOrganizing','livingRoomOrganizing','postPartyOrganizing','fullHouseOrganizing','childrenOrganizing'],
    cooking: ['mainDishes','desserts','specialRequests'],
    childcare: ['homeBabysitting','schoolAccompaniment','homeworkHelp','educationalActivities','childrenMealPrep','sickChildCare'],
    elderly: ['homeElderlyCare','medicalTransport','healthMonitoring','medicationAssistance','emotionalSupport','mobilityAssistance'],
    maintenance: ['electricalWork','plumbingWork','aluminumWork','carpentryWork','painting','hangingItems','satelliteInstallation','applianceMaintenance'],
    newhome: ['furnitureMoving','packingUnpacking','furnitureWrapping','newHomeArrangement','newApartmentCleaning','preOccupancyRepairs','kitchenSetup','applianceInstallation'],
    miscellaneous: ['documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup']
  };
  function categoryOf(sub) {
    for (const [cat, arr] of Object.entries(CATEGORY_MAP)) {
      if (arr.includes(sub)) return cat;
    }
    return 'miscellaneous';
  }
  function pretty(key) {
    return String(key).replace(/([A-Z])/g, ' $1').replace(/^./, c => c.toUpperCase()).trim();
  }

  const providers = await Provider.find({ isActive: true, services: key }).lean();
  console.log(`Found ${providers.length} providers with service key: ${key}`);

  let created = 0, updated = 0;
  for (const p of providers) {
    const exists = await Service.findOne({ provider: p._id, subcategory: key }).select('_id');
    const city = (p.addresses && p.addresses[0] && p.addresses[0].city) || 'Ramallah';
    const base = {
      title: pretty(key),
      description: `Professional ${pretty(key)} service`,
      provider: p._id,
      category: categoryOf(key),
      subcategory: key,
      price: { amount: p.hourlyRate || 50, type: 'hourly', currency: 'ILS' },
      duration: { estimated: 120, flexible: true },
      availability: { days: ['monday','tuesday','wednesday','thursday','friday'], timeSlots: [{ start: '09:00', end: '17:00' }], flexible: true },
      location: { serviceArea: city ? (city[0].toUpperCase()+city.slice(1)) : 'Ramallah', radius: 20, onSite: true, remote: false },
      isActive: true,
      featured: false,
      updatedAt: new Date()
    };
    if (!exists) {
      await Service.create(base);
      created++;
    } else {
      await Service.updateOne({ _id: exists._id }, { $set: base });
      updated++;
    }
  }

  console.log(`Done. Services created: ${created}, updated: ${updated}`);
  await mongoose.connection.close();
}

console.warn('[deprecated] linkProvidersToServiceKey.js is no longer used.');
console.warn('Use: node src/utils/syncProviderServices.js <serviceKey> --ensure-one --enable-emergency');
process.exit(0);

main().catch(err => { console.error(err); process.exit(1); });
