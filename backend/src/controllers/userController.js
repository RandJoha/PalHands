const User = require('../models/User');
const Provider = require('../models/Provider');
const SavedProvider = require('../models/SavedProvider');
const asyncHandler = require('../utils/asyncHandler');
const { ok, created, error } = require('../utils/response');

// Update user profile
// City normalization helper to keep alignment with FE predefined list
const ALLOWED_CITIES = new Set([
  'jerusalem','ramallah','nablus','hebron','bethlehem','jericho','tulkarm','qalqilya','jenin','salfit','tubas','gaza','rafah','khan yunis','deir al-balah','north gaza'
]);

const normalizeCity = (c) => {
  if (!c) return '';
  const v = String(c).toLowerCase().trim();
  return ALLOWED_CITIES.has(v) ? v : v; // allow passthrough; validator will enforce when provided
};

const updateProfile = asyncHandler(async (req, res) => {
  const { firstName, lastName, phone, address, addresses, profileImage, email, age } = req.body;
    const userId = req.user._id;

    // Find user
    const user = await User.findById(userId);
  if (!user) return error(res, 404, 'User not found', [], 'NOT_FOUND');

    // Update fields if provided
    if (firstName) user.firstName = firstName;
    if (lastName) user.lastName = lastName;
    if (phone) {
      // Check if phone is already taken by another user
      const existingUser = await User.findOne({ phone, _id: { $ne: userId } });
  if (existingUser) return error(res, 400, 'Phone number already registered', [], 'CONFLICT');
      user.phone = phone;
    }
    if (typeof age !== 'undefined') {
      user.age = age;
    }
    if (email && email.toLowerCase() !== user.email) {
      // Do NOT immediately change email; store as pending and send a dedicated email-change link
      const nextEmail = email.toLowerCase();
      // Unique check against existing users' primary email and any pendingEmail
      const conflict = await User.findOne({
        _id: { $ne: userId },
        $or: [ { email: nextEmail }, { pendingEmail: nextEmail } ]
      });
      if (conflict) return error(res, 400, 'Email already registered', [], 'CONFLICT');
      user.pendingEmail = nextEmail;
      if (process.env.ENABLE_EMAIL_VERIFICATION === 'true') {
        const crypto = require('crypto');
        user.emailChangeToken = crypto.randomBytes(24).toString('hex');
        user.emailChangeExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);
        try {
          const { sendEmail } = require('../services/mailer');
          const API_BASE = process.env.API_BASE_URL || `${process.env.APP_API_BASE_URL || 'http://localhost:3000'}/api`;
          const verifyUrl = `${API_BASE}/auth/confirm-email-change/start?token=${user.emailChangeToken}&redirect=%2Fuser`;
          await sendEmail({
            to: user.pendingEmail,
            subject: 'Verify your new PalHands email',
            text: `Confirm this email change by opening ${verifyUrl}`,
            html: `<p>To confirm your email change, click the button below:</p>
                   <p><a href="${verifyUrl}" style="background:#CE1126;color:#fff;padding:10px 14px;border-radius:8px;text-decoration:none;display:inline-block">Confirm my new email</a></p>
                   <p>If the button doesn't work, copy and paste this link:<br/><a href="${verifyUrl}">${verifyUrl}</a></p>`
          });
        } catch (_) {}
      }
    }
    if (address) {
      // Maintain legacy single address field
      user.address = {
        ...address,
        city: normalizeCity(address.city)
      };
      // If addresses array not provided but legacy address is, ensure at least one entry exists
      if (!Array.isArray(addresses) && (!Array.isArray(user.addresses) || user.addresses.length === 0)) {
        user.addresses = [{
          type: (address.type && ['home','work','other'].includes(address.type)) ? address.type : 'home',
          street: address.street || '',
          city: address.city || '',
          area: address.area || '',
          coordinates: address.coordinates || {},
          isDefault: true
        }];
      }
    }
    if (Array.isArray(addresses)) {
      // Sanitize addresses items
      const sanitized = addresses.map((a = {}) => ({
        type: (a.type && ['home','work','other'].includes(a.type)) ? a.type : 'home',
        street: a.street || '',
        city: normalizeCity(a.city || ''),
        area: a.area || '',
        coordinates: a.coordinates || {},
        isDefault: !!a.isDefault
      }));
      // Ensure only one default
      let foundDefault = false;
      for (const item of sanitized) {
        if (item.isDefault && !foundDefault) {
          foundDefault = true;
        } else {
          item.isDefault = false;
        }
      }
      // If none marked default, set first one
      if (!foundDefault && sanitized.length > 0) sanitized[0].isDefault = true;
      user.addresses = sanitized;
    }
  if (profileImage) user.profileImage = profileImage;

    // Update timestamp
    user.updatedAt = new Date();

    try {
      await user.save();
    } catch (e) {
      // Handle duplicate key errors (race conditions)
      if (e && e.code === 11000) {
        const msg = (e.keyPattern && e.keyPattern.phone) ? 'Phone number already registered' :
                    (e.keyPattern && e.keyPattern.email) ? 'Email already registered' : 'Duplicate value';
        return error(res, 400, msg, [], 'CONFLICT');
      }
      throw e;
    }

    // Return updated user data (without password) with clean structure
    const userResponse = {
      _id: user._id,
      // Personal info
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      pendingEmail: user.pendingEmail,
      phone: user.phone,
      age: user.age,
      profileImage: user.profileImage,
      // Account info
      role: user.role,
      isVerified: user.isVerified,
      isActive: user.isActive,
      rating: user.rating,
      // Addresses
      addresses: user.addresses,
      // Metadata
      createdAt: user.createdAt,
      updatedAt: user.updatedAt
    };

  return ok(res, { user: userResponse }, 'Profile updated successfully');
});

