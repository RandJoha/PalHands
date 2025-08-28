const express = require('express');
const router = express.Router();

const { authenticate } = require('../middleware/authMiddleware');
const { uploadReportEvidence } = require('../middleware/upload');
const {
  createReportValidator,
  listMyReportsValidator,
  getByIdValidator
} = require('../validators/reportsValidators');

const {
  createReport,
  listMyReports,
  getReportById,
  addEvidence
} = require('../controllers/reportsController');
const { createReportLimiter } = require('../middleware/rateLimiters');

// Create a new report - allow anonymous for feature suggestions
router.post('/', createReportLimiter, createReportValidator, createReport);

// Auth required for all other report routes
router.use(authenticate);

// List my reports
router.get('/me', listMyReportsValidator, listMyReports);

// Get a specific report (reporter or admin)
router.get('/:id', getByIdValidator, getReportById);

// Add evidence to an existing report (reporter or admin)
router.post('/:id/evidence', getByIdValidator, uploadReportEvidence.array('files', 10), addEvidence);

module.exports = router;
