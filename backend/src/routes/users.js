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
router.get('/:id', authenticate, checkRole(['admin']), userController.getUserById);
router.put('/:id/status', authenticate, checkRole(['admin']), userController.updateUserStatus);
router.delete('/:id', authenticate, checkRole(['admin']), userController.deleteUser);

module.exports = router; 