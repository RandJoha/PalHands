const Service = require('../models/Service');
const { ok, created, error } = require('../utils/response');
const { servicePolicies } = require('../policies');

// List services with basic filters
async function listServices(req, res) {
  try {
    const { page = 1, limit = 20, category, q, area, providerId } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const filter = { isActive: true };
    if (category) filter.category = category;
    if (providerId) filter.provider = providerId;
    if (area) filter['location.serviceArea'] = { $regex: area, $options: 'i' };
    if (q) filter.$text = { $search: q };

    const services = await Service.find(filter)
      .populate('provider', 'firstName lastName email rating')
      .sort({ featured: -1, 'rating.average': -1, createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
    const total = await Service.countDocuments(filter);
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

module.exports = { listServices, getServiceById, createService, updateService, deleteService };
