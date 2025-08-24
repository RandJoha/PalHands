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
    
    // Improved search functionality
    if (q && q.trim().length >= 2) {
      const searchQuery = q.trim();
      // Use text search if available, otherwise use regex
      if (searchQuery.length >= 3) {
        filter.$text = { $search: searchQuery };
      } else {
        // Fallback to regex search for shorter queries
        filter.$or = [
          { title: { $regex: searchQuery, $options: 'i' } },
          { description: { $regex: searchQuery, $options: 'i' } },
          { category: { $regex: searchQuery, $options: 'i' } },
          { subcategory: { $regex: searchQuery, $options: 'i' } }
        ];
      }
    } else if (q && q.trim().length < 2) {
      return error(res, 400, 'Search query must be at least 2 characters long');
    }

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
    
    // Add text score for relevance sorting when using text search
    const sortOptions = { featured: -1, createdAt: -1 };
    if (q && q.trim().length >= 3 && filter.$text) {
      sortOptions.$text = { $meta: 'textScore' };
    } else {
      sortOptions['rating.average'] = -1;
    }
    
    const services = await Service.find(qFilter)
      .populate('provider', 'firstName lastName email rating')
      .sort(sortOptions)
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

async function getMyServices(req, res) {
  try {
    console.log('🔍 Debug: Fetching services for user:', req.user._id);
    
    const services = await Service.find({ provider: req.user._id })
      .populate('provider', 'firstName lastName email rating')
      .sort({ createdAt: -1 });
    
    console.log('🔍 Debug: Found services:', services.length);
    console.log('🔍 Debug: Services:', services.map(s => ({ id: s._id, title: s.title, category: s.category })));
    
    return ok(res, { services });
  } catch (e) {
    console.error('getMyServices error', e);
    return error(res, 400, 'Failed to get services');
  }
}

async function createService(req, res) {
  try {
    const actor = req.user;
    
    console.log('🔍 Debug: Creating service for user:', actor._id, 'Role:', actor.role);
    console.log('🔍 Debug: Request body:', req.body);
    
    // Check if this is a provider creating their own service
    if (actor.role === 'provider') {
      // Provider creating their own service
      const data = { ...req.body, provider: actor._id };
      console.log('🔍 Debug: Service data to create:', data);
      const service = await Service.create(data);
      console.log('🔍 Debug: Service created successfully:', service._id);
      return created(res, service, 'Service created');
    }
    
    // Admin creating service for a provider
    if (!servicePolicies.canCreate(actor)) {
      return error(res, 403, 'Only admins can create services for other providers');
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

// Bulk activate services for provider
async function bulkActivateServices(req, res) {
  try {
    const { serviceIds } = req.body;
    if (!Array.isArray(serviceIds) || serviceIds.length === 0) {
      return error(res, 400, 'serviceIds array is required');
    }

    const result = await Service.updateMany(
      { 
        _id: { $in: serviceIds }, 
        provider: req.user._id 
      },
      { 
        isActive: true,
        updatedAt: Date.now()
      }
    );

    return ok(res, { 
      updatedCount: result.modifiedCount,
      message: `${result.modifiedCount} services activated successfully`
    });
  } catch (e) {
    console.error('bulkActivateServices error', e);
    return error(res, 500, 'Failed to activate services');
  }
}

// Bulk deactivate services for provider
async function bulkDeactivateServices(req, res) {
  try {
    const { serviceIds } = req.body;
    if (!Array.isArray(serviceIds) || serviceIds.length === 0) {
      return error(res, 400, 'serviceIds array is required');
    }

    const result = await Service.updateMany(
      { 
        _id: { $in: serviceIds }, 
        provider: req.user._id 
      },
      { 
        isActive: false,
        updatedAt: Date.now()
      }
    );

    return ok(res, { 
      updatedCount: result.modifiedCount,
      message: `${result.modifiedCount} services deactivated successfully`
    });
  } catch (e) {
    console.error('bulkDeactivateServices error', e);
    return error(res, 500, 'Failed to deactivate services');
  }
}

// Bulk delete services for provider
async function bulkDeleteServices(req, res) {
  try {
    const { serviceIds } = req.body;
    if (!Array.isArray(serviceIds) || serviceIds.length === 0) {
      return error(res, 400, 'serviceIds array is required');
    }

    const result = await Service.deleteMany({
      _id: { $in: serviceIds },
      provider: req.user._id
    });

    return ok(res, { 
      deletedCount: result.deletedCount,
      message: `${result.deletedCount} services deleted successfully`
    });
  } catch (e) {
    console.error('bulkDeleteServices error', e);
    return error(res, 500, 'Failed to delete services');
  }
}

// Submit custom service request for admin approval
async function submitCustomServiceRequest(req, res) {
  try {
    const actor = req.user;
    
    // Create a custom service request
    const customRequest = {
      title: req.body.title,
      description: req.body.description,
      fieldDescription: req.body.fieldDescription,
      category: req.body.category,
      subcategory: req.body.subcategory,
      price: req.body.price,
      provider: actor._id,
      status: 'pending_approval',
      submittedAt: new Date(),
      providerInfo: {
        name: `${actor.firstName} ${actor.lastName}`,
        email: actor.email,
        phone: actor.phone,
      }
    };

    // For now, we'll store this in a simple way
    // In production, you might want a separate CustomServiceRequest model
    console.log('🔔 ADMIN NOTIFICATION: New custom service request submitted');
    console.log('Provider:', customRequest.providerInfo.name);
    console.log('Service:', customRequest.title);
    console.log('Description:', customRequest.description);
    console.log('Price:', customRequest.price);
    console.log('Category:', customRequest.category);
    console.log('Subcategory:', customRequest.subcategory);
    console.log('Submitted at:', customRequest.submittedAt);
    console.log('---');

    // TODO: Store in database and send admin notification
    // For now, just log it and return success
    
    return ok(res, { 
      requestId: `req_${Date.now()}`,
      message: 'Custom service request submitted successfully. Admin will review and approve/reject.',
      status: 'pending_approval'
    }, 'Custom service request submitted');
    
  } catch (e) {
    console.error('submitCustomServiceRequest error', e);
    return error(res, 400, e.message || 'Failed to submit custom service request');
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

module.exports = { listServices, getServiceById, getMyServices, createService, updateService, deleteService, uploadServiceImages, presignServiceImages, attachServiceImages, cleanupServiceImages, submitCustomServiceRequest, bulkActivateServices, bulkDeactivateServices, bulkDeleteServices };
