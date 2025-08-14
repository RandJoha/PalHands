const { celebrate, Joi, Segments } = require('celebrate');

const createServiceValidator = celebrate({
  [Segments.BODY]: Joi.object({
    title: Joi.string().trim().required(),
    description: Joi.string().trim().required(),
    category: Joi.string().valid('cleaning','laundry','caregiving','furniture_moving','elderly_support','aluminum_work','carpentry','home_nursing','maintenance','other').required(),
    subcategory: Joi.string().trim().allow('').optional(),
    price: Joi.object({ amount: Joi.number().positive().required(), type: Joi.string().valid('hourly','fixed','daily').required(), currency: Joi.string().default('ILS') }).required(),
    duration: Joi.object({ estimated: Joi.number().integer().min(0).optional(), flexible: Joi.boolean().optional() }).optional(),
    availability: Joi.object({ days: Joi.array().items(Joi.string().valid('monday','tuesday','wednesday','thursday','friday','saturday','sunday')).optional(), timeSlots: Joi.array().items(Joi.object({ start: Joi.string().pattern(/^\d{2}:\d{2}$/), end: Joi.string().pattern(/^\d{2}:\d{2}$/) })).optional(), flexible: Joi.boolean().optional() }).optional(),
    location: Joi.object({ serviceArea: Joi.string().required(), radius: Joi.number().min(0).default(10), onSite: Joi.boolean().default(true), remote: Joi.boolean().default(false) }).required(),
    images: Joi.array().items(Joi.object({ url: Joi.string().uri().required(), alt: Joi.string().allow('') })).optional(),
    requirements: Joi.array().items(Joi.string()).optional(),
    equipment: Joi.array().items(Joi.string()).optional(),
    provider: Joi.string().hex().length(24).required()
  })
});

const updateServiceValidator = celebrate({
  [Segments.BODY]: Joi.object({
    title: Joi.string().trim().optional(),
    description: Joi.string().trim().optional(),
    category: Joi.string().valid('cleaning','laundry','caregiving','furniture_moving','elderly_support','aluminum_work','carpentry','home_nursing','maintenance','other').optional(),
    subcategory: Joi.string().trim().allow('').optional(),
    price: Joi.object({ amount: Joi.number().positive().optional(), type: Joi.string().valid('hourly','fixed','daily').optional(), currency: Joi.string().optional() }).optional(),
    duration: Joi.object({ estimated: Joi.number().integer().min(0).optional(), flexible: Joi.boolean().optional() }).optional(),
    availability: Joi.object({ days: Joi.array().items(Joi.string().valid('monday','tuesday','wednesday','thursday','friday','saturday','sunday')).optional(), timeSlots: Joi.array().items(Joi.object({ start: Joi.string().pattern(/^\d{2}:\d{2}$/), end: Joi.string().pattern(/^\d{2}:\d{2}$/) })).optional(), flexible: Joi.boolean().optional() }).optional(),
    location: Joi.object({ serviceArea: Joi.string().optional(), radius: Joi.number().min(0).optional(), onSite: Joi.boolean().optional(), remote: Joi.boolean().optional() }).optional(),
    images: Joi.array().items(Joi.object({ url: Joi.string().uri().required(), alt: Joi.string().allow('') })).optional(),
    requirements: Joi.array().items(Joi.string()).optional(),
    equipment: Joi.array().items(Joi.string()).optional(),
    isActive: Joi.boolean().optional()
  }).min(1)
});

module.exports = { createServiceValidator, updateServiceValidator };
