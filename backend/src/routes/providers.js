const express = require('express');
const router = express.Router();
const providersController = require('../controllers/providersController');

// Public routes - no authentication required for browsing providers
router.get('/', providersController.listProviders);
router.get('/category/:category', providersController.getProvidersByCategory);
router.get('/:id', providersController.getProviderById);

module.exports = router;
