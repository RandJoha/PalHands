const express = require('express');
const router = express.Router();
const { auth: authenticate, checkRole } = require('../middleware/auth');
const { celebrate, Joi, Segments } = require('celebrate');
const availabilityController = require('../controllers/availabilityController');

const timeWindow = Joi.object({ start: Joi.string().pattern(/^\d{2}:\d{2}$/).required(), end: Joi.string().pattern(/^\d{2}:\d{2}$/).required() });

const upsertSchema = celebrate({
  [Segments.BODY]: Joi.object({
    timezone: Joi.string().required(),
    weekly: Joi.object({
      monday: Joi.array().items(timeWindow).default([]),
      tuesday: Joi.array().items(timeWindow).default([]),
      wednesday: Joi.array().items(timeWindow).default([]),
      thursday: Joi.array().items(timeWindow).default([]),
      friday: Joi.array().items(timeWindow).default([]),
      saturday: Joi.array().items(timeWindow).default([]),
      sunday: Joi.array().items(timeWindow).default([])
    }).required(),
    exceptions: Joi.array().items(Joi.object({ date: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required(), windows: Joi.array().items(timeWindow).default([]) })).default([])
  })
});

// Get raw availability: public view
router.get('/:providerId', availabilityController.getAvailability);

// Get resolved availability with bookings applied (public)
router.get('/:providerId/resolve', celebrate({
  [Segments.QUERY]: Joi.object({
    from: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).optional(),
    to: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).optional(),
  step: Joi.number().integer().min(10).max(180).optional(),
  emergency: Joi.boolean().optional(),
  serviceId: Joi.string().hex().length(24).optional()
  })
}), availabilityController.getResolvedAvailability);

// Update availability:
// - provider can update only their own record
router.put('/:providerId', authenticate, upsertSchema, (req, res, next) => {
  const isSelf = req.user && req.user.role === 'provider' && String(req.user._id) === String(req.params.providerId);
  if (!isSelf) {
    return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'You can only modify your own availability' });
  }
  return availabilityController.upsertAvailability(req, res, next);
});

module.exports = router;