// Change password
const changePassword = asyncHandler(async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user._id;

    // Validate required fields
  if (!currentPassword || !newPassword) return error(res, 400, 'Current password and new password are required', [], 'VALIDATION_ERROR');

    // Validate new password length
  if (newPassword.length < 6) return error(res, 400, 'New password must be at least 6 characters long', [], 'VALIDATION_ERROR');

    // Find user
    const user = await User.findById(userId);
  if (!user) return error(res, 404, 'User not found', [], 'NOT_FOUND');

    // Verify current password
    const isCurrentPasswordValid = await user.comparePassword(currentPassword);
  if (!isCurrentPasswordValid) return error(res, 400, 'Current password is incorrect', [], 'UNAUTHORIZED');

    // Update password
    user.password = newPassword;
    user.updatedAt = new Date();

    await user.save();

  return ok(res, {}, 'Password changed successfully');
});

// Get user by ID (admin only)
const getUserById = asyncHandler(async (req, res) => {
    const { id } = req.params;

    const user = await User.findById(id).select('-password');
  if (!user) return error(res, 404, 'User not found', [], 'NOT_FOUND');
  return ok(res, { user }, 'User fetched');
});

// Get all users (admin only)
const getAllUsers = asyncHandler(async (req, res) => {
    const { page = 1, limit = 10, role, search } = req.query;

    // Build query
    const query = {};
    if (role) query.role = role;
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }

    // Calculate pagination
    const skip = (page - 1) * limit;

    // Get users
    const users = await User.find(query)
      .select('-password')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count
    const total = await User.countDocuments(query);

    return ok(res, {
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    }, 'Users fetched');
});

// Update user status (admin only)
const updateUserStatus = asyncHandler(async (req, res) => {
    const { id } = req.params;
    const { isActive, isVerified } = req.body;

    const user = await User.findById(id);
  if (!user) return error(res, 404, 'User not found', [], 'NOT_FOUND');

    // Update status fields
    if (typeof isActive === 'boolean') user.isActive = isActive;
    if (typeof isVerified === 'boolean') user.isVerified = isVerified;

    user.updatedAt = new Date();

    await user.save();

    return ok(res, {
      message: 'User status updated successfully',
      user: {
        _id: user._id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        isActive: user.isActive,
        isVerified: user.isVerified,
        updatedAt: user.updatedAt
      }
    }, 'User status updated');
});

