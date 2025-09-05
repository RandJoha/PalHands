/*
  Migration: Seed ProviderService documents based on Provider.services array.
  Run once: node scripts/migrateProviderServices.js
*/
require('dotenv').config();
const mongoose = require('mongoose');
const Provider = require('../src/models/Provider');
const ProviderService = require('../src/models/ProviderService');

async function main() {
  const uri = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/palhands';
  await mongoose.connect(uri);
  console.log('Connected to MongoDB');

  const providers = await Provider.find({ isActive: true }).select('_id services');
  let created = 0;
  for (const p of providers) {
    if (!Array.isArray(p.services)) continue;
    for (const key of p.services) {
      try {
        await ProviderService.updateOne(
          { provider: p._id, serviceKey: key },
          { $setOnInsert: { provider: p._id, serviceKey: key, hourlyRate: 0, experienceYears: 0, status: 'inactive', isPublished: false } },
          { upsert: true }
        );
        created++;
      } catch (e) {
        if (e.code !== 11000) console.error('Upsert error', e);
      }
    }
  }
  console.log(`Seeded/ensured ProviderService entries: ${created}`);
  await mongoose.disconnect();
}

main().catch(e => { console.error(e); process.exit(1); });
