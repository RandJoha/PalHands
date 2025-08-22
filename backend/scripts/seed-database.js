// Load environment variables first
require('dotenv').config();

// ============================================================================
// IMPORTANT: All providers will have the same password for testing purposes
// PASSWORD: password123
// ============================================================================

const mongoose = require('mongoose');
const ServiceCategory = require('../src/models/ServiceCategory');
const Service = require('../src/models/Service');
const Provider = require('../src/models/Provider');

// Database connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/palhands';

// Categories data from frontend
const categoriesData = [
  {
    id: 'cleaning',
    name: 'cleaningServices',
    icon: 'cleaning_services',
    color: '#4CAF50',
    description: 'cleaningServicesDescription',
    services: [
      'bedroomCleaning',
      'livingRoomCleaning',
      'kitchenCleaning',
      'bathroomCleaning',
      'windowCleaning',
      'doorCabinetCleaning',
      'floorCleaning',
      'carpetCleaning',
      'furnitureCleaning',
      'gardenCleaning',
      'entranceCleaning',
      'stairCleaning',
      'garageCleaning',
      'postEventCleaning',
      'postConstructionCleaning',
      'apartmentCleaning',
      'regularCleaning',
    ],
  },
  {
    id: 'organizing',
    name: 'organizingServices',
    icon: 'folder_open',
    color: '#2196F3',
    description: 'organizingServicesDescription',
    services: [
      'bedroomOrganizing',
      'kitchenOrganizing',
      'closetOrganizing',
      'storageOrganizing',
      'livingRoomOrganizing',
      'postPartyOrganizing',
      'fullHouseOrganizing',
      'childrenOrganizing',
    ],
  },
  {
    id: 'cooking',
    name: 'homeCookingServices',
    icon: 'restaurant',
    color: '#FF9800',
    description: 'homeCookingServicesDescription',
    services: [
      'mainDishes',
      'desserts',
      'specialRequests',
    ],
  },
  {
    id: 'childcare',
    name: 'childCareServices',
    icon: 'child_care',
    color: '#9C27B0',
    description: 'childCareServicesDescription',
    services: [
      'homeBabysitting',
      'schoolAccompaniment',
      'homeworkHelp',
      'educationalActivities',
      'childrenMealPrep',
      'sickChildCare',
    ],
  },
  {
    id: 'elderly',
    name: 'personalElderlyCare',
    icon: 'elderly',
    color: '#607D8B',
    description: 'personalElderlyCareDescription',
    services: [
      'homeElderlyCare',
      'medicalTransport',
      'healthMonitoring',
      'medicationAssistance',
      'emotionalSupport',
      'mobilityAssistance',
    ],
  },
  {
    id: 'maintenance',
    name: 'maintenanceRepair',
    icon: 'build',
    color: '#795548',
    description: 'maintenanceRepairDescription',
    services: [
      'electricalWork',
      'plumbingWork',
      'aluminumWork',
      'carpentryWork',
      'painting',
      'hangingItems',
      'satelliteInstallation',
      'applianceMaintenance',
    ],
  },
  {
    id: 'newhome',
    name: 'newHomeServices',
    icon: 'home',
    color: '#E91E63',
    description: 'newHomeServicesDescription',
    services: [
      'furnitureMoving',
      'packingUnpacking',
      'furnitureWrapping',
      'newHomeArrangement',
      'newApartmentCleaning',
      'preOccupancyRepairs',
      'kitchenSetup',
      'applianceInstallation',
    ],
  },
  {
    id: 'miscellaneous',
    name: 'miscellaneousErrands',
    icon: 'miscellaneous_services',
    color: '#00BCD4',
    description: 'miscellaneousErrandsDescription',
    services: [
      'documentDelivery',
      'shoppingDelivery',
      'specialErrands',
      'billPayment',
      'prescriptionPickup',
    ],
  },
];

// All service keys for provider generation
const allServices = [
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
  // Misc
  'documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup',
];

