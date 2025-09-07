const express = require('express');
const router = express.Router();
const providersController = require('../controllers/providersController');
const { auth: authenticate, checkRole } = require('../middleware/auth');

// Public routes - no authentication required for browsing providers
router.get('/', providersController.listProviders);
router.get('/category/:category', providersController.getProvidersByCategory);
router.get('/:id', providersController.getProviderById);
router.get('/:id/services', providersController.getProviderServices);

// Provider-service management (admin or provider owner)
router.post('/:providerId/services/:serviceId/deactivate-month', authenticate, checkRole(['admin','provider']), providersController.deactivateServiceForMonth);
router.post('/:providerId/services/:serviceId/activate-month', authenticate, checkRole(['admin','provider']), providersController.activateServiceForMonth);
router.delete('/:providerId/services/:serviceId', authenticate, checkRole(['admin','provider']), providersController.unlinkServiceFromProvider);

// Provider dashboard stats (can be public for now; tighten later if needed)
router.get('/:id/bookings/stats', providersController.getProviderStats);

// Provider reviews route (clients can view provider reviews)
router.get('/:id/reviews', auth, checkRole(['client', 'admin']), providersController.getProviderReviews);

module.exports = router;
