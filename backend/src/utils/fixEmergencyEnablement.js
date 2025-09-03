/*
  fixEmergencyEnablement.js
  - Scans Service documents and enables emergency only for services matching
    a whitelist of emergency-related keywords (medical, child, nursing, etc.)
  - Mirrors provider Availability.weekly -> Availability.emergencyWeekly so
    emergency slots match normal slots (as requested)
  - Sets emergencyRateMultiplier and emergencySurcharge defaults when enabling

  Usage: node src/utils/fixEmergencyEnablement.js [providerId]
    If providerId is provided, only operate on that provider. Otherwise scans all services.
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
  await mongoose.connect(MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });
  const providerId = process.argv[2];
  const q = providerId ? { provider: providerId } : {};

  const services = await Service.find(q).lean();
  const toEnable = [];
  for (const s of services) {
    const already = s.emergencyEnabled;
    const should = matchesWhitelist(s) || (Array.isArray(s.emergencyTypes) && s.emergencyTypes.length > 0);
    if (should && !already) toEnable.push(s._id);
  }

  if (!toEnable.length) {
    console.log('No services to enable for emergency (matched whitelist).');
  } else {
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

  // For providers that have at least one emergency-enabled service, mirror weekly availability
  const providers = await Service.aggregate([
    { $match: { emergencyEnabled: true } },
    { $group: { _id: '$provider', count: { $sum: 1 } } }
  ]);
  const providerIds = providers.map(p => p._id).filter(Boolean);
  if (providerIds.length === 0) {
    console.log('No providers with emergency-enabled services found.');
    await mongoose.disconnect();
    return;
  }

  console.log('Mirroring weekly availability for providers:', providerIds.slice(0, 10));
  for (const pid of providerIds) {
    try {
      const avail = await Availability.findOne({ provider: pid });
      if (!avail) continue;
      if (!avail.emergencyWeekly || Object.keys(avail.emergencyWeekly).length === 0) {
        avail.emergencyWeekly = avail.weekly || {};
      }
      if (!Array.isArray(avail.emergencyExceptions)) avail.emergencyExceptions = [];
      await avail.save();
    } catch (e) {
      console.warn('Failed updating availability for provider', pid, e.message || e);
    }
  }

  // If a specific providerId was passed and it had services enabled, print provider details
  if (providerId) {
    const prov = await Provider.findById(providerId).select('firstName lastName email');
    console.log('Target provider:', prov ? `${prov.firstName} ${prov.lastName} <${prov.email}>` : providerId);
  }

  console.log('Done.');
  await mongoose.disconnect();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
