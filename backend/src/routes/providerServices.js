const express = require('express');
const router = express.Router();
const { auth: authenticate, checkRole } = require('../middleware/auth');
const ctrl = require('../controllers/providerServicesController');
const { celebrate, Joi, Segments } = require('celebrate');

const addSchema = celebrate({
  [Segments.BODY]: Joi.object({
    serviceId: Joi.string().hex().length(24).required(),
    hourlyRate: Joi.number().positive().required(),
    experienceYears: Joi.number().min(0).required(),
    emergencyEnabled: Joi.boolean().optional(),
    emergencyLeadTimeMinutes: Joi.number().integer().min(0).max(1440).optional(),
    weeklyOverrides: Joi.object().optional(),
    exceptionOverrides: Joi.array().items(Joi.object({ date: Joi.string(), windows: Joi.array().items(Joi.object({ start: Joi.string(), end: Joi.string() }))})).optional()
  })
});

const updateSchema = celebrate({
  [Segments.BODY]: Joi.object({
    hourlyRate: Joi.number().positive().optional(),
    experienceYears: Joi.number().min(0).optional(),
    emergencyEnabled: Joi.boolean().optional(),
    emergencyLeadTimeMinutes: Joi.number().integer().min(0).max(1440).optional(),
  weeklyOverrides: Joi.alternatives(Joi.object(), Joi.valid(null)).optional(),
  exceptionOverrides: Joi.alternatives(Joi.array(), Joi.valid(null)).optional(),
  emergencyWeeklyOverrides: Joi.alternatives(Joi.object(), Joi.valid(null)).optional(),
  emergencyExceptionOverrides: Joi.alternatives(Joi.array(), Joi.valid(null)).optional()
  }).min(1)
});

// Public aggregated read (migration safe) - active & publishable only
router.get('/public', ctrl.listPublic);

// Authenticated management routes
router.get('/:providerId', authenticate, ctrl.listMy);
router.post('/:providerId', authenticate, addSchema, ctrl.add);
router.patch('/:providerId/:id', authenticate, updateSchema, ctrl.update);
router.post('/:providerId/:id/deactivate-month', authenticate, ctrl.deactivateMonth);
router.post('/:providerId/:id/activate-month', authenticate, ctrl.activateMonth);
router.delete('/:providerId/:id', authenticate, ctrl.remove);

module.exports = router;
