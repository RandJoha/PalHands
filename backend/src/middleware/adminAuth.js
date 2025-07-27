const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Admin = require('../models/Admin');

// Middleware to verify admin authentication
const adminAuth = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Find user
    const user = await User.findById(decoded.userId).select('-password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token. User not found.'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated.'
      });
    }

    // Check if user is admin
    if (user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin privileges required.'
      });
    }

    // Check if admin record exists and is active
    const adminRecord = await Admin.findOne({ user: user._id });
    if (!adminRecord || !adminRecord.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Admin access not granted or account deactivated.'
      });
    }

    // Add user and admin info to request
    req.user = user;
    req.admin = adminRecord;
    next();
  } catch (error) {
    console.error('Admin auth error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid token.'
    });
  }
};

// Middleware to check specific admin permissions
const checkAdminPermission = (permission) => {
  return (req, res, next) => {
    if (!req.admin) {
      return res.status(403).json({
        success: false,
        message: 'Admin access required.'
      });
    }

    // Super admin has all permissions
    if (req.admin.role === 'super_admin') {
      return next();
    }

    // Check specific permission
    if (!req.admin.permissions[permission]) {
      return res.status(403).json({
        success: false,
        message: `Permission denied. ${permission} access required.`
      });
    }

    next();
  };
};

// Middleware to log admin actions
const logAdminAction = (action, targetType, targetId, details = {}) => {
  return (req, res, next) => {
    const originalSend = res.send;
    
    res.send = function(data) {
      // Log the action after response is sent
      setTimeout(async () => {
        try {
          const AdminAction = require('../models/AdminAction');
          await AdminAction.create({
            admin: req.user._id,
            action,
            targetType,
            targetId,
            details: {
              ...details,
              responseStatus: res.statusCode,
              responseData: data
            },
            ipAddress: req.ip,
            userAgent: req.get('User-Agent'),
            status: res.statusCode < 400 ? 'success' : 'failed'
          });
        } catch (error) {
          console.error('Failed to log admin action:', error);
        }
      }, 0);
      
      originalSend.call(this, data);
    };
    
    next();
  };
};

module.exports = {
  adminAuth,
  checkAdminPermission,
  logAdminAction
}; 