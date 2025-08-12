const User = require('../models/User');
const asyncHandler = require('../utils/asyncHandler');
const { ok, created, error } = require('../utils/response');

// Update user profile
const updateProfile = asyncHandler(async (req, res) => {
    const { firstName, lastName, phone, address, profileImage } = req.body;
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
    if (address) user.address = address;
    if (profileImage) user.profileImage = profileImage;

    // Update timestamp
    user.updatedAt = new Date();

    await user.save();

    // Return updated user data (without password)
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

module.exports = {
  updateProfile,
  changePassword,
  getUserById,
  getAllUsers,
  updateUserStatus,
  deleteUser
}; 