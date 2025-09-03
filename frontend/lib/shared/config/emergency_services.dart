// Emergency services mapping: list of service slugs (or identifiers) that are
// allowed to be booked as emergency. Keep services available as normal too.

const List<String> kEmergencyServiceSlugs = [
  // Maintenance & repair
  'maintenance_repair',
  'install_satellite_or_wifi',
  'heater_or_washer_service',

  // Childcare
  'babysitting_at_home',
  'sick_child_care',

  // Misc & errands
  'deliver_documents',
  'deliver_shopping',
  'private_drive',
  'pay_bills_or_transactions',
  // Prescription Pickup appears in the codebase as several identifiers.
  // Include common variants so backend/frontend slug differences don't block emergency mode.
  'collect_prescription',
  'prescriptionPickup',
  'prescription_pickup',

  // New home
  'install_electrical_appliances',

  // Personal care & elderly
  'elderly_care_at_home',
  'deliver_to_medical_centers',
  'bp_and_sugar_monitoring',
  'administer_medicine_supervised',
  'assistance_mobility_and_bathing',
  // Mobility & Bathing Assistance slug variants (backend/front-end use different keys)
  'mobilityAssistance',
  'mobility_assistance',
  'mobility-assistance',
  // Home & Appliance Services
  'install_electrical_appliances',
  'satelliteInstallation',
  'satellite_installation',
  'applianceMaintenance',
  'water_heater_maintenance',
  'washing_machine_maintenance',
  // Miscellaneous & Errands
  'documentDelivery',
  'shoppingDelivery',
  'specialErrands',
  'billPayment',
  'prescriptionPickup',
  // Care Services
  'homeBabysitting',
  'homeElderlyCare',
  'medicalTransport',
  'healthMonitoring',
  'medicationAssistance',
];
