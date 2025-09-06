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
router.get('/:id', auth, checkRole(['admin']), userController.getUserById);
router.put('/:id/status', auth, checkRole(['admin']), userController.updateUserStatus);
router.delete('/:id', auth, checkRole(['admin']), userController.deleteUser);

// Client reviews route (providers can view client reviews)
router.get('/:id/reviews', auth, checkRole(['provider', 'admin']), userController.getClientReviews);

module.exports = router; 