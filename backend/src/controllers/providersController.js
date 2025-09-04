const Provider = require('../models/Provider');
const Booking = require('../models/Booking');
const { ok, error } = require('../utils/response');

/**
 * List providers with filtering and search
 */
async function listProviders(req, res) {
  try {
    const { parsePagination } = require('../utils/pagination');
    const { page, limit, skip } = parsePagination(req.query);
  const { city, services, category, sortBy, sortOrder, q, emergency, emergencyType } = req.query;

    // Build filter
    const filter = { isActive: true };
    
    // City filter
    if (city) {
      filter['addresses.city'] = { $regex: city, $options: 'i' };
    }
    
    // Services filter (comma-separated list)
    if (services) {
      const servicesList = services.split(',').map(s => s.trim());
      if (servicesList.length > 0) {
        filter.services = { $in: servicesList };
      }
    }
    
    // Category filter (match any service in category)
    if (category) {
      filter.services = { $regex: category, $options: 'i' };
    }
    
    // Text search
    if (q) {
      filter.$text = { $search: q };
    }

    // Build sort options
    let sortOptions = { createdAt: -1 }; // Default sort
    if (sortBy === 'rating') {
      sortOptions = { 'rating.average': sortOrder === 'asc' ? 1 : -1 };
    } else if (sortBy === 'price') {
      sortOptions = { hourlyRate: sortOrder === 'asc' ? 1 : -1 };
    }

    // If emergency filter is requested, precompute provider IDs that have at least one emergency-enabled service
    let providerIdsEmergency = null;
    if (emergency === 'emergency' || emergency === 'normal' || emergencyType) {
      try {
        const Service = require('../models/Service');
        const match = { emergencyEnabled: true };
        if (emergencyType) match.emergencyTypes = emergencyType;
        const svcAgg = await Service.aggregate([
          { $match: match },
          { $group: { _id: '$provider' } }
        ]);
        providerIdsEmergency = new Set(svcAgg.map(x => String(x._id)));
      } catch (_) {}
    }

    if (providerIdsEmergency) {
      if (emergency === 'emergency') {
        filter._id = { $in: Array.from(providerIdsEmergency) };
      } else if (emergency === 'normal') {
        filter._id = filter._id || {};
        filter._id.$nin = Array.from(providerIdsEmergency);
      }
      // If only emergencyType was provided without emergency flag, narrow to providers with that type
      if (emergencyType && !emergency) {
        filter._id = { $in: Array.from(providerIdsEmergency) };
      }
    }

    const providers = await Provider.find(filter)
      .select('-password -emailVerificationToken -passwordResetToken -passwordResetTokenHash')
      .sort(sortOptions)
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Provider.countDocuments(filter);
    const totalPages = Math.ceil(total / limit);
    const currentPage = totalPages ? parseInt(page) : 0;

    // Transform providers to match frontend ProviderModel
    const transformedProviders = providers.map(provider => ({
      _id: provider._id,
      id: provider._id,
      name: `${provider.firstName} ${provider.lastName}`.trim(),
      city: provider.addresses && provider.addresses.length > 0 
        ? provider.addresses.find(addr => addr.isDefault)?.city || provider.addresses[0].city 
        : '',
      phone: provider.phone,
      experienceYears: provider.experienceYears,
      languages: provider.languages,
      hourlyRate: provider.hourlyRate,
      services: provider.services,
      ratingAverage: provider.rating.average,
      ratingCount: provider.rating.count,
      avatarUrl: provider.profileImage,
      rating: {
        average: provider.rating.average,
        count: provider.rating.count
      }
    }));

    return ok(res, {
      data: transformedProviders,
      providers: transformedProviders, // For backward compatibility
      pagination: {
        currentPage,
        totalPages,
        totalCount: total,
        pageSize: limit,
        hasNext: currentPage < totalPages,
        hasPrev: currentPage > 1
      }
    });
  } catch (e) {
    console.error('listProviders error', e);
    return error(res, 500, 'Failed to fetch providers');
  }
}

/**
 * Get a specific provider by ID
 */
