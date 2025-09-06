const express = require('express');
const router = express.Router();
const serviceCategoriesController = require('../controllers/serviceCategoriesController');

// Public routes - no authentication required for browsing categories
router.get('/', serviceCategoriesController.listCategories);
router.get('/counts', serviceCategoriesController.getCategoriesWithCounts);
router.get('/with-services', serviceCategoriesController.getCategoriesWithServices);
router.get('/:id', serviceCategoriesController.getCategoryById);

module.exports = router;
