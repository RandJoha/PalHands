const { celebrate, Joi, Segments } = require('celebrate');

const registerValidator = celebrate({
  [Segments.BODY]: Joi.object({
    firstName: Joi.string().trim().max(50).required(),
    lastName: Joi.string().trim().max(50).allow('').optional(),
    email: Joi.string().email().required(),
    phone: Joi.string().pattern(/^[\+]?[0-9\s\-\(\)]{8,15}$/).required(),
    password: Joi.string().min(6).required(),
    role: Joi.string().valid('client', 'provider', 'admin').optional(),
    age: Joi.number().integer().min(1).max(120).required(),
    address: Joi.object({
      city: Joi.string().trim().required(),
      street: Joi.string().trim().required(),
    }).required(),
  })
});

const loginValidator = celebrate({
  [Segments.BODY]: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required()
  })
});

const forgotPasswordValidator = celebrate({
  [Segments.BODY]: Joi.object({
    email: Joi.string().email().required()
  })
});

const resetPasswordValidator = celebrate({
  [Segments.BODY]: Joi.object({
    token: Joi.string().required(),
    newPassword: Joi.string().min(6).required()
  })
});

const changePasswordDirectValidator = celebrate({
  [Segments.BODY]: Joi.object({
    email: Joi.string().email().required(),
    currentPassword: Joi.string().min(6).required(),
    newPassword: Joi.string().min(6).required(),
  })
});

module.exports = { registerValidator, loginValidator, forgotPasswordValidator, resetPasswordValidator, changePasswordDirectValidator };
