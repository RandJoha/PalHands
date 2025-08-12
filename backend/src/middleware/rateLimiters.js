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

module.exports = { globalLimiter, authLimiter };
