const express = require('express');
const { celebrate, Segments } = require('celebrate');
const Joi = require('joi');
const ServiceCategory = require('../models/ServiceCategory');
const { auth: authenticateToken, checkRole: authorizeRoles } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const createCategoryValidator = celebrate({
  [Segments.BODY]: Joi.object({
    id: Joi.string().required(),
    name: Joi.string().required(),
    icon: Joi.string().required(),
    color: Joi.string().required(),
    description: Joi.string().required(),
    services: Joi.array().items(Joi.string()).required(),
    isActive: Joi.boolean().default(true)
  })
});

const updateCategoryValidator = celebrate({
  [Segments.BODY]: Joi.object({
    name: Joi.string(),
    icon: Joi.string(),
    color: Joi.string(),
    description: Joi.string(),
    services: Joi.array().items(Joi.string()),
    isActive: Joi.boolean()
  })
});

// GET /api/servicecategories - Get all service categories
router.get('/', async (req, res) => {
  try {
    const { isActive } = req.query;
    const filter = {};
    
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }
    
    const categories = await ServiceCategory.find(filter).sort({ id: 1 });
    
    res.json({
      success: true,
      code: 'OK',
      message: 'Service categories retrieved successfully',
      data: categories
    });
  } catch (error) {
    console.error('Error fetching service categories:', error);
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to fetch service categories',
      error: error.message
    });
  }
});

// GET /api/servicecategories/:id - Get specific service category
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const category = await ServiceCategory.findOne({ id });
    
    if (!category) {
      return res.status(404).json({
        success: false,
        code: 'NOT_FOUND',
        message: 'Service category not found'
      });
    }
    
    res.json({
      success: true,
      code: 'OK',
      message: 'Service category retrieved successfully',
      data: category
    });
  } catch (error) {
    console.error('Error fetching service category:', error);
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to fetch service category',
      error: error.message
    });
  }
});

// POST /api/servicecategories - Create new service category (Admin only)
router.post('/', 
  authenticateToken, 
  authorizeRoles(['admin']), 
  createCategoryValidator,
  async (req, res) => {
    try {
      const categoryData = req.body;
      
      // Check if category with same ID already exists
      const existingCategory = await ServiceCategory.findOne({ id: categoryData.id });
      if (existingCategory) {
        return res.status(400).json({
          success: false,
          code: 'DUPLICATE_ERROR',
          message: 'Service category with this ID already exists'
        });
      }
      
      const category = new ServiceCategory(categoryData);
      await category.save();
      
      res.status(201).json({
        success: true,
        code: 'CREATED',
        message: 'Service category created successfully',
        data: category
      });
    } catch (error) {
      console.error('Error creating service category:', error);
      res.status(500).json({
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Failed to create service category',
        error: error.message
      });
    }
  }
);

// PUT /api/servicecategories/:id - Update service category (Admin only)
router.put('/:id', 
  authenticateToken, 
  authorizeRoles(['admin']), 
  updateCategoryValidator,
  async (req, res) => {
    try {
      const { id } = req.params;
      const updateData = req.body;
      updateData.updatedAt = new Date();
      
      const category = await ServiceCategory.findOneAndUpdate(
        { id },
        updateData,
        { new: true, runValidators: true }
      );
      
      if (!category) {
        return res.status(404).json({
          success: false,
          code: 'NOT_FOUND',
          message: 'Service category not found'
        });
      }
      
      res.json({
        success: true,
        code: 'OK',
        message: 'Service category updated successfully',
        data: category
      });
    } catch (error) {
      console.error('Error updating service category:', error);
      res.status(500).json({
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Failed to update service category',
        error: error.message
      });
    }
  }
);

// DELETE /api/servicecategories/:id - Delete service category (Admin only)
router.delete('/:id', 
  authenticateToken, 
  authorizeRoles(['admin']), 
  async (req, res) => {
    try {
      const { id } = req.params;
      const category = await ServiceCategory.findOneAndDelete({ id });
      
      if (!category) {
        return res.status(404).json({
          success: false,
          code: 'NOT_FOUND',
          message: 'Service category not found'
        });
      }
      
      res.json({
        success: true,
        code: 'OK',
        message: 'Service category deleted successfully',
        data: category
      });
    } catch (error) {
      console.error('Error deleting service category:', error);
      res.status(500).json({
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Failed to delete service category',
        error: error.message
      });
    }
  }
);

module.exports = router;