async function getProviderById(req, res) {
  try {
    const { id } = req.params;
    
    const provider = await Provider.findById(id)
      .select('-password -emailVerificationToken -passwordResetToken -passwordResetTokenHash');
    
    if (!provider || !provider.isActive) {
      return error(res, 404, 'Provider not found');
    }

    // Transform provider to match frontend ProviderModel
    const transformedProvider = {
      _id: provider._id,
      id: provider._id,
      name: `${provider.firstName} ${provider.lastName}`.trim(),
      city: provider.addresses && provider.addresses.length > 0 
        ? provider.addresses.find(addr => addr.isDefault)?.city || provider.addresses[0].city 
        : '',
      phone: provider.phone,
      experienceYears: provider.experienceYears,
      languages: provider.languages,
      hourlyRate: provider.hourlyRate,
      services: provider.services,
      ratingAverage: provider.rating.average,
      ratingCount: provider.rating.count,
      avatarUrl: provider.profileImage,
      rating: {
        average: provider.rating.average,
        count: provider.rating.count
      }
    };

    return ok(res, {
      data: transformedProvider
    });
  } catch (e) {
    console.error('getProviderById error', e);
    return error(res, 500, 'Failed to fetch provider');
  }
}

/**
 * Get providers by category
 */
async function getProvidersByCategory(req, res) {
  try {
    const { category } = req.params;
    const { parsePagination } = require('../utils/pagination');
    const { page, limit, skip } = parsePagination(req.query);
    const { city, sortBy, sortOrder } = req.query;

    // Build filter
    const filter = { 
      isActive: true,
      services: { $regex: category, $options: 'i' }
    };
    
    // City filter
    if (city) {
      filter['addresses.city'] = { $regex: city, $options: 'i' };
    }

    // Build sort options
    let sortOptions = { createdAt: -1 }; // Default sort
    if (sortBy === 'rating') {
      sortOptions = { 'rating.average': sortOrder === 'asc' ? 1 : -1 };
    } else if (sortBy === 'price') {
      sortOptions = { hourlyRate: sortOrder === 'asc' ? 1 : -1 };
    }

    const providers = await Provider.find(filter)
      .select('-password -emailVerificationToken -passwordResetToken -passwordResetTokenHash')
      .sort(sortOptions)
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Provider.countDocuments(filter);
    const totalPages = Math.ceil(total / limit);
    const currentPage = totalPages ? parseInt(page) : 0;

    // Transform providers to match frontend ProviderModel
    const transformedProviders = providers.map(provider => ({
      _id: provider._id,
      id: provider._id,
      name: `${provider.firstName} ${provider.lastName}`.trim(),
      city: provider.addresses && provider.addresses.length > 0 
        ? provider.addresses.find(addr => addr.isDefault)?.city || provider.addresses[0].city 
        : '',
      phone: provider.phone,
      experienceYears: provider.experienceYears,
      languages: provider.languages,
      hourlyRate: provider.hourlyRate,
      services: provider.services,
      ratingAverage: provider.rating.average,
      ratingCount: provider.rating.count,
      avatarUrl: provider.profileImage,
      rating: {
        average: provider.rating.average,
        count: provider.rating.count
      }
    }));

    return ok(res, {
      data: transformedProviders,
      providers: transformedProviders, // For backward compatibility
      pagination: {
        currentPage,
        totalPages,
        totalCount: total,
        pageSize: limit,
        hasNext: currentPage < totalPages,
        hasPrev: currentPage > 1
      }
    });
  } catch (e) {
    console.error('getProvidersByCategory error', e);
    return error(res, 500, 'Failed to fetch providers by category');
  }
}

/**
 * Get services offered by a provider
 */
async function getProviderServices(req, res) {
  try {
    const providerId = req.params.id;
    const provider = await Provider.findById(providerId).select('services isActive');
    if (!provider || !provider.isActive) return error(res, 404, 'Provider not found');
    return ok(res, { data: provider.services || [] });
  } catch (e) {
    console.error('getProviderServices error', e);
    return error(res, 500, 'Failed to fetch provider services');
  }
}

/**
 * Deactivate a service for one month (minimal safe implementation)
 */
