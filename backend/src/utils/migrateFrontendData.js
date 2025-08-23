require('dotenv').config();
const { connectDB, mongoose } = require('../config/database');
const Provider = require('../models/Provider');
const Service = require('../models/Service');

// Categories data extracted from frontend
const CATEGORIES = [
  {
    id: 'cleaning',
    name: 'Cleaning Services',
    nameKey: 'cleaningServices',
    description: 'Professional cleaning services for your home',
    services: [
      'bedroomCleaning', 'livingRoomCleaning', 'kitchenCleaning', 'bathroomCleaning',
      'windowCleaning', 'doorCabinetCleaning', 'floorCleaning', 'carpetCleaning',
      'furnitureCleaning', 'gardenCleaning', 'entranceCleaning', 'stairCleaning',
      'garageCleaning', 'postEventCleaning', 'postConstructionCleaning', 
      'apartmentCleaning', 'regularCleaning'
    ]
  },
  {
    id: 'organizing',
    name: 'Organizing Services',
    nameKey: 'organizingServices',
    description: 'Professional organizing services for your home',
    services: [
      'bedroomOrganizing', 'kitchenOrganizing', 'closetOrganizing', 'storageOrganizing',
      'livingRoomOrganizing', 'postPartyOrganizing', 'fullHouseOrganizing', 'childrenOrganizing'
    ]
  },
  {
    id: 'cooking',
    name: 'Home Cooking Services',
    nameKey: 'homeCookingServices',
    description: 'Professional cooking services for your home',
    services: [
      'mainDishes', 'desserts', 'specialRequests'
    ]
  },
  {
    id: 'childcare',
    name: 'Child Care Services',
    nameKey: 'childCareServices',
    description: 'Professional childcare services',
    services: [
      'homeBabysitting', 'schoolAccompaniment', 'homeworkHelp', 
      'educationalActivities', 'childrenMealPrep', 'sickChildCare'
    ]
  },
  {
    id: 'elderly',
    name: 'Personal & Elderly Care',
    nameKey: 'personalElderlyCare',
    description: 'Personal and elderly care services',
    services: [
      'homeElderlyCare', 'medicalTransport', 'healthMonitoring',
      'medicationAssistance', 'emotionalSupport', 'mobilityAssistance'
    ]
  },
  {
    id: 'maintenance',
    name: 'Maintenance & Repair',
    nameKey: 'maintenanceRepair',
    description: 'Home maintenance and repair services',
    services: [
      'electricalWork', 'plumbingWork', 'aluminumWork', 'carpentryWork',
      'painting', 'hangingItems', 'satelliteInstallation', 'applianceMaintenance'
    ]
  },
  {
    id: 'newhome',
    name: 'New Home Services',
    nameKey: 'newHomeServices',
    description: 'Services for new home setup and moving',
    services: [
      'furnitureMoving', 'packingUnpacking', 'furnitureWrapping', 'newHomeArrangement',
      'newApartmentCleaning', 'preOccupancyRepairs', 'kitchenSetup', 'applianceInstallation'
    ]
  },
  {
    id: 'miscellaneous',
    name: 'Miscellaneous & Errands',
    nameKey: 'miscellaneousErrands',
    description: 'Various errands and miscellaneous services',
    services: [
      'documentDelivery', 'shoppingDelivery', 'specialErrands', 
      'billPayment', 'prescriptionPickup'
    ]
  }
];

