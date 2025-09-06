// Minimal working Express app for development
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { errors: celebrateErrors } = require('celebrate');

console.log('🚀 Starting minimal PalHands API...');

const app = express();

// CORS - very permissive for development
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'authorization']
}));
// Ensure preflight requests are handled for all routes
app.options('*', cors());

// Body parsing
app.use(express.json({ limit: '10mb' }));

// Request logging (disabled for cleaner console)
// app.use((req, res, next) => {
//   console.log(`${req.method} ${req.path} from ${req.get('origin') || 'unknown'}`);
//   next();
// });

// Health check
app.get('/api/health', (req, res) => {
  // console.log('Health check requested');
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    message: 'PalHands API is running'
  });
});

// Essential routes for Phase 3
try {
  const authRoutes = require('./routes/auth');
  app.use('/api/auth', authRoutes);
  console.log('✅ Auth routes loaded');
} catch (error) {
  console.error('❌ Auth routes failed:', error.message);
}

try {
  const serviceCategoriesRoutes = require('./routes/servicecategories');
  app.use('/api/servicecategories', serviceCategoriesRoutes);
  console.log('✅ Service categories routes loaded');
} catch (error) {
  console.error('❌ Service categories routes failed:', error.message);
}

try {
  const servicesRoutes = require('./routes/services');
  app.use('/api/services', servicesRoutes);
  console.log('✅ Services routes loaded');
} catch (error) {
  console.error('❌ Services routes failed:', error.message);
}

try {
  const bookingsRoutes = require('./routes/bookings');
  app.use('/api/bookings', bookingsRoutes);
  console.log('✅ Bookings routes loaded');
} catch (error) {
  console.error('❌ Bookings routes failed:', error.message);
}

try {
  const userRoutes = require('./routes/users');
  app.use('/api/users', userRoutes);
  console.log('✅ User routes loaded');
} catch (error) {
  console.error('❌ User routes failed:', error.message);
}

try {
  const providersRoutes = require('./routes/providers');
  app.use('/api/providers', providersRoutes);
  console.log('✅ Providers routes loaded');
} catch (error) {
  console.error('❌ Providers routes failed:', error.message);
}

try {
  const reportsRoutes = require('./routes/reports');
  app.use('/api/reports', reportsRoutes);
  console.log('✅ Reports routes loaded');
} catch (error) {
  console.error('❌ Reports routes failed:', error.message);
}

try {
  const adminRoutes = require('./routes/admin');
  app.use('/api/admin', adminRoutes);
  console.log('✅ Admin routes loaded');
} catch (error) {
  console.error('❌ Admin routes failed:', error.message);
}

try {
  const notificationRoutes = require('./routes/notifications');
  app.use('/api/notifications', notificationRoutes);
  console.log('✅ Notification routes loaded');
} catch (error) {
  console.error('❌ Notification routes failed:', error.message);
}

try {
  const chatRoutes = require('./routes/chat');
  app.use('/api/chat', chatRoutes);
  console.log('✅ Chat routes loaded');
} catch (error) {
  console.error('❌ Chat routes failed:', error.message);
}

try {
  const availabilityRoutes = require('./routes/availability');
  app.use('/api/availability', availabilityRoutes);
  console.log('✅ Availability routes loaded');
} catch (error) {
  console.error('❌ Availability routes failed:', error.message);
}

try {
  const providerServicesRoutes = require('./routes/providerServices');
  app.use('/api/provider-services', providerServicesRoutes);
  console.log('✅ Provider-services routes loaded');
} catch (error) {
  console.error('❌ Provider-services routes failed:', error.message);
}

// Validation error handler (Celebrate)
app.use(celebrateErrors());

// Simple error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Server error', message: err.message });
});

// 404 handler
app.use('*', (req, res) => {
  console.log('404:', req.method, req.originalUrl);
  res.status(404).json({ error: 'Not found' });
});

console.log('✅ Minimal app ready');
module.exports = app;
