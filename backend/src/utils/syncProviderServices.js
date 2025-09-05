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

async function syncProviders() {
  // Optional args:
  //   node src/utils/syncProviderServices.js <serviceKey> --ensure-one --enable-emergency
  const argv = process.argv.slice(2);
  const KEY = argv.find(a => !a.startsWith('--')) || null;
  const flags = new Set(argv.filter(a => a.startsWith('--')));
  const ENSURE_ONE = flags.has('--ensure-one') && !!KEY;
  const ENABLE_EMERGENCY = flags.has('--enable-emergency');

  await connectDB();

  // If requested, ensure at least one active provider advertises the KEY
  if (ENSURE_ONE && KEY) {
    const one = await Provider.findOne({ isActive: true, services: { $ne: KEY } });
    if (one) {
      const next = Array.isArray(one.services) ? [...one.services] : [];
      next.push(KEY);
      await Provider.updateOne({ _id: one._id }, { $set: { services: next } });
      console.log(`✅ Added ${KEY} to provider ${one.email || one._id}`);
    } else {
      console.log(`ℹ️ No eligible provider found to add ${KEY} (either none active or all already have it).`);
    }
  }

  // Whitelist of keys that should be emergency-enabled by default when syncing
  const EMERGENCY_KEYS = new Set([
    'applianceMaintenance','applianceInstallation','satelliteInstallation','install_electrical_appliances',
    'water_heater_maintenance','washing_machine_maintenance',
    'documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup',
    'homeBabysitting','homeElderlyCare','medicalTransport','healthMonitoring','medicationAssistance',
    'mobilityAssistance','mobility_assistance','mobility-assistance'
  ]);

  const providers = await Provider.find({ isActive: true }).lean();
  let created = 0, updated = 0;
  for (const p of providers) {
    const city = (p.addresses && p.addresses[0] && p.addresses[0].city) || 'Ramallah';
    let services = Array.isArray(p.services) ? p.services : [];
    if (KEY) services = services.filter(s => s === KEY);
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
        updatedAt: new Date(),
      };

      // Optional emergency enablement for eligible keys (requested behavior)
      if (ENABLE_EMERGENCY && EMERGENCY_KEYS.has(sKey)) {
        base.emergencyEnabled = true;
        base.emergencyRateMultiplier = 1.6;
        base.emergencyLeadTimeMinutes = 60;
        base.emergencySurcharge = { type: 'percent', amount: 0 };
      }

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

syncProviders().catch(err => { console.error('❌ Sync failed:', err); process.exit(1); });