// Generate providers data
function generateProviders() {
  const providers = [];
  
  // Arabic names for variety
  const arabicNames = [
    { firstName: 'أحمد', lastName: 'محمد' },
    { firstName: 'فاطمة', lastName: 'علي' },
    { firstName: 'محمد', lastName: 'أحمد' },
    { firstName: 'عائشة', lastName: 'عمر' },
    { firstName: 'علي', lastName: 'حسن' },
    { firstName: 'خديجة', lastName: 'أبو بكر' },
    { firstName: 'عمر', lastName: 'عثمان' },
    { firstName: 'مريم', lastName: 'يوسف' },
    { firstName: 'حسن', lastName: 'علي' },
    { firstName: 'زينب', lastName: 'أحمد' }
  ];
  
  // English names for variety
  const englishNames = [
    { firstName: 'John', lastName: 'Smith' },
    { firstName: 'Sarah', lastName: 'Johnson' },
    { firstName: 'Michael', lastName: 'Brown' },
    { firstName: 'Emily', lastName: 'Davis' },
    { firstName: 'David', lastName: 'Wilson' },
    { firstName: 'Lisa', lastName: 'Anderson' },
    { firstName: 'Robert', lastName: 'Taylor' },
    { firstName: 'Jennifer', lastName: 'Martinez' },
    { firstName: 'William', lastName: 'Garcia' },
    { firstName: 'Amanda', lastName: 'Rodriguez' }
  ];
  
  // Palestinian cities
  const cities = ['Ramallah', 'Nablus', 'Bethlehem', 'Hebron', 'Jenin', 'Tulkarm', 'Qalqilya', 'Salfit', 'Jericho', 'Tubas'];
  
  // Languages
  const languages = ['Arabic', 'English', 'Hebrew'];
  
  // Services by category - using the actual service keys from categoriesData
  const servicesByCategory = {
    cleaning: ['bedroomCleaning', 'livingRoomCleaning', 'kitchenCleaning', 'bathroomCleaning', 'windowCleaning', 'carpetCleaning'],
    organizing: ['bedroomOrganizing', 'kitchenOrganizing', 'closetOrganizing', 'storageOrganizing', 'livingRoomOrganizing'],
    cooking: ['mainDishes', 'desserts', 'specialRequests'],
    childcare: ['homeBabysitting', 'schoolAccompaniment', 'homeworkHelp', 'educationalActivities', 'childrenMealPrep'],
    elderly: ['homeElderlyCare', 'medicalTransport', 'healthMonitoring', 'medicationAssistance', 'emotionalSupport'],
    maintenance: ['electricalWork', 'plumbingWork', 'aluminumWork', 'carpentryWork', 'painting'],
    newhome: ['furnitureMoving', 'packingUnpacking', 'furnitureWrapping', 'newHomeArrangement', 'kitchenSetup'],
    miscellaneous: ['documentDelivery', 'shoppingDelivery', 'specialErrands', 'billPayment', 'prescriptionPickup']
  };

  for (let i = 0; i < 79; i++) {
    const isArabic = i < 40; // First 40 are Arabic names
    const nameSet = isArabic ? arabicNames[i % arabicNames.length] : englishNames[i % englishNames.length];
    const city = cities[i % cities.length];
    const experienceYears = Math.floor(Math.random() * 15) + 1;
    const hourlyRate = Math.floor(Math.random() * 50) + 20; // 20-70 ILS per hour
    const rating = Math.random() * 2 + 3; // 3.0-5.0 rating
    
    // Generate unique email - ALWAYS use English/ASCII characters for email
    // Use a transliteration or English equivalent for Arabic names
    let emailFirstName;
    if (isArabic) {
      // Map Arabic names to English equivalents for email
      const arabicToEnglish = {
        'أحمد': 'ahmed',
        'فاطمة': 'fatima', 
        'محمد': 'mohammed',
        'عائشة': 'aisha',
        'علي': 'ali',
        'خديجة': 'khadija',
        'عمر': 'omar',
        'مريم': 'maryam',
        'حسن': 'hassan',
        'زينب': 'zainab'
      };
      emailFirstName = arabicToEnglish[nameSet.firstName] || 'provider';
    } else {
      emailFirstName = nameSet.firstName.toLowerCase();
    }
    const email = `${emailFirstName}${i}@palhands.com`;
    
    // Generate unique phone (Palestinian format)
    const phone = `059${String(i + 1000000).padStart(7, '0')}`;
    
    // Generate age (18-65)
    const age = Math.floor(Math.random() * 47) + 18;
    
    // Generate addresses
    const addresses = [
      {
        type: 'home',
        street: `${Math.floor(Math.random() * 100) + 1} Main Street`,
        city: city,
        area: `${city} Area`,
        coordinates: {
          latitude: 31.5 + (Math.random() - 0.5) * 2, // Palestine latitude range
          longitude: 35.0 + (Math.random() - 0.5) * 2 // Palestine longitude range
        },
        isDefault: true
      }
    ];
    
    // Add work address for some providers
    if (Math.random() > 0.5) {
      addresses.push({
        type: 'work',
        street: `${Math.floor(Math.random() * 100) + 1} Work Street`,
        city: city,
        area: `${city} Business District`,
        coordinates: {
          latitude: 31.5 + (Math.random() - 0.5) * 2,
          longitude: 35.0 + (Math.random() - 0.5) * 2
        },
        isDefault: false
      });
    }
    
    // Select services based on category
    const categoryKeys = Object.keys(servicesByCategory);
    const selectedCategory = categoryKeys[i % categoryKeys.length];
    const selectedServices = servicesByCategory[selectedCategory];
    const numServices = Math.floor(Math.random() * 3) + 1; // 1-3 services
    const services = [];
    
    for (let j = 0; j < numServices; j++) {
      const service = selectedServices[j % selectedServices.length];
      if (!services.includes(service)) {
        services.push(service);
      }
    }
    
    // Generate languages (1-2 languages)
    const numLanguages = Math.floor(Math.random() * 2) + 1;
    const selectedLanguages = [];
    for (let j = 0; j < numLanguages; j++) {
      const language = languages[j % languages.length];
      if (!selectedLanguages.includes(language)) {
        selectedLanguages.push(language);
      }
    }
    
    // Use plain text password - bcrypt will hash it automatically
    const password = 'password123'; // All providers will have the same password
    
    const provider = {
      firstName: nameSet.firstName,
      lastName: nameSet.lastName,
      email: email,
      password: password,
      role: 'provider',
      phone: phone,
      profileImage: null,
      age: age,
      addresses: addresses,
      experienceYears: experienceYears,
      languages: selectedLanguages,
      hourlyRate: hourlyRate,
      services: services,
      rating: {
        average: parseFloat(rating.toFixed(1)),
        count: Math.floor(Math.random() * 50) + 5
      },
      location: {
        address: addresses[0].street + ', ' + addresses[0].city,
        coordinates: addresses[0].coordinates
      },
      isActive: true,
      isVerified: Math.random() > 0.2, // 80% verified
      totalBookings: Math.floor(Math.random() * 100) + 10,
      completedBookings: Math.floor(Math.random() * 80) + 5,
      // Email verification fields
      emailVerificationToken: null,
      emailVerificationExpires: null,
      pendingEmail: null,
      emailChangeToken: null,
      emailChangeExpires: null,
      passwordResetToken: null,
      passwordResetTokenHash: null,
      passwordResetExpires: null
    };
    
    providers.push(provider);
  }
  
  return providers;
}

