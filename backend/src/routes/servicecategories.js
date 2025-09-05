const express = require('express');
const router = express.Router();
const serviceCategoriesController = require('../controllers/serviceCategoriesController');

// Public routes - no authentication required for browsing categories
router.get('/', serviceCategoriesController.listCategories);
router.get('/counts', serviceCategoriesController.getCategoriesWithCounts);
router.get('/:id', serviceCategoriesController.getCategoryById);
// Distinct service keys for a category (from services collection)
router.get('/:id/services', serviceCategoriesController.getDistinctServicesByCategory);

module.exports = router;
