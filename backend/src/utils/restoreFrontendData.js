require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const fs = require('fs');
const path = require('path');

// Models
const Provider = require('../models/Provider');
const Service = require('../models/Service');

// Lazy model for servicecategories collection (no permanent model file needed)
const serviceCategorySchema = new mongoose.Schema({
  id: { type: String, unique: true },
  name: String,              // i18n key used on FE
  description: String,       // i18n key used on FE
  icon: String,
  color: String,
  isActive: { type: Boolean, default: true },
  sortOrder: { type: Number, default: 0 },
  services: [String],        // service keys
}, { collection: 'servicecategories' });
const ServiceCategory = mongoose.models.ServiceCategory || mongoose.model('ServiceCategory', serviceCategorySchema);

// Canonical categories/services — mirrored from frontend/mobile_category_widget.dart
const CATEGORIES = [
  { id: 'cleaning',     name: 'cleaningServices',     description: 'cleaningServicesDescription',     icon: 'cleaning_services',          color: '#4CAF50', services: ['bedroomCleaning','livingRoomCleaning','kitchenCleaning','bathroomCleaning','windowCleaning','doorCabinetCleaning','floorCleaning','carpetCleaning','furnitureCleaning','gardenCleaning','entranceCleaning','stairCleaning','garageCleaning','postEventCleaning','postConstructionCleaning','apartmentCleaning','regularCleaning'] },
  { id: 'organizing',   name: 'organizingServices',   description: 'organizingServicesDescription',   icon: 'folder_open',                color: '#2196F3', services: ['bedroomOrganizing','kitchenOrganizing','closetOrganizing','storageOrganizing','livingRoomOrganizing','postPartyOrganizing','fullHouseOrganizing','childrenOrganizing'] },
  { id: 'cooking',      name: 'homeCookingServices',  description: 'homeCookingServicesDescription',  icon: 'restaurant',                 color: '#FF9800', services: ['mainDishes','desserts','specialRequests'] },
  { id: 'childcare',    name: 'childCareServices',    description: 'childCareServicesDescription',    icon: 'child_care',                 color: '#9C27B0', services: ['homeBabysitting','schoolAccompaniment','homeworkHelp','educationalActivities','childrenMealPrep','sickChildCare'] },
  { id: 'elderly',      name: 'personalElderlyCare',  description: 'personalElderlyCareDescription', icon: 'elderly',                    color: '#607D8B', services: ['homeElderlyCare','medicalTransport','healthMonitoring','medicationAssistance','emotionalSupport','mobilityAssistance'] },
  { id: 'maintenance',  name: 'maintenanceRepair',    description: 'maintenanceRepairDescription',    icon: 'build',                      color: '#795548', services: ['electricalWork','plumbingWork','aluminumWork','carpentryWork','painting','hangingItems','satelliteInstallation','applianceMaintenance'] },
  { id: 'newhome',      name: 'newHomeServices',      description: 'newHomeServicesDescription',      icon: 'home',                       color: '#E91E63', services: ['furnitureMoving','packingUnpacking','furnitureWrapping','newHomeArrangement','newApartmentCleaning','preOccupancyRepairs','kitchenSetup','applianceInstallation'] },
  { id: 'miscellaneous',name: 'miscellaneousErrands', description: 'miscellaneousErrandsDescription', icon: 'miscellaneous_services',      color: '#00BCD4', services: ['documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup'] },
];