// Service translations/descriptions (simplified)
const SERVICE_NAMES = {
  // Cleaning
  bedroomCleaning: 'Bedroom Cleaning',
  livingRoomCleaning: 'Living Room Cleaning',
  kitchenCleaning: 'Kitchen Cleaning',
  bathroomCleaning: 'Bathroom Cleaning',
  windowCleaning: 'Window Cleaning',
  doorCabinetCleaning: 'Door & Cabinet Cleaning',
  floorCleaning: 'Floor Cleaning (Ceramic/Marble)',
  carpetCleaning: 'Carpet Cleaning',
  furnitureCleaning: 'Furniture/Sofa Cleaning',
  gardenCleaning: 'Garden Cleaning',
  entranceCleaning: 'House Entrance Cleaning',
  stairCleaning: 'Stair & Courtyard Cleaning',
  garageCleaning: 'Garage or Roof Cleaning',
  postEventCleaning: 'Post-Event/Party Cleaning',
  postConstructionCleaning: 'Post-Construction/Painting Cleaning',
  apartmentCleaning: 'Apartment Cleaning (Before/After Rental)',
  regularCleaning: 'Daily/Weekly/Monthly Cleaning',
  
  // Organizing
  bedroomOrganizing: 'Bedroom Organizing',
  kitchenOrganizing: 'Kitchen & Cabinet Organizing',
  closetOrganizing: 'Closet Organizing',
  storageOrganizing: 'Storage/Warehouse Organizing',
  livingRoomOrganizing: 'Living Room or Majlis Organizing',
  postPartyOrganizing: 'Post-Party or Event Organizing',
  fullHouseOrganizing: 'Full House Organizing',
  childrenOrganizing: 'Children or School Organizing',
  
  // Cooking
  mainDishes: 'Main Dishes',
  desserts: 'Desserts',
  specialRequests: 'Special Requests',
  
  // Childcare
  homeBabysitting: 'Home Babysitting',
  schoolAccompaniment: 'School/Nursery Accompaniment',
  homeworkHelp: 'Homework Assistance',
  educationalActivities: 'Educational & Recreational Activities',
  childrenMealPrep: 'Children Meal Preparation',
  sickChildCare: 'Sick Child Care',
  
  // Elderly
  homeElderlyCare: 'Home Elderly Care',
  medicalTransport: 'Medical Center/Clinic Transportation',
  healthMonitoring: 'Blood Pressure & Sugar Monitoring',
  medicationAssistance: 'Medication Administration (Under Supervision)',
  emotionalSupport: 'Psychological & Moral Support',
  mobilityAssistance: 'Mobility & Bathing Assistance',
  
  // Maintenance
  electricalWork: 'Electrical Work',
  plumbingWork: 'Plumbing Work',
  aluminumWork: 'Aluminum Work',
  carpentryWork: 'Carpentry Work',
  painting: 'Wall or Room Painting',
  hangingItems: 'Hanging Pictures/Mirrors/Curtains',
  satelliteInstallation: 'Satellite or WiFi Installation',
  applianceMaintenance: 'Water Heater or Washing Machine Maintenance',
  
  // New Home
  furnitureMoving: 'Indoor Furniture Moving',
  packingUnpacking: 'Packing & Unpacking Items',
  furnitureWrapping: 'Furniture & Belongings Wrapping',
  newHomeArrangement: 'New Home Arrangement After Moving',
  newApartmentCleaning: 'Complete New Apartment Cleaning',
  preOccupancyRepairs: 'Pre-Occupancy Repairs',
  kitchenSetup: 'Kitchen/Cabinets/Rooms Setup',
  applianceInstallation: 'Electrical Appliance Installation',
  
  // Miscellaneous
  documentDelivery: 'Document or Paper Delivery',
  shoppingDelivery: 'Shopping Delivery from Market/Mall',
  specialErrands: 'Special Errands',
  billPayment: 'Bill Payment/Transaction Processing',
  prescriptionPickup: 'Prescription Pickup'
};

// Provider data from frontend (extracted from ProviderService)
const PROVIDER_NAMES = [
  // English
  'Rami Services', 'Maya Haddad', 'Omar Khalil', 'Sara Nasser', 'Khaled Mansour',
  'Yara Saleh', 'Hadi Suleiman', 'Noor Ali', 'Lina Faris', 'Osama T.',
  'Adam Q.', 'Layla Z.', 'Sami R.', 'Dana M.', 'Fares K.',
  // Arabic
  'محمد العابد', 'سارة يوسف', 'ليلى حسن', 'أحمد درويش', 'نور الهدى',
  'مريم خليل', 'رامي ناصر', 'عمر عوض', 'هالة سمير', 'رنا أحمد'
];

const CITIES = ['Ramallah', 'Nablus', 'Jerusalem', 'Hebron', 'Bethlehem', 'Gaza'];
const LANGUAGE_POOLS = [
  ['Arabic'],
  ['Arabic', 'English'],
  ['Arabic', 'Hebrew'],
  ['Arabic', 'Turkish']
];

