// Canonical provider dataset for restoring the database to a known-good state.
// These entries align with UI expectations and current backend schema (Provider model).

/**
 * Minimal provider definition shape for restore script:
 * {
 *   email, firstName, lastName, phone, city, area, age, experienceYears,
 *   languages: [..], hourlyRate, services: [category keys per Service model],
 * }
 */

const cities = [
  { city: 'Ramallah', area: 'Al-Tireh' },
  { city: 'Nablus', area: 'Rafidia' },
  { city: 'Jerusalem', area: 'Beit Hanina' },
  { city: 'Hebron', area: 'Wadi Al-Hariyah' },
  { city: 'Bethlehem', area: 'Beit Jala' },
  { city: 'Gaza', area: 'Rimal' },
];

const EN = [
  { email: 'rami.services0@palhands.com', firstName: 'Rami', lastName: 'Services' },
  { email: 'maya.haddad1@palhands.com', firstName: 'Maya', lastName: 'Haddad' },
  { email: 'omar.khalil2@palhands.com', firstName: 'Omar', lastName: 'Khalil' },
  { email: 'sara.nasser3@palhands.com', firstName: 'Sara', lastName: 'Nasser' },
  { email: 'khaled.mansour4@palhands.com', firstName: 'Khaled', lastName: 'Mansour' },
  { email: 'yara.saleh5@palhands.com', firstName: 'Yara', lastName: 'Saleh' },
  { email: 'hadi.suleiman6@palhands.com', firstName: 'Hadi', lastName: 'Suleiman' },
  { email: 'noor.ali7@palhands.com', firstName: 'Noor', lastName: 'Ali' },
  { email: 'lina.faris8@palhands.com', firstName: 'Lina', lastName: 'Faris' },
  { email: 'osama.t.9@palhands.com', firstName: 'Osama', lastName: 'Tareq' },
];

const AR = [
  { email: 'provider15@palhands.com', firstName: 'محمد', lastName: 'العابد' },
  { email: 'provider16@palhands.com', firstName: 'سارة', lastName: 'يوسف' },
  { email: 'provider17@palhands.com', firstName: 'ليلى', lastName: 'حسن' },
  { email: 'provider18@palhands.com', firstName: 'أحمد', lastName: 'درويش' },
  { email: 'provider19@palhands.com', firstName: 'نور', lastName: 'الهدى' },
];

// Use subcategory keys (exact UI service keys) to align provider.services with frontend chips
const subcategories = [
  // Cleaning
  'bedroomCleaning','livingRoomCleaning','kitchenCleaning','bathroomCleaning','windowCleaning','doorCabinetCleaning','floorCleaning','carpetCleaning','furnitureCleaning','gardenCleaning','entranceCleaning','stairCleaning','garageCleaning','postEventCleaning','postConstructionCleaning','apartmentCleaning','regularCleaning',
  // Organizing
  'bedroomOrganizing','kitchenOrganizing','closetOrganizing','storageOrganizing','livingRoomOrganizing','postPartyOrganizing','fullHouseOrganizing','childrenOrganizing',
  // Cooking
  'mainDishes','desserts','specialRequests',
  // Childcare
  'homeBabysitting','schoolAccompaniment','homeworkHelp','educationalActivities','childrenMealPrep','sickChildCare',
  // Elderly
  'homeElderlyCare','medicalTransport','healthMonitoring','medicationAssistance','emotionalSupport','mobilityAssistance',
  // Maintenance
  'electricalWork','plumbingWork','aluminumWork','carpentryWork','painting','hangingItems','satelliteInstallation','applianceMaintenance',
  // New Home
  'furnitureMoving','packingUnpacking','furnitureWrapping','newHomeArrangement','newApartmentCleaning','preOccupancyRepairs','kitchenSetup','applianceInstallation',
  // Miscellaneous
  'documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup',
];

function pickCity(i) {
  return cities[i % cities.length];
}

function pickServices(i) {
  // Each provider gets 2-4 subcategory services deterministically
  const count = 2 + (i % 3);
  const start = (i * 5) % subcategories.length;
  const set = new Set();
  for (let k = 0; k < count; k++) set.add(subcategories[(start + k * 3) % subcategories.length]);
  return Array.from(set);
}

function buildDataset() {
  const all = [...EN, ...AR];
  return all.map((p, idx) => {
    const c = pickCity(idx);
    return {
      email: p.email,
      firstName: p.firstName,
      lastName: p.lastName,
      phone: `+9705910${(1000 + idx).toString().padStart(4, '0')}`,
      city: c.city,
      area: c.area,
      age: 24 + (idx % 18),
      experienceYears: 1 + (idx % 10),
      languages: idx % 2 === 0 ? ['Arabic', 'English'] : ['Arabic'],
      hourlyRate: 45 + (idx % 8) * 10, // 45..115
      services: pickServices(idx),
    };
  });
}

module.exports = {
  providers: buildDataset(),
  serviceSubcategories: subcategories,
};
