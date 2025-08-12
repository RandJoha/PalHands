// Backwards-compatible exports from unified middleware
const {
  authenticate,
  requireRole,
  requireVerification,
  requireOwnership
} = require('./authMiddleware');

module.exports = {
  auth: authenticate,
  checkRole: requireRole,
  requireVerification,
  checkOwnership: requireOwnership
};