function generateProviderEmail(name, index) {
  // Create email-friendly version of name
  const emailName = name.toLowerCase()
    .replace(/[^\w\s]/g, '') // Remove special chars
    .replace(/\s+/g, '.') // Replace spaces with dots
    .replace(/[أ-ي]/g, '') // Remove Arabic chars
    .replace(/\.+/g, '.') // Remove multiple dots
    .replace(/^\./, '') // Remove leading dot
    .replace(/\.$/, ''); // Remove trailing dot
  
  return emailName ? `${emailName}${index}@palhands.com` : `provider${index}@palhands.com`;
}

function generateRandomPhone() {
  return `+97059${Math.floor(Math.random() * 9999999).toString().padLeft(7, '0')}`;
}

// Add padLeft method if it doesn't exist
String.prototype.padLeft = function(length, char) {
  return char.repeat(Math.max(0, length - this.length)) + this;
};

async function createServices() {
  console.log('🔄 Creating services...');
  const services = [];
  
  for (const category of CATEGORIES) {
    for (const serviceKey of category.services) {
      const serviceName = SERVICE_NAMES[serviceKey] || serviceKey;
      
      const serviceData = {
        title: serviceName,
        description: `Professional ${serviceName.toLowerCase()} service`,
        category: category.id,
        subcategory: serviceKey,
        provider: null, // Will be set when linking to providers
        price: {
          amount: 50 + Math.floor(Math.random() * 100), // Random price 50-150
          type: 'hourly',
          currency: 'ILS'
        },
        duration: {
          estimated: 60 + Math.floor(Math.random() * 180), // 1-4 hours
          flexible: true
        },
        availability: {
          days: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
          timeSlots: [{ start: '09:00', end: '17:00' }],
          flexible: true
        },
        location: {
          serviceArea: CITIES[Math.floor(Math.random() * CITIES.length)],
          radius: 20,
          onSite: true,
          remote: false
        },
        images: [],
        requirements: [],
        equipment: [],
        isActive: true
      };
      
      services.push(serviceData);
    }
  }
  
  try {
    await Service.deleteMany({}); // Clear existing services
    const createdServices = await Service.insertMany(services);
    console.log(`✅ Created ${createdServices.length} services`);
    return createdServices;
  } catch (error) {
    console.error('❌ Error creating services:', error);
    throw error;
  }
}

