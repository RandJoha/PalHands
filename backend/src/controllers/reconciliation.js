const ReconciliationService = require('../services/reconciliation');
const reconciliationScheduler = require('../services/reconciliationScheduler');
const Reconciliation = require('../models/Reconciliation');
const { ok, error } = require('../utils/response');

/**
 * Get reconciliation statistics
 * GET /api/reconciliation/stats
 */
async function getStats(req, res) {
  try {
    const { days = 30 } = req.query;
    const actor = req.user;

    // Only admin can view reconciliation stats
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view reconciliation statistics');
    }

    const stats = await ReconciliationService.getStats(parseInt(days));
    return ok(res, stats, 'Reconciliation statistics retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get reconciliation statistics');
  }
}

/**
 * Get reconciliation jobs with filtering
 * GET /api/reconciliation/jobs
 */
async function getJobs(req, res) {
  try {
    const { 
      status, 
      period, 
      processorType,
      limit = 50, 
      skip = 0 
    } = req.query;
    const actor = req.user;

    // Only admin can view reconciliation jobs
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view reconciliation jobs');
    }

    const query = {};
    
    if (status) query.status = status;
    if (period) query.period = period;
    if (processorType) query.processorType = processorType;

    const jobs = await Reconciliation.find(query)
      .populate('createdBy', 'firstName lastName email')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await Reconciliation.countDocuments(query);

    return ok(res, {
      jobs,
      pagination: {
        total,
        limit: parseInt(limit),
        skip: parseInt(skip),
        hasMore: total > parseInt(skip) + jobs.length
      }
    }, 'Reconciliation jobs retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get reconciliation jobs');
  }
}

/**
 * Get reconciliation job details
 * GET /api/reconciliation/jobs/:reconciliationId
 */
async function getJobDetails(req, res) {
  try {
    const { reconciliationId } = req.params;
    const actor = req.user;

    // Only admin can view reconciliation job details
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view reconciliation job details');
    }

    const job = await Reconciliation.findOne({ reconciliationId })
      .populate('createdBy', 'firstName lastName email')
      .populate('discrepancies.paymentId', 'amount currency method status')
      .populate('discrepancies.resolvedBy', 'firstName lastName email');

    if (!job) {
      return error(res, 404, 'Reconciliation job not found');
    }

    const variance = job.calculateVariance();

    return ok(res, {
      job,
      variance
    }, 'Reconciliation job details retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get reconciliation job details');
  }
}

/**
 * Create a new reconciliation job
 * POST /api/reconciliation/jobs
 */
async function createJob(req, res) {
  try {
    const { period, startDate, endDate, processorType } = req.body;
    const actor = req.user;

    // Only admin can create reconciliation jobs
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can create reconciliation jobs');
    }

    if (!period || !startDate || !endDate) {
      return error(res, 400, 'period, startDate, and endDate are required');
    }

    const reconciliation = await ReconciliationService.createReconciliation({
      period,
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      processorType: processorType || 'all',
      createdBy: actor._id
    });

    return ok(res, reconciliation, 'Reconciliation job created successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to create reconciliation job');
  }
}

/**
 * Process a reconciliation job
 * POST /api/reconciliation/jobs/:reconciliationId/process
 */
async function processJob(req, res) {
  try {
    const { reconciliationId } = req.params;
    const actor = req.user;

    // Only admin can process reconciliation jobs
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can process reconciliation jobs');
    }

    const reconciliation = await Reconciliation.findOne({ reconciliationId });
    if (!reconciliation) {
      return error(res, 404, 'Reconciliation job not found');
    }

    const result = await ReconciliationService.processReconciliation(reconciliation);

    return ok(res, result, 'Reconciliation job processed successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to process reconciliation job');
  }
}

/**
 * Get jobs with discrepancies
 * GET /api/reconciliation/discrepancies
 */
async function getDiscrepancies(req, res) {
  try {
    const { limit = 50, skip = 0, resolved } = req.query;
    const actor = req.user;

    // Only admin can view discrepancies
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view discrepancies');
    }

    const query = { status: 'discrepancies_found' };
    
    if (resolved !== undefined) {
      query['discrepancies.resolved'] = resolved === 'true';
    }

    const jobs = await Reconciliation.find(query)
      .populate('createdBy', 'firstName lastName email')
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await Reconciliation.countDocuments(query);

    return ok(res, {
      jobs,
      pagination: {
        total,
        limit: parseInt(limit),
        skip: parseInt(skip),
        hasMore: total > parseInt(skip) + jobs.length
      }
    }, 'Reconciliation jobs with discrepancies retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get discrepancies');
  }
}

