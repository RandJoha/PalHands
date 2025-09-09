#!/usr/bin/env node
/*
Diagnostic script (provider collection focus) for Special Errands service.
Looks directly at User (role=provider) documents whose legacy 'services' array
contains the slug (e.g. 'specialErrands'), then enriches with any matching
ProviderService and Service docs to compare data consistency.

Run:
  node scripts/diagnose_special_errands_from_providers.js
Options:
  --slug=specialErrands      (default)
  --title="Special Errands"  (fallback match in Service.title)
*/
require('dotenv').config({ path: '.env' });
const mongoose = require('mongoose');
const User = require('../src/models/User');
const ProviderService = require('../src/models/ProviderService');
const Service = require('../src/models/Service');

async function main() {
  const mongo = process.env.MONGODB_URI || process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/palhands';
  await mongoose.connect(mongo, { maxPoolSize: 5 });

  let slug = 'specialErrands';
  let title = 'Special Errands';
  for (const a of process.argv.slice(2)) {
    if (a.startsWith('--slug=')) slug = a.split('=')[1];
    if (a.startsWith('--title=')) title = a.split('=')[1];
  }

  console.log('🔍 Provider-based diagnostic for Special Errands');
  console.log({ slug, title });

  // 1. Providers whose services array contains slug
  const providers = await User.find({ role: 'provider', services: slug }).lean();
  console.log(`👤 Providers (User collection) referencing slug '${slug}': ${providers.length}`);

  if (!providers.length) {
    console.log('❌ No providers list the slug in their legacy services array.');
  }

  // 2. Fetch any Service docs matching slug or title
  const serviceDocs = await Service.find({ $or: [ { subcategory: slug }, { title: new RegExp('^' + escapeRegex(title) + '$','i') } ] }).lean();
  console.log(`🧾 Service docs matching slug/title: ${serviceDocs.length}`);
  const serviceIds = serviceDocs.map(s => s._id.toString());

  // 3. ProviderService docs for those providers + services
  let psDocs = [];
  if (providers.length && serviceIds.length) {
    psDocs = await ProviderService.find({ provider: { $in: providers.map(p => p._id) }, service: { $in: serviceIds }, status: { $ne: 'deleted' } })
      .populate('service')
      .lean();
  }
  console.log(`🔗 ProviderService docs linking providers to serviceIds: ${psDocs.length}`);

  // Index for quick lookups
  const psByProvider = new Map();
  for (const ps of psDocs) {
    const arr = psByProvider.get(ps.provider.toString()) || [];
    arr.push(ps);
    psByProvider.set(ps.provider.toString(), arr);
  }

  const serviceById = Object.fromEntries(serviceDocs.map(s => [s._id.toString(), s]));

  // 4. Build rows
  const rows = providers.map(p => {
    const psList = psByProvider.get(p._id.toString()) || [];
    // Choose first matching ProviderService (if multiple, list count)
    const primaryPs = psList[0];
    const svc = primaryPs ? primaryPs.service : null;
    return {
      providerId: p._id.toString(),
      providerName: deriveProviderName(p),
      city: (p.addresses && p.addresses[0] && p.addresses[0].city) || '',
      legacyServicesCount: (p.services || []).length,
      legacyHasSlug: (p.services || []).includes(slug),
      providerHourlyRate: p.hourlyRate,
      providerExperienceYears: p.experienceYears,
      psCount: psList.length,
      psHourlyRate: primaryPs ? primaryPs.hourlyRate : null,
      psExperienceYears: primaryPs ? primaryPs.experienceYears : null,
      psEmergencyEnabled: primaryPs ? primaryPs.emergencyEnabled : null,
      psStatus: primaryPs ? primaryPs.status : null,
      psPublishable: primaryPs ? primaryPs.publishable : null,
      serviceId: svc ? svc._id.toString() : (serviceIds[0] || null),
      serviceTitle: svc ? svc.title : (serviceDocs[0]?.title || null),
      serviceSubcategory: svc ? svc.subcategory : (serviceDocs[0]?.subcategory || null),
    };
  });

  if (rows.length) console.table(rows);

  console.log('\nJSON_RESULT_START');
  console.log(JSON.stringify({ diagnostic: 'specialErrands_provider_collection', slug, title, count: rows.length, rows }, null, 2));
  console.log('JSON_RESULT_END');

  await mongoose.disconnect();
}

function deriveProviderName(p) {
  if (!p) return null;
  if (p.name) return p.name; // some code paths may use name
  if (p.firstName || p.lastName) return [p.firstName, p.lastName].filter(Boolean).join(' ').trim();
  return p._id?.toString();
}

function escapeRegex(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

main().catch(e => { console.error('Fatal provider diagnostic error', e); process.exit(1); });
