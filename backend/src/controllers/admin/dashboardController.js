const User = require('../../models/User');
const Provider = require('../../models/Provider');
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

// Get user management data (combined Users + Providers)
const getUserManagementData = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, role = 'all', status, excludeRole } = req.query;
    const pageNum = parseInt(page);
    const pageSize = parseInt(limit);
    const skip = (pageNum - 1) * pageSize;

    // Build base filters for users and providers
    const userFilter = {};
    const providerFilter = {};

    // Search across name/email/phone; support 4-digit providerId for providers
    if (search && search.trim()) {
      const s = search.trim();
      const isProviderId = /^\d{4}$/.test(s);
      userFilter.$or = [
        { firstName: { $regex: s, $options: 'i' } },
        { lastName: { $regex: s, $options: 'i' } },
        { email: { $regex: s, $options: 'i' } },
        { phone: { $regex: s, $options: 'i' } }
      ];
      providerFilter.$or = [
        { firstName: { $regex: s, $options: 'i' } },
        { lastName: { $regex: s, $options: 'i' } },
        { email: { $regex: s, $options: 'i' } },
        { phone: { $regex: s, $options: 'i' } }
      ];
      if (isProviderId) {
        providerFilter.providerId = parseInt(s, 10);
      }
    }

    // Role filters
    if (role && role !== 'all') {
      if (role === 'provider') {
        // Only providers; exclude users entirely
        if (excludeRole) userFilter.role = { $ne: excludeRole };
      } else {
        userFilter.role = role; // e.g., 'client' or 'admin'
      }
    } else if (excludeRole) {
      userFilter.role = { $ne: excludeRole };
    }

    // Status
    if (status !== undefined && status !== 'all') {
      const isActive = status === 'active';
      userFilter.isActive = isActive;
      providerFilter.isActive = isActive;
    }

    // Fetch and combine
    const MAX_BATCH = Math.max(pageSize * 3, 100);
    const [
      userTotal,
      providerTotal
    ] = await Promise.all([
      (role === 'provider') ? Promise.resolve(0) : User.countDocuments(userFilter),
      (role && role !== 'all' && role !== 'provider') ? Promise.resolve(0) : Provider.countDocuments(providerFilter)
    ]);

    const [users, providers] = await Promise.all([
      (role === 'provider')
        ? Promise.resolve([])
        : User.find(userFilter)
            .select('-password')
            .sort({ createdAt: -1 })
            .limit(MAX_BATCH),
      (role && role !== 'all' && role !== 'provider')
        ? Promise.resolve([])
        : Provider.find(providerFilter)
            .select('-password -emailVerificationToken -passwordResetToken -passwordResetTokenHash')
            .sort({ createdAt: -1 })
            .limit(MAX_BATCH)
    ]);

    // Normalize to a unified shape expected by FE table
    const normalizeUser = (u) => ({
      _id: u._id,
      firstName: u.firstName,
      lastName: u.lastName,
      email: u.email,
      phone: u.phone,
      role: u.role || 'client',
      isActive: u.isActive,
      isVerified: u.isVerified ?? false,
      rating: u.rating ?? null,
      createdAt: u.createdAt,
    });
    const normalizeProvider = (p) => ({
      _id: p._id,
      firstName: p.firstName,
      lastName: p.lastName,
      email: p.email,
      phone: p.phone,
      role: 'provider',
      isActive: p.isActive,
      isVerified: p.isVerified ?? false,
      rating: p.rating ? { average: p.rating.average || 0, count: p.rating.count || 0 } : { average: 0, count: 0 },
      createdAt: p.createdAt,
      providerId: p.providerId,
    });

    const combined = [
      ...(users || []).map(normalizeUser),
      ...(providers || []).map(normalizeProvider)
    ].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    const totalCombined = userTotal + providerTotal;
    const paged = combined.slice(skip, skip + pageSize);

    return res.json({
      success: true,
      data: {
        users: paged,
        pagination: {
          current: pageNum,
          total: Math.ceil(totalCombined / pageSize),
          totalRecords: totalCombined
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

// Update user or provider status/role
const updateUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { isActive, role, isVerified, deactivationReason } = req.body;
    
    // Try user first
    let doc = await User.findById(userId);
    let entity = 'user';
    if (!doc) {
      // Try provider
      doc = await Provider.findById(userId);
      entity = doc ? 'provider' : 'user';
    }
    if (!doc) {
      return res.status(404).json({ success: false, message: 'User/Provider not found' });
    }

    // Update fields
    if (isActive !== undefined) {
      doc.isActive = isActive;
      if (!isActive && deactivationReason) {
        doc.deactivationReason = deactivationReason;
      } else if (isActive) {
        doc.deactivationReason = null;
      }
    }
    // Only allow changing role for User documents; Providers keep role 'provider'
    if (entity === 'user' && role) {
      doc.role = role;
    }
    if (isVerified !== undefined) {
      doc.isVerified = isVerified;
    }

    await doc.save();

    res.json({
      success: true,
      message: `${entity === 'provider' ? 'Provider' : 'User'} updated successfully`,
      data: doc
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