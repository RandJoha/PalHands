// Express app for testing and development
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const { errors: celebrateErrors } = require('celebrate');
const rateLimit = require('express-rate-limit');

console.log('🚀 Starting PalHands API...');

const app = express();

// Trust proxy for rate limiting (needed for tests and production)
if (process.env.TRUST_PROXY === 'true') {
  app.set('trust proxy', true);
}

// Security middleware
app.use(helmet({
  contentSecurityPolicy: false, // Disable CSP for API
  crossOriginEmbedderPolicy: false
}));

// Compression
app.use(compression());

// CORS - configured for production
app.use(cors({
  origin: process.env.FRONTEND_URL || true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'authorization', 'Idempotency-Key']
}));

// Ensure preflight requests are handled for all routes
app.options('*', cors());

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting (only in production)
if (process.env.NODE_ENV === 'production' && process.env.RATE_LIMIT !== 'false') {
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
  });
  app.use('/api/', limiter);
}

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    message: 'PalHands API is running',
    version: '1.0.0'
  });
});

// Load all routes
try {
  const authRoutes = require('./routes/auth');
  app.use('/api/auth', authRoutes);
  console.log('✅ Auth routes loaded');
} catch (error) {
  console.error('❌ Auth routes failed:', error.message);
}

try {
  const userRoutes = require('./routes/users');
  app.use('/api/users', userRoutes);
  console.log('✅ User routes loaded');
} catch (error) {
  console.error('❌ User routes failed:', error.message);
}

try {
  const providerRoutes = require('./routes/providers');
  app.use('/api/providers', providerRoutes);
  console.log('✅ Provider routes loaded');
} catch (error) {
  console.error('❌ Provider routes failed:', error.message);
}

try {
  const serviceRoutes = require('./routes/services');
  app.use('/api/services', serviceRoutes);
  console.log('✅ Service routes loaded');
} catch (error) {
  console.error('❌ Service routes failed:', error.message);
}

try {
  const serviceCategoryRoutes = require('./routes/servicecategories');
  app.use('/api/servicecategories', serviceCategoryRoutes);
  console.log('✅ Service category routes loaded');
} catch (error) {
  console.error('❌ Service category routes failed:', error.message);
}

try {
  const bookingRoutes = require('./routes/bookings');
  app.use('/api/bookings', bookingRoutes);
  console.log('✅ Booking routes loaded');
} catch (error) {
  console.error('❌ Booking routes failed:', error.message);
}

try {
  const providerServiceRoutes = require('./routes/providerServices');
  app.use('/api/provider-services', providerServiceRoutes);
  console.log('✅ Provider service routes loaded');
} catch (error) {
  console.error('❌ Provider service routes failed:', error.message);
}

try {
  const availabilityRoutes = require('./routes/availability');
  app.use('/api/availability', availabilityRoutes);
  console.log('✅ Availability routes loaded');
} catch (error) {
  console.error('❌ Availability routes failed:', error.message);
}

try {
  const reportRoutes = require('./routes/reports');
  app.use('/api/reports', reportRoutes);
  console.log('✅ Report routes loaded');
} catch (error) {
  console.error('❌ Report routes failed:', error.message);
}

try {
  const chatRoutes = require('./routes/chat');
  app.use('/api/chat', chatRoutes);
  console.log('✅ Chat routes loaded');
} catch (error) {
  console.error('❌ Chat routes failed:', error.message);
}

try {
  const notificationRoutes = require('./routes/notifications');
  app.use('/api/notifications', notificationRoutes);
  console.log('✅ Notification routes loaded');
} catch (error) {
  console.error('❌ Notification routes failed:', error.message);
}

try {
  const adminRoutes = require('./routes/admin');
  app.use('/api/admin', adminRoutes);
  console.log('✅ Admin routes loaded');
} catch (error) {
  console.error('❌ Admin routes failed:', error.message);
}

// Error handling middleware
app.use(celebrateErrors());

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.originalUrl
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Global error handler:', err);
  
  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map(e => e.message);
    return res.status(400).json({
      success: false,
      message: 'Validation Error',
      errors
    });
  }
  
  // Mongoose duplicate key error
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue)[0];
    return res.status(400).json({
      success: false,
      message: `${field} already exists`
    });
  }
  
  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Invalid token'
    });
  }
  
  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Token expired'
    });
  }
  
  // Default error
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

module.exports = app;
