const mongoose = require('mongoose');
const { DateTime } = require('luxon');
const ProviderService = require('../models/ProviderService');
const Service = require('../models/Service');
const Provider = require('../models/Provider');
const { ok, created, error } = require('../utils/response');

function isOwner(req, providerId) {
  return req.user && req.user.role === 'provider' && String(req.user._id) === String(providerId);
}

function categoryOf(serviceKey){
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
  const c = CATEGORIES.find(cat => cat.services.includes(serviceKey));
  return c ? c.id : 'miscellaneous';
}

function prettyServiceName(key) {
  return String(key).replace(/([A-Z])/g, ' $1').replace(/^./, c => c.toUpperCase()).trim();
}

// List own provider-services
async function listMy(req, res) {
  try {
    const providerId = req.params.providerId;
    if (!isOwner(req, providerId) && !(req.user && req.user.role === 'admin')) {
      return error(res, 403, 'Forbidden');
    }
    // Ensure Service docs exist for legacy providers with services stored on Provider doc
    let ownedServices = await Service.find({ provider: providerId }).select('_id price amount emergencyEnabled isActive subcategory');
    if (!ownedServices || ownedServices.length === 0) {
      const prov = await Provider.findById(providerId).lean();
      const keys = Array.isArray(prov?.services) ? prov.services : [];
      if (keys.length) {
        const city = (prov?.addresses && prov.addresses[0] && prov.addresses[0].city) || 'Ramallah';
        const ops = [];
        for (const sKey of keys) {
          const base = {
            title: prettyServiceName(sKey),
            description: `Professional ${prettyServiceName(sKey)} service`,
            provider: providerId,
            category: categoryOf(sKey),
            subcategory: sKey,
            price: { amount: prov?.hourlyRate || 50, type: 'hourly', currency: 'ILS' },
            duration: { estimated: 120, flexible: true },
            // Do not inject legacy per-service availability; unified source is Availability collection
            location: { serviceArea: city ? (city[0].toUpperCase()+city.slice(1)) : 'Ramallah', radius: 20, onSite: true, remote: false },
            isActive: true,
            featured: false,
            updatedAt: new Date(),
          };
          ops.push(base);
        }
        if (ops.length) {
          try { await Service.insertMany(ops, { ordered: false }); } catch (_) {}
          ownedServices = await Service.find({ provider: providerId }).select('_id price amount emergencyEnabled isActive subcategory');
        }
      }
    }

    // Auto-sync: ensure a ProviderService exists per Service owned by this provider
    const existing = await ProviderService.find({ provider: providerId }).select('service');
    const existingSet = new Set(existing.map(e => String(e.service)));
    const toCreate = [];
    
    // Get provider data for migration defaults
    const prov = await Provider.findById(providerId).select('experienceYears hourlyRate');
    
    for (const s of ownedServices) {
      const sid = String(s._id);
      if (!existingSet.has(sid)) {
        toCreate.push({
          provider: providerId,
          service: s._id,
          hourlyRate: (s.price && Number.isFinite(s.price.amount)) ? s.price.amount : (prov?.hourlyRate || 50),
          experienceYears: prov?.experienceYears || 0,
          emergencyEnabled: !!s.emergencyEnabled,
          status: s.isActive ? 'draft' : 'inactive'
        });
      }
    }
    if (toCreate.length) {
      try { await ProviderService.insertMany(toCreate, { ordered: false }); } catch (_) {}
    }
    const items = await ProviderService.find({ provider: providerId, status: { $ne: 'deleted' } })
      .populate({
        path: 'service',
        select: 'title category emergencyEnabled isActive',
        // Temporarily remove the isActive filter to see all services
        // match: { isActive: true } // Only populate if service is active
      })
      .limit(50); // Add a high limit to ensure we get all services
    
    console.log(`🔍 listMy: Found ${items.length} ProviderService documents for provider ${providerId}`);
    
    // Log each item to see which ones have null service
    items.forEach((item, index) => {
      if (item.service === null) {
        console.log(`⚠️ listMy: Item ${index} has null service (ProviderService ID: ${item._id})`);
      } else {
        console.log(`✅ listMy: Item ${index} has service: ${item.service.title} (isActive: ${item.service.isActive})`);
      }
    });
    
    // Filter out items where service is null (deleted services)
    const filteredItems = items.filter(item => item.service !== null);
    
    console.log(`🔍 listMy: After filtering, returning ${filteredItems.length} items`);
    
    // Log the final response structure
    console.log(`🔍 listMy: Response structure: { items: [${filteredItems.length} items] }`);
    
    return ok(res, { items: filteredItems });
  } catch (e) { return error(res, 400, e.message || 'Failed to list services'); }
}

