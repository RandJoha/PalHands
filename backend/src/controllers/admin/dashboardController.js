const User = require('../../models/User');
const Service = require('../../models/Service');
const Booking = require('../../models/Booking');
const Report = require('../../models/Report');
const AdminAction = require('../../models/AdminAction');
const SystemSetting = require('../../models/SystemSetting');

// Get dashboard overview data
const getDashboardOverview = async (req, res) => {
  try {
    const today = new Date();
    const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    const startOfWeek = new Date(today.getFullYear(), today.getMonth(), today.getDate() - today.getDay());
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

    // User statistics
    const totalUsers = await User.countDocuments();
    const activeUsers = await User.countDocuments({ isActive: true });
    const inactiveUsers = totalUsers - activeUsers;
    
    const usersByRole = await User.aggregate([
      {
        $group: {
          _id: '$role',
          count: { $sum: 1 }
        }
      }
    ]);

    // Service statistics
    const totalServices = await Service.countDocuments();
    const activeServices = await Service.countDocuments({ isActive: true });
    const featuredServices = await Service.countDocuments({ featured: true });

    // Booking statistics
    const totalBookings = await Booking.countDocuments();
    const todayBookings = await Booking.countDocuments({
      'schedule.date': { $gte: startOfToday }
    });
    const weekBookings = await Booking.countDocuments({
      'schedule.date': { $gte: startOfWeek }
    });
    const monthBookings = await Booking.countDocuments({
      'schedule.date': { $gte: startOfMonth }
    });

    // Revenue statistics (platform commission)
    const revenueStats = await Booking.aggregate([
      {
        $match: {
          'payment.status': 'paid',
          'schedule.date': { $gte: startOfMonth }
        }
      },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$pricing.totalAmount' },
          avgBookingValue: { $avg: '$pricing.totalAmount' }
        }
      }
    ]);

    // Report statistics
    const pendingReports = await Report.countDocuments({ status: 'pending' });
    const urgentReports = 0; // Priority removed, no urgent reports

    // Recent admin actions
    const recentActions = await AdminAction.find()
      .populate('admin', 'firstName lastName email')
      .sort({ timestamp: -1 })
      .limit(10);

    // System health
    const systemHealth = {
      database: 'healthy',
      api: 'healthy',
      uptime: process.uptime(),
      memoryUsage: process.memoryUsage(),
      timestamp: new Date()
    };

    res.json({
      success: true,
      data: {
        users: {
          total: totalUsers,
          active: activeUsers,
          inactive: inactiveUsers,
          byRole: usersByRole
        },
        services: {
          total: totalServices,
          active: activeServices,
          featured: featuredServices
        },
        bookings: {
          total: totalBookings,
          today: todayBookings,
          thisWeek: weekBookings,
          thisMonth: monthBookings
        },
        revenue: {
          monthly: revenueStats[0]?.totalRevenue || 0,
          averageBooking: revenueStats[0]?.avgBookingValue || 0
        },
        reports: {
          pending: pendingReports,
          urgent: urgentReports
        },
        recentActions,
        systemHealth
      }
    });
  } catch (error) {
    console.error('Dashboard overview error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch dashboard overview'
    });
  }
};

// Get user management data
const getUserManagementData = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, role, status, excludeRole } = req.query;
    const skip = (page - 1) * limit;

    // Build filter
    const filter = {};
    if (search) {
      filter.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } }
      ];
    }
    
    // Handle role filtering - prioritize specific role over excludeRole
    if (role && role !== 'all') {
      filter.role = role;
    } else if (excludeRole) {
      filter.role = { $ne: excludeRole };
    }
    
    if (status !== undefined) filter.isActive = status === 'active';

    console.log('🔍 User management filter:', filter);
    console.log('🔍 Query params:', { page, limit, search, role, status, excludeRole });
    
    const users = await User.find(filter)
      .select('-password')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await User.countDocuments(filter);
    
    console.log('🔍 Found users:', users.length);
    console.log('🔍 Total count:', total);

    res.json({
      success: true,
      data: {
        users,
        pagination: {
          current: parseInt(page),
          total: Math.ceil(total / limit),
          totalRecords: total
        }
      }
    });
  } catch (error) {
    console.error('User management error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user data'
    });
  }
};

