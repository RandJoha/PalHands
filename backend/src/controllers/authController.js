const jwt = require('jsonwebtoken');
const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const { ok, created, error } = require('../utils/response');

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

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

  return created(res, { token, user: userResponse }, 'User registered successfully');
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
  getProfile
}; 