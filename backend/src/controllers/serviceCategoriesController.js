const { ok, error, created } = require('../utils/response');
const ServiceCategory = require('../models/ServiceCategory');
const Service = require('../models/Service');

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
 * Get all service categories (including dynamic ones from database)
 */
async function listCategories(req, res) {
  try {
    // Get all unique categories from services in the database
    const dbCategories = await Service.aggregate([
      { $match: { isActive: true } },
      { $group: { _id: '$category', count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);
    
    // Get all categories from ServiceCategory collection
    const storedCategories = await ServiceCategory.find({ isActive: true });
    
    // Start with predefined categories
    const allCategories = [...SERVICE_CATEGORIES];
    
    // Add stored categories from database
    const predefinedIds = new Set(SERVICE_CATEGORIES.map(cat => cat.id));
    const storedCategoryIds = new Set(storedCategories.map(cat => cat.id));
    
    // Add stored categories that aren't predefined
    const storedDynamicCategories = storedCategories
      .filter(cat => !predefinedIds.has(cat.id))
      .map(cat => ({
        id: cat.id,
        name: cat.name,
        nameKey: cat.nameKey,
        description: cat.description,
        icon: cat.icon,
        color: cat.color,
        services: cat.services,
        isDynamic: cat.isDynamic
      }));
    
    allCategories.push(...storedDynamicCategories);
    
    // Add service-based categories that aren't in predefined or stored lists
    const allCategoryIds = new Set([...predefinedIds, ...storedCategoryIds]);
    const serviceBasedCategories = dbCategories
      .filter(item => !allCategoryIds.has(item._id))
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
    
    // Combine all categories
    allCategories.push(...serviceBasedCategories);
    
    return ok(res, {
      categories: allCategories,
      total: allCategories.length
    });
  } catch (e) {
    console.error('listCategories error', e);
    return error(res, 500, 'Failed to fetch service categories');
  }
}

/**
 * Get a specific category by ID (including dynamic categories)
 */
async function getCategoryById(req, res) {
  try {
    const { id } = req.params;
    
    // First check predefined categories
    let category = SERVICE_CATEGORIES.find(cat => cat.id === id);
    
    // If not found in predefined, check if it's a dynamic category from database
    if (!category) {
      const serviceCount = await Service.countDocuments({ category: id, isActive: true });
      
      if (serviceCount > 0) {
        // Create dynamic category
        category = {
          id: id,
          name: id.charAt(0).toUpperCase() + id.slice(1) + ' Services',
          nameKey: id + 'Services',
          description: `Services in the ${id} category`,
          icon: 'category',
          color: '#9E9E9E',
          services: [],
          isDynamic: true
        };
      }
    }
    
    if (!category) {
      return error(res, 404, 'Category not found');
    }
    
    return ok(res, category);
  } catch (e) {
    console.error('getCategoryById error', e);
    return error(res, 500, 'Failed to fetch category');
  }
}

// Get categories with live service counts from services collection
async function getCategoriesWithCounts(req, res) {
  try {
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

// New: return distinct service subcategories for a given category from services collection
async function getDistinctServicesByCategory(req, res) {
  try {
    const { id } = req.params; // category id
    if (!id) return error(res, 400, 'Category id is required');
    const subcategories = await Service.distinct('subcategory', { category: id, isActive: true });
    // Filter out empty/null
    const items = subcategories.filter(Boolean).sort();
    return ok(res, { category: id, services: items, total: items.length });
  } catch (e) {
    console.error('getDistinctServicesByCategory error', e);
    return error(res, 500, 'Failed to fetch services for category');
  }
}

/**
 * Get categories with their actual services from the database
 */
async function getCategoriesWithServices(req, res) {
  try {
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

/**
 * Create a new service category (admin only)
 */
async function createCategory(req, res) {
  try {
    const { name, description, icon, color } = req.body;
    
    // Generate ID from name (lowercase, replace spaces with underscores)
    const id = name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '');
    const nameKey = id + 'Services';
    
    // Check if category already exists
    const existingCategory = await ServiceCategory.findOne({ id });
    if (existingCategory) {
      return error(res, 400, 'Category with this name already exists');
    }
    
    const categoryData = {
      id,
      name,
      nameKey,
      description: description || `Services in the ${name} category`,
      icon: icon || 'category',
      color: color || '#9E9E9E',
      services: [],
      isDynamic: true,
      isActive: true
    };
    
    const category = await ServiceCategory.create(categoryData);
    
    return created(res, category, 'Category created successfully');
  } catch (e) {
    console.error('createCategory error', e);
    return error(res, 400, e.message || 'Failed to create category');
  }
}

module.exports = {
  listCategories,
  getCategoryById,
  getCategoriesWithCounts,
  getDistinctServicesByCategory,
  getCategoriesWithServices,
  createCategory
};
