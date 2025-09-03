/*
  ensureProviderEmergencyStrict.js
  - Target a single provider by id and enforce emergency enablement rules:
    * For each service of the provider: if it matches the medical/urgent whitelist OR has non-empty emergencyTypes, set emergencyEnabled=true
    * Otherwise set emergencyEnabled=false
  - Set emergencyRateMultiplier and emergencySurcharge defaults when enabling
  - Mirror Availability.weekly -> Availability.emergencyWeekly for the provider

  Usage: node src/utils/ensureProviderEmergencyStrict.js <providerId>

  NOTE: Run this on the machine where your MongoDB is reachable (set MONGO_URL env var if needed).
*/

const mongoose = require('mongoose');
const Service = require('../models/Service');
const Availability = require('../models/Availability');
const Provider = require('../models/Provider');

const MONGO_URL = process.env.MONGO_URL || process.env.MONGODB_URI || 'mongodb://localhost:27017/palhands';

const WHITELIST = [
  'medical', 'medicine', 'medic', 'pharmacy', 'ambulance', 'transport',
  'sick', 'health', 'nurse', 'nursing', 'doctor', 'child', 'childcare',
  'baby', 'infant', 'emergency', 'urgent', 'injury', 'first aid', 'care'
];

function matchesWhitelist(svc) {
  const fields = [svc.title || '', svc.subcategory || '', svc.category || ''];
  const text = fields.join(' ').toLowerCase();
  return WHITELIST.some(w => text.includes(w));
}

async function main() {
  const providerId = process.argv[2];
  if (!providerId) {
    console.error('Usage: node src/utils/ensureProviderEmergencyStrict.js <providerId>');
    process.exit(2);
  }
  await mongoose.connect(MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });

  const prov = await Provider.findById(providerId).select('firstName lastName email');
  console.log('Target provider:', prov ? `${prov.firstName} ${prov.lastName} <${prov.email}>` : providerId);

  const services = await Service.find({ provider: providerId });
  if (!services.length) {
    console.log('No services found for provider.');
    await mongoose.disconnect();
    return;
  }

  const toEnable = [];
  const toDisable = [];
  for (const s of services) {
    const shouldEnable = matchesWhitelist(s) || (Array.isArray(s.emergencyTypes) && s.emergencyTypes.length > 0);
    if (shouldEnable) toEnable.push(s._id);
    else toDisable.push(s._id);
  }

  if (toEnable.length) {
    console.log('Enabling emergency for services:', toEnable);
    await Service.updateMany({ _id: { $in: toEnable } }, {
      $set: {
        emergencyEnabled: true,
        emergencyRateMultiplier: 1.5,
        'emergencySurcharge.type': 'percent',
        'emergencySurcharge.amount': 25
      }
    });
  }
  if (toDisable.length) {
    console.log('Disabling emergency for services:', toDisable);
    await Service.updateMany({ _id: { $in: toDisable } }, { $set: { emergencyEnabled: false } });
  }

  // Mirror availability weekly -> emergencyWeekly for this provider if emergencyWeekly empty
  try {
    const avail = await Availability.findOne({ provider: providerId });
    if (avail) {
      if (!avail.emergencyWeekly || Object.keys(avail.emergencyWeekly || {}).length === 0) {
        avail.emergencyWeekly = avail.weekly || {};
      }
      if (!Array.isArray(avail.emergencyExceptions)) avail.emergencyExceptions = [];
      await avail.save();
      console.log('Availability mirrored for provider');
    } else {
      console.log('No availability document found for provider');
    }
  } catch (e) {
    console.warn('Availability mirror failed:', e.message || e);
  }

  console.log('Done.');
  await mongoose.disconnect();
}

main().catch(err => { console.error(err); process.exit(1); });
