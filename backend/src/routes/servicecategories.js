const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const serviceCategoriesController = require('../controllers/serviceCategoriesController');
const { celebrate, Joi, Segments } = require('celebrate');

// Public routes - no authentication required for browsing categories
router.get('/', serviceCategoriesController.listCategories);
router.get('/counts', serviceCategoriesController.getCategoriesWithCounts);
router.get('/with-services', serviceCategoriesController.getCategoriesWithServices);
router.get('/:id', serviceCategoriesController.getCategoryById);

// Admin-only routes
router.post('/', auth, checkRole(['admin']), celebrate({
  [Segments.BODY]: Joi.object({
    name: Joi.string().trim().min(1).max(100).required(),
    description: Joi.string().trim().max(500).optional(),
    icon: Joi.string().trim().max(50).optional(),
    color: Joi.string().trim().pattern(/^#[0-9A-Fa-f]{6}$/).optional()
  })
}), serviceCategoriesController.createCategory);

module.exports = router;
