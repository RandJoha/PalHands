const express = require('express');
const router = express.Router();
const { adminAuth, checkAdminPermission, logAdminAction } = require('../middleware/adminAuth');
const dashboardController = require('../controllers/admin/dashboardController');

// Apply admin authentication to all routes
router.use(adminAuth);

// Dashboard Overview
router.get('/dashboard/overview', 
  checkAdminPermission('analytics'),
  dashboardController.getDashboardOverview
);

// User Management
router.get('/users', 
  checkAdminPermission('userManagement'),
  dashboardController.getUserManagementData
);

router.put('/users/:userId', 
  checkAdminPermission('userManagement'),
  logAdminAction('user_update', 'user', 'req.params.userId'),
  dashboardController.updateUser
);

// Service Management
router.get('/services', 
  checkAdminPermission('serviceManagement'),
  dashboardController.getServiceManagementData
);

router.put('/services/:serviceId', 
  checkAdminPermission('serviceManagement'),
  logAdminAction('service_update', 'service', 'req.params.serviceId'),
  dashboardController.updateService
);

// Booking Management
router.get('/bookings', 
  checkAdminPermission('bookingManagement'),
  dashboardController.getBookingManagementData
);

router.put('/bookings/:bookingId', 
  checkAdminPermission('bookingManagement'),
  logAdminAction('booking_update', 'booking', 'req.params.bookingId'),
  dashboardController.updateBooking
);

// Reports & Disputes
router.get('/reports', 
  checkAdminPermission('reports'),
  async (req, res) => {
    try {
      const { page = 1, limit = 20, status, priority } = req.query;
      const skip = (page - 1) * limit;

      const filter = {};
      if (status) filter.status = status;
      if (priority) filter.priority = priority;

      const Report = require('../models/Report');
      const reports = await Report.find(filter)
        .populate('reporter', 'firstName lastName email')
        .populate('assignedAdmin', 'firstName lastName email')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));

      const total = await Report.countDocuments(filter);

      res.json({
        success: true,
        data: {
          reports,
          pagination: {
            current: parseInt(page),
            total: Math.ceil(total / limit),
            totalRecords: total
          }
        }
      });
    } catch (error) {
      console.error('Reports error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch reports'
      });
    }
  }
);

router.put('/reports/:reportId', 
  checkAdminPermission('reports'),
  logAdminAction('report_resolve', 'report', 'req.params.reportId'),
  async (req, res) => {
    try {
      const { reportId } = req.params;
      const { status, assignedAdmin, resolution, adminNote } = req.body;

      const Report = require('../models/Report');
      const report = await Report.findById(reportId);
      
      if (!report) {
        return res.status(404).json({
          success: false,
          message: 'Report not found'
        });
      }

      // Update report
      if (status) report.status = status;
      if (assignedAdmin) report.assignedAdmin = assignedAdmin;
      if (resolution) report.resolution = resolution;
      if (adminNote) {
        report.adminNotes.push({
          admin: req.user._id,
          note: adminNote
        });
      }

      await report.save();

      res.json({
        success: true,
        message: 'Report updated successfully',
        data: report
      });
    } catch (error) {
      console.error('Update report error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update report'
      });
    }
  }
);

// System Settings
router.get('/settings', 
  checkAdminPermission('systemSettings'),
  async (req, res) => {
    try {
      const SystemSetting = require('../models/SystemSetting');
      const settings = await SystemSetting.find().sort({ category: 1, key: 1 });

      res.json({
        success: true,
        data: settings
      });
    } catch (error) {
      console.error('Settings error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch settings'
      });
    }
  }
);

router.put('/settings/:key', 
  checkAdminPermission('systemSettings'),
  logAdminAction('system_setting_change', 'system', 'req.params.key'),
  async (req, res) => {
    try {
      const { key } = req.params;
      const { value } = req.body;

      const SystemSetting = require('../models/SystemSetting');
      const setting = await SystemSetting.findOne({ key });
      
      if (!setting) {
        return res.status(404).json({
          success: false,
          message: 'Setting not found'
        });
      }

      if (!setting.isEditable) {
        return res.status(403).json({
          success: false,
          message: 'This setting cannot be modified'
        });
      }

      setting.value = value;
      setting.lastModifiedBy = req.user._id;
      await setting.save();

      res.json({
        success: true,
        message: 'Setting updated successfully',
        data: setting
      });
    } catch (error) {
      console.error('Update setting error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to update setting'
      });
    }
  }
);

// Analytics & Growth
router.get('/analytics', 
  checkAdminPermission('analytics'),
  async (req, res) => {
    try {
      const { period = 'month' } = req.query;
      
      const User = require('../models/User');
      const Booking = require('../models/Booking');
      const Service = require('../models/Service');

      // Calculate date range
      const now = new Date();
      let startDate;
      switch (period) {
        case 'week':
          startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7);
          break;
        case 'month':
          startDate = new Date(now.getFullYear(), now.getMonth(), 1);
          break;
        case 'year':
          startDate = new Date(now.getFullYear(), 0, 1);
          break;
        default:
          startDate = new Date(now.getFullYear(), now.getMonth(), 1);
      }

      // User growth
      const userGrowth = await User.aggregate([
        {
          $match: {
            createdAt: { $gte: startDate }
          }
        },
        {
          $group: {
            _id: {
              $dateToString: { format: "%Y-%m-%d", date: "$createdAt" }
            },
            count: { $sum: 1 }
          }
        },
        {
          $sort: { _id: 1 }
        }
      ]);

      // Booking growth
      const bookingGrowth = await Booking.aggregate([
        {
          $match: {
            createdAt: { $gte: startDate }
          }
        },
        {
          $group: {
            _id: {
              $dateToString: { format: "%Y-%m-%d", date: "$createdAt" }
            },
            count: { $sum: 1 },
            revenue: { $sum: "$pricing.totalAmount" }
          }
        },
        {
          $sort: { _id: 1 }
        }
      ]);

      // Service category distribution
      const categoryDistribution = await Service.aggregate([
        {
          $group: {
            _id: '$category',
            count: { $sum: 1 }
          }
        },
        {
          $sort: { count: -1 }
        }
      ]);

      res.json({
        success: true,
        data: {
          userGrowth,
          bookingGrowth,
          categoryDistribution,
          period
        }
      });
    } catch (error) {
      console.error('Analytics error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch analytics'
      });
    }
  }
);

// Admin Actions Log
router.get('/actions', 
  checkAdminPermission('analytics'),
  async (req, res) => {
    try {
      const { page = 1, limit = 50, adminId, action, startDate, endDate } = req.query;
      const skip = (page - 1) * limit;

      const filter = {};
      if (adminId) filter.admin = adminId;
      if (action) filter.action = action;
      if (startDate || endDate) {
        filter.timestamp = {};
        if (startDate) filter.timestamp.$gte = new Date(startDate);
        if (endDate) filter.timestamp.$lte = new Date(endDate);
      }

      const AdminAction = require('../models/AdminAction');
      const actions = await AdminAction.find(filter)
        .populate('admin', 'firstName lastName email')
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(parseInt(limit));

      const total = await AdminAction.countDocuments(filter);

      res.json({
        success: true,
        data: {
          actions,
          pagination: {
            current: parseInt(page),
            total: Math.ceil(total / limit),
            totalRecords: total
          }
        }
      });
    } catch (error) {
      console.error('Actions log error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to fetch actions log'
      });
    }
  }
);

module.exports = router; 