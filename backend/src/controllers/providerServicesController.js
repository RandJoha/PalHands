const ProviderService = require('../models/ProviderService');
const Provider = require('../models/Provider');
const { ok, created, error } = require('../utils/response');

function ensureOwnerOrAdmin(req, providerId) {
  try {
    if (!req.user) return false;
    if (req.user.role === 'admin') return true;
    return String(req.user._id) === String(providerId);
  } catch (_) {
    return false;
  }
}

async function listMyServices(req, res) {
  try {
    const { providerId } = req.params;
    const provider = await Provider.findById(providerId).select('_id isActive');
    if (!provider || !provider.isActive) return error(res, 404, 'Provider not found');
    if (!ensureOwnerOrAdmin(req, provider._id)) return error(res, 403, 'Forbidden');

    const items = await ProviderService.find({ provider: provider._id, status: { $ne: 'deleted' } })
      .sort({ updatedAt: -1 });
    return ok(res, { data: items });
  } catch (e) {
    console.error('listMyServices error', e);
    return error(res, 500, 'Failed to list services');
  }
}

async function addService(req, res) {
  try {
    const { providerId } = req.params;
    const provider = await Provider.findById(providerId).select('_id isActive');
    if (!provider || !provider.isActive) return error(res, 404, 'Provider not found');
    if (!ensureOwnerOrAdmin(req, provider._id)) return error(res, 403, 'Forbidden');

    const { serviceKey, serviceTitle, category, hourlyRate, experienceYears } = req.body;
    if (!serviceKey || hourlyRate == null || experienceYears == null) {
      return error(res, 400, 'serviceKey, hourlyRate and experienceYears are required');
    }
    const doc = await ProviderService.create({
      provider: provider._id,
      serviceKey,
      serviceTitle,
      category,
      hourlyRate,
      experienceYears,
      status: 'inactive',
      isPublished: false
    });
    return created(res, { data: doc });
  } catch (e) {
    console.error('addService error', e);
    if (e.code === 11000) return error(res, 409, 'Service already exists for this provider');
    return error(res, 500, 'Failed to add service');
  }
}

async function updateService(req, res) {
  try {
    const { providerId, id } = req.params; // id = providerService id
    const provider = await Provider.findById(providerId).select('_id isActive');
    if (!provider || !provider.isActive) return error(res, 404, 'Provider not found');
    if (!ensureOwnerOrAdmin(req, provider._id)) return error(res, 403, 'Forbidden');

    const payload = {};
    ['hourlyRate', 'experienceYears', 'emergencyEnabled', 'emergencyTypes', 'weekly', 'emergencyWeekly', 'exceptions', 'emergencyExceptions'].forEach(k => {
      if (req.body[k] !== undefined) payload[k] = req.body[k];
    });
    if (req.body.status) payload.status = req.body.status;
    if (req.body.isPublished !== undefined) payload.isPublished = req.body.isPublished;

    // If setting status to active and isPublished not explicitly provided, publish automatically
    if (payload.status === 'active' && payload.isPublished === undefined) {
      payload.isPublished = true;
    }
    // If setting status to inactive and isPublished not explicitly provided, unpublish automatically
    if (payload.status === 'inactive' && payload.isPublished === undefined) {
      payload.isPublished = false;
    }

    const doc = await ProviderService.findOneAndUpdate({ _id: id, provider: provider._id }, { $set: payload }, { new: true });
    if (!doc) return error(res, 404, 'Service not found');
    return ok(res, { data: doc });
  } catch (e) {
    console.error('updateService error', e);
    return error(res, 500, 'Failed to update service');
  }
}

async function removeService(req, res) {
  try {
    const { providerId, id } = req.params;
    const provider = await Provider.findById(providerId).select('_id isActive');
    if (!provider || !provider.isActive) return error(res, 404, 'Provider not found');
    if (!ensureOwnerOrAdmin(req, provider._id)) return error(res, 403, 'Forbidden');
    const doc = await ProviderService.findOneAndUpdate({ _id: id, provider: provider._id }, { $set: { status: 'deleted', isPublished: false } }, { new: true });
    if (!doc) return error(res, 404, 'Service not found');
    return ok(res, { data: doc });
  } catch (e) {
    console.error('removeService error', e);
    return error(res, 500, 'Failed to remove service');
  }
}

async function publishService(req, res) {
  try {
    const { providerId, id } = req.params;
    const provider = await Provider.findById(providerId).select('_id isActive');
    if (!provider || !provider.isActive) return error(res, 404, 'Provider not found');
    if (!ensureOwnerOrAdmin(req, provider._id)) return error(res, 403, 'Forbidden');

    const item = await ProviderService.findOne({ _id: id, provider: provider._id });
    if (!item) return error(res, 404, 'Service not found');
    // Simple gate: require hourlyRate > 0, experienceYears >= 0, and at least one weekly window
    const hasSchedule = item.weekly && Object.values(item.weekly.toObject ? item.weekly.toObject() : item.weekly).some(arr => Array.isArray(arr) && arr.length > 0);
    if (!(item.hourlyRate > 0) || item.experienceYears == null || !hasSchedule) {
      return error(res, 400, 'Please set rate, experience and availability before publishing');
    }
    item.isPublished = true;
    item.status = 'active';
    await item.save();
    return ok(res, { data: item });
  } catch (e) {
    console.error('publishService error', e);
    return error(res, 500, 'Failed to publish service');
  }
}

async function unpublishService(req, res) {
  try {
    const { providerId, id } = req.params;
    const provider = await Provider.findById(providerId).select('_id isActive');
    if (!provider || !provider.isActive) return error(res, 404, 'Provider not found');
    if (!ensureOwnerOrAdmin(req, provider._id)) return error(res, 403, 'Forbidden');

    const doc = await ProviderService.findOneAndUpdate({ _id: id, provider: provider._id }, { $set: { isPublished: false } }, { new: true });
    if (!doc) return error(res, 404, 'Service not found');
    return ok(res, { data: doc });
  } catch (e) {
    console.error('unpublishService error', e);
    return error(res, 500, 'Failed to unpublish service');
  }
}

module.exports = {
  listMyServices,
  addService,
  updateService,
  removeService,
  publishService,
  unpublishService
};