// Generate services data
function generateServices(providers) {
  const services = [];
  
  // Create services for each provider
  providers.forEach((provider, index) => {
    // Get the city from the default address
    const city = provider.addresses.find(addr => addr.isDefault)?.city || provider.addresses[0]?.city || 'Unknown City';
    
    provider.services.forEach((serviceKey, serviceIndex) => {
      const category = getCategoryForService(serviceKey);
      if (category) {
        services.push({
          title: getServiceTitle(serviceKey),
          description: getServiceDescription(serviceKey),
          category: category.id,
          subcategory: serviceKey,
          provider: provider._id, // Will be set after provider creation
          price: {
            amount: provider.hourlyRate,
            type: 'hourly',
            currency: 'ILS'
          },
          duration: {
            estimated: 60,
            flexible: true
          },
          availability: {
            days: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'],
            timeSlots: [
              { start: '08:00', end: '18:00' }
            ],
            flexible: true
          },
          location: {
            serviceArea: city,
            radius: 15,
            onSite: true,
            remote: false
          },
          rating: {
            average: provider.rating.average,
            count: provider.rating.count
          },
          totalBookings: provider.totalBookings,
          isActive: true,
          featured: Math.random() > 0.7 // 30% chance of being featured
        });
      }
    });
  });
  
  return services;
}

// Helper function to get category for a service
function getCategoryForService(serviceKey) {
  return categoriesData.find(category => 
    category.services.includes(serviceKey)
  );
}