// Provider roster generation consistent with FE mocks (deterministic)
const rnd = (seed => () => (seed = (seed * 16807) % 2147483647) / 2147483647)(3);
const pick = (arr) => arr[Math.floor(rnd() * arr.length)];
// Use lowercase city keys to match FE dropdown values and i18n keys
const CITIES = ['ramallah','nablus','jerusalem','hebron','bethlehem','gaza'];
const LANG_POOLS = [ ['Arabic'], ['Arabic','English'], ['Arabic','Hebrew'], ['Arabic','Turkish'] ];
const NAMES = ['Rami Services','Maya Haddad','Omar Khalil','Sara Nasser','Khaled Mansour','Yara Saleh','Hadi Suleiman','Noor Ali','Lina Faris','Osama T.','Adam Q.','Layla Z.','Sami R.','Dana M.','Fares K.','محمد العابد','سارة يوسف','ليلى حسن','أحمد درويش','نور الهدى','مريم خليل','رامي ناصر','عمر عوض','هالة سمير','رنا أحمد'];

const ALL_SERVICE_KEYS = CATEGORIES.flatMap(c => c.services);

function slugify(str){
  return String(str).toLowerCase().replace(/[^a-z0-9]+/gi,'-').replace(/(^-|-$)/g,'');
}

function providerEmail(firstName, index){
  const base = slugify(firstName) || `pro${index}`;
  // Use dot-separated local part; avoid '+' aliasing which some validators reject
  return `provider.${base}.${index}@palhands.com`;
}

function buildProviderRoster(targetCount = 34){
  const roster = [];
  for (let i=0;i<targetCount;i++){
    const name = NAMES[i % NAMES.length];
    const firstName = name.split(' ')[0].replace(/[^\p{L}A-Za-z]/gu,'') || 'Pro';
    const lastName = name.split(' ').slice(1).join(' ').replace(/[^\p{L}A-Za-z]/gu,'');
    const city = CITIES[i % CITIES.length];
    const languages = LANG_POOLS[i % LANG_POOLS.length];
    const baseRate = 45 + (i % 50) + Math.floor(rnd()*20);
  // deterministic age between 21-55
  const age = 21 + (i % 35);
    // deterministic 2-3 services per provider
    const services = new Set();
    services.add(ALL_SERVICE_KEYS[(i*3) % ALL_SERVICE_KEYS.length]);
    services.add(ALL_SERVICE_KEYS[(i*7+5) % ALL_SERVICE_KEYS.length]);
    if (i % 3 === 0) services.add(ALL_SERVICE_KEYS[(i*11+2) % ALL_SERVICE_KEYS.length]);
  const email = providerEmail(firstName, i);
    roster.push({
      firstName,
      lastName,
      email,
      password: 'Provider123!', // uniform dev password (hashed via pre-save)
      role: 'provider',
      phone: `+97059${String(1000000 + i).padStart(7,'0')}`,
      age,
      experienceYears: 1 + (i % 10),
      languages,
      hourlyRate: baseRate,
      services: Array.from(services),
      addresses: [{ type: 'home', street: `${city} Main St ${10 + (i % 50)}`, city, area: 'City Center', coordinates: { latitude: null, longitude: null }, isDefault: true }],
      isActive: true,
      isVerified: true,
      rating: { average: 3.8 + (rnd()*1.2), count: 5 + (i % 50) }
    });
  }
  return roster;
}

function categoryOf(serviceKey){
  const c = CATEGORIES.find(cat => cat.services.includes(serviceKey));
  return c ? c.id : 'miscellaneous';
}

function prettyServiceName(key) {
  // Convert camelCase or mixed to spaced and capitalized words
  return String(key)
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, c => c.toUpperCase())
    .trim();
}

async function upsertCategories(){
  let sortOrder = 1;
  for (const cat of CATEGORIES){
    await ServiceCategory.updateOne(
      { id: cat.id },
      { $set: { ...cat, isActive: true, sortOrder } },
      { upsert: true }
    );
    sortOrder++;
  }
}