// Delete user (admin only)
const deleteUser = asyncHandler(async (req, res) => {
    const { id } = req.params;

    const user = await User.findById(id);
  if (!user) return error(res, 404, 'User not found', [], 'NOT_FOUND');

    // Prevent admin from deleting themselves
    if (user._id.toString() === req.user._id.toString()) {
      return error(res, 400, 'Cannot delete your own account', [], 'VALIDATION_ERROR');
    }

    await User.findByIdAndDelete(id);

  return ok(res, {}, 'User deleted successfully');
});

// Get client reviews
const getClientReviews = asyncHandler(async (req, res) => {
  const { id } = req.params;
  
  const user = await User.findById(id).select('reviews firstName lastName');
  if (!user) {
    return error(res, 404, 'User not found');
  }
  
  // Return the reviews array
  return ok(res, user.reviews || [], 'Client reviews retrieved successfully');
});

// Add provider to favorites
const addToFavorites = asyncHandler(async (req, res) => {
  const { providerId } = req.params;
  const userId = req.user._id;
  
  try {
    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return error(res, 404, 'User not found');
    }
    
    // Check if provider exists
    const provider = await Provider.findById(providerId);
    if (!provider) {
      return error(res, 404, 'Provider not found');
    }
    
    // Check if provider is already saved
    const existingSavedProvider = await SavedProvider.findOne({ 
      userId: userId, 
      providerId: providerId 
    });
    
    if (existingSavedProvider) {
      return error(res, 409, 'Provider already in favorites');
    }
    
    // Get provider's primary service
    const primaryService = provider.services && provider.services.length > 0 
      ? provider.services[0] 
      : null;
    
    // Create saved provider record with provider data snapshot
    const savedProvider = new SavedProvider({
      userId: userId,
      providerId: providerId,
      providerData: {
        firstName: provider.firstName,
        lastName: provider.lastName,
        email: provider.email,
        phone: provider.phone,
        primaryService: primaryService ? {
          title: primaryService.title,
          description: primaryService.description,
          hourlyRate: primaryService.hourlyRate,
          category: primaryService.category
        } : null,
        rating: provider.rating || { average: 0, count: 0 },
        isAvailable: provider.isAvailable !== false,
        location: {
          city: provider.city,
          address: provider.address
        }
      }
    });
    
    await savedProvider.save();
    
    // Also add to user's favoriteProviders array for backward compatibility
    if (!user.favoriteProviders.includes(providerId)) {
      user.favoriteProviders.push(providerId);
      await user.save();
    }
    
    console.log('✅ Provider saved to favorites:', {
      userId: userId,
      providerId: providerId,
      providerName: `${provider.firstName} ${provider.lastName}`
    });
    
    return ok(res, { 
      savedProvider: savedProvider,
      favoriteProviders: user.favoriteProviders 
    }, 'Provider added to favorites');
    
  } catch (err) {
    console.error('❌ Error adding provider to favorites:', err);
    return error(res, 500, 'Failed to add provider to favorites');
  }
});

// Remove provider from favorites
const removeFromFavorites = asyncHandler(async (req, res) => {
  const { providerId } = req.params;
  const userId = req.user._id;
  
  try {
    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return error(res, 404, 'User not found');
    }
    
    // Remove from savedProviders collection
    const deletedSavedProvider = await SavedProvider.findOneAndDelete({
      userId: userId,
      providerId: providerId
    });
    
    // Also remove from user's favoriteProviders array for backward compatibility
    user.favoriteProviders = user.favoriteProviders.filter(id => id.toString() !== providerId);
    await user.save();
    
    if (!deletedSavedProvider) {
      return error(res, 404, 'Provider not found in favorites');
    }
    
    console.log('✅ Provider removed from favorites:', {
      userId: userId,
      providerId: providerId,
      providerName: `${deletedSavedProvider.providerData.firstName} ${deletedSavedProvider.providerData.lastName}`
    });
    
    return ok(res, { 
      favoriteProviders: user.favoriteProviders 
    }, 'Provider removed from favorites');
    
  } catch (err) {
    console.error('❌ Error removing provider from favorites:', err);
    return error(res, 500, 'Failed to remove provider from favorites');
  }
});