// Helper function to get service title
function getServiceTitle(serviceKey) {
  const titles = {
    'bedroomCleaning': 'Bedroom Cleaning',
    'livingRoomCleaning': 'Living Room Cleaning',
    'kitchenCleaning': 'Kitchen Cleaning',
    'bathroomCleaning': 'Bathroom Cleaning',
    'windowCleaning': 'Window Cleaning',
    'doorCabinetCleaning': 'Door & Cabinet Cleaning',
    'floorCleaning': 'Floor Cleaning',
    'carpetCleaning': 'Carpet Cleaning',
    'furnitureCleaning': 'Furniture Cleaning',
    'gardenCleaning': 'Garden Cleaning',
    'entranceCleaning': 'Entrance Cleaning',
    'stairCleaning': 'Stair Cleaning',
    'garageCleaning': 'Garage Cleaning',
    'postEventCleaning': 'Post-Event Cleaning',
    'postConstructionCleaning': 'Post-Construction Cleaning',
    'apartmentCleaning': 'Apartment Cleaning',
    'regularCleaning': 'Regular Cleaning',
    'bedroomOrganizing': 'Bedroom Organizing',
    'kitchenOrganizing': 'Kitchen Organizing',
    'closetOrganizing': 'Closet Organizing',
    'storageOrganizing': 'Storage Organizing',
    'livingRoomOrganizing': 'Living Room Organizing',
    'postPartyOrganizing': 'Post-Party Organizing',
    'fullHouseOrganizing': 'Full House Organizing',
    'childrenOrganizing': 'Children Room Organizing',
    'mainDishes': 'Main Dishes',
    'desserts': 'Desserts',
    'specialRequests': 'Special Cooking Requests',
    'homeBabysitting': 'Home Babysitting',
    'schoolAccompaniment': 'School Accompaniment',
    'homeworkHelp': 'Homework Help',
    'educationalActivities': 'Educational Activities',
    'childrenMealPrep': 'Children Meal Preparation',
    'sickChildCare': 'Sick Child Care',
    'homeElderlyCare': 'Home Elderly Care',
    'medicalTransport': 'Medical Transportation',
    'healthMonitoring': 'Health Monitoring',
    'medicationAssistance': 'Medication Assistance',
    'emotionalSupport': 'Emotional Support',
    'mobilityAssistance': 'Mobility Assistance',
    'electricalWork': 'Electrical Work',
    'plumbingWork': 'Plumbing Work',
    'aluminumWork': 'Aluminum Work',
    'carpentryWork': 'Carpentry Work',
    'painting': 'Painting',
    'hangingItems': 'Hanging Items',
    'satelliteInstallation': 'Satellite Installation',
    'applianceMaintenance': 'Appliance Maintenance',
    'furnitureMoving': 'Furniture Moving',
    'packingUnpacking': 'Packing & Unpacking',
    'furnitureWrapping': 'Furniture Wrapping',
    'newHomeArrangement': 'New Home Arrangement',
    'newApartmentCleaning': 'New Apartment Cleaning',
    'preOccupancyRepairs': 'Pre-Occupancy Repairs',
    'kitchenSetup': 'Kitchen Setup',
    'applianceInstallation': 'Appliance Installation',
    'documentDelivery': 'Document Delivery',
    'shoppingDelivery': 'Shopping Delivery',
    'specialErrands': 'Special Errands',
    'billPayment': 'Bill Payment',
    'prescriptionPickup': 'Prescription Pickup'
  };
  
  return titles[serviceKey] || serviceKey;
}