async function upsertProviders(roster){
  const results = { created: 0, updated: 0 };
  for (const p of roster){
    // Try matching by new email, old email pattern, or phone (stable)
    const oldEmail = `provider+${slugify(p.firstName)}.${/\.(\d+)$/.test(p.email) ? p.email.match(/\.(\d+)$/)[1] : '0'}@palhands.com`;
    const existing = await Provider.findOne({ $or: [
      { email: p.email.toLowerCase() },
      { email: oldEmail.toLowerCase() },
      { phone: p.phone }
    ] }).lean();
    if (!existing){
      await new Provider({ ...p, email: p.email.toLowerCase() }).save();
      results.created++;
    } else {
  await Provider.updateOne({ _id: existing._id }, { $set: {
        firstName: p.firstName,
        lastName: p.lastName,
        phone: p.phone,
        email: p.email.toLowerCase(),
        age: p.age,
        experienceYears: p.experienceYears,
        languages: p.languages,
        hourlyRate: p.hourlyRate,
        services: p.services,
        addresses: p.addresses,
        isActive: true,
        isVerified: true,
        rating: p.rating,
  }}, { runValidators: true });
      results.updated++;
    }
  }
  return results;
}

async function upsertServicesForProviders(roster, capTotal = 50){
  // Build candidate list across all providers first (round-robin-ish but deterministic)
  const providerDocs = await Provider.find({ email: { $in: roster.map(r => r.email) } });
  const byEmail = new Map(providerDocs.map(p => [p.email, p]));

  const candidates = [];
  for (const r of roster) {
    const prov = byEmail.get(r.email);
    if (!prov) continue;
    const city = r.addresses?.[0]?.city || '';
    for (const sKey of r.services) {
      candidates.push({ prov, r, sKey, city });
    }
  }

  // Take first N unique (provider,subcategory) combos
  const seen = new Set();
  const selected = [];
  for (const c of candidates) {
    const key = `${c.prov._id}-${c.sKey}`;
    if (seen.has(key)) continue;
    seen.add(key);
    selected.push(c);
    if (selected.length >= capTotal) break;
  }

  let created = 0, updated = 0;
  const keepServiceIds = [];
  const selectedPairs = []; // [{provider: ObjectId, subcategory: string, keepId: ObjectId}]
  for (const c of selected) {
    const cat = categoryOf(c.sKey);
    const title = prettyServiceName(c.sKey);
    const filter = { provider: c.prov._id, category: cat, subcategory: c.sKey };
    const update = {
      title,
      description: `Professional ${prettyServiceName(c.sKey)} service`,
      provider: c.prov._id,
      category: cat,
      subcategory: c.sKey,
      price: { amount: c.r.hourlyRate, type: 'hourly', currency: 'ILS' },
      duration: { estimated: 120, flexible: true },
      availability: { days: ['monday','tuesday','wednesday','thursday','friday'], timeSlots: [{ start: '09:00', end: '17:00' }], flexible: true },
  // Keep serviceArea capitalized nicely for readability; city stored lowercase in provider address
  location: { serviceArea: (c.city ? (c.city[0].toUpperCase()+c.city.slice(1)) : 'Ramallah'), radius: 20, onSite: true, remote: false },
      isActive: true,
      featured: false,
    };

    const existing = await Service.findOne(filter).select('_id');
    if (!existing) {
      const createdDoc = await Service.create(update);
      keepServiceIds.push(createdDoc._id);
      selectedPairs.push({ provider: c.prov._id.toString(), subcategory: c.sKey, keepId: createdDoc._id.toString() });
      created++;
    } else {
      await Service.updateOne({ _id: existing._id }, { $set: update });
      keepServiceIds.push(existing._id);
      selectedPairs.push({ provider: c.prov._id.toString(), subcategory: c.sKey, keepId: existing._id.toString() });
      updated++;
    }
  }
  return { created, updated, keepServiceIds, selectedPairs };
}

