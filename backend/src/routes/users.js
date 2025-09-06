const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { auth, checkRole } = require('../middleware/auth');
const { updateProfileValidator, changePasswordValidator } = require('../validators/userValidators');

// User profile routes (authenticated users)
router.put('/profile', auth, updateProfileValidator, userController.updateProfile);
router.put('/change-password', auth, changePasswordValidator, userController.changePassword);

// Admin routes (admin only)
router.get('/', auth, checkRole(['admin']), userController.getAllUsers);

// Favorite providers routes (authenticated users) - MUST come before /:id routes
router.post('/favorites/:providerId', auth, userController.addToFavorites);
router.delete('/favorites/:providerId', auth, userController.removeFromFavorites);
router.get('/favorites', auth, userController.getFavoriteProviders);
router.get('/favorites/:providerId/check', auth, userController.isProviderFavorite);

// Client reviews route (providers can view client reviews)
router.get('/:id/reviews', auth, checkRole(['provider', 'admin']), userController.getClientReviews);

// Generic /:id routes (admin only) - MUST come after specific routes
router.get('/:id', auth, checkRole(['admin']), userController.getUserById);
router.put('/:id/status', auth, checkRole(['admin']), userController.updateUserStatus);
router.delete('/:id', auth, checkRole(['admin']), userController.deleteUser);

module.exports = router; 