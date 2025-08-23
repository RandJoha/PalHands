// Minimal working Express app for development
require('dotenv').config();

const express = require('express');
const cors = require('cors');

console.log('🚀 Starting minimal PalHands API...');

const app = express();

// CORS - very permissive for development
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept']
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));

// Request logging
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path} from ${req.get('origin') || 'unknown'}`);
  next();
});

// Health check
app.get('/api/health', (req, res) => {
  console.log('Health check requested');
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    message: 'PalHands API is running'
  });
});

// Auth routes only (the essential one)
try {
  const authRoutes = require('./routes/auth');
  app.use('/api/auth', authRoutes);
  console.log('✅ Auth routes loaded');
} catch (error) {
  console.error('❌ Auth routes failed:', error.message);
}

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