// Add new service with required fields
async function add(req, res) {
  try {
    const providerId = req.params.providerId;
    if (!isOwner(req, providerId) && !(req.user && req.user.role === 'admin')) {
      return error(res, 403, 'Forbidden');
    }
  const { serviceId, hourlyRate, experienceYears, emergencyEnabled, emergencyLeadTimeMinutes, weeklyOverrides, exceptionOverrides, emergencyWeeklyOverrides, emergencyExceptionOverrides } = req.body || {};
    if (!serviceId || !mongoose.Types.ObjectId.isValid(serviceId)) return error(res, 400, 'serviceId required');
    if (!(Number.isFinite(hourlyRate) && hourlyRate > 0)) return error(res, 400, 'hourlyRate required');
    if (!(Number.isFinite(experienceYears) && experienceYears >= 0)) return error(res, 400, 'experienceYears required');
    const svc = await Service.findById(serviceId);
    if (!svc) return error(res, 404, 'Service not found');
    const doc = await ProviderService.create({
      provider: providerId,
      service: serviceId,
      hourlyRate, experienceYears,
      emergencyEnabled: !!emergencyEnabled,
  emergencyLeadTimeMinutes: Number.isFinite(emergencyLeadTimeMinutes) ? emergencyLeadTimeMinutes : 0,
  weeklyOverrides, exceptionOverrides,
  emergencyWeeklyOverrides, emergencyExceptionOverrides,
      status: 'active' // create active if publishable pass in pre-save
    });
    return created(res, doc, 'Provider service created');
  } catch (e) { 
    console.log('❌ ProviderService.add error:', e);
    if (e.code === 11000) {
      return error(res, 409, 'This service is already added to your profile');
    }
    return error(res, 400, e.message || 'Failed to add provider service'); 
  }
}

// Edit details
async function update(req, res) {
  try {
    const providerId = req.params.providerId;
    const id = req.params.id;
    if (!isOwner(req, providerId) && !(req.user && req.user.role === 'admin')) {
      return error(res, 403, 'Forbidden');
    }
    const doc = await ProviderService.findOne({ _id: id, provider: providerId, status: { $ne: 'deleted' } });
    if (!doc) return error(res, 404, 'Not found');
    const allowed = ['hourlyRate','experienceYears','emergencyEnabled','emergencyLeadTimeMinutes','weeklyOverrides','exceptionOverrides','emergencyWeeklyOverrides','emergencyExceptionOverrides'];
    const normWeekly = (w) => {
      const days = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
      if (!w || typeof w !== 'object') return undefined;
      const out = {};
      for (const d of days) {
        const arr = Array.isArray(w[d]) ? w[d] : [];
        const list = arr.filter(Boolean).map(x => ({ start: String(x.start||''), end: String(x.end||'') })).filter(v => v.start && v.end);
        if (list.length) out[d] = list; else out[d] = [];
      }
      return out;
    };
    const normExceptions = (list) => {
      if (!Array.isArray(list)) return undefined;
      const out = list.map(e => ({
        date: String((e && e.date) || ''),
        windows: Array.isArray(e && e.windows) ? e.windows.map(w => ({ start: String(w.start||''), end: String(w.end||'') })).filter(w => w.start && w.end) : []
      })).filter(e => e.date);
      return out;
    };

    for (const k of allowed) {
      if (!Object.prototype.hasOwnProperty.call(req.body, k)) continue;
      const v = req.body[k];
      if (v === null) { doc[k] = undefined; continue; }
      if (k === 'weeklyOverrides' || k === 'emergencyWeeklyOverrides') { doc[k] = normWeekly(v); continue; }
      if (k === 'exceptionOverrides' || k === 'emergencyExceptionOverrides') { doc[k] = normExceptions(v); continue; }
      doc[k] = v;
    }
    await doc.save();
    return ok(res, doc, 'Updated');
  } catch (e) { return error(res, 400, e.message || 'Failed to update'); }
}

