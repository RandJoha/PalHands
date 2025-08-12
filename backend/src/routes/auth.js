const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { auth } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiters');
const { registerValidator, loginValidator } = require('../validators/authValidators');

// Public routes (no authentication required)
router.post('/register', registerValidator, authController.register);
router.post('/login', authLimiter, loginValidator, authController.login);
router.post('/logout', authController.logout);

// Protected routes (authentication required)
router.get('/validate', auth, authController.validateToken);
router.get('/profile', auth, authController.getProfile);
// Email verification (optional)
router.post('/request-verification', auth, authController.requestVerification);
router.post('/verify', authController.verifyEmail);

module.exports = router; 