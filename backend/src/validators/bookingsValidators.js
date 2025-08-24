const { celebrate, Joi, Segments } = require('celebrate');

const createBookingValidator = celebrate({
  [Segments.BODY]: Joi.object({
    clientId: Joi.string().hex().length(24).optional(),
    serviceId: Joi.string().hex().length(24).required(),
    schedule: Joi.object({
      date: Joi.date().iso().required(),
      startTime: Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
      endTime: Joi.string().pattern(/^\d{2}:\d{2}$/).required(),
      duration: Joi.number().integer().min(0).optional()
    }).required(),
    location: Joi.object({
      address: Joi.string().required(),
      coordinates: Joi.object({ latitude: Joi.number(), longitude: Joi.number() }).optional(),
      instructions: Joi.string().allow('').optional()
    }).required(),
    notes: Joi.string().allow('').optional()
  })
});

const updateStatusValidator = celebrate({
  [Segments.BODY]: Joi.object({ status: Joi.string().valid('confirmed','in_progress','completed','cancelled','disputed').required() })
});

module.exports = { createBookingValidator, updateStatusValidator };