// Deactivate for rest of current month: record blackout batch metadata only
async function deactivateMonth(req, res) {
  try {
    const providerId = req.params.providerId; const id = req.params.id;
    if (!isOwner(req, providerId) && !(req.user && req.user.role === 'admin')) return error(res, 403, 'Forbidden');
    const doc = await ProviderService.findOne({ _id: id, provider: providerId, status: { $ne: 'deleted' } });
    if (!doc) return error(res, 404, 'Not found');
    const now = DateTime.now();
    const from = now.toFormat('yyyy-MM-dd');
    const end = now.endOf('month').toFormat('yyyy-MM-dd');
    const batchId = `${id}:${from}`;
    doc.status = 'inactive';
    doc.deactivationBatches.push({ batchId, fromDate: from, toDate: end });
    doc.lastDeactivationBatchId = batchId;
    await doc.save();
    return ok(res, { batchId, from, to: end }, 'Deactivated for month');
  } catch (e) { return error(res, 400, e.message || 'Failed to deactivate'); }
}

// Reactivate: mark active and remember last batch id for UI; actual slot restoration is handled in resolver
async function activateMonth(req, res) {
  try {
    const providerId = req.params.providerId; const id = req.params.id;
    if (!isOwner(req, providerId) && !(req.user && req.user.role === 'admin')) return error(res, 403, 'Forbidden');
    const doc = await ProviderService.findOne({ _id: id, provider: providerId, status: { $ne: 'deleted' } });
    if (!doc) return error(res, 404, 'Not found');
    if (!doc.publishable) return error(res, 400, 'Service not publishable');
    doc.status = 'active';
    await doc.save();
    return ok(res, { id: doc._id }, 'Reactivated');
  } catch (e) { return error(res, 400, e.message || 'Failed to activate'); }
}

// Soft delete
async function remove(req, res) {
  try {
    const providerId = req.params.providerId; const id = req.params.id;
    if (!isOwner(req, providerId) && !(req.user && req.user.role === 'admin')) return error(res, 403, 'Forbidden');
    const doc = await ProviderService.findOne({ _id: id, provider: providerId });
    if (!doc) return error(res, 404, 'Not found');
    doc.status = 'deleted';
    await doc.save();
    return ok(res, {}, 'Deleted');
  } catch (e) { return error(res, 400, e.message || 'Failed to delete'); }
}

module.exports = { listMy, add, update, deactivateMonth, activateMonth, remove };