async function main(){
  const RESET = String(process.env.RESET || '').toLowerCase() === 'true';
  const PRUNE = String(process.env.PRUNE || '').toLowerCase() === 'true';
  await connectDB();

  if (RESET){
    console.log('⚠️  RESET=true → Dropping providers, services, and servicecategories collections');
    try { await mongoose.connection.collection('providers').drop(); } catch(_){}
    try { await mongoose.connection.collection('services').drop(); } catch(_){}
    try { await mongoose.connection.collection('servicecategories').drop(); } catch(_){}
  }

  console.log('⏳ Upserting service categories…');
  await upsertCategories();
  console.log('✅ Categories ready');

  const roster = buildProviderRoster(34);
  console.log(`⏳ Upserting ${roster.length} providers… (will NOT touch users collection)`);
  const provRes = await upsertProviders(roster);
  console.log(`✅ Providers upserted → created: ${provRes.created}, updated: ${provRes.updated}`);

  console.log('⏳ Upserting services (capped to ~50)…');
  const svcRes = await upsertServicesForProviders(roster, 50);
  console.log(`✅ Services upserted → created: ${svcRes.created}, updated: ${svcRes.updated}`);

  if (PRUNE) {
    console.log('🧹 PRUNE=true → Deleting services not in the canonical 50 set…');
    const keepMap = new Map();
    for (const p of svcRes.selectedPairs) {
      keepMap.set(`${p.provider}|${p.subcategory}`, p.keepId);
    }
    const all = await Service.find({}, { _id: 1, provider: 1, subcategory: 1 }).lean();
    const toDelete = [];
    for (const s of all) {
      const key = `${s.provider?.toString()}|${s.subcategory}`;
      const keepId = keepMap.get(key);
      if (!keepId) {
        toDelete.push(s._id);
      } else if (s._id.toString() !== keepId) {
        // duplicate for a kept pair
        toDelete.push(s._id);
      }
    }
    if (toDelete.length) {
      const delRes = await Service.deleteMany({ _id: { $in: toDelete } });
      console.log(`✅ Pruned services: removed ${delRes.deletedCount} extraneous service(s)`);
    } else {
      console.log('✅ No extraneous services to prune');
    }
    const finalCount = await Service.countDocuments({});
    console.log(`📦 Final services count: ${finalCount}`);
  }

  // Write snapshots to disk for fast recovery
  try {
    const outDir = path.join(__dirname, 'data');
    if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
    const snapshot = {
      generatedAt: new Date().toISOString(),
      categories: CATEGORIES,
      providers: roster.map(p => ({
        firstName: p.firstName,
        lastName: p.lastName,
        email: p.email,
        phone: p.phone,
        city: p.addresses?.[0]?.city || '',
        experienceYears: p.experienceYears,
        languages: p.languages,
        hourlyRate: p.hourlyRate,
        services: p.services,
        isActive: p.isActive,
        isVerified: p.isVerified,
      })),
      services: (await Service.find({ _id: { $in: svcRes.keepServiceIds } }).lean()).map(s => ({
        id: s._id,
        title: s.title,
        category: s.category,
        subcategory: s.subcategory,
        provider: s.provider,
        location: s.location,
        price: s.price,
      }))
    };
    fs.writeFileSync(path.join(outDir, 'snapshot.json'), JSON.stringify(snapshot, null, 2), 'utf8');
    fs.writeFileSync(path.join(outDir, 'categories.json'), JSON.stringify(CATEGORIES, null, 2), 'utf8');
    fs.writeFileSync(path.join(outDir, 'providers.json'), JSON.stringify(snapshot.providers, null, 2), 'utf8');
    fs.writeFileSync(path.join(outDir, 'services.json'), JSON.stringify(snapshot.services, null, 2), 'utf8');
    console.log(`📝 Snapshots written to ${path.relative(process.cwd(), outDir)}`);
  } catch (e) {
    console.warn('⚠️  Failed to write snapshot files:', e.message);
  }

  console.log('\nTest login for any seeded provider:');
  console.log('- Email format: provider.<slug>.<index>@palhands.com  (e.g., provider.rami.0@palhands.com)');
  console.log('- Password: Provider123!');

  await mongoose.connection.close();
}

main().catch(err => { console.error('❌ Restore failed:', err); process.exit(1); });
