const { celebrate, Joi, Segments } = require('celebrate');

const updateProfileValidator = celebrate({
  [Segments.BODY]: Joi.object({
    firstName: Joi.string().trim().max(50).optional(),
    lastName: Joi.string().trim().max(50).allow('').optional(),
    phone: Joi.string().pattern(/^[\+]?[0-9\s\-\(\)]{8,15}$/).optional(),
    profileImage: Joi.string().uri().optional(),
    address: Joi.object({
      street: Joi.string().allow('').optional(),
      city: Joi.string().allow('').optional(),
      area: Joi.string().allow('').optional(),
      coordinates: Joi.object({
        latitude: Joi.number().optional(),
        longitude: Joi.number().optional()
      }).optional()
    }).optional()
  }).min(1)
});

const changePasswordValidator = celebrate({
  [Segments.BODY]: Joi.object({
    currentPassword: Joi.string().required(),
    newPassword: Joi.string().min(6).required()
  })
});

module.exports = { updateProfileValidator, changePasswordValidator };