/**
 * Resolve a discrepancy
 * POST /api/reconciliation/discrepancies/:reconciliationId/resolve
 */
async function resolveDiscrepancy(req, res) {
  try {
    const { reconciliationId } = req.params;
    const { discrepancyIndex, notes } = req.body;
    const actor = req.user;

    // Only admin can resolve discrepancies
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can resolve discrepancies');
    }

    if (discrepancyIndex === undefined || !notes) {
      return error(res, 400, 'discrepancyIndex and notes are required');
    }

    const result = await ReconciliationService.resolveDiscrepancy(
      reconciliationId,
      parseInt(discrepancyIndex),
      actor._id,
      notes
    );

    return ok(res, result, 'Discrepancy resolved successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to resolve discrepancy');
  }
}

/**
 * Generate reconciliation report
 * GET /api/reconciliation/reports/:reconciliationId
 */
async function generateReport(req, res) {
  try {
    const { reconciliationId } = req.params;
    const actor = req.user;

    // Only admin can generate reports
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can generate reconciliation reports');
    }

    const report = await ReconciliationService.generateReport(reconciliationId);

    return ok(res, report, 'Reconciliation report generated successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to generate reconciliation report');
  }
}

/**
 * Get scheduler status
 * GET /api/reconciliation/scheduler/status
 */
async function getSchedulerStatus(req, res) {
  try {
    const actor = req.user;

    // Only admin can view scheduler status
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view scheduler status');
    }

    const status = reconciliationScheduler.getStatus();
    return ok(res, status, 'Scheduler status retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get scheduler status');
  }
}

/**
 * Start scheduler
 * POST /api/reconciliation/scheduler/start
 */
async function startScheduler(req, res) {
  try {
    const { config } = req.body;
    const actor = req.user;

    // Only admin can control scheduler
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can control scheduler');
    }

    reconciliationScheduler.start(config);
    const status = reconciliationScheduler.getStatus();
    
    return ok(res, status, 'Scheduler started successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to start scheduler');
  }
}

/**
 * Stop scheduler
 * POST /api/reconciliation/scheduler/stop
 */
async function stopScheduler(req, res) {
  try {
    const actor = req.user;

    // Only admin can control scheduler
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can control scheduler');
    }

    reconciliationScheduler.stop();
    const status = reconciliationScheduler.getStatus();
    
    return ok(res, status, 'Scheduler stopped successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to stop scheduler');
  }
}

/**
 * Update scheduler configuration
 * PUT /api/reconciliation/scheduler/config
 */
async function updateSchedulerConfig(req, res) {
  try {
    const { config } = req.body;
    const actor = req.user;

    // Only admin can control scheduler
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can control scheduler');
    }

    if (!config || typeof config !== 'object') {
      return error(res, 400, 'Valid config object is required');
    }

    reconciliationScheduler.updateConfig(config);
    const status = reconciliationScheduler.getStatus();
    
    return ok(res, status, 'Scheduler configuration updated successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to update scheduler configuration');
  }
}

/**
 * Process pending jobs
 * POST /api/reconciliation/process-pending
 */
async function processPendingJobs(req, res) {
  try {
    const { limit = 10 } = req.body;
    const actor = req.user;

    // Only admin can process pending jobs
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can process pending jobs');
    }

    const results = await reconciliationScheduler.processPendingJobs(parseInt(limit));
    
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;

    return ok(res, {
      results,
      summary: {
        total: results.length,
        successful,
        failed
      }
    }, `Processed ${results.length} pending reconciliation jobs`);
  } catch (e) {
    return error(res, 400, e.message || 'Failed to process pending jobs');
  }
}

/**
 * Run reconciliation immediately
 * POST /api/reconciliation/run-now
 */
async function runNow(req, res) {
  try {
    const { period = 'daily', processorType = 'all' } = req.body;
    const actor = req.user;

    // Only admin can run reconciliation immediately
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can run reconciliation immediately');
    }

    if (!['daily', 'weekly', 'monthly'].includes(period)) {
      return error(res, 400, 'Period must be daily, weekly, or monthly');
    }

    const result = await reconciliationScheduler.runNow(period, processorType);
    
    return ok(res, result, `Immediate reconciliation (${period}) completed successfully`);
  } catch (e) {
    return error(res, 400, e.message || 'Failed to run reconciliation immediately');
  }
}

module.exports = {
  getStats,
  getJobs,
  getJobDetails,
  createJob,
  processJob,
  getDiscrepancies,
  resolveDiscrepancy,
  generateReport,
  getSchedulerStatus,
  startScheduler,
  stopScheduler,
  updateSchedulerConfig,
  processPendingJobs,
  runNow
};
