const Availability = require('../models/Availability');
const { ok, created, error } = require('../utils/response');

async function getAvailability(req, res) {
  try {
    const providerId = req.params.providerId;
    const a = await Availability.findOne({ provider: providerId });
    return ok(res, a || {});
  } catch (e) {
    return error(res, 400, 'Failed to fetch availability');
  }
}

async function upsertAvailability(req, res) {
  try {
    const providerId = req.params.providerId;
    const data = { ...req.body, provider: providerId };
    const a = await Availability.findOneAndUpdate({ provider: providerId }, data, { upsert: true, new: true, setDefaultsOnInsert: true });
    return ok(res, a, 'Availability saved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to save availability');
  }
}

module.exports = { getAvailability, upsertAvailability };
