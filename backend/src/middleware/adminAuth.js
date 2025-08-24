// Re-export from unified middleware to avoid duplication
const {
  adminAuth,
  checkAdminPermission,
  logAdminAction
} = require('./authMiddleware');

module.exports = {
  adminAuth,
  checkAdminPermission,
  logAdminAction
};