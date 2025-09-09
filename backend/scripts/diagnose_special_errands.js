#!/usr/bin/env node
/*
Diagnostic script to verify which providers offer the "Special Errands" service
using two data sources:
  1. ProviderService collection (authoritative link provider<->service)
  2. Service collection (reverse lookup to its provider field if present)

Outputs unified list with: providerId, provider name, serviceId, serviceTitle, hourlyRate, experienceYears, emergencyEnabled, publishable/status flags.

Run with:
  node scripts/diagnose_special_errands.js
Optionally specify --slug=specialErrands or --title="Special Errands" or a --serviceId=<ObjectId>
*/

require('dotenv').config({ path: '.env' });
const mongoose = require('mongoose');
const ProviderService = require('../src/models/ProviderService');
const Service = require('../src/models/Service');
const User = require('../src/models/User');

async function main() {
  const mongo = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/palhands';
  await mongoose.connect(mongo, { maxPoolSize: 5 });

  const args = process.argv.slice(2);
  let titleFilter = 'Special Errands';
  let slugFilter = 'specialErrands';
  let explicitServiceId = null;
  let mode = 'auto'; // auto | providerService | service
  for (const a of args) {
    if (a.startsWith('--title=')) titleFilter = a.split('=')[1];
    if (a.startsWith('--slug=')) slugFilter = a.split('=')[1];
    if (a.startsWith('--serviceId=')) explicitServiceId = a.split('=')[1];
    if (a.startsWith('--mode=')) mode = a.split('=')[1];
  }

  console.log('🔍 Diagnostic: Special Errands');
  console.log({ titleFilter, slugFilter, explicitServiceId, mode });

  // 1. Find candidate Service documents
  const serviceQuery = explicitServiceId ? { _id: explicitServiceId } : {
    $or: [
      { title: new RegExp('^' + escapeRegex(titleFilter) + '$', 'i') },
      { subcategory: new RegExp('^' + escapeRegex(slugFilter) + '$', 'i') },
    ]
  };
  const services = await Service.find(serviceQuery).lean();
  console.log(`🧾 Found ${services.length} Service docs matching criteria.`);

  const serviceIds = services.map(s => s._id.toString());

  // 2. ProviderService lookup for those services
  let psDocs = [];
  if (mode !== 'service') {
    psDocs = await ProviderService.find({ service: { $in: serviceIds }, status: { $ne: 'deleted' } })
      .populate('service')
      .populate('provider', 'name firstName lastName city role isProvider')
      .lean();
    console.log(`🔗 ProviderService links found: ${psDocs.length}`);
  } else {
    console.log('🔗 Skipping ProviderService lookup (mode=service)');
  }

  // 3. Build unified rows
  const rows = psDocs.map(ps => ({
    providerId: ps.provider?._id?.toString(),
    providerName: deriveProviderName(ps.provider),
    city: ps.provider?.city,
    serviceId: ps.service?._id?.toString(),
    serviceTitle: ps.service?.title,
    serviceSubcategory: ps.service?.subcategory,
    hourlyRate: ps.hourlyRate,
    experienceYears: ps.experienceYears,
    emergencyEnabled: ps.emergencyEnabled,
    status: ps.status,
    publishable: ps.publishable,
  }));

  // 4. If no links found, attempt reverse from Service.provider field
  let reverse = [];
  if ((rows.length === 0 || mode === 'service') && services.length) {
    const withProvider = services.filter(s => s.provider);
    if (withProvider.length) {
      const providerIds = withProvider.map(s => s.provider);
      const providers = await User.find({ _id: { $in: providerIds } }).lean();
      const providerMap = Object.fromEntries(providers.map(p => [p._id.toString(), p]));
      reverse = withProvider.map(s => ({
        providerId: s.provider.toString(),
        providerName: deriveProviderName(providerMap[s.provider.toString()]),
        city: providerMap[s.provider.toString()]?.city,
        serviceId: s._id.toString(),
        serviceTitle: s.title,
        serviceSubcategory: s.subcategory,
        hourlyRate: s.price?.amount,
        experienceYears: undefined,
        emergencyEnabled: s.emergencyEnabled,
        status: s.isActive ? 'active' : 'inactive',
        publishable: s.isActive,
      }));
      console.log(`↩️ Reverse links from Service.provider: ${reverse.length}`);
    }
  }

  const all = rows.length ? rows : reverse;
  if (!all.length) {
    console.log('❌ No providers found offering Special Errands by either method.');
  } else {
    console.table(all);
  }

  // Distinct providers count
  const distinctProviders = new Set(all.map(r => r.providerId)).size;
  console.log(`👥 Distinct providers: ${distinctProviders}`);

  // Aggregate minimal JSON output for frontend sanity check
  console.log('\nJSON_RESULT_START');
  console.log(JSON.stringify({
    diagnostic: 'specialErrands',
    source: rows.length ? 'ProviderService' : 'Service.provider',
    count: all.length,
    distinctProviders,
    rows: all,
    serviceIds,
  }, null, 2));
  console.log('JSON_RESULT_END');

  await mongoose.disconnect();
}

function deriveProviderName(p) {
  if (!p) return null;
  if (p.name) return p.name;
  if (p.firstName || p.lastName) return [p.firstName, p.lastName].filter(Boolean).join(' ').trim();
  return p._id?.toString();
}

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

main().catch(e => {
  console.error('Fatal diagnostic error', e);
  process.exit(1);
});
