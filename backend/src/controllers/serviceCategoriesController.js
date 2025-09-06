const { ok, error } = require('../utils/response');

// Categories data for the frontend
const SERVICE_CATEGORIES = [
  {
    id: 'cleaning',
    name: 'Cleaning Services',
    nameKey: 'cleaningServices',
    description: 'Professional cleaning services for your home',
    icon: 'cleaning_services',
    color: '#4CAF50',
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
    icon: 'folder_open',
    color: '#2196F3',
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
    icon: 'restaurant',
    color: '#FF9800',
    services: [
      'mainDishes', 'desserts', 'specialRequests'
    ]
  },
  {
    id: 'childcare',
    name: 'Child Care Services',
    nameKey: 'childCareServices',
    description: 'Professional childcare services',
    icon: 'child_care',
    color: '#E91E63',
    services: [
      'homeBabysitting', 'schoolAccompaniment', 'homeworkHelp', 
      'educationalActivities', 'childrenMealPrep', 'sickChildCare'
    ]
  },
  {
    id: 'elderly',
    name: 'Personal & Elderly Care',
    nameKey: 'personalElderlyCareServices',
    description: 'Compassionate care for elderly individuals',
    icon: 'elderly',
    color: '#9C27B0',
    services: [
      'personalCare', 'companionship', 'medicationReminders', 
      'lightHousekeeping', 'mealPreparation', 'transportationAssistance'
    ]
  },
  {
    id: 'maintenance',
    name: 'Home Maintenance',
    nameKey: 'homeMaintenanceServices',
    description: 'Professional home maintenance and repair services',
    icon: 'handyman',
    color: '#795548',
    services: [
      'generalRepairs', 'plumbing', 'electrical', 'painting',
      'furnitureAssembly', 'applianceInstallation'
    ]
  },
  {
    id: 'newhome',
    name: 'New Home Setup',
    nameKey: 'newHomeSetupServices',
    description: 'Complete setup services for your new home',
    icon: 'home',
    color: '#607D8B',
    services: [
      'movingIn', 'unpacking', 'organizing', 'deepCleaning',
      'furnitureArrangement', 'kitchenSetup'
    ]
  },
  {
    id: 'miscellaneous',
    name: 'Miscellaneous Services',
    nameKey: 'miscellaneousServices',
    description: 'Various other helpful services',
    icon: 'miscellaneous_services',
    color: '#9E9E9E',
    services: [
      'petCare', 'gardenWork', 'eventPreparation', 'specialProjects'
    ]
  }
];

/**
 * Get all service categories
 */
async function listCategories(req, res) {
  try {
    return ok(res, {
      categories: SERVICE_CATEGORIES,
      total: SERVICE_CATEGORIES.length
    });
  } catch (e) {
    console.error('listCategories error', e);
    return error(res, 500, 'Failed to fetch service categories');
  }
}

/**
 * Get a specific category by ID
 */
async function getCategoryById(req, res) {
  try {
    const { id } = req.params;
    const category = SERVICE_CATEGORIES.find(cat => cat.id === id);
    
    if (!category) {
      return error(res, 404, 'Category not found');
    }
    
    return ok(res, category);
  } catch (e) {
    console.error('getCategoryById error', e);
    return error(res, 500, 'Failed to fetch category');
  }
}

/**
 * Get categories with service counts from the database
 */
async function getCategoriesWithCounts(req, res) {
  try {
    const Service = require('../models/Service');
    
    // Get all unique categories from services in the database
    const dbCategories = await Service.aggregate([
      { $match: { isActive: true } },
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    
    // Create a map for quick lookup
    const countMap = dbCategories.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {});
    
    // Start with predefined categories
    const allCategories = [...SERVICE_CATEGORIES];
    
    // Add dynamic categories from database that aren't in predefined list
    const predefinedIds = new Set(SERVICE_CATEGORIES.map(cat => cat.id));
    const dynamicCategories = dbCategories
      .filter(item => !predefinedIds.has(item._id))
      .map(item => ({
        id: item._id,
        name: item._id.charAt(0).toUpperCase() + item._id.slice(1) + ' Services',
        nameKey: item._id + 'Services',
        description: `Services in the ${item._id} category`,
        icon: 'category',
        color: '#9E9E9E', // Default gray color for dynamic categories
        services: [], // Will be populated with actual services
        isDynamic: true
      }));
    
    // Combine predefined and dynamic categories
    allCategories.push(...dynamicCategories);
    
    // Add counts to all categories
    const categoriesWithCounts = allCategories.map(category => ({
      ...category,
      serviceCount: countMap[category.id] || 0
    }));
    
    return ok(res, {
      categories: categoriesWithCounts,
      total: categoriesWithCounts.length
    });
  } catch (e) {
    console.error('getCategoriesWithCounts error', e);
    return error(res, 500, 'Failed to fetch categories with counts');
  }
}

/**
 * Get categories with their actual services from the database
 */
async function getCategoriesWithServices(req, res) {
  try {
    const Service = require('../models/Service');
    
    // Get all unique categories from services in the database
    const dbCategories = await Service.aggregate([
      { $match: { isActive: true } },
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    
    // Get actual services for each category
    const categoriesWithServices = await Promise.all(
      dbCategories.map(async (cat) => {
        const services = await Service.find(
          { category: cat._id, isActive: true },
          { title: 1, description: 1, category: 1, subcategory: 1, price: 1, rating: 1, provider: 1 }
        ).populate('provider', 'fullName email phone')
         .limit(20); // Limit services per category for performance
        
        // Find predefined category or create dynamic one
        const predefinedCategory = SERVICE_CATEGORIES.find(c => c.id === cat._id);
        const categoryData = predefinedCategory || {
          id: cat._id,
          name: cat._id.charAt(0).toUpperCase() + cat._id.slice(1) + ' Services',
          nameKey: cat._id + 'Services',
          description: `Services in the ${cat._id} category`,
          icon: 'category',
          color: '#9E9E9E',
          services: [],
          isDynamic: true
        };
        
        return {
          ...categoryData,
          serviceCount: cat.count,
          actualServices: services
        };
      })
    );
    
    return ok(res, {
      categories: categoriesWithServices,
      total: categoriesWithServices.length
    });
  } catch (e) {
    console.error('getCategoriesWithServices error', e);
    return error(res, 500, 'Failed to fetch categories with services');
  }
}

module.exports = {
  listCategories,
  getCategoryById,
  getCategoriesWithCounts,
  getCategoriesWithServices
};
