const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });
const mongoose = require('mongoose');
const Service = require('../models/Service');

const keys = [
  // Home & Appliance
  'applianceMaintenance',
  'applianceInstallation',
  'satelliteInstallation',
  'install_electrical_appliances',
  'water_heater_maintenance',
  'washing_machine_maintenance',
  // Misc & Errands
  'documentDelivery',
  'shoppingDelivery',
  'specialErrands',
  'billPayment',
  'prescriptionPickup',
  // Care Services
  'homeBabysitting',
  'homeElderlyCare',
  'medicalTransport',
  'healthMonitoring',
  'medicationAssistance',
  // mobility variants (already handled but kept idempotent)
  'mobilityAssistance',
  'mobility_assistance',
  'mobility-assistance'
];

async function main() {
  if (!process.env.MONGODB_URI) {
    console.error('MONGODB_URI not found in environment. Aborting.');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });
  console.log('Connected to MongoDB');

  const query = {
    $or: [
      { subcategory: { $in: keys } },
      { slug: { $in: keys } },
      { code: { $in: keys } }
    ]
  };

  const services = await Service.find(query).lean();
  console.log(`Found ${services.length} matching services`);

  const results = [];
  for (const s of services) {
    const before = {
      id: s._id.toString(),
      title: s.title,
      subcategory: s.subcategory,
      slug: s.slug || s.code,
      emergencyEnabled: !!s.emergencyEnabled,
      emergencyRateMultiplier: s.emergencyRateMultiplier,
      emergencySurcharge: s.emergencySurcharge,
      emergencyTypes: s.emergencyTypes
    };

    const updated = {
      emergencyEnabled: true,
      emergencyRateMultiplier: 1.6,
      emergencySurcharge: 0,
      emergencyLeadTimeMinutes: 60,
    };

    await Service.updateOne({ _id: s._id }, { $set: updated });

    results.push({ before, after: { ...before, ...updated } });
    console.log(`Updated service ${before.id} - ${before.title}`);
  }

  console.log('Update complete. Summary:');
  console.log(JSON.stringify(results, null, 2));

  await mongoose.disconnect();
  process.exit(0);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
