const User = require('../../models/User');
const Provider = require('../../models/Provider');
const Service = require('../../models/Service');
const Booking = require('../../models/Booking');
const Report = require('../../models/Report');
const AdminAction = require('../../models/AdminAction');
const SystemSetting = require('../../models/SystemSetting');
const ServiceCategory = require('../../models/ServiceCategory');

// Deduplicate services by title to avoid duplicates from provider-service relationships
function deduplicateServicesByTitle(services) {
  if (!services || services.length === 0) return services;
  
  // Use a map to track unique services by title (case-insensitive)
  const uniqueServices = new Map();
  
  for (const service of services) {
    const titleKey = service.title.toLowerCase().trim();
    
    // Only add if we haven't seen this title before
    if (!uniqueServices.has(titleKey)) {
      uniqueServices.set(titleKey, service);
    } else {
      // If we have a duplicate, keep the one with more bookings or better rating
      const existingService = uniqueServices.get(titleKey);
      if (service.totalBookings > existingService.totalBookings ||
          (service.totalBookings === existingService.totalBookings && 
           service.rating?.average > existingService.rating?.average)) {
        uniqueServices.set(titleKey, service);
      }
    }
  }
  
  const deduplicatedServices = Array.from(uniqueServices.values());
  
  // console.log(`🔄 Deduplicated services: ${services.length} -> ${deduplicatedServices.length}`);
  
  return deduplicatedServices;
}

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
    const underReviewReports = await Report.countDocuments({ status: 'under_review' });
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
          underReview: underReviewReports,
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
    const pageNum = parseInt(page);
    const pageSize = parseInt(limit);
    const skip = (pageNum - 1) * pageSize;

    // Build filter
    const filter = {};
    if (category) filter.category = category;
    if (status !== undefined) filter.isActive = status === 'active';
    if (location) filter['location.serviceArea'] = { $regex: location, $options: 'i' };

    const allServices = await Service.find(filter)
      .populate('provider', 'firstName lastName email phone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(pageSize * 2); // Get more services to allow for deduplication

    // Deduplicate services by title
    const dedupedServices = deduplicateServicesByTitle(allServices);
    const services = dedupedServices.slice(0, pageSize); // Limit after deduplication

    // Get all categories from ServiceCategory collection (for icon/color metadata)
    const storedCategories = await ServiceCategory.find({ isActive: true })
      .select('id name icon color');

    // Build a lookup map for stored category metadata
    const categoryMetaById = new Map(
      (storedCategories || []).map((c) => [c.id, {
        id: c.id,
        name: c.name,
        icon: c.icon || 'category',
        color: c.color || '#9E9E9E'
      }])
    );

    // Aggregate distinct services per category (deduplicated by title)
    const dbCategories = await Service.aggregate([
      { $match: { isActive: true } },
      // Distinct by category + title
      { $group: { _id: { category: '$category', title: { $toLower: { $trim: { input: '$title' } } } } } },
      // Regroup by category and count distinct titles
      { $group: { _id: '$_id.category', serviceCount: { $sum: 1 } } },
      { $sort: { serviceCount: -1 } }
    ]);

    // Create enhanced categories with counts and metadata
    const enhancedCategories = dbCategories.map((cat) => {
      const meta = categoryMetaById.get(cat._id) || {
        id: cat._id,
        name: (cat._id || '').charAt(0).toUpperCase() + (cat._id || '').slice(1) + ' Services',
        icon: 'category',
        color: '#9E9E9E'
      };
      return {
        id: meta.id,
        name: meta.name,
        icon: meta.icon,
        color: meta.color,
        serviceCount: cat.serviceCount
      };
    });

    // Calculate accurate total for deduplicated services
    const total = await Service.aggregate([
      { $match: filter },
      { $group: { _id: '$title' } },
      { $count: 'total' }
    ]);

    const totalCount = total.length > 0 ? total[0].total : 0;

    res.json({
      success: true,
      data: {
        services,
        categories: enhancedCategories,
        pagination: {
          current: pageNum,
          total: Math.ceil(totalCount / pageSize),
          totalRecords: totalCount
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

// Delete service
const deleteService = async (req, res) => {
  try {
    const { serviceId } = req.params;
    
    console.log(`🗑️ Delete service request for ID: ${serviceId}`);
    
    // Import required models
    const ProviderService = require('../../models/ProviderService');
    
    // Find the service first to get provider info
    const service = await Service.findById(serviceId).populate('provider', 'firstName lastName email');
    
    if (!service) {
      console.log(`🗑️ Service not found for ID: ${serviceId}`);
      return res.status(404).json({
        success: false,
        message: 'Service not found'
      });
    }
    
    console.log(`🗑️ Found service: "${service.title}" by provider: ${service.provider?.firstName} ${service.provider?.lastName}`);
    
    // Delete all provider services that reference this service
    const providerServicesDeleteResult = await ProviderService.deleteMany({ service: serviceId });
    console.log(`🗑️ Deleted ${providerServicesDeleteResult.deletedCount} provider services for service "${service.title}"`);
    
    // Delete all bookings for this service
    const bookingsDeleteResult = await Booking.deleteMany({ service: serviceId });
    console.log(`🗑️ Deleted ${bookingsDeleteResult.deletedCount} bookings for service "${service.title}"`);
    
    // Delete the service itself
    const serviceDeleteResult = await Service.findByIdAndDelete(serviceId);
    
    if (!serviceDeleteResult) {
      console.log(`🗑️ Failed to delete service with ID: ${serviceId}`);
      return res.status(500).json({
        success: false,
        message: 'Failed to delete service from database'
      });
    }
    
    console.log(`✅ Service "${service.title}" and ${providerServicesDeleteResult.deletedCount} provider services and ${bookingsDeleteResult.deletedCount} bookings deleted successfully by admin`);
    
    res.json({
      success: true,
      message: `Service "${service.title}" and ${providerServicesDeleteResult.deletedCount} provider services and ${bookingsDeleteResult.deletedCount} bookings deleted successfully`
    });
  } catch (error) {
    console.error('Service deletion error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete service'
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

const deleteCategory = async (req, res) => {
  try {
    const { categoryId } = req.params;
    
    console.log(`🗑️ Delete category request for ID: ${categoryId}`);
    
    // Import required models
    const Service = require('../../models/Service');
    const ProviderService = require('../../models/ProviderService');
    const Booking = require('../../models/Booking');
    
    // Check if category exists - ServiceCategory uses custom 'id' field (String), not _id
    const category = await ServiceCategory.findOne({ id: categoryId });
    
    console.log(`🗑️ Found category:`, category ? `${category.name} (${category.id})` : 'null');
    console.log(`🗑️ Searched for categoryId: ${categoryId}`);
    
    if (!category) {
      console.log(`🗑️ Category not found for ID: ${categoryId}`);
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }
    
    // Get all services in this category
    const servicesInCategory = await Service.find({ category: category.id });
    const servicesCount = servicesInCategory.length;
    console.log(`🗑️ Services count for category "${category.name}": ${servicesCount}`);
    
    // Delete all services in this category and their related data
    if (servicesCount > 0) {
      console.log(`🗑️ Deleting ${servicesCount} services from category "${category.name}"`);
      
      // Get all service IDs for this category
      const serviceIds = servicesInCategory.map(service => service._id);
      
      // Delete all provider services that reference these services
      const providerServicesDeleteResult = await ProviderService.deleteMany({ 
        service: { $in: serviceIds } 
      });
      console.log(`🗑️ Deleted ${providerServicesDeleteResult.deletedCount} provider services for services in category "${category.name}"`);
      
      // Delete all bookings for these services
      const bookingsDeleteResult = await Booking.deleteMany({ 
        service: { $in: serviceIds } 
      });
      console.log(`🗑️ Deleted ${bookingsDeleteResult.deletedCount} bookings for services in category "${category.name}"`);
      
      // Delete all services in this category
      const servicesDeleteResult = await Service.deleteMany({ category: category.id });
      console.log(`🗑️ Deleted ${servicesDeleteResult.deletedCount} services from category "${category.name}"`);
    }
    
    // Delete the category - ServiceCategory uses custom 'id' field (String), not _id
    const deleteResult = await ServiceCategory.findOneAndDelete({ id: categoryId });
    
    if (!deleteResult) {
      console.log(`🗑️ Failed to delete category with ID: ${categoryId}`);
      return res.status(500).json({
        success: false,
        message: 'Failed to delete category from database'
      });
    }
    
    console.log(`✅ Category "${category.name}" and ${servicesCount} associated services deleted successfully by admin`);
    
    res.json({
      success: true,
      message: `Category "${category.name}" and ${servicesCount} associated services deleted successfully`
    });
  } catch (error) {
    console.error('Category deletion error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete category'
    });
  }
};

module.exports = {
  getDashboardOverview,
  getUserManagementData,
  updateUser,
  getServiceManagementData,
  updateService,
  deleteService,
  getBookingManagementData,
  updateBooking,
  deleteCategory
}; 