async function deactivateServiceForMonth(req, res) {
  try {
    const { providerId, serviceId } = req.params;
    // Minimal implementation: record intent and return success. Full implementation should
    // add an entry to a provider availability/exception collection. For now, verify provider exists.
    const provider = await Provider.findById(providerId).select('_id isActive');
    if (!provider || !provider.isActive) return error(res, 404, 'Provider not found');
    return ok(res, { message: `Service ${serviceId} marked for deactivation for a month (no-op).` });
  } catch (e) {
    console.error('deactivateServiceForMonth error', e);
    return error(res, 500, 'Failed to deactivate service for month');
  }
}

/**
 * Activate a previously deactivated service for one month (minimal safe implementation)
 */
async function activateServiceForMonth(req, res) {
  try {
    const { providerId, serviceId } = req.params;
    const provider = await Provider.findById(providerId).select('_id isActive');
    if (!provider || !provider.isActive) return error(res, 404, 'Provider not found');
    return ok(res, { message: `Service ${serviceId} marked for activation for a month (no-op).` });
  } catch (e) {
    console.error('activateServiceForMonth error', e);
    return error(res, 500, 'Failed to activate service for month');
  }
}

/**
 * Unlink a service from a provider (remove service key from provider.services)
 */
async function unlinkServiceFromProvider(req, res) {
  try {
    const { providerId, serviceId } = req.params;
    const provider = await Provider.findById(providerId);
    if (!provider) return error(res, 404, 'Provider not found');
    // Remove the service string if present
    const idx = provider.services ? provider.services.indexOf(serviceId) : -1;
    if (idx >= 0) {
      provider.services.splice(idx, 1);
      await provider.save();
    }
    return ok(res, { message: 'Service unlinked from provider', services: provider.services });
  } catch (e) {
    console.error('unlinkServiceFromProvider error', e);
    return error(res, 500, 'Failed to unlink service from provider');
  }
}

module.exports = {
  listProviders,
  getProviderById,
  getProvidersByCategory,
  getProviderServices,
  deactivateServiceForMonth,
  activateServiceForMonth,
  unlinkServiceFromProvider,
  getProviderStats
};

/**
 * Provider dashboard stats: counts by status and recent bookings
 */
async function getProviderStats(req, res) {
  try {
    const providerId = req.params.id;

    // Ensure provider exists (and optionally is active)
    const provider = await Provider.findById(providerId).select('_id isActive totalBookings completedBookings');
    if (!provider) return error(res, 404, 'Provider not found');

    // Aggregation for counts by status
    const pipeline = [
      { $match: { provider: provider._id } },
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ];
    const grouped = await Booking.aggregate(pipeline);
    const counts = {
      total: 0,
      pending: 0,
      confirmed: 0,
      in_progress: 0,
      completed: 0,
      cancelled: 0,
      disputed: 0
    };
    grouped.forEach(g => {
      counts[g._id] = g.count;
      counts.total += g.count;
    });

    // Recent bookings (last 10)
    const recent = await Booking.find({ provider: provider._id })
      .populate('client', 'firstName lastName')
      .populate('service', 'title category')
      .sort({ createdAt: -1 })
      .limit(10);

    const recentTransformed = recent.map(b => ({
      id: b._id,
      bookingId: b.bookingId,
      clientName: b.client ? `${b.client.firstName} ${b.client.lastName}`.trim() : '—',
      serviceTitle: b.service ? b.service.title : b.serviceDetails?.title,
      category: b.service ? b.service.category : b.serviceDetails?.category,
      date: b.schedule?.date,
      startTime: b.schedule?.startTime,
      endTime: b.schedule?.endTime,
      totalAmount: b.pricing?.totalAmount,
      currency: b.pricing?.currency || 'ILS',
      status: b.status,
      createdAt: b.createdAt
    }));

    return ok(res, {
      provider: {
        id: provider._id,
        totalBookings: provider.totalBookings || counts.total,
        completedBookings: provider.completedBookings || counts.completed
      },
      counts,
      recent: recentTransformed
    });
  } catch (e) {
    console.error('getProviderStats error', e);
    return error(res, 500, 'Failed to fetch provider stats');
  }
}
