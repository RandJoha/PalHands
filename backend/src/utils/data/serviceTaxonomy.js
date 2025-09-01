// Canonical taxonomy mapping subcategory keys to their parent categories.
// Keep in sync with frontend category widgets.

const TAXONOMY = {
  cleaning: [
    'bedroomCleaning','livingRoomCleaning','kitchenCleaning','bathroomCleaning','windowCleaning','doorCabinetCleaning','floorCleaning','carpetCleaning','furnitureCleaning','gardenCleaning','entranceCleaning','stairCleaning','garageCleaning','postEventCleaning','postConstructionCleaning','apartmentCleaning','regularCleaning'
  ],
  organizing: [
    'bedroomOrganizing','kitchenOrganizing','closetOrganizing','storageOrganizing','livingRoomOrganizing','postPartyOrganizing','fullHouseOrganizing','childrenOrganizing'
  ],
  cooking: [
    'mainDishes','desserts','specialRequests'
  ],
  childcare: [
    'homeBabysitting','schoolAccompaniment','homeworkHelp','educationalActivities','childrenMealPrep','sickChildCare'
  ],
  elderly: [
    'homeElderlyCare','medicalTransport','healthMonitoring','medicationAssistance','emotionalSupport','mobilityAssistance'
  ],
  maintenance: [
    'electricalWork','plumbingWork','aluminumWork','carpentryWork','painting','hangingItems','satelliteInstallation','applianceMaintenance'
  ],
  newhome: [
    'furnitureMoving','packingUnpacking','furnitureWrapping','newHomeArrangement','newApartmentCleaning','preOccupancyRepairs','kitchenSetup','applianceInstallation'
  ],
  miscellaneous: [
    'documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup'
  ],
};

const subcategoryToCategory = (() => {
  const map = new Map();
  for (const [cat, subs] of Object.entries(TAXONOMY)) {
    subs.forEach((s) => map.set(s, cat));
  }
  return map;
})();

function getCategoryForSubcategory(subKey) {
  return subcategoryToCategory.get(subKey) || null;
}

function allSubcategories() {
  return Object.values(TAXONOMY).flat();
}

module.exports = { TAXONOMY, getCategoryForSubcategory, allSubcategories };
