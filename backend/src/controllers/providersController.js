const Provider = require('../models/Provider');
const ProviderService = require('../models/ProviderService');
const Service = require('../models/Service');
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

  // Build filter - query Provider collection directly
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

    // Build sort options - price sorting will be done after aggregation
    let sortOptions = { createdAt: -1 }; // Default sort
    if (sortBy === 'rating') {
      sortOptions = { 'rating.average': sortOrder === 'asc' ? 1 : -1 };
    }
    // Note: price sorting is handled after per-service aggregation

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

    let providers = await Provider.find(filter)
      .select('-password -emailVerificationToken -passwordResetToken -passwordResetTokenHash')
      .sort(sortOptions)
      .skip(skip)
      .limit(parseInt(limit));

    // Optional gate: only include providers having at least one active+publishable ProviderService
    try {
      const ProviderService = require('../models/ProviderService');
      const ids = providers.map(p => String(p._id));
      const ps = await ProviderService.aggregate([
        { $match: { provider: { $in: ids.map(id => require('mongoose').Types.ObjectId(id)) }, status: 'active', publishable: true } },
        { $group: { _id: '$provider', count: { $sum: 1 } } }
      ]);
      const ok = new Set(ps.map(x => String(x._id)));
      providers = providers.filter(p => ok.has(String(p._id)));
    } catch (_) {}

    // console.log(`📊 Found ${providers.length} providers`);

  // Count total matching providers for pagination
  const total = providers.length;
    const totalPages = Math.ceil(total / limit);
    const currentPage = totalPages ? parseInt(page) : 0;

    // Transform providers to match frontend ProviderModel using per-service data
    const transformedProviders = [];
    
    for (const provider of providers) {
      // Get provider's service data from ProviderService collection
      const providerServices = await ProviderService.find({ 
        provider: provider._id, 
        status: { $in: ['active', 'draft'] },
        publishable: true 
      }).populate('service', 'title subcategory');

      // Calculate aggregated data from per-service information
      let avgHourlyRate = 0;
      let avgExperienceYears = 0;
      let totalServices = 0;

      if (providerServices.length > 0) {
        const validServices = providerServices.filter(ps => ps.hourlyRate > 0);
        if (validServices.length > 0) {
          avgHourlyRate = validServices.reduce((sum, ps) => sum + ps.hourlyRate, 0) / validServices.length;
          avgExperienceYears = validServices.reduce((sum, ps) => sum + ps.experienceYears, 0) / validServices.length;
          totalServices = validServices.length;
        }
      }

      // Fallback to provider static data if no service data available
      if (totalServices === 0) {
        avgHourlyRate = provider.hourlyRate || 50;
        avgExperienceYears = provider.experienceYears || 2;
      }

      transformedProviders.push({
        _id: provider._id,
        id: provider._id,
        providerId: provider.providerId || 1000 + Math.floor(Math.random() * 9000),
        name: `${provider.firstName} ${provider.lastName}`.trim(),
        city: provider.addresses && provider.addresses.length > 0 
          ? provider.addresses.find(addr => addr.isDefault)?.city || provider.addresses[0].city 
          : 'Palestine',
        phone: provider.phone,
        experienceYears: Math.round(avgExperienceYears), // Aggregated from services
        languages: provider.languages || ['Arabic'],
        hourlyRate: Math.round(avgHourlyRate), // Aggregated from services
        services: provider.services || ['homeCleaning'],
        ratingAverage: provider.rating?.average || 4.0,
        ratingCount: provider.rating?.count || 5,
        avatarUrl: provider.profileImage,
        rating: {
          average: provider.rating?.average || 4.0,
          count: provider.rating?.count || 5
        },
        // Add metadata about per-service data
        _serviceCount: totalServices,
        _hasPerServiceData: totalServices > 0
      });
    }

    // Apply price sorting after aggregation if requested
    if (sortBy === 'price') {
      transformedProviders.sort((a, b) => {
        if (sortOrder === 'asc') {
          return a.hourlyRate - b.hourlyRate;
        } else {
          return b.hourlyRate - a.hourlyRate;
        }
      });
    }

    // console.log(`✅ Returning ${transformedProviders.length} transformed providers with per-service data`);

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

    // Get provider's service data from ProviderService collection
    const providerServices = await ProviderService.find({ 
      provider: provider._id, 
      status: { $in: ['active', 'draft'] },
      publishable: true 
    }).populate('service', 'title subcategory');

    // Calculate aggregated data from per-service information
    let avgHourlyRate = 0;
    let avgExperienceYears = 0;
    let totalServices = 0;

    if (providerServices.length > 0) {
      const validServices = providerServices.filter(ps => ps.hourlyRate > 0);
      if (validServices.length > 0) {
        avgHourlyRate = validServices.reduce((sum, ps) => sum + ps.hourlyRate, 0) / validServices.length;
        avgExperienceYears = validServices.reduce((sum, ps) => sum + ps.experienceYears, 0) / validServices.length;
        totalServices = validServices.length;
      }
    }

    // Fallback to provider static data if no service data available
    if (totalServices === 0) {
      avgHourlyRate = provider.hourlyRate || 50;
      avgExperienceYears = provider.experienceYears || 2;
    }

    // Transform provider to match frontend ProviderModel using per-service data
    const transformedProvider = {
      _id: provider._id,
      id: provider._id,
      providerId: provider.providerId,
      name: `${provider.firstName} ${provider.lastName}`.trim(),
      city: provider.addresses && provider.addresses.length > 0 
        ? provider.addresses.find(addr => addr.isDefault)?.city || provider.addresses[0].city 
        : '',
      phone: provider.phone,
      experienceYears: Math.round(avgExperienceYears), // Aggregated from services
      languages: provider.languages,
      hourlyRate: Math.round(avgHourlyRate), // Aggregated from services
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

    // Build sort options - price sorting will be done after aggregation
    let sortOptions = { createdAt: -1 }; // Default sort
    if (sortBy === 'rating') {
      sortOptions = { 'rating.average': sortOrder === 'asc' ? 1 : -1 };
    }
    // Note: price sorting is handled after per-service aggregation

    const providers = await Provider.find(filter)
      .select('-password -emailVerificationToken -passwordResetToken -passwordResetTokenHash')
      .sort(sortOptions)
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Provider.countDocuments(filter);
    const totalPages = Math.ceil(total / limit);
    const currentPage = totalPages ? parseInt(page) : 0;

    // Transform providers to match frontend ProviderModel using per-service data
    const transformedProviders = [];
    
    for (const provider of providers) {
      // Get provider's service data from ProviderService collection
      const providerServices = await ProviderService.find({ 
        provider: provider._id, 
        status: { $in: ['active', 'draft'] },
        publishable: true 
      }).populate('service', 'title subcategory');

      // Calculate aggregated data from per-service information
      let avgHourlyRate = 0;
      let avgExperienceYears = 0;
      let totalServices = 0;

      if (providerServices.length > 0) {
        const validServices = providerServices.filter(ps => ps.hourlyRate > 0);
        if (validServices.length > 0) {
          avgHourlyRate = validServices.reduce((sum, ps) => sum + ps.hourlyRate, 0) / validServices.length;
          avgExperienceYears = validServices.reduce((sum, ps) => sum + ps.experienceYears, 0) / validServices.length;
          totalServices = validServices.length;
        }
      }

      // Fallback to provider static data if no service data available
      if (totalServices === 0) {
        avgHourlyRate = provider.hourlyRate || 50;
        avgExperienceYears = provider.experienceYears || 2;
      }

      transformedProviders.push({
        _id: provider._id,
        id: provider._id,
        providerId: provider.providerId,
        name: `${provider.firstName} ${provider.lastName}`.trim(),
        city: provider.addresses && provider.addresses.length > 0 
          ? provider.addresses.find(addr => addr.isDefault)?.city || provider.addresses[0].city 
          : '',
        phone: provider.phone,
        experienceYears: Math.round(avgExperienceYears), // Aggregated from services
        languages: provider.languages,
        hourlyRate: Math.round(avgHourlyRate), // Aggregated from services
        services: provider.services,
        ratingAverage: provider.rating.average,
        ratingCount: provider.rating.count,
        avatarUrl: provider.profileImage,
        rating: {
          average: provider.rating.average,
          count: provider.rating.count
        },
        // Add metadata about per-service data
        _serviceCount: totalServices,
        _hasPerServiceData: totalServices > 0
      });
    }

    // Apply price sorting after aggregation if requested
    if (sortBy === 'price') {
      transformedProviders.sort((a, b) => {
        if (sortOrder === 'asc') {
          return a.hourlyRate - b.hourlyRate;
        } else {
          return b.hourlyRate - a.hourlyRate;
        }
      });
    }

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

// Get provider reviews
async function getProviderReviews(req, res) {
  try {
    const { id } = req.params;
    
    console.log('🔍 Getting provider reviews for provider ID:', id);
    
    const provider = await Provider.findById(id).select('reviews firstName lastName');
    if (!provider) {
      console.log('❌ Provider not found:', id);
      return error(res, 404, 'Provider not found');
    }
    
    console.log('✅ Provider found:', provider.firstName, provider.lastName);
    console.log('📊 Reviews count:', (provider.reviews || []).length);
    console.log('📊 Reviews data:', JSON.stringify(provider.reviews || [], null, 2));
    
    // Return the reviews array
    return ok(res, provider.reviews || [], 'Provider reviews retrieved successfully');
  } catch (e) {
    console.error('getProviderReviews error', e);
    return error(res, 500, 'Failed to get provider reviews');
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
  getProviderStats,
  getProviderReviews
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