// Get user's favorite providers
const getFavoriteProviders = asyncHandler(async (req, res) => {
  const userId = req.user._id;
  
  // Debug logging
  console.log('🔍 getFavoriteProviders called:', {
    userId: userId,
    userRole: req.user.role,
    userEmail: req.user.email,
    userType: req.user.constructor.modelName
  });
  
  try {
    // Get saved providers from the savedProviders collection
    const savedProviders = await SavedProvider.find({ userId: userId })
      .sort({ savedAt: -1 }) // Most recently saved first
      .lean(); // Use lean() for better performance
    
    // Return the data in the new format with providerData
    const favoriteProviders = savedProviders.map(savedProvider => ({
      _id: savedProvider.providerId,
      id: savedProvider.providerId,
      providerId: savedProvider.providerId,
      providerData: {
        firstName: savedProvider.providerData?.firstName || '',
        lastName: savedProvider.providerData?.lastName || '',
        email: savedProvider.providerData?.email || '',
        phone: savedProvider.providerData?.phone || '',
        rating: savedProvider.providerData?.rating || { average: 0, count: 0 },
        isAvailable: savedProvider.providerData?.isAvailable !== false,
        location: savedProvider.providerData?.location || {},
        primaryService: savedProvider.providerData?.primaryService || null
      },
      services: savedProvider.providerData?.primaryService ? [savedProvider.providerData.primaryService] : [],
      savedAt: savedProvider.savedAt,
      notes: savedProvider.notes || '',
      tags: savedProvider.tags || []
    }));
    
    console.log('✅ Retrieved favorite providers:', {
      userId: userId,
      count: favoriteProviders.length
    });
    
    // Debug logging for data structure
    if (favoriteProviders.length > 0) {
      console.log('📊 Sample provider data structure:', {
        keys: Object.keys(favoriteProviders[0]),
        providerDataKeys: favoriteProviders[0].providerData ? Object.keys(favoriteProviders[0].providerData) : 'No providerData',
        firstName: favoriteProviders[0].providerData?.firstName,
        lastName: favoriteProviders[0].providerData?.lastName
      });
      
      // Log all providers for debugging
      favoriteProviders.forEach((provider, index) => {
        console.log(`📊 Provider ${index + 1}:`, {
          id: provider._id,
          name: `${provider.providerData?.firstName} ${provider.providerData?.lastName}`,
          email: provider.providerData?.email,
          savedAt: provider.savedAt
        });
      });
    } else {
      console.log('📊 No favorite providers found for user:', userId);
    }
    
    return ok(res, favoriteProviders, 'Favorite providers retrieved successfully');
    
  } catch (err) {
    console.error('❌ Error retrieving favorite providers:', err);
    return error(res, 500, 'Failed to retrieve favorite providers');
  }
});

// Check if provider is favorite
const isProviderFavorite = asyncHandler(async (req, res) => {
  const { providerId } = req.params;
  const userId = req.user._id;
  
  try {
    // Check if provider exists in savedProviders collection
    const savedProvider = await SavedProvider.findOne({
      userId: userId,
      providerId: providerId
    });
    
    const isFavorite = !!savedProvider;
    
    return ok(res, { isFavorite }, 'Favorite status retrieved successfully');
    
  } catch (err) {
    console.error('❌ Error checking favorite status:', err);
    return error(res, 500, 'Failed to check favorite status');
  }
});

module.exports = {
  updateProfile,
  changePassword,
  getUserById,
  getAllUsers,
  updateUserStatus,
  deleteUser,
  getClientReviews,
  addToFavorites,
  removeFromFavorites,
  getFavoriteProviders,
  isProviderFavorite
}; 