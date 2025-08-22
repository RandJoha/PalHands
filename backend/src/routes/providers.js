const express = require('express');
const { celebrate, Segments } = require('celebrate');
const Joi = require('joi');
const Provider = require('../models/Provider');
const { auth: authenticateToken, checkRole: authorizeRoles } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const createProviderValidator = celebrate({
  [Segments.BODY]: Joi.object({
    name: Joi.string().required(),
    city: Joi.string().required(),
    phone: Joi.string().required(),
    experienceYears: Joi.number().min(0).required(),
    languages: Joi.array().items(Joi.string()).required(),
    hourlyRate: Joi.number().min(0).required(),
    services: Joi.array().items(Joi.string()).required(),
    rating: Joi.object({
      average: Joi.number().min(0).max(5),
      count: Joi.number().min(0)
    }),
    avatarUrl: Joi.string().allow(null),
    location: Joi.object({
      address: Joi.string(),
      coordinates: Joi.object({
        latitude: Joi.number(),
        longitude: Joi.number()
      })
    }),
    isActive: Joi.boolean().default(true),
    isVerified: Joi.boolean().default(false)
  })
});

const updateProviderValidator = celebrate({
  [Segments.BODY]: Joi.object({
    name: Joi.string(),
    city: Joi.string(),
    phone: Joi.string(),
    experienceYears: Joi.number().min(0),
    languages: Joi.array().items(Joi.string()),
    hourlyRate: Joi.number().min(0),
    services: Joi.array().items(Joi.string()),
    rating: Joi.object({
      average: Joi.number().min(0).max(5),
      count: Joi.number().min(0)
    }),
    avatarUrl: Joi.string().allow(null),
    location: Joi.object({
      address: Joi.string(),
      coordinates: Joi.object({
        latitude: Joi.number(),
        longitude: Joi.number()
      })
    }),
    isActive: Joi.boolean(),
    isVerified: Joi.boolean()
  })
});

// GET /api/providers - Get all providers with filtering and search
router.get('/', async (req, res) => {
  try {
    const {
      city,
      services,
      minRating,
      maxPrice,
      minPrice,
      sortBy = 'rating',
      sortOrder = 'desc',
      page = 1,
      limit = 20,
      isActive
    } = req.query;

    // Build filter
    const filter = {};
    
    if (city) {
      filter.city = new RegExp(city, 'i');
    }
    
    if (services) {
      const serviceArray = services.split(',').map(s => s.trim());
      filter.services = { $in: serviceArray };
    }
    
    if (minRating) {
      filter['rating.average'] = { $gte: parseFloat(minRating) };
    }
    
    if (minPrice !== undefined) {
      filter.hourlyRate = { $gte: parseFloat(minPrice) };
    }
    
    if (maxPrice !== undefined) {
      if (filter.hourlyRate) {
        filter.hourlyRate.$lte = parseFloat(maxPrice);
      } else {
        filter.hourlyRate = { $lte: parseFloat(maxPrice) };
      }
    }
    
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }

    // Build sort
    let sort = {};
    if (sortBy === 'rating') {
      sort['rating.average'] = sortOrder === 'asc' ? 1 : -1;
    } else if (sortBy === 'price') {
      sort.hourlyRate = sortOrder === 'asc' ? 1 : -1;
    } else if (sortBy === 'experience') {
      sort.experienceYears = sortOrder === 'asc' ? 1 : -1;
    } else {
      sort['rating.average'] = -1; // Default sort by rating
    }

    // Pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    // Execute query
    const providers = await Provider.find(filter)
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    // Get total count for pagination
    const total = await Provider.countDocuments(filter);

    res.json({
      success: true,
      code: 'OK',
      message: 'Providers retrieved successfully',
      data: {
        providers,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Error fetching providers:', error);
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to fetch providers',
      error: error.message
    });
  }
});

// GET /api/providers/search - Search providers by text
router.get('/search', async (req, res) => {
  try {
    const { q, limit = 10 } = req.query;
    
    if (!q) {
      return res.status(400).json({
        success: false,
        code: 'BAD_REQUEST',
        message: 'Search query is required'
      });
    }

    const providers = await Provider.find({
      $text: { $search: q }
    })
    .sort({ score: { $meta: 'textScore' } })
    .limit(parseInt(limit))
    .lean();

    res.json({
      success: true,
      code: 'OK',
      message: 'Provider search completed',
      data: providers
    });
  } catch (error) {
    console.error('Error searching providers:', error);
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to search providers',
      error: error.message
    });
  }
});

// GET /api/providers/:id - Get specific provider
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const provider = await Provider.findById(id);
    
    if (!provider) {
      return res.status(404).json({
        success: false,
        code: 'NOT_FOUND',
        message: 'Provider not found'
      });
    }
    
    res.json({
      success: true,
      code: 'OK',
      message: 'Provider retrieved successfully',
      data: provider
    });
  } catch (error) {
    console.error('Error fetching provider:', error);
    res.status(500).json({
      success: false,
      code: 'INTERNAL_ERROR',
      message: 'Failed to fetch provider',
      error: error.message
    });
  }
});

// POST /api/providers - Create new provider (Admin only)
router.post('/', 
  authenticateToken, 
  authorizeRoles(['admin']), 
  createProviderValidator,
  async (req, res) => {
    try {
      const providerData = req.body;
      const provider = new Provider(providerData);
      await provider.save();
      
      res.status(201).json({
        success: true,
        code: 'CREATED',
        message: 'Provider created successfully',
        data: provider
      });
    } catch (error) {
      console.error('Error creating provider:', error);
      res.status(500).json({
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Failed to create provider',
        error: error.message
      });
    }
  }
);

// PUT /api/providers/:id - Update provider (Admin only)
router.put('/:id', 
  authenticateToken, 
  authorizeRoles(['admin']), 
  updateProviderValidator,
  async (req, res) => {
    try {
      const { id } = req.params;
      const updateData = req.body;
      updateData.updatedAt = new Date();
      
      const provider = await Provider.findByIdAndUpdate(
        id,
        updateData,
        { new: true, runValidators: true }
      );
      
      if (!provider) {
        return res.status(404).json({
          success: false,
          code: 'NOT_FOUND',
          message: 'Provider not found'
        });
      }
      
      res.json({
        success: true,
        code: 'OK',
        message: 'Provider updated successfully',
        data: provider
      });
    } catch (error) {
      console.error('Error updating provider:', error);
      res.status(500).json({
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Failed to update provider',
        error: error.message
      });
    }
  }
);

// DELETE /api/providers/:id - Delete provider (Admin only)
router.delete('/:id', 
  authenticateToken, 
  authorizeRoles(['admin']), 
  async (req, res) => {
    try {
      const { id } = req.params;
      const provider = await Provider.findByIdAndDelete(id);
      
      if (!provider) {
        return res.status(404).json({
          success: false,
          code: 'NOT_FOUND',
          message: 'Provider not found'
        });
      }
      
      res.json({
        success: true,
        code: 'OK',
        message: 'Provider deleted successfully',
        data: provider
      });
    } catch (error) {
      console.error('Error deleting provider:', error);
      res.status(500).json({
        success: false,
        code: 'INTERNAL_ERROR',
        message: 'Failed to delete provider',
        error: error.message
      });
    }
  }
);

module.exports = router;
