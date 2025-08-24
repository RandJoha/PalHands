const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const controller = require('../controllers/reconciliation');
const { celebrate, Joi, Segments } = require('celebrate');

// Validation schemas
const createJobValidator = celebrate({
  [Segments.BODY]: Joi.object({
    period: Joi.string().valid('daily', 'weekly', 'monthly', 'custom').required(),
    startDate: Joi.date().required(),
    endDate: Joi.date().greater(Joi.ref('startDate')).required(),
    processorType: Joi.string().valid('stripe', 'paypal', 'cash', 'all').default('all')
  })
});

const resolveDiscrepancyValidator = celebrate({
  [Segments.BODY]: Joi.object({
    discrepancyIndex: Joi.number().min(0).required(),
    notes: Joi.string().min(1).max(1000).required()
  })
});

const schedulerConfigValidator = celebrate({
  [Segments.BODY]: Joi.object({
    config: Joi.object({
      dailyIntervalMs: Joi.number().min(3600000).max(86400000), // 1 hour to 24 hours
      weeklyIntervalMs: Joi.number().min(86400000).max(604800000), // 1 day to 7 days
      monthlyIntervalMs: Joi.number().min(2592000000).max(31536000000), // 30 days to 365 days
      batchSize: Joi.number().min(1).max(50),
      maxConcurrentJobs: Joi.number().min(1).max(10)
    }).required()
  })
});

const processPendingJobsValidator = celebrate({
  [Segments.BODY]: Joi.object({
    limit: Joi.number().min(1).max(50).default(10)
  })
});

const runNowValidator = celebrate({
  [Segments.BODY]: Joi.object({
    period: Joi.string().valid('daily', 'weekly', 'monthly').default('daily'),
    processorType: Joi.string().valid('stripe', 'paypal', 'cash', 'all').default('all')
  })
});

// Routes - All require admin authentication
router.use(auth, checkRole(['admin']));

// Statistics and monitoring
router.get('/stats', controller.getStats);

// Job management
router.get('/jobs', controller.getJobs);
router.get('/jobs/:reconciliationId', controller.getJobDetails);
router.post('/jobs', createJobValidator, controller.createJob);
router.post('/jobs/:reconciliationId/process', controller.processJob);

// Discrepancy management
router.get('/discrepancies', controller.getDiscrepancies);
router.post('/discrepancies/:reconciliationId/resolve', resolveDiscrepancyValidator, controller.resolveDiscrepancy);

// Reports
router.get('/reports/:reconciliationId', controller.generateReport);

// Scheduler control
router.get('/scheduler/status', controller.getSchedulerStatus);
router.post('/scheduler/start', controller.startScheduler);
router.post('/scheduler/stop', controller.stopScheduler);
router.put('/scheduler/config', schedulerConfigValidator, controller.updateSchedulerConfig);

// Processing
router.post('/process-pending', processPendingJobsValidator, controller.processPendingJobs);
router.post('/run-now', runNowValidator, controller.runNow);

module.exports = router;
