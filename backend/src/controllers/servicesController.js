const Service = require('../models/Service');
const { ok, created, error } = require('../utils/response');
const { servicePolicies } = require('../policies');
const { validateEnv } = require('../utils/config');
const { getPresignedPutUrls, objectExists, cleanupOrphansForService, ALLOWED_IMAGE_TYPES } = require('../services/storage');
const env = validateEnv();

// List services with basic filters
async function listServices(req, res) {
  try {
    const { parsePagination } = require('../utils/pagination');
    const { page, limit, skip } = parsePagination(req.query);
    const { category, q, area, providerId, near, maxDistanceKm } = req.query;

    const filter = { isActive: true };
    if (category) filter.category = category;
    if (providerId) filter.provider = providerId;
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
    const services = await Service.find(qFilter)
      .populate('provider', 'firstName lastName email rating')
      .sort({ featured: -1, 'rating.average': -1, createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    const total = await Service.countDocuments(qFilter);
    const totalPages = Math.ceil(total / limit);
    const currentPage = totalPages ? parseInt(page) : 0;

    return ok(res, {
      services,
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
    // Only admins (route guarded) or owner can set; double-check policies
    if (!servicePolicies.canModify(req.user, service)) return error(res, 403, 'Not allowed');

    const { emergencyEnabled, emergencyRateMultiplier, emergencySurcharge, emergencyTypes, emergencyLeadTimeMinutes } = req.body || {};
    if (typeof emergencyEnabled === 'boolean') service.emergencyEnabled = emergencyEnabled;
    if (typeof emergencyRateMultiplier === 'number') service.emergencyRateMultiplier = emergencyRateMultiplier;
    if (emergencySurcharge && typeof emergencySurcharge === 'object') service.emergencySurcharge = emergencySurcharge;
    if (Array.isArray(emergencyTypes)) service.emergencyTypes = emergencyTypes;
    if (typeof emergencyLeadTimeMinutes === 'number') service.emergencyLeadTimeMinutes = emergencyLeadTimeMinutes;
    service.updatedAt = Date.now();
    await service.save();
    return ok(res, service, 'Service emergency configuration updated');
  } catch (e) {
    console.error('setServiceEmergency error', e);
    return error(res, 400, e.message || 'Failed to update emergency config');
  }
}

module.exports = { listServices, getServiceById, createService, updateService, deleteService, uploadServiceImages, presignServiceImages, attachServiceImages, cleanupServiceImages, setServiceEmergency };
