require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Service = require('../models/Service');
const { providers } = require('./data/providers.dataset');
const { getCategoryForSubcategory } = require('./data/serviceTaxonomy');

const PASSWORD = process.env.PROVIDER_DEFAULT_PASSWORD || 'Provider123!';

async function upsertProvider(entry) {
  // Upsert provider by email
  let p = await Provider.findOne({ email: entry.email });
  if (!p) {
    p = new Provider({
      firstName: entry.firstName,
      lastName: entry.lastName || '',
      email: entry.email,
      phone: entry.phone,
      password: PASSWORD,
      role: 'provider',
      isVerified: true,
      isActive: true,
      age: entry.age,
      experienceYears: entry.experienceYears,
      languages: entry.languages,
      hourlyRate: entry.hourlyRate,
      services: entry.services,
      addresses: [{
        type: 'home',
        street: `${entry.area || 'Main Street'} 1`,
        city: entry.city || '',
        area: entry.area || '',
        coordinates: { latitude: null, longitude: null },
        isDefault: true,
      }],
    });
  } else {
    // Update core fields; reset password to known value for dev restore
    p.firstName = entry.firstName;
    p.lastName = entry.lastName || '';
    p.phone = entry.phone;
    p.password = PASSWORD; // hashed by pre-save
    p.isVerified = true;
    p.isActive = true;
    p.age = entry.age;
    p.experienceYears = entry.experienceYears;
    p.languages = entry.languages;
    p.hourlyRate = entry.hourlyRate;
    p.services = entry.services;
    p.addresses = [{
      type: 'home',
      street: `${entry.area || 'Main Street'} 1`,
      city: entry.city || '',
      area: entry.area || '',
      coordinates: { latitude: null, longitude: null },
      isDefault: true,
    }];
  }
  await p.save();
  return p;
}

async function ensureServicesForProvider(providerDoc) {
  // For each subcategory assigned to provider, ensure at least one active Service snapshot
  const promises = providerDoc.services.map(async (subKey) => {
    const category = getCategoryForSubcategory(subKey) || 'miscellaneous';
    const title = `${subKey.charAt(0).toUpperCase() + subKey.slice(1)} Service`;
    const existing = await Service.findOne({ provider: providerDoc._id, category, subcategory: subKey });
    if (!existing) {
      return Service.create({
        title,
        description: `Professional ${subKey} service provided by ${providerDoc.firstName}.`,
        category,
        subcategory: subKey,
        provider: providerDoc._id,
        price: { amount: providerDoc.hourlyRate, type: 'hourly', currency: 'ILS' },
        duration: { estimated: 120, flexible: true },
        availability: {
          days: ['monday','tuesday','wednesday','thursday','friday'],
          timeSlots: [{ start: '09:00', end: '17:00' }],
          flexible: true,
        },
        location: { serviceArea: providerDoc.addresses?.[0]?.city || 'Ramallah', radius: 20, onSite: true, remote: false },
        images: [],
        requirements: [],
        equipment: [],
      });
    }
    return existing;
  });
  await Promise.all(promises);
}

async function pruneUnknownProviders() {
  if (!['1','true','yes'].includes(String(process.env.PRUNE_UNKNOWN_PROVIDERS || '').toLowerCase())) return;
  const knownEmails = new Set(providers.map(p => p.email));
  const toDelete = await Provider.find({ email: { $nin: Array.from(knownEmails) } });
  if (toDelete.length) {
    const ids = toDelete.map(p => p._id);
    await Service.deleteMany({ provider: { $in: ids } });
    await Provider.deleteMany({ _id: { $in: ids } });
    console.log(`Pruned ${toDelete.length} unknown providers (and their services).`);
  }
}

async function main() {
  await connectDB();

  console.log('Restoring providers from canonical dataset...');
  for (const entry of providers) {
    const p = await upsertProvider(entry);
    await ensureServicesForProvider(p);
  }

  await pruneUnknownProviders();

  console.log('Done. Provider default password (dev):', PASSWORD);
  await mongoose.connection.close();
}

main().catch(err => { console.error(err); process.exit(1); });
