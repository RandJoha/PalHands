const Provider = require('../models/Provider');
const { ok, error } = require('../utils/response');

/**
 * List providers with filtering and search
 */
async function listProviders(req, res) {
  try {
    const { parsePagination } = require('../utils/pagination');
    const { page, limit, skip } = parsePagination(req.query);
    const { city, services, category, sortBy, sortOrder, q } = req.query;

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

module.exports = {
  listProviders,
  getProviderById,
  getProvidersByCategory
};
