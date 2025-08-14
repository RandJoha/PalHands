const jwt = require('jsonwebtoken');
const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const { ok, created, error } = require('../utils/response');
const { sendEmail } = require('../services/mailer');

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

// Helper to create a verification token (dev-only flow)
const crypto = require('crypto');

// Register new user
const register = asyncHandler(async (req, res) => {
    const { firstName, lastName = '', email, phone, password, role = 'client' } = req.body;

    // Validate required fields and provide specific error messages
    const missingFields = [];
    if (!firstName) missingFields.push('firstName');
    if (!email) missingFields.push('email');
    if (!phone) missingFields.push('phone');
    if (!password) missingFields.push('password');
    
    if (missingFields.length > 0) {
      return error(res, 400, `Missing required fields: ${missingFields.join(', ')}`, [], 'VALIDATION_ERROR');
    }

    // Validate role
    const validRoles = ['client', 'provider', 'admin'];
    if (!validRoles.includes(role)) {
      return error(res, 400, 'Invalid role. Must be client, provider, or admin', [], 'VALIDATION_ERROR');
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email: email.toLowerCase() }, { phone }]
    });

    if (existingUser) {
      return error(res, 400, existingUser.email === email.toLowerCase() ? 'Email already registered' : 'Phone number already registered', [], 'CONFLICT');
    }

    // Create new user
    const user = new User({
      firstName,
      lastName,
      email: email.toLowerCase(),
      phone,
      password,
      role
    });

    // If email verification enabled, set token (email sending can be added later)
    if (process.env.ENABLE_EMAIL_VERIFICATION === 'true') {
      user.emailVerificationToken = crypto.randomBytes(20).toString('hex');
      user.emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h
    }

    await user.save();

    // Generate token
    const token = generateToken(user._id);

    // Return user data (without password)
    const userResponse = {
      _id: user._id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      profileImage: user.profileImage,
      address: user.address,
      isVerified: user.isVerified,
      isActive: user.isActive,
      rating: user.rating,
      createdAt: user.createdAt
    };

  return created(res, { token, user: userResponse, ...(user.emailVerificationToken && { verificationToken: user.emailVerificationToken }) }, 'User registered successfully');
});

// Login user
const login = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    // Validate required fields
    if (!email || !password) {
      return error(res, 400, 'Email and password are required', [], 'VALIDATION_ERROR');
    }

    // Find user by email
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return error(res, 401, 'Invalid email or password', [], 'UNAUTHORIZED');
    }

    // Check if user is active
    if (!user.isActive) {
      return error(res, 401, 'Account is deactivated', [], 'UNAUTHORIZED');
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return error(res, 401, 'Invalid email or password', [], 'UNAUTHORIZED');
    }

    // Generate token
    const token = generateToken(user._id);

    // Return user data (without password)
    const userResponse = {
      _id: user._id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      profileImage: user.profileImage,
      address: user.address,
      isVerified: user.isVerified,
      isActive: user.isActive,
      rating: user.rating,
      createdAt: user.createdAt
    };

  return ok(res, { token, user: userResponse }, 'Login successful');
});

// Validate token
const validateToken = asyncHandler(async (req, res) => {
    // User is already verified by auth middleware
    const user = req.user;

    return ok(res, {
      valid: true,
      user: {
        _id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profileImage: user.profileImage,
        address: user.address,
        isVerified: user.isVerified,
        isActive: user.isActive,
        rating: user.rating,
        createdAt: user.createdAt
      }
    }, 'Token valid');
});

// Logout user (client-side token removal)
const logout = asyncHandler(async (req, res) => {
    // In a stateless JWT system, logout is handled client-side
    // You could implement a blacklist here if needed
  return ok(res, {}, 'Logout successful');
});

// Get current user profile
const getProfile = asyncHandler(async (req, res) => {
    const user = req.user;
    return ok(res, {
      _id: user._id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      profileImage: user.profileImage,
      address: user.address,
      isVerified: user.isVerified,
      isActive: user.isActive,
      rating: user.rating,
      createdAt: user.createdAt
    }, 'Profile fetched');
});

module.exports = {
  register,
  login,
  validateToken,
  logout,
  getProfile,
  // Forgot password: issue reset token and email it
  forgotPassword: asyncHandler(async (req, res) => {
    const { email } = req.body;
    if (!email) return error(res, 400, 'Email is required');
    const user = await User.findOne({ email: email.toLowerCase() });
    // Do not reveal whether the email exists
    if (!user) return ok(res, {}, 'If the email exists, a reset link has been sent');
    user.passwordResetToken = require('crypto').randomBytes(20).toString('hex');
    user.passwordResetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1h
    await user.save();
    const resetUrl = `${process.env.APP_BASE_URL || 'http://localhost:3000'}/reset-password?token=${user.passwordResetToken}`;
    await sendEmail({
      to: user.email,
      subject: 'Reset your PalHands password',
      text: `Use this token to reset your password: ${user.passwordResetToken}. Or open ${resetUrl}`,
      html: `<p>Use this token to reset your password:</p><p><b>${user.passwordResetToken}</b></p><p>Or open <a href="${resetUrl}">${resetUrl}</a></p>`
    });
    return ok(res, {}, 'If the email exists, a reset link has been sent');
  }),
  // Reset password with token
  resetPassword: asyncHandler(async (req, res) => {
    const { token, newPassword } = req.body;
    if (!token || !newPassword) return error(res, 400, 'Token and newPassword are required');
    const user = await User.findOne({ passwordResetToken: token, passwordResetExpires: { $gt: new Date() } });
    if (!user) return error(res, 400, 'Invalid or expired token');
    user.password = newPassword;
    user.passwordResetToken = null;
    user.passwordResetExpires = null;
    await user.save();
    return ok(res, {}, 'Password has been reset');
  }),
  // Issue a verification token (dev/simple flow)
  requestVerification: asyncHandler(async (req, res) => {
    if (process.env.ENABLE_EMAIL_VERIFICATION !== 'true') {
      return error(res, 400, 'Email verification is disabled');
    }
    const user = await User.findById(req.user._id);
    if (!user) return error(res, 404, 'User not found');
    if (user.isVerified) return ok(res, {}, 'Already verified');
    user.emailVerificationToken = require('crypto').randomBytes(20).toString('hex');
    user.emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);
    await user.save();
    return ok(res, { verificationToken: user.emailVerificationToken }, 'Verification token issued');
  }),
  // Verify email with token
  verifyEmail: asyncHandler(async (req, res) => {
    if (process.env.ENABLE_EMAIL_VERIFICATION !== 'true') {
      return error(res, 400, 'Email verification is disabled');
    }
    const token = req.body.token || req.query.token;
    if (!token) return error(res, 400, 'Missing token');
    const user = await User.findOne({
      emailVerificationToken: token,
      emailVerificationExpires: { $gt: new Date() }
    });
    if (!user) return error(res, 400, 'Invalid or expired token');
    user.isVerified = true;
    user.emailVerificationToken = null;
    user.emailVerificationExpires = null;
    await user.save();
    return ok(res, {}, 'Email verified');
  })
}; 