async function createProviders(services) {
  console.log('🔄 Creating providers...');
  
  // Get all service keys for random assignment
  const allServiceKeys = CATEGORIES.flatMap(cat => cat.services);
  const providers = [];
  
  // Create providers ensuring coverage of all services
  for (let i = 0; i < PROVIDER_NAMES.length; i++) {
    const name = PROVIDER_NAMES[i];
    const [firstName, ...lastNameParts] = name.split(' ');
    const lastName = lastNameParts.join(' ') || '';
    
    const city = CITIES[i % CITIES.length];
    const languages = LANGUAGE_POOLS[i % LANGUAGE_POOLS.length];
    const experienceYears = 1 + (i % 10);
    const hourlyRate = 45 + (i % 50) + Math.floor(Math.random() * 20);
    
    // Assign 2-5 random services to each provider
    const numServices = 2 + Math.floor(Math.random() * 4);
    const providerServices = [];
    const usedServices = new Set();
    
    while (providerServices.length < numServices && usedServices.size < allServiceKeys.length) {
      const randomService = allServiceKeys[Math.floor(Math.random() * allServiceKeys.length)];
      if (!usedServices.has(randomService)) {
        providerServices.push(randomService);
        usedServices.add(randomService);
      }
    }
    
    const providerData = {
      firstName,
      lastName,
      email: generateProviderEmail(name, i),
      password: 'Provider123!', // Uniform password for all providers
      role: 'provider',
      phone: generateRandomPhone(),
      age: 25 + Math.floor(Math.random() * 20), // Age 25-45
      addresses: [{
        type: 'home',
        street: 'Main Street',
        city: city,
        area: 'Central',
        isDefault: true
      }],
      experienceYears,
      languages,
      hourlyRate,
      services: providerServices,
      rating: {
        average: 3.8 + Math.random() * 1.2, // Rating 3.8-5.0
        count: 8 + Math.floor(Math.random() * 90) // Review count 8-98
      },
      location: {
        address: `${city}, Palestine`,
        coordinates: {
          latitude: 31.9 + Math.random() * 1.0, // Rough Palestine coordinates
          longitude: 35.2 + Math.random() * 0.8
        }
      },
      isActive: true,
      isVerified: true,
      totalBookings: Math.floor(Math.random() * 50),
      completedBookings: Math.floor(Math.random() * 40)
    };
    
    providers.push(providerData);
  }
  
  // Create additional providers to ensure every service has at least one provider
  for (let i = 0; i < allServiceKeys.length; i++) {
    const serviceKey = allServiceKeys[i];
    const hasProvider = providers.some(p => p.services.includes(serviceKey));
    
    if (!hasProvider) {
      const extraProviderIndex = providers.length;
      const nameIndex = extraProviderIndex % PROVIDER_NAMES.length;
      const name = PROVIDER_NAMES[nameIndex] + ` (${serviceKey})`;
      const [firstName, ...lastNameParts] = name.split(' ');
      
      providers.push({
        firstName,
        lastName: lastNameParts.join(' ') || '',
        email: generateProviderEmail(name, extraProviderIndex),
        password: 'Provider123!',
        role: 'provider',
        phone: generateRandomPhone(),
        age: 25 + Math.floor(Math.random() * 20),
        addresses: [{
          type: 'home',
          street: 'Service Street',
          city: CITIES[i % CITIES.length],
          area: 'Service Area',
          isDefault: true
        }],
        experienceYears: 1 + Math.floor(Math.random() * 8),
        languages: LANGUAGE_POOLS[i % LANGUAGE_POOLS.length],
        hourlyRate: 50 + Math.floor(Math.random() * 80),
        services: [serviceKey],
        rating: {
          average: 4.0 + Math.random() * 1.0,
          count: 5 + Math.floor(Math.random() * 30)
        },
        location: {
          address: `${CITIES[i % CITIES.length]}, Palestine`,
          coordinates: {
            latitude: 31.9 + Math.random() * 1.0,
            longitude: 35.2 + Math.random() * 0.8
          }
        },
        isActive: true,
        isVerified: true,
        totalBookings: Math.floor(Math.random() * 20),
        completedBookings: Math.floor(Math.random() * 15)
      });
    }
  }
  
  try {
    await Provider.deleteMany({}); // Clear existing providers
    const createdProviders = await Provider.insertMany(providers);
    console.log(`✅ Created ${createdProviders.length} providers`);
    return createdProviders;
  } catch (error) {
    console.error('❌ Error creating providers:', error);
    throw error;
  }
}

async function linkServicesToProviders(services, providers) {
  console.log('🔄 Linking services to providers...');
  
  let linkedCount = 0;
  
  for (const service of services) {
    // Find providers that offer this service
    const matchingProviders = providers.filter(provider => 
      provider.services.includes(service.subcategory)
    );
    
    if (matchingProviders.length > 0) {
      // Randomly assign one of the matching providers to this service
      const randomProvider = matchingProviders[Math.floor(Math.random() * matchingProviders.length)];
      service.provider = randomProvider._id;
      service.location.serviceArea = randomProvider.addresses[0]?.city || 'Palestine';
      service.price.amount = randomProvider.hourlyRate;
      
      await service.save();
      linkedCount++;
    }
  }
  
  console.log(`✅ Linked ${linkedCount} services to providers`);
}

async function run() {
  console.log('🚀 Starting frontend data migration...');
  
  try {
    await connectDB();
    
    // Step 1: Create all services
    const services = await createServices();
    
    // Step 2: Create all providers
    const providers = await createProviders(services);
    
    // Step 3: Link services to providers
    await linkServicesToProviders(services, providers);
    
    console.log('\n📊 Migration Summary:');
    console.log(`- Categories: ${CATEGORIES.length}`);
    console.log(`- Services: ${services.length}`);
    console.log(`- Providers: ${providers.length}`);
    console.log('\n✅ Migration completed successfully!');
    
    console.log('\n🔐 Provider Login Credentials:');
    console.log('All providers use password: Provider123!');
    console.log('\nSample provider emails:');
    for (let i = 0; i < Math.min(5, providers.length); i++) {
      console.log(`- ${providers[i].email}`);
    }
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
  }
}

// Run if called directly
if (require.main === module) {
  run().catch(err => {
    console.error('❌ Fatal error:', err);
    process.exit(1);
  });
}

module.exports = { run, CATEGORIES, SERVICE_NAMES, PROVIDER_NAMES };
