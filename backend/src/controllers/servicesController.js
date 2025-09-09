const mongoose = require('mongoose');
const Service = require('../models/Service');
const { ok, created, error } = require('../utils/response');
const { servicePolicies } = require('../policies');
const { validateEnv } = require('../utils/config');
const { getPresignedPutUrls, objectExists, cleanupOrphansForService, ALLOWED_IMAGE_TYPES } = require('../services/storage');
const env = validateEnv();

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
  
  console.log(`🔄 Deduplicated services: ${services.length} -> ${deduplicatedServices.length}`);
  
  return deduplicatedServices;
}

// List services with basic filters
async function listServices(req, res) {
  try {
    const { parsePagination } = require('../utils/pagination');
    const { page, limit, skip } = parsePagination(req.query);
    const { category, q, area, providerId, near, maxDistanceKm } = req.query;

    const filter = { isActive: true };
    if (category) filter.category = category;
    if (providerId) {
      filter.provider = providerId;
      // Telemetry: mark usage of deprecated providerId flow on /services
      try { res.set('X-Deprecated-Provider-Query', '1'); } catch (_) {}
      // console.warn(`[DEPRECATION] /services?providerId=${providerId} used. Prefer /provider-services/public?providerId=...`);
      // Optional feature flag: block legacy providerId path (safe default: off)
      const usePublicOnly = String(process.env.USE_PROVIDER_SERVICES_PUBLIC_ONLY || 'false').toLowerCase() === 'true';
      if (usePublicOnly) {
        try { res.set('X-Deprecated-Provider-Query', 'blocked'); } catch (_) {}
        return ok(res, { services: [], pagination: { current: 0, total: 0, totalRecords: 0 } }, 'Use /provider-services/public instead');
      }
    }
    if (area) filter['location.serviceArea'] = { $regex: area, $options: 'i' };
    if (q) filter.$text = { $search: q };

    let geoQuery = null;
    if (near) {
      const [lngStr, latStr] = String(near).split(',');
      const lng = parseFloat(lngStr); const lat = parseFloat(latStr);
      if (!Number.isNaN(lng) && !Number.isNaN(lat)) {
        const maxMeters = Math.min(200000, Math.max(100, parseFloat(maxDistanceKm || '10') * 1000));
        geoQuery = {
          'location.geo': {
            $near: {
              $geometry: { type: 'Point', coordinates: [lng, lat] },
              $maxDistance: maxMeters
            }
          }
        };
      }
    }

  const qFilter = geoQuery ? { ...filter, ...geoQuery } : filter;
  let services = await Service.find(qFilter)
      .populate('provider', 'firstName lastName email rating')
      .sort({ featured: -1, 'rating.average': -1, createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();
    // Fallback: if no services found and caller filtered by providerId, try to resolve
    // provider.services (string IDs) and load those services (some providers reference
    // services by string ids instead of setting Service.provider).
    if ((!services || services.length === 0) && providerId) {
      try {
        const Provider = require('../models/Provider');
        const prov = await Provider.findById(providerId).select('services');
        if (prov && Array.isArray(prov.services) && prov.services.length) {
          // Filter valid ObjectId strings
          const ids = prov.services.map(s => {
            try { return mongoose.Types.ObjectId(String(s)); } catch (_) { return null; }
          }).filter(Boolean);
          if (ids.length) {
            services = await Service.find({ _id: { $in: ids } })
              .populate('provider', 'firstName lastName email rating')
              .sort({ featured: -1, 'rating.average': -1, createdAt: -1 })
              .skip(skip)
              .limit(parseInt(limit))
              .lean();
          }
        }
      } catch (_) {
        // ignore fallback errors
      }
    }

    // Gate by ProviderService publishable+active when providerId specified
  if (providerId) {
      try {
        const ProviderService = require('../models/ProviderService');
        const psDocs = await ProviderService
          .find({ provider: providerId, status: 'active', publishable: true })
          .select('service hourlyRate experienceYears emergencyEnabled emergencyLeadTimeMinutes')
          .lean();
        const allowedMap = new Map(psDocs.map(ps => [String(ps.service), ps]));
        // Keep only services with an active+publishable ProviderService entry
        services = services.filter(s => allowedMap.has(String(s._id)));
        // Overlay ProviderService per-service fields (price.amount, experienceYears, emergency flags)
        services = services.map(s => {
          const ps = allowedMap.get(String(s._id));
          if (ps) {
            // Ensure price exists
            s.price = s.price || { amount: 0, type: 'hourly', currency: 'ILS' };
            if (Number.isFinite(ps.hourlyRate)) {
              s.price.amount = ps.hourlyRate;
            }
            if (Number.isFinite(ps.experienceYears)) {
              s.experienceYears = ps.experienceYears;
            }
            // Reflect per-provider emergency toggle and lead time when present
            if (typeof ps.emergencyEnabled === 'boolean') {
              s.emergencyEnabled = !!ps.emergencyEnabled;
            }
            if (Number.isFinite(ps.emergencyLeadTimeMinutes)) {
              s.emergencyLeadTimeMinutes = ps.emergencyLeadTimeMinutes;
            }
          }
          return s;
        });
      } catch (e) {
        // If overlay fails, continue with original services list
      }
    }

    // Deduplicate services by title to avoid duplicates from provider-service relationships
    const deduplicatedServices = deduplicateServicesByTitle(services);

    const total = deduplicatedServices.length; // simple total post-filter to avoid double queries
    const totalPages = Math.ceil(total / limit);
    const currentPage = totalPages ? parseInt(page) : 0;

    return ok(res, {
      services: deduplicatedServices,
      pagination: { current: currentPage, total: totalPages, totalRecords: total }
    });
  } catch (e) {
    console.error('listServices error', e);
    return error(res, 500, 'Failed to fetch services');
  }
}

async function getServiceById(req, res) {
  try {
    const service = await Service.findById(req.params.id).populate('provider', 'firstName lastName email rating');
    if (!service) return error(res, 404, 'Service not found');
    return ok(res, service);
  } catch (e) {
    return error(res, 404, 'Service not found');
  }
}

async function createService(req, res) {
  try {
    // Enforce admin-only via policies
    const actor = req.user;
    if (!servicePolicies.canCreate(actor)) {
      return error(res, 403, 'Only admins can create services');
    }

    // Admin must specify a valid provider id
    const User = require('../models/User');
    const providerIdFromBody = req.body.provider;
    if (!providerIdFromBody) {
      return error(res, 400, 'Missing provider field: admin must assign a provider user ID');
    }
    const p = await User.findById(providerIdFromBody);
    if (!p || p.role !== 'provider') {
      return error(res, 400, 'Invalid provider id for service creation');
    }

    const data = { ...req.body, provider: p._id };
    const service = await Service.create(data);
    return created(res, service, 'Service created');
  } catch (e) {
    console.error('createService error', e);
    return error(res, 400, e.message || 'Failed to create service');
  }
}

async function createSimpleService(req, res) {
  try {
    // Enforce admin-only via policies
    const actor = req.user;
    if (!servicePolicies.canCreate(actor)) {
      return error(res, 403, 'Only admins can create services');
    }

    // Prepare service data with defaults
    const serviceData = {
      title: req.body.title,
      description: req.body.description,
      category: req.body.category,
      subcategory: req.body.subcategory || '',
      // Set default values for required fields
      price: {
        amount: 0,
        type: 'hourly',
        currency: 'ILS'
      },
      location: {
        serviceArea: 'General',
        radius: 10,
        onSite: true,
        remote: false
      },
      provider: null, // Will be assigned later
      isActive: true
    };

    // If provider ID is provided, validate it
    if (req.body.provider) {
      const User = require('../models/User');
      const provider = await User.findById(req.body.provider);
      if (provider && provider.role === 'provider') {
        serviceData.provider = provider._id;
      }
    }

    const service = await Service.create(serviceData);
    return created(res, service, 'Service created successfully');
  } catch (e) {
    console.error('createSimpleService error', e);
    return error(res, 400, e.message || 'Failed to create service');
  }
}

async function updateService(req, res) {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) return error(res, 404, 'Service not found');

    // Ownership via policies
    if (!servicePolicies.canModify(req.user, service)) {
      return error(res, 403, 'You can only modify your own services');
    }

    Object.assign(service, req.body, { updatedAt: Date.now() });
    await service.save();
    return ok(res, service, 'Service updated');
  } catch (e) {
    console.error('updateService error', e);
    return error(res, 400, e.message || 'Failed to update service');
  }
}

