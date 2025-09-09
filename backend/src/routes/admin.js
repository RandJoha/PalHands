const express = require('express');
const router = express.Router();
const { adminAuth, checkAdminPermission, logAdminAction } = require('../middleware/adminAuth');
const dashboardController = require('../controllers/admin/dashboardController');
const reportsController = require('../controllers/admin/reportsController');
const { adminListValidator, adminUpdateValidator, adminRequestInfoValidator } = require('../validators/reportsValidators');
const settingsController = require('../controllers/admin/settingsController');
const analyticsController = require('../controllers/admin/analyticsController');
const actionsController = require('../controllers/admin/actionsController');

// Apply admin authentication to all routes
router.use(adminAuth);

// Dashboard Overview
router.get('/dashboard/overview', checkAdminPermission('analytics'), dashboardController.getDashboardOverview);

// User Management
router.get('/users', checkAdminPermission('userManagement'), dashboardController.getUserManagementData);
router.put('/users/:userId', checkAdminPermission('userManagement'), logAdminAction('user_update', 'user', 'req.params.userId'), dashboardController.updateUser);

// Service Management
router.get('/services', checkAdminPermission('serviceManagement'), dashboardController.getServiceManagementData);
router.put('/services/:serviceId', checkAdminPermission('serviceManagement'), logAdminAction('service_update', 'service', 'req.params.serviceId'), dashboardController.updateService);
router.delete('/services/:serviceId', checkAdminPermission('serviceManagement'), logAdminAction('service_delete', 'service', 'req.params.serviceId'), dashboardController.deleteService);

// Category Management
router.delete('/categories/:categoryId', checkAdminPermission('serviceManagement'), logAdminAction('category_delete', 'category', 'req.params.categoryId'), dashboardController.deleteCategory);

// Booking Management
router.get('/bookings', checkAdminPermission('bookingManagement'), dashboardController.getBookingManagementData);
router.put('/bookings/:bookingId', checkAdminPermission('bookingManagement'), logAdminAction('booking_update', 'booking', 'req.params.bookingId'), dashboardController.updateBooking);

// Reports & Disputes
router.get('/reports', checkAdminPermission('reports'), adminListValidator, reportsController.listReports);
router.put('/reports/:reportId', checkAdminPermission('reports'), adminUpdateValidator, logAdminAction('report_update', 'report', 'req.params.reportId'), reportsController.updateReport);
router.post('/reports/:reportId/request-info', checkAdminPermission('reports'), adminRequestInfoValidator, logAdminAction('report_request_info', 'report', 'req.params.reportId'), reportsController.requestInfo);
router.put('/reports/:reportId/resolve', checkAdminPermission('reports'), logAdminAction('report_resolve', 'report', 'req.params.reportId'), reportsController.resolveReport);
router.put('/reports/:reportId/dismiss', checkAdminPermission('reports'), logAdminAction('report_dismiss', 'report', 'req.params.reportId'), reportsController.dismissReport);

// System Settings
router.get('/settings', checkAdminPermission('systemSettings'), settingsController.listSettings);
router.put('/settings/:key', checkAdminPermission('systemSettings'), logAdminAction('system_setting_change', 'system', 'req.params.key'), settingsController.updateSetting);

// Analytics & Growth
router.get('/analytics', checkAdminPermission('analytics'), analyticsController.getAnalytics);
// Reports stats
router.get('/reports/stats', checkAdminPermission('reports'), reportsController.stats);

// Admin Actions Log
router.get('/actions', checkAdminPermission('analytics'), actionsController.listActions);

module.exports = router; 