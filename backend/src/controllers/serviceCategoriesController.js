const { ok, error } = require('../utils/response');
const ServiceCategory = require('../models/ServiceCategory');
const Service = require('../models/Service');

// Get all categories from DB (servicecategories collection)
async function listCategories(req, res) {
  try {
    const categories = await ServiceCategory.find({ isActive: { $ne: false } })
      .sort({ sortOrder: 1, name: 1 })
      .lean();
    return ok(res, { categories, total: categories.length });
  } catch (e) {
    console.error('listCategories error', e);
    return error(res, 500, 'Failed to fetch service categories');
  }
}

// Get a specific category by ID
async function getCategoryById(req, res) {
  try {
    const { id } = req.params;
    const category = await ServiceCategory.findOne({ id }).lean();
    if (!category) return error(res, 404, 'Category not found');
    return ok(res, category);
  } catch (e) {
    console.error('getCategoryById error', e);
    return error(res, 500, 'Failed to fetch category');
  }
}

// Get categories with live service counts from services collection
async function getCategoriesWithCounts(req, res) {
  try {
    const [categories, counts] = await Promise.all([
      ServiceCategory.find({ isActive: { $ne: false } }).lean(),
      Service.aggregate([
        { $match: { isActive: true } },
        { $group: { _id: '$category', count: { $sum: 1 } } }
      ])
    ]);
    const countMap = counts.reduce((acc, c) => { acc[c._id] = c.count; return acc; }, {});
    const categoriesWithCounts = categories.map(c => ({ ...c, serviceCount: countMap[c.id] || 0 }));
    return ok(res, { categories: categoriesWithCounts, total: categoriesWithCounts.length });
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

module.exports = { listCategories, getCategoryById, getCategoriesWithCounts, getDistinctServicesByCategory };
