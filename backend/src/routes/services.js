const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const servicesController = require('../controllers/servicesController');
const { uploadServiceImages } = require('../middleware/upload');
const { celebrate, Joi, Segments } = require('celebrate');
const { validateEnv } = require('../utils/config');
const { createServiceValidator, createSimpleServiceValidator, updateServiceValidator } = require('../validators/servicesValidators');
const env = validateEnv();

// Routes use validators from separate file

// Public browse
router.get('/', servicesController.listServices);
router.get('/:id', servicesController.getServiceById);

// Admin-only management
router.post('/', auth, checkRole(['admin']), createServiceValidator, servicesController.createService);
router.post('/simple', auth, checkRole(['admin']), createSimpleServiceValidator, servicesController.createSimpleService);
router.put('/:id', auth, checkRole(['admin']), updateServiceValidator, servicesController.updateService);
router.delete('/:id', auth, checkRole(['admin']), servicesController.deleteService);
// Images: local upload (only when STORAGE_DRIVER=local)
if (env.STORAGE_DRIVER === 'local') {
  router.post('/:id/images', auth, checkRole(['admin']), uploadServiceImages.array('images', 10), servicesController.uploadServiceImages);
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
