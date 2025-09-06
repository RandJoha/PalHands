const { celebrate, Joi, Segments } = require('celebrate');

// Validation schema for creating services (admin interface)
const createServiceValidator = celebrate({
  [Segments.BODY]: Joi.object({
    title: Joi.string().trim().required(),
    description: Joi.string().trim().required(),
    category: Joi.string().valid(
      'cleaning','organizing','cooking','childcare','elderly','maintenance','newhome','miscellaneous',
      'laundry','caregiving','furniture_moving','elderly_support','aluminum_work','carpentry','home_nursing','other'
    ).required(),
    subcategory: Joi.string().trim().allow('').optional(),
    // Make price optional for admin-created services
    price: Joi.object({
      amount: Joi.number().positive().default(0),
      type: Joi.string().valid('hourly','fixed','daily').default('hourly'),
      currency: Joi.string().default('ILS')
    }).optional(),
    // Make location optional for admin-created services
    location: Joi.object({
      serviceArea: Joi.string().default('General'),
      radius: Joi.number().min(0).default(10),
      onSite: Joi.boolean().default(true),
      remote: Joi.boolean().default(false)
    }).optional(),
    // Admin-only: must specify provider id
    provider: Joi.string().hex().length(24).required()
  })
});

// Validation schema for simple admin service creation (minimal fields)
const createSimpleServiceValidator = celebrate({
  [Segments.BODY]: Joi.object({
    title: Joi.string().trim().required(),
    description: Joi.string().trim().required(),
    category: Joi.string().valid(
      'cleaning','organizing','cooking','childcare','elderly','maintenance','newhome','miscellaneous',
      'laundry','caregiving','furniture_moving','elderly_support','aluminum_work','carpentry','home_nursing','other'
    ).required(),
    subcategory: Joi.string().trim().allow('').optional(),
    // Optional provider - if not provided, will be null
    provider: Joi.string().hex().length(24).optional()
  })
});

const updateServiceValidator = celebrate({
  [Segments.BODY]: Joi.object({
    title: Joi.string().trim().optional(),
    description: Joi.string().trim().optional(),
    category: Joi.string().valid(
      'cleaning','organizing','cooking','childcare','elderly','maintenance','newhome','miscellaneous',
      'laundry','caregiving','furniture_moving','elderly_support','aluminum_work','carpentry','home_nursing','other'
    ).optional(),
    subcategory: Joi.string().trim().allow('').optional(),
    price: Joi.object({
      amount: Joi.number().positive().optional(),
      type: Joi.string().valid('hourly','fixed','daily').optional(),
      currency: Joi.string().optional()
    }).optional(),
    duration: Joi.object({ 
      estimated: Joi.number().integer().min(0).optional(), 
      flexible: Joi.boolean().optional() 
    }).optional(),
    availability: Joi.object({
      days: Joi.array().items(Joi.string().valid('monday','tuesday','wednesday','thursday','friday','saturday','sunday')).optional(),
      timeSlots: Joi.array().items(Joi.object({ 
        start: Joi.string().pattern(/^\d{2}:\d{2}$/), 
        end: Joi.string().pattern(/^\d{2}:\d{2}$/) 
      })).optional(),
      flexible: Joi.boolean().optional()
    }).optional(),
    location: Joi.object({
      serviceArea: Joi.string().optional(),
      radius: Joi.number().min(0).optional(),
      onSite: Joi.boolean().optional(),
      remote: Joi.boolean().optional(),
      geo: Joi.object({ 
        type: Joi.string().valid('Point').required(), 
        coordinates: Joi.array().length(2).items(Joi.number()).required() 
      }).optional()
    }).optional(),
    images: Joi.array().items(Joi.object({ 
      url: Joi.string().uri().required(), 
      alt: Joi.string().allow('') 
    })).optional(),
    requirements: Joi.array().items(Joi.string()).optional(),
    equipment: Joi.array().items(Joi.string()).optional(),
    isActive: Joi.boolean().optional()
  }).min(1)
});

module.exports = {
  createServiceValidator,
  createSimpleServiceValidator,
  updateServiceValidator
};