async function deleteService(req, res) {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) return error(res, 404, 'Service not found');

    if (!servicePolicies.canModify(req.user, service)) {
      return error(res, 403, 'You can only delete your own services');
    }

    await service.deleteOne();
    return ok(res, {}, 'Service deleted');
  } catch (e) {
    return error(res, 400, 'Failed to delete service');
  }
}

// Upload images and attach to service (admin only via route guard)
async function uploadServiceImages(req, res) {
  try {
    if (env.STORAGE_DRIVER !== 'local') {
      return error(res, 400, 'Direct upload not allowed with non-local storage. Use presign + attach flow.');
    }
    const service = await Service.findById(req.params.id);
    if (!service) return error(res, 404, 'Service not found');

    // Authorization: admin handled via route checkRole(['admin'])
    const files = req.files || [];
    if (!files.length) return error(res, 400, 'No files uploaded');

    const newImages = files.map((f) => ({
      url: `/uploads/services/${service._id}/${f.filename}`,
      alt: req.body.alt || service.title
    }));
    service.images = [...(service.images || []), ...newImages];
    service.updatedAt = Date.now();
    await service.save();

    return ok(res, { images: service.images }, 'Images uploaded');
  } catch (e) {
    console.error('uploadServiceImages error', e);
    return error(res, 400, e.message || 'Failed to upload images');
  }
}

