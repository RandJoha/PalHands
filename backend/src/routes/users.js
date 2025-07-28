const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { auth, checkRole } = require('../middleware/auth');

// User profile routes (authenticated users)
router.put('/profile', auth, userController.updateProfile);
router.put('/change-password', auth, userController.changePassword);

// Admin routes (admin only)
router.get('/', auth, checkRole(['admin']), userController.getAllUsers);
router.get('/:id', auth, checkRole(['admin']), userController.getUserById);
router.put('/:id/status', auth, checkRole(['admin']), userController.updateUserStatus);
router.delete('/:id', auth, checkRole(['admin']), userController.deleteUser);

module.exports = router; 