// --- Public aggregated read (Phase 1 migration helper) ---
// GET /api/provider-services/public?providerId=XXXX
// Returns flattened provider-service offerings (active+publishable only)
async function listPublic(req, res) {
  try {
    const { providerId } = req.query;
    if (!providerId) return error(res, 400, 'providerId required');
    // Validate provider exists & active (lightweight select)
    const prov = await Provider.findById(providerId).select('_id isActive');
    if (!prov || !prov.isActive) return error(res, 404, 'Provider not found');

    const docs = await ProviderService.find({
      provider: providerId,
      status: { $ne: 'deleted' } // Match the authenticated endpoint
    })
      .populate({
        path: 'service',
        select: 'title category subcategory description price duration images emergencyEnabled emergencyLeadTimeMinutes emergencySurcharge emergencyRateMultiplier emergencyTypes',
        // Remove the isActive filter to match the authenticated endpoint
        // match: { isActive: true } // Only populate if service is active
      })
      .lean();

  let items = docs
    .filter(ps => ps.service !== null) // Only include items where service exists and is active
    .map(ps => {
      const svc = ps.service;
      const priceObj = (svc.price && typeof svc.price === 'object') ? svc.price : {};
      const pricing = {
        amount: Number.isFinite(ps.hourlyRate) ? ps.hourlyRate : (priceObj.amount || 0),
        type: priceObj.type || 'hourly',
        currency: priceObj.currency || 'ILS'
      };
      const isPublishable = Number.isFinite(ps.hourlyRate) && ps.hourlyRate > 0
        && Number.isFinite(ps.experienceYears) && ps.experienceYears >= 0;
      return {
        providerServiceId: ps._id,
        serviceId: svc._id,
        title: svc.title || '',
        category: svc.category || '',
        subcategory: svc.subcategory || '',
        pricing,
        experienceYears: ps.experienceYears || 0,
        emergency: {
          enabled: !!ps.emergencyEnabled,
          leadTimeMinutes: (Number.isFinite(ps.emergencyLeadTimeMinutes) ? ps.emergencyLeadTimeMinutes : 0),
          surcharge: svc.emergencySurcharge || { type: 'flat', amount: 0 },
          rateMultiplier: svc.emergencyRateMultiplier || 1.5,
          types: svc.emergencyTypes || []
        },
        publishable: isPublishable,
        // Future: rating/totalBookings can be moved here once migrated
        createdAt: ps.createdAt,
        updatedAt: ps.updatedAt
      };
  });

  // Debug logging
  console.log(`🔍 listPublic: Found ${docs.length} ProviderService documents for provider ${providerId}`);
  console.log(`🔍 listPublic: After filtering for non-null services: ${items.length} services`);
  
  // Log each service to see which ones are being filtered
  docs.forEach((doc, index) => {
    if (doc.service === null) {
      console.log(`⚠️ listPublic: Document ${index} has null service (ProviderService ID: ${doc._id})`);
    } else {
      console.log(`✅ listPublic: Document ${index}: ${doc.service.title} (isActive: ${doc.service.isActive})`);
    }
  });
  
  items.forEach((item, index) => {
    console.log(`🔍 listPublic Service ${index}: ${item.title} - publishable: ${item.publishable} - hourlyRate: ${item.pricing.amount} - experienceYears: ${item.experienceYears}`);
  });

  // Filter by publishable unless includeAll is requested
  const { includeAll } = req.query;
  console.log(`🔍 listPublic: includeAll=${includeAll}, filtering by publishable...`);
  if (!includeAll) {
    const beforeFilter = items.length;
    items = items.filter(it => it.publishable);
    console.log(`🔍 listPublic: Before publishable filter: ${beforeFilter} services, after: ${items.length} services`);
    
    // Show which services were filtered out
    const filteredOut = docs.filter(ps => {
      const isPublishable = Number.isFinite(ps.hourlyRate) && ps.hourlyRate > 0
        && Number.isFinite(ps.experienceYears) && ps.experienceYears >= 0;
      return !isPublishable;
    });
    
    if (filteredOut.length > 0) {
      console.log(`⚠️ listPublic: ${filteredOut.length} services filtered out (not publishable):`);
      filteredOut.forEach((ps, index) => {
        console.log(`⚠️ Filtered Service ${index}: hourlyRate=${ps.hourlyRate}, experienceYears=${ps.experienceYears}`);
      });
    }
  }

  // Optional filters
  const { category: catFilter, subcategory: subFilter, limit } = req.query;
  if (catFilter) items = items.filter(it => String(it.category) === String(catFilter));
  if (subFilter) items = items.filter(it => String(it.subcategory) === String(subFilter));
  const lim = parseInt(limit, 10);
  if (Number.isFinite(lim) && lim > 0) items = items.slice(0, lim);

  return ok(res, { data: items });
  } catch (e) {
    return error(res, 500, 'Failed to list provider services');
  }
}

module.exports.listPublic = listPublic;

// GET /api/provider-services/public/providers-by-services?serviceIds=ID1,ID2
// Returns providers (distinct) who have at least one active & publishable provider-service for the given serviceIds
async function providersByServices(req, res) {
  try {
    const { serviceIds } = req.query;
    if (!serviceIds) return error(res, 400, 'serviceIds required');

    const tokens = String(serviceIds).split(',').map(s => s.trim()).filter(Boolean);
    if (!tokens.length) return ok(res, { data: [] });

    const objectIdTokens = [];
    const slugTokens = [];
    for (const t of tokens) {
      if (/^[a-f0-9]{24}$/i.test(t)) objectIdTokens.push(t); else slugTokens.push(t);
    }

    // Resolve slugs -> Service ObjectIds by matching subcategory (service key)
    let resolvedSlugIds = [];
    if (slugTokens.length) {
      const svcDocs = await Service.find({ subcategory: { $in: slugTokens } }).select('_id subcategory');
      resolvedSlugIds = svcDocs.map(s => String(s._id));
    }
    const allServiceObjectIds = [...new Set([...objectIdTokens, ...resolvedSlugIds])];
    if (!allServiceObjectIds.length) return ok(res, { data: [] });

    const psDocs = await ProviderService.find({
      service: { $in: allServiceObjectIds },
      status: 'active',
      publishable: true
    }).populate('service', 'subcategory title').select('provider service').lean();

    if (!psDocs.length) return ok(res, { data: [] });

    const providerIds = [...new Set(psDocs.map(d => String(d.provider)))];
    const providers = await Provider.find({ _id: { $in: providerIds }, isActive: true })
      .select('_id firstName lastName email phone city rating hourlyRate services') // legacy services retained
      .lean();

    // Map provider -> matched service slugs (subcategory) for display & filtering
    const matchedSlugsByProvider = {};
    for (const d of psDocs) {
      const pid = String(d.provider);
      const subcat = d.service && d.service.subcategory ? d.service.subcategory : null;
      if (!subcat) continue;
      if (!matchedSlugsByProvider[pid]) matchedSlugsByProvider[pid] = new Set();
      matchedSlugsByProvider[pid].add(subcat);
    }

    const result = providers.map(p => ({
      ...p,
      services: Array.from(matchedSlugsByProvider[String(p._id)] || [])
    }));

    return ok(res, { data: result, count: result.length, meta: { requested: tokens.length, matchedServiceIds: allServiceObjectIds.length } });
  } catch (e) {
    return error(res, 500, 'Failed to list providers by services');
  }
}