// Helper function to get service description
function getServiceDescription(serviceKey) {
  const descriptions = {
    'bedroomCleaning': 'Professional bedroom cleaning service including dusting, vacuuming, and sanitizing',
    'livingRoomCleaning': 'Comprehensive living room cleaning with attention to detail',
    'kitchenCleaning': 'Deep kitchen cleaning including appliances, countertops, and cabinets',
    'bathroomCleaning': 'Thorough bathroom cleaning and sanitization',
    'windowCleaning': 'Professional window cleaning for crystal clear views',
    'doorCabinetCleaning': 'Detailed cleaning of doors and cabinets',
    'floorCleaning': 'Complete floor cleaning and maintenance',
    'carpetCleaning': 'Deep carpet cleaning and stain removal',
    'furnitureCleaning': 'Professional furniture cleaning and care',
    'gardenCleaning': 'Garden maintenance and cleaning services',
    'entranceCleaning': 'Entrance area cleaning and maintenance',
    'stairCleaning': 'Stair cleaning and maintenance',
    'garageCleaning': 'Comprehensive garage cleaning and organization',
    'postEventCleaning': 'Post-event cleanup and restoration',
    'postConstructionCleaning': 'Post-construction cleanup and detailing',
    'apartmentCleaning': 'Complete apartment cleaning service',
    'regularCleaning': 'Regular maintenance cleaning service',
    'bedroomOrganizing': 'Bedroom organization and decluttering',
    'kitchenOrganizing': 'Kitchen organization and storage optimization',
    'closetOrganizing': 'Closet organization and space maximization',
    'storageOrganizing': 'Storage space organization and optimization',
    'livingRoomOrganizing': 'Living room organization and arrangement',
    'postPartyOrganizing': 'Post-party cleanup and organization',
    'fullHouseOrganizing': 'Complete house organization service',
    'childrenOrganizing': 'Children room organization and toy management',
    'mainDishes': 'Home-cooked main dishes preparation',
    'desserts': 'Delicious dessert preparation',
    'specialRequests': 'Custom cooking requests and special meals',
    'homeBabysitting': 'Professional in-home childcare service',
    'schoolAccompaniment': 'Safe school transportation and accompaniment',
    'homeworkHelp': 'Educational support and homework assistance',
    'educationalActivities': 'Engaging educational activities for children',
    'childrenMealPrep': 'Healthy meal preparation for children',
    'sickChildCare': 'Compassionate care for sick children',
    'homeElderlyCare': 'Professional elderly care and support',
    'medicalTransport': 'Safe medical transportation service',
    'healthMonitoring': 'Regular health monitoring and check-ins',
    'medicationAssistance': 'Medication management and assistance',
    'emotionalSupport': 'Compassionate emotional support and companionship',
    'mobilityAssistance': 'Mobility support and assistance',
    'electricalWork': 'Professional electrical work and repairs',
    'plumbingWork': 'Expert plumbing services and repairs',
    'aluminumWork': 'Professional aluminum work and installation',
    'carpentryWork': 'Quality carpentry and woodwork',
    'painting': 'Professional painting services',
    'hangingItems': 'Safe hanging and installation of items',
    'satelliteInstallation': 'Professional satellite installation',
    'applianceMaintenance': 'Appliance maintenance and repair',
    'furnitureMoving': 'Safe and professional furniture moving',
    'packingUnpacking': 'Efficient packing and unpacking services',
    'furnitureWrapping': 'Professional furniture protection and wrapping',
    'newHomeArrangement': 'New home setup and arrangement',
    'newApartmentCleaning': 'New apartment preparation and cleaning',
    'preOccupancyRepairs': 'Pre-occupancy repairs and maintenance',
    'kitchenSetup': 'Complete kitchen setup and organization',
    'applianceInstallation': 'Professional appliance installation',
    'documentDelivery': 'Secure document delivery service',
    'shoppingDelivery': 'Reliable shopping and delivery service',
    'specialErrands': 'Custom errand running service',
    'billPayment': 'Convenient bill payment service',
    'prescriptionPickup': 'Prescription pickup and delivery'
  };
  
  return descriptions[serviceKey] || 'Professional service with attention to detail';
}

async function seedDatabase() {
  try {
    console.log('🌱 Starting database seeding...');
    
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    // Clear existing data
    console.log('🧹 Clearing existing data...');
    await ServiceCategory.deleteMany({});
    await Provider.deleteMany({});
    await Service.deleteMany({});
    console.log('✅ Existing data cleared');
    
    // Seed categories
    console.log('📂 Seeding service categories...');
    const categories = await ServiceCategory.insertMany(categoriesData);
    console.log(`✅ ${categories.length} categories seeded`);
    
    // Seed providers
    console.log('👥 Seeding providers...');
    const providersData = generateProviders();
    const providers = await Provider.insertMany(providersData);
    console.log(`✅ ${providers.length} providers seeded`);
    
    // Seed services
    console.log('🔧 Seeding services...');
    const servicesData = generateServices(providers);
    const services = await Service.insertMany(servicesData);
    console.log(`✅ ${services.length} services seeded`);
    
    console.log('🎉 Database seeding completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - Categories: ${categories.length}`);
    console.log(`   - Providers: ${providers.length}`);
    console.log(`   - Services: ${services.length}`);
    
  } catch (error) {
    console.error('❌ Error seeding database:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Run seeding if called directly
if (require.main === module) {
  seedDatabase();
}

module.exports = { seedDatabase };
