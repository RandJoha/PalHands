const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { auth } = require('../middleware/auth');
const { authLimiter, passwordResetLimiter } = require('../middleware/rateLimiters');
const { registerValidator, loginValidator, forgotPasswordValidator, resetPasswordValidator, changePasswordDirectValidator } = require('../validators/authValidators');

// Public routes (no authentication required)
router.post('/register', registerValidator, authController.register);
router.post('/login', authLimiter, loginValidator, authController.login);
router.post('/logout', authController.logout);
// Password reset (public)
router.post('/forgot-password', passwordResetLimiter, forgotPasswordValidator, authController.forgotPassword);
router.post('/reset-password', passwordResetLimiter, resetPasswordValidator, authController.resetPassword);
// Change password directly with current password (public but verified by email+currentPassword)
router.post('/change-password-direct', passwordResetLimiter, changePasswordDirectValidator, authController.changePasswordDirect);

// Protected routes (authentication required)
router.get('/validate', auth, authController.validateToken);
router.get('/profile', auth, authController.getProfile);
// Email verification (optional)
router.post('/request-verification', auth, authController.requestVerification);
// Safer flow: GET page requires explicit user click; that page will POST to /verify
router.get('/verify/start', authController.verifyEmailStartPage);
router.post('/verify', authController.verifyEmail);
// Email change confirmation
router.get('/confirm-email-change/start', authController.confirmEmailChangeStartPage);
router.post('/confirm-email-change', authController.confirmEmailChange);

module.exports = router; 