const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Provider = require('../models/Provider');
const Admin = require('../models/Admin');

// Core: verify token, load user/provider, ensure active
const authenticate = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) {
      return res.status(401).json({ success: false, message: 'Access denied. No token provided.' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // First try to find user in users collection
    let user = await User.findById(decoded.userId).select('-password');
    
    // If not found in users, check providers collection
    if (!user) {
      const provider = await Provider.findById(decoded.userId).select('-password');
      if (provider) {
        if (!provider.isActive) {
          return res.status(401).json({ 
            success: false, 
            message: 'Account is deactivated.',
            code: 'ACCOUNT_DEACTIVATED',
            reason: provider.deactivationReason || 'Account deactivated by administrator',
            deactivatedAt: provider.deactivatedAt,
            deactivatedBy: provider.deactivatedBy
          });
        }
        req.user = provider;
        return next();
      }
    }
    
    // If we found a user in users collection
    if (user) {
      if (!user.isActive) {
        return res.status(401).json({ 
          success: false, 
          message: 'Account is deactivated.',
          code: 'ACCOUNT_DEACTIVATED',
          reason: user.deactivationReason || 'Account deactivated by administrator',
          deactivatedAt: user.deactivatedAt,
          deactivatedBy: user.deactivatedBy
        });
      }
      req.user = user;
      // console.log('🔍 User authenticated:', {
      //   userId: user._id,
      //   role: user.role,
      //   email: user.email,
      //   isActive: user.isActive
      // });
      return next();
    }
    
    // If we reach here, no user or provider was found
    return res.status(401).json({ success: false, message: 'Invalid token. User not found.' });
  } catch (error) {
    console.error('Auth error:', error);
    return res.status(401).json({ success: false, message: 'Invalid token.' });
  }
};

// Role guard (e.g., ['admin'])
const requireRole = (roles) => (req, res, next) => {
  console.log('🔍 Role check:', {
    userRole: req.user?.role,
    requiredRoles: roles,
    userId: req.user?._id
  });
  
  if (!req.user) {
    return res.status(401).json({ success: false, message: 'Authentication required.' });
  }
  if (!roles.includes(req.user.role)) {
    console.log('❌ Role check failed:', {
      userRole: req.user.role,
      requiredRoles: roles
    });
    return res.status(403).json({ success: false, message: `Access denied. ${roles.join(' or ')} role required.` });
  }
  console.log('✅ Role check passed');
  next();
};

// Extra: account verification guard
const requireVerification = (req, res, next) => {
  if (!req.user?.isVerified) {
    return res.status(403).json({ success: false, message: 'Account verification required.' });
  }
  next();
};

// Ownership guard for resources
const requireOwnership = (modelName) => {
  return async (req, res, next) => {
    try {
      const Model = require(`../models/${modelName}`);
      const resource = await Model.findById(req.params.id);
      if (!resource) {
        return res.status(404).json({ success: false, message: `${modelName} not found.` });
      }
      if (req.user.role === 'admin') {
        req.resource = resource;
        return next();
      }
      const ownerField = modelName === 'User' ? '_id' : 'user';
      if (resource[ownerField].toString() !== req.user._id.toString()) {
        return res.status(403).json({ success: false, message: 'Access denied. You can only access your own resources.' });
      }
      req.resource = resource;
      next();
    } catch (error) {
      console.error('Ownership check error:', error);
      res.status(500).json({ success: false, message: 'Internal server error.' });
    }
  };
};

// Admin: ensure authenticated + admin role + active admin record
const adminAuth = async (req, res, next) => {
  try {
    await authenticate(req, res, async () => {
      if (req.user.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Access denied. Admin privileges required.' });
      }
      const adminRecord = await Admin.findOne({ user: req.user._id });
      if (!adminRecord || !adminRecord.isActive) {
        return res.status(403).json({ success: false, message: 'Admin access not granted or account deactivated.' });
      }
      req.admin = adminRecord;
      next();
    });
  } catch (error) {
    console.error('Admin auth error:', error);
    return res.status(401).json({ success: false, message: 'Invalid token.' });
  }
};

// Admin permission guard
const checkAdminPermission = (permission) => (req, res, next) => {
  if (!req.admin) {
    return res.status(403).json({ success: false, message: 'Admin access required.' });
  }
  if (req.admin.role === 'super_admin') return next();
  if (!req.admin.permissions[permission]) {
    return res.status(403).json({ success: false, message: `Permission denied. ${permission} access required.` });
  }
  next();
};

// Admin action logger (unchanged behavior)
const logAdminAction = (action, targetType, targetId, details = {}) => {
  return (req, res, next) => {
    const originalSend = res.send;
    res.send = function(data) {
      setTimeout(async () => {
        try {
          const AdminAction = require('../models/AdminAction');
          const mongoose = require('mongoose');
          
          // Get the actual targetId from the request
          let actualTargetId = targetId;
          if (typeof targetId === 'string' && targetId.startsWith('req.params.')) {
            const paramName = targetId.replace('req.params.', '');
            actualTargetId = req.params[paramName];
          }
          
          // Only log if targetId is a valid ObjectId or if it's a string that can be converted
          let targetIdToLog = null;
          if (mongoose.Types.ObjectId.isValid(actualTargetId)) {
            targetIdToLog = actualTargetId;
          } else {
            // For non-ObjectId targets (like category names), store in details instead
            targetIdToLog = new mongoose.Types.ObjectId(); // Generate a dummy ObjectId
          }
          
          await AdminAction.create({
            admin: req.user?._id,
            action,
            targetType,
            targetId: targetIdToLog,
            details: { 
              ...details, 
              responseStatus: res.statusCode, 
              responseData: data,
              // Store the actual string ID in details if it's not an ObjectId
              ...(mongoose.Types.ObjectId.isValid(actualTargetId) ? {} : { actualTargetId })
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
  authenticate,
  requireRole,
  requireVerification,
  requireOwnership,
  adminAuth,
  checkAdminPermission,
  logAdminAction
};
