const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const servicesController = require('../controllers/servicesController');
const { uploadServiceImages } = require('../middleware/upload');
const { celebrate, Joi, Segments } = require('celebrate');
const { validateEnv } = require('../utils/config');
const env = validateEnv();

// Validation schemas
const createServiceValidator = celebrate({
  [Segments.BODY]: Joi.object({
    title: Joi.string().trim().required(),
    description: Joi.string().trim().required(),
    category: Joi.string().valid(
      'cleaning','laundry','caregiving','furniture_moving','elderly_support','aluminum_work','carpentry','home_nursing','maintenance','other'
    ).required(),
    subcategory: Joi.string().trim().allow('').optional(),
    price: Joi.object({
      amount: Joi.number().positive().required(),
      type: Joi.string().valid('hourly','fixed','daily').required(),
      currency: Joi.string().default('ILS')
    }).required(),
    duration: Joi.object({
      estimated: Joi.number().integer().min(0).optional(),
      flexible: Joi.boolean().optional()
    }).optional(),
    availability: Joi.object({
      days: Joi.array().items(Joi.string().valid('monday','tuesday','wednesday','thursday','friday','saturday','sunday')).optional(),
      timeSlots: Joi.array().items(Joi.object({ start: Joi.string().pattern(/^\d{2}:\d{2}$/), end: Joi.string().pattern(/^\d{2}:\d{2}$/) })).optional(),
      flexible: Joi.boolean().optional()
    }).optional(),
    location: Joi.object({
      serviceArea: Joi.string().required(),
      radius: Joi.number().min(0).default(10),
      onSite: Joi.boolean().default(true),
  remote: Joi.boolean().default(false),
  geo: Joi.object({ type: Joi.string().valid('Point').required(), coordinates: Joi.array().length(2).items(Joi.number()).required() }).optional()
    }).required(),
    images: Joi.array().items(Joi.object({ url: Joi.string().uri().required(), alt: Joi.string().allow('') })).optional(),
    requirements: Joi.array().items(Joi.string()).optional(),
  equipment: Joi.array().items(Joi.string()).optional(),
  // Admin-only: must specify provider id
  provider: Joi.string().hex().length(24).required()
  })
});

// Provider service creation validator (provider field is optional since it's auto-assigned)
const createProviderServiceValidator = celebrate({
  [Segments.BODY]: Joi.object({
    title: Joi.string().trim().required(),
    description: Joi.string().trim().allow('').default(''),
    category: Joi.string().valid(
      'cleaning','laundry','caregiving','furniture_moving','elderly_support','aluminum_work','carpentry','home_nursing','maintenance','other'
    ).required(),
    subcategory: Joi.string().trim().allow('').optional(),
    price: Joi.object({
      amount: Joi.number().positive().required(),
      type: Joi.string().valid('hourly','fixed','daily').required(),
      currency: Joi.string().default('ILS')
    }).required(),
    duration: Joi.object({
      estimated: Joi.number().integer().min(0).optional(),
      flexible: Joi.boolean().optional()
    }).optional(),
    availability: Joi.object({
      days: Joi.array().items(Joi.string().valid('monday','tuesday','wednesday','thursday','friday','saturday','sunday')).optional(),
      timeSlots: Joi.array().items(Joi.object({ start: Joi.string().pattern(/^\d{2}:\d{2}$/), end: Joi.string().pattern(/^\d{2}:\d{2}$/) })).optional(),
      flexible: Joi.boolean().optional()
    }).optional(),
    location: Joi.object({
      serviceArea: Joi.string().required(),
      radius: Joi.number().min(0).default(10),
      onSite: Joi.boolean().default(true),
  remote: Joi.boolean().default(false),
  geo: Joi.object({ type: Joi.string().valid('Point').required(), coordinates: Joi.array().length(2).items(Joi.number()).required() }).optional()
    }).required(),
    images: Joi.array().items(Joi.object({ url: Joi.string().uri().required(), alt: Joi.string().allow('') })).optional(),
    requirements: Joi.array().items(Joi.string()).optional(),
  equipment: Joi.array().items(Joi.string()).optional()
  })
});

