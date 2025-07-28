const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

// Register new user
const register = async (req, res) => {
  try {
    const { firstName, lastName = '', email, phone, password, role = 'client' } = req.body;

    // Validate required fields and provide specific error messages
    const missingFields = [];
    if (!firstName) missingFields.push('firstName');
    if (!email) missingFields.push('email');
    if (!phone) missingFields.push('phone');
    if (!password) missingFields.push('password');
    
    if (missingFields.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Missing required fields: ${missingFields.join(', ')}`
      });
    }

    // Validate role
    const validRoles = ['client', 'provider', 'admin'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid role. Must be client, provider, or admin'
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email: email.toLowerCase() }, { phone }]
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: existingUser.email === email.toLowerCase() 
          ? 'Email already registered' 
          : 'Phone number already registered'
      });
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

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user: userResponse
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Login user
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate required fields
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Find user by email
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
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

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: userResponse
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Validate token
const validateToken = async (req, res) => {
  try {
    // User is already verified by auth middleware
    const user = req.user;

    res.json({
      success: true,
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
    });

  } catch (error) {
    console.error('Token validation error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Logout user (client-side token removal)
const logout = async (req, res) => {
  try {
    // In a stateless JWT system, logout is handled client-side
    // You could implement a blacklist here if needed
    res.json({
      success: true,
      message: 'Logout successful'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get current user profile
const getProfile = async (req, res) => {
  try {
    const user = req.user;

    res.json({
      success: true,
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
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

module.exports = {
  register,
  login,
  validateToken,
  logout,
  getProfile
}; 