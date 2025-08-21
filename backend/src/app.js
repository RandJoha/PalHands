const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const helmet = require('helmet');
const compression = require('compression');
const { errors: celebrateErrors, isCelebrateError } = require('celebrate');
const mongoose = require('mongoose');
const { httpLogger } = require('./middleware/logger');
const { accessLog } = require('./middleware/accessLog');
const { globalLimiter } = require('./middleware/rateLimiters');
const { validateEnv } = require('./utils/config');

// Load environment variables
dotenv.config();

// Validate env and expose
const env = validateEnv();

const app = express();

// Trust proxy in tests when explicitly enabled (for X-Forwarded-For in rate-limiter)
if (String(process.env.TRUST_PROXY || '').toLowerCase() === 'true') {
	app.set('trust proxy', true);
}

// Security & compression
app.use(helmet());
app.use(compression());

// Request logging
app.use(httpLogger);
app.use(accessLog);

// CORS allowlist
const allowedOrigins = env.CORS_ORIGIN.split(',').map((o) => o.trim());
// Also allow same-origin requests to the API itself (e.g., HTML forms served from this host)
const serverOrigin = process.env.SERVER_ORIGIN || `http://localhost:${env.PORT}`;
if (!allowedOrigins.includes(serverOrigin)) allowedOrigins.push(serverOrigin);
const isDev = env.NODE_ENV !== 'production';
app.use(cors({
  origin: function (origin, callback) {
    // Non-CORS or server-to-server
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) return callback(null, true);
    if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\\d+)?$/.test(origin)) return callback(null, true);
    if (isDev) return callback(null, true);
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true
}));

// Rate limiting
app.use(globalLimiter);

// Body parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files (dev only suggested)
app.use('/uploads', express.static('uploads'));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/admin', require('./routes/admin'));
// New modules (Phase 1)
app.use('/api/services', require('./routes/services'));
app.use('/api/bookings', require('./routes/bookings'));
app.use('/api/availability', require('./routes/availability'));
app.use('/api/reports', require('./routes/reports'));

// Probes
app.get('/api/health', (req, res) => {
  res.json({ status: 'success', message: 'PalHands API is running', timestamp: new Date().toISOString() });
});
app.get('/api/livez', (req, res) => res.status(200).send('OK'));
app.get('/api/readyz', (req, res) => {
  const state = mongoose.connection.readyState; // 1=connected
  if (state === 1) return res.status(200).send('READY');
  return res.status(503).send('NOT_READY');
});

// Celebrate validation errors (custom shape)
app.use(celebrateErrors());
app.use((err, req, res, next) => {
  if (isCelebrateError && isCelebrateError(err)) {
    const details = [];
    for (const [segment, joiError] of err.details.entries()) {
      joiError.details.forEach((d) => {
        details.push({ path: d.path.join('.'), message: d.message, segment });
      });
    }
    return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: 'Validation failed', details });
  }
  return next(err);
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ success: false, code: 'NOT_FOUND', message: 'Route not found' });
});

// Global error handler
app.use((error, req, res, next) => {
  // Map CORS errors to 403 for clarity
  if (error && /CORS/i.test(error.message || '')) {
    return res.status(403).json({ success: false, code: 'CORS_FORBIDDEN', message: error.message });
  }
  const status = error.statusCode || 500;
  const message = error.message || 'Internal server error';
  res.status(status).json({ success: false, code: 'ERROR', message, ...(process.env.NODE_ENV === 'development' && { stack: error.stack }) });
});

module.exports = app; 