// Update user status/role
const updateUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { isActive, role, isVerified, deactivationReason } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Update fields
    if (isActive !== undefined) {
      user.isActive = isActive;
      // Set deactivation reason when deactivating
      if (!isActive && deactivationReason) {
        user.deactivationReason = deactivationReason;
      } else if (isActive) {
        // Clear deactivation reason when reactivating
        user.deactivationReason = null;
      }
    }
    if (role) user.role = role;
    if (isVerified !== undefined) user.isVerified = isVerified;

    await user.save();

    res.json({
      success: true,
      message: 'User updated successfully',
      data: user
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user'
    });
  }
};

// Get service management data
const getServiceManagementData = async (req, res) => {
  try {
    const { page = 1, limit = 20, category, status, location } = req.query;
    const skip = (page - 1) * limit;

    // Build filter
    const filter = {};
    if (category) filter.category = category;
    if (status !== undefined) filter.isActive = status === 'active';
    if (location) filter['location.serviceArea'] = { $regex: location, $options: 'i' };

    const services = await Service.find(filter)
      .populate('provider', 'firstName lastName email phone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Service.countDocuments(filter);

    res.json({
      success: true,
      data: {
        services,
        pagination: {
          current: parseInt(page),
          total: Math.ceil(total / limit),
          totalRecords: total
        }
      }
    });
  } catch (error) {
    console.error('Service management error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch service data'
    });
  }
};

// Update service status
const updateService = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const { isActive, featured } = req.body;

    const service = await Service.findById(serviceId);
    if (!service) {
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }

    // Update fields
    if (isActive !== undefined) service.isActive = isActive;
    if (featured !== undefined) service.featured = featured;

    await service.save();

    res.json({
      success: true,
      message: 'Service updated successfully',
      data: service
    });
  } catch (error) {
    console.error('Update service error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update service'
    });
  }
};

// Get booking management data
const getBookingManagementData = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, startDate, endDate, clientId, providerId } = req.query;
    const skip = (page - 1) * limit;

    // Build filter
    const filter = {};
    if (status) filter.status = status;
    if (clientId) filter.client = clientId;
    if (providerId) filter.provider = providerId;
    if (startDate || endDate) {
      filter['schedule.date'] = {};
      if (startDate) filter['schedule.date'].$gte = new Date(startDate);
      if (endDate) filter['schedule.date'].$lte = new Date(endDate);
    }

    const bookings = await Booking.find(filter)
      .populate('client', 'firstName lastName email phone')
      .populate('provider', 'firstName lastName email phone')
      .populate('service', 'title category')
      .sort({ 'schedule.date': -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Booking.countDocuments(filter);

    res.json({
      success: true,
      data: {
        bookings,
        pagination: {
          current: parseInt(page),
          total: Math.ceil(total / limit),
          totalRecords: total
        }
      }
    });
  } catch (error) {
    console.error('Booking management error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch booking data'
    });
  }
};

// Update booking status
const updateBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { status, adminNotes } = req.body;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Update fields
    if (status) booking.status = status;
    if (adminNotes) {
      booking.notes.adminNotes = adminNotes;
    }

    await booking.save();

    res.json({
      success: true,
      message: 'Booking updated successfully',
      data: booking
    });
  } catch (error) {
    console.error('Update booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update booking'
    });
  }
};

module.exports = {
  getDashboardOverview,
  getUserManagementData,
  updateUser,
  getServiceManagementData,
  updateService,
  getBookingManagementData,
  updateBooking
}; 