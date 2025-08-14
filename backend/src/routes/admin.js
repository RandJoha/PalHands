const express = require('express');
const router = express.Router();
const { adminAuth, checkAdminPermission, logAdminAction } = require('../middleware/adminAuth');
const dashboardController = require('../controllers/admin/dashboardController');
const reportsController = require('../controllers/admin/reportsController');
const settingsController = require('../controllers/admin/settingsController');
const analyticsController = require('../controllers/admin/analyticsController');
const actionsController = require('../controllers/admin/actionsController');

// Apply admin authentication to all routes
router.use(adminAuth);

// Dashboard Overview
router.get('/dashboard/overview', checkAdminPermission('analytics'), dashboardController.getDashboardOverview);

// User Management
router.get('/users', checkAdminPermission('userManagement'), dashboardController.getUserManagementData);
router.put('/users/:userId', checkAdminPermission('userManagement'), logAdminAction('user_update', 'user', (req)=>req.params.userId), dashboardController.updateUser);

// Service Management
router.get('/services', checkAdminPermission('serviceManagement'), dashboardController.getServiceManagementData);
router.put('/services/:serviceId', checkAdminPermission('serviceManagement'), logAdminAction('service_update', 'service', (req)=>req.params.serviceId), dashboardController.updateService);

// Booking Management
router.get('/bookings', checkAdminPermission('bookingManagement'), dashboardController.getBookingManagementData);
router.put('/bookings/:bookingId', checkAdminPermission('bookingManagement'), logAdminAction('booking_update', 'booking', (req)=>req.params.bookingId), dashboardController.updateBooking);

// Reports & Disputes
router.get('/reports', checkAdminPermission('reports'), reportsController.listReports);
router.put('/reports/:reportId', checkAdminPermission('reports'), logAdminAction('report_resolve', 'report', (req)=>req.params.reportId), reportsController.updateReport);

// System Settings
router.get('/settings', checkAdminPermission('systemSettings'), settingsController.listSettings);
router.put('/settings/:key', checkAdminPermission('systemSettings'), logAdminAction('system_setting_change', 'system', (req)=>req.params.key), settingsController.updateSetting);

// Analytics & Growth
router.get('/analytics', checkAdminPermission('analytics'), analyticsController.getAnalytics);

// Admin Actions Log
router.get('/actions', checkAdminPermission('analytics'), actionsController.listActions);

module.exports = router; 