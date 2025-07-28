const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { auth } = require('../middleware/auth');

// Public routes (no authentication required)
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/logout', authController.logout);

// Protected routes (authentication required)
router.get('/validate', auth, authController.validateToken);
router.get('/profile', auth, authController.getProfile);

module.exports = router; 