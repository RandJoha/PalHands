const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { auth: authenticate, checkRole } = require('../middleware/auth');
const { updateProfileValidator, changePasswordValidator } = require('../validators/userValidators');

// User profile routes (authenticated users)
router.put('/profile', authenticate, updateProfileValidator, userController.updateProfile);
router.put('/change-password', authenticate, changePasswordValidator, userController.changePassword);

// Admin routes (admin only)
router.get('/', authenticate, checkRole(['admin']), userController.getAllUsers);

// Favorite providers routes (authenticated users) - MUST come before /:id routes
router.post('/favorites/:providerId', authenticate, userController.addToFavorites);
router.delete('/favorites/:providerId', authenticate, userController.removeFromFavorites);
router.get('/favorites', authenticate, userController.getFavoriteProviders);
router.get('/favorites/:providerId/check', authenticate, userController.isProviderFavorite);

// Client reviews route (providers can view client reviews)
router.get('/:id/reviews', authenticate, checkRole(['provider', 'admin']), userController.getClientReviews);

// Generic /:id routes (admin only) - MUST come after specific routes
router.get('/:id', authenticate, checkRole(['admin']), userController.getUserById);
router.put('/:id/status', authenticate, checkRole(['admin']), userController.updateUserStatus);
router.delete('/:id', authenticate, checkRole(['admin']), userController.deleteUser);

module.exports = router; 