// Presign S3/MinIO URLs for direct upload
async function presignServiceImages(req, res) {
  try {
    if (env.STORAGE_DRIVER === 'local') {
      return error(res, 400, 'Presign not required for local storage');
    }
    const service = await Service.findById(req.params.id);
    if (!service) return error(res, 404, 'Service not found');

    const files = req.body?.files || [];
    if (!Array.isArray(files) || !files.length) return error(res, 400, 'files[] required');
    const uploads = await getPresignedPutUrls({ serviceId: service._id.toString(), files });
    return ok(res, { uploads, allowed: ALLOWED_IMAGE_TYPES, maxFileSize: env.MAX_FILE_SIZE }, 'Presigned URLs');
  } catch (e) {
    console.error('presignServiceImages error', e);
    const status = e.statusCode || 400;
    return error(res, status, e.message || 'Failed to presign');
  }
}

// Attach already uploaded images by key to the service
async function attachServiceImages(req, res) {
  try {
    if (env.STORAGE_DRIVER === 'local') {
      return error(res, 400, 'Attach flow is for S3/MinIO storage');
    }
    const service = await Service.findById(req.params.id);
    if (!service) return error(res, 404, 'Service not found');

    const images = req.body?.images || [];
    if (!Array.isArray(images) || !images.length) return error(res, 400, 'images[] required');

    const valid = [];
    for (const img of images) {
      const exists = await objectExists(img.key);
      if (exists) {
        valid.push({ url: `/${img.key}`, alt: img.alt || service.title });
      }
    }
    if (!valid.length) return error(res, 400, 'No valid images to attach');
    service.images = [...(service.images || []), ...valid];
    service.updatedAt = Date.now();
    await service.save();
    return ok(res, { images: service.images }, 'Images attached');
  } catch (e) {
    console.error('attachServiceImages error', e);
    return error(res, 400, e.message || 'Failed to attach images');
  }
}

// Cleanup orphans for a service (admin)
async function cleanupServiceImages(req, res) {
  try {
    if (env.STORAGE_DRIVER === 'local') {
      return error(res, 400, 'Cleanup is for S3/MinIO storage');
    }
    const service = await Service.findById(req.params.id);
    if (!service) return error(res, 404, 'Service not found');
    const result = await cleanupOrphansForService(service);
    return ok(res, result, 'Cleanup done');
  } catch (e) {
    console.error('cleanupServiceImages error', e);
    return error(res, 400, e.message || 'Failed to cleanup');
  }
}

// Admin: set emergency configuration for a service
async function setServiceEmergency(req, res) {
  try {
    const service = await Service.findById(req.params.id);
    if (!service) return error(res, 404, 'Service not found');

    // Only admins can set emergency flags — route should be guarded, but double-check
    if (!servicePolicies.canModify(req.user, service)) return error(res, 403, 'Not authorized');

    const { emergencyEnabled, emergencyRateMultiplier, emergencySurcharge, emergencyLeadTimeMinutes } = req.body;
    if (typeof emergencyEnabled !== 'undefined') service.emergencyEnabled = !!emergencyEnabled;
    if (typeof emergencyRateMultiplier !== 'undefined') service.emergencyRateMultiplier = parseFloat(emergencyRateMultiplier) || service.emergencyRateMultiplier;
    if (typeof emergencySurcharge !== 'undefined') service.emergencySurcharge = parseFloat(emergencySurcharge) || service.emergencySurcharge;
    if (typeof emergencyLeadTimeMinutes !== 'undefined') service.emergencyLeadTimeMinutes = parseInt(emergencyLeadTimeMinutes) || service.emergencyLeadTimeMinutes;

    service.updatedAt = Date.now();
    await service.save();
    return ok(res, service, 'Service emergency configuration updated');
  } catch (e) {
    console.error('setServiceEmergency error', e);
    return error(res, 400, e.message || 'Failed to update service emergency settings');
  }

}

module.exports = { listServices, getServiceById, createService, createSimpleService, updateService, deleteService, uploadServiceImages, presignServiceImages, attachServiceImages, cleanupServiceImages, setServiceEmergency };
