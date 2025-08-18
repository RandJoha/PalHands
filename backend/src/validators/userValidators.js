const { celebrate, Joi, Segments } = require('celebrate');

// Predefined cities list (lowercase) to align with FE dropdown
// Note: keep values lowercase to match current FE payloads (e.g., 'hebron', 'tulkarm')
const ALLOWED_CITIES = [
  'jerusalem', 'ramallah', 'nablus', 'hebron', 'bethlehem', 'jericho', 'tulkarm', 'qalqilya', 'jenin', 'salfit', 'tubas',
  'gaza', 'rafah', 'khan yunis', 'deir al-balah', 'north gaza'
];

const addressItem = Joi.object({
  type: Joi.string().valid('home', 'work', 'other').optional(),
  street: Joi.string().allow('').optional(),
  city: Joi.string().valid(...ALLOWED_CITIES).allow('').optional(),
  area: Joi.string().allow('').optional(),
  coordinates: Joi.object({
    // Accept numbers or null to avoid 400 when FE sends null placeholders
    latitude: Joi.number().allow(null).optional(),
    longitude: Joi.number().allow(null).optional()
  }).optional(),
  isDefault: Joi.boolean().optional()
});

const updateProfileValidator = celebrate({
  [Segments.BODY]: Joi.object({
    firstName: Joi.string().trim().max(50).optional(),
    lastName: Joi.string().trim().max(50).allow('').optional(),
    email: Joi.string().email().optional(),
    phone: Joi.string().pattern(/^[\+]?[0-9\s\-\(\)]{8,15}$/).optional(),
    profileImage: Joi.string().uri().optional(),
    age: Joi.number().integer().min(0).max(120).optional(),
    address: addressItem.optional(),
    addresses: Joi.array().items(addressItem).optional()
  }).min(1)
});

const changePasswordValidator = celebrate({
  [Segments.BODY]: Joi.object({
    currentPassword: Joi.string().required(),
    newPassword: Joi.string().min(6).required()
  })
});

module.exports = { updateProfileValidator, changePasswordValidator };
