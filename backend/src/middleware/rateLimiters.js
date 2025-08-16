const rateLimit = require('express-rate-limit');

const isProd = process.env.NODE_ENV === 'production';

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: isProd ? 100 : 1000,
  standardHeaders: true,
  legacyHeaders: false
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: isProd ? 10 : 100,
  message: { success: false, code: 'RATE_LIMIT', message: 'Too many login attempts, please try again later' },
  standardHeaders: true,
  legacyHeaders: false
});

// Per-user limiter for creating reports
const createReportLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: isProd ? 5 : 50,
  keyGenerator: (req) => (req.user ? req.user._id.toString() : req.ip),
  message: { success: false, code: 'RATE_LIMIT', message: 'Too many reports submitted, please try again later' },
  standardHeaders: true,
  legacyHeaders: false
});

module.exports = { globalLimiter, authLimiter, createReportLimiter };