module.exports.providersByServices = providersByServices;

// GET /api/provider-services/public/providers-by-services-expanded?serviceIds=ID1,slug2
// Returns providers with only the matched ProviderService details (hourlyRate, experience, emergency flags)
async function providersByServicesExpanded(req, res) {
  try {
    const { serviceIds } = req.query;
    if (!serviceIds) return error(res, 400, 'serviceIds required');
    const tokens = String(serviceIds).split(',').map(s => s.trim()).filter(Boolean);
    if (!tokens.length) return ok(res, { data: [] });

    const objectIdTokens = [];
    const slugTokens = [];
    for (const t of tokens) {
      if (/^[a-f0-9]{24}$/i.test(t)) objectIdTokens.push(t); else slugTokens.push(t);
    }
    let resolvedSlugIds = [];
    if (slugTokens.length) {
      const svcDocs = await Service.find({ subcategory: { $in: slugTokens } }).select('_id subcategory');
      resolvedSlugIds = svcDocs.map(s => String(s._id));
    }
    const allServiceObjectIds = [...new Set([...objectIdTokens, ...resolvedSlugIds])];
    if (!allServiceObjectIds.length) return ok(res, { data: [] });

    let psDocs = await ProviderService.find({
      service: { $in: allServiceObjectIds },
      status: 'active',
      publishable: true
    }).populate('service', 'subcategory title').lean();

    if (!psDocs.length) return ok(res, { data: [] });

    // Group ProviderService docs by provider
    const byProvider = new Map();
    for (const ps of psDocs) {
      const pid = String(ps.provider);
      if (!byProvider.has(pid)) byProvider.set(pid, []);
      byProvider.get(pid).push(ps);
    }
    const providerIds = Array.from(byProvider.keys());
    const providers = await Provider.find({ _id: { $in: providerIds }, isActive: true })
      .select('_id firstName lastName addresses rating hourlyRate experienceYears providerId services languages')
      .lean();
    const providerMap = Object.fromEntries(providers.map(p => [String(p._id), p]));

    const items = [];
    for (const pid of providerIds) {
      const prov = providerMap[pid];
      if (!prov) continue; // skip inactive or missing
      const psList = byProvider.get(pid) || [];
      const matched = psList.map(ps => ({
        providerServiceId: ps._id,
        serviceId: ps.service?._id,
        subcategory: ps.service?.subcategory,
        title: ps.service?.title,
        hourlyRate: ps.hourlyRate,
        experienceYears: ps.experienceYears,
        emergencyEnabled: ps.emergencyEnabled
      }));
      items.push({
        provider: {
          _id: prov._id,
          providerId: prov.providerId,
          firstName: prov.firstName,
          lastName: prov.lastName,
          city: (prov.addresses && prov.addresses[0] && prov.addresses[0].city) || '',
          rating: prov.rating,
          baseHourlyRate: prov.hourlyRate,
          baseExperienceYears: prov.experienceYears,
          languages: prov.languages || []
        },
        matchedServices: matched
      });
    }

    return ok(res, { data: items, count: items.length, meta: { requestedTokens: tokens.length } });
  } catch (e) {
    return error(res, 500, 'Failed to list expanded providers by services');
  }
}

module.exports.providersByServicesExpanded = providersByServicesExpanded;