const updateServiceValidator = celebrate({
  [Segments.BODY]: Joi.object({
    title: Joi.string().trim().optional(),
    description: Joi.string().trim().optional(),
    category: Joi.string().valid(
      'cleaning','laundry','caregiving','furniture_moving','elderly_support','aluminum_work','carpentry','home_nursing','maintenance','other'
    ).optional(),
    subcategory: Joi.string().trim().allow('').optional(),
    price: Joi.object({
      amount: Joi.number().positive().optional(),
      type: Joi.string().valid('hourly','fixed','daily').optional(),
      currency: Joi.string().optional()
    }).optional(),
    duration: Joi.object({ estimated: Joi.number().integer().min(0).optional(), flexible: Joi.boolean().optional() }).optional(),
    availability: Joi.object({
      days: Joi.array().items(Joi.string().valid('monday','tuesday','wednesday','thursday','friday','saturday','sunday')).optional(),
      timeSlots: Joi.array().items(Joi.object({ start: Joi.string().pattern(/^\d{2}:\d{2}$/), end: Joi.string().pattern(/^\d{2}:\d{2}$/) })).optional(),
      flexible: Joi.boolean().optional()
    }).optional(),
    location: Joi.object({ serviceArea: Joi.string().optional(), radius: Joi.number().min(0).optional(), onSite: Joi.boolean().optional(), remote: Joi.boolean().optional() }).optional(),
    location: Joi.object({
      serviceArea: Joi.string().optional(),
      radius: Joi.number().min(0).optional(),
      onSite: Joi.boolean().optional(),
      remote: Joi.boolean().optional(),
      geo: Joi.object({ type: Joi.string().valid('Point').required(), coordinates: Joi.array().length(2).items(Joi.number()).required() }).optional()
    }).optional(),
    images: Joi.array().items(Joi.object({ url: Joi.string().uri().required(), alt: Joi.string().allow('') })).optional(),
    requirements: Joi.array().items(Joi.string()).optional(),
    equipment: Joi.array().items(Joi.string()).optional(),
    isActive: Joi.boolean().optional()
  }).min(1)
});

// Public browse
router.get('/', servicesController.listServices);

// Provider service management (must come before /:id to avoid conflicts)
router.get('/my-services', auth, checkRole(['provider']), servicesController.getMyServices);
router.post('/provider', auth, checkRole(['provider']), createProviderServiceValidator, servicesController.createService);

// Service by ID (must come after specific routes)
router.get('/:id', servicesController.getServiceById);

// Custom service requests (for admin approval)
router.post('/custom-requests', auth, checkRole(['provider']), servicesController.submitCustomServiceRequest);

// Bulk operations for providers (must come before /:id routes)
router.put('/bulk-activate', auth, checkRole(['provider']), servicesController.bulkActivateServices);
router.put('/bulk-deactivate', auth, checkRole(['provider']), servicesController.bulkDeactivateServices);
router.post('/bulk-delete', auth, checkRole(['provider']), servicesController.bulkDeleteServices);

// Provider service management (providers can update their own services)
router.put('/:id/provider', auth, checkRole(['provider']), updateServiceValidator, servicesController.updateService);
router.delete('/:id/provider', auth, checkRole(['provider']), servicesController.deleteService);

// Admin-only management
router.post('/', auth, checkRole(['admin']), createServiceValidator, servicesController.createService);
router.put('/:id', auth, checkRole(['admin']), updateServiceValidator, servicesController.updateService);
router.delete('/:id', auth, checkRole(['admin']), servicesController.deleteService);
// Images: local upload (only when STORAGE_DRIVER=local)
if (env.STORAGE_DRIVER === 'local') {
  router.post('/:id/images', auth, checkRole(['admin']), uploadServiceImages, servicesController.uploadServiceImages);
}
// Images: S3/MinIO presign + attach + cleanup (admin only)
router.post('/:id/images/presign', auth, checkRole(['admin']), celebrate({
  [Segments.BODY]: Joi.object({ files: Joi.array().items(Joi.object({ filename: Joi.string().required(), contentType: Joi.string().required(), size: Joi.number().optional() })).min(1).required() })
}), servicesController.presignServiceImages);
router.post('/:id/images/attach', auth, checkRole(['admin']), celebrate({
  [Segments.BODY]: Joi.object({ images: Joi.array().items(Joi.object({ key: Joi.string().required(), alt: Joi.string().allow('').optional() })).min(1).required() })
}), servicesController.attachServiceImages);
router.post('/:id/images/cleanup', auth, checkRole(['admin']), servicesController.cleanupServiceImages);

module.exports = router;
