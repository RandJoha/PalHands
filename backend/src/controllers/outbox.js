const OutboxService = require('../services/outbox');
const outboxScheduler = require('../services/outboxScheduler');
const Outbox = require('../models/Outbox');
const { ok, error } = require('../utils/response');

/**
 * Get outbox statistics
 * GET /api/outbox/stats
 */
async function getStats(req, res) {
  try {
    const { days = 7 } = req.query;
    const actor = req.user;

    // Only admin can view outbox stats
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view outbox statistics');
    }

    const stats = await OutboxService.getStats(parseInt(days));
    return ok(res, stats, 'Outbox statistics retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get outbox statistics');
  }
}

/**
 * Get outbox messages with filtering
 * GET /api/outbox/messages
 */
async function getMessages(req, res) {
  try {
    const { 
      status, 
      type, 
      limit = 50, 
      skip = 0,
      correlationId,
      messageId 
    } = req.query;
    const actor = req.user;

    // Only admin can view outbox messages
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view outbox messages');
    }

    const query = {};
    
    if (status) query.status = status;
    if (type) query.type = type;
    if (correlationId) query.correlationId = correlationId;
    if (messageId) query.messageId = messageId;

    const messages = await Outbox.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await Outbox.countDocuments(query);

    return ok(res, {
      messages,
      pagination: {
        total,
        limit: parseInt(limit),
        skip: parseInt(skip),
        hasMore: total > parseInt(skip) + messages.length
      }
    }, 'Outbox messages retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get outbox messages');
  }
}

/**
 * Get dead letter messages
 * GET /api/outbox/dead-letters
 */
async function getDeadLetters(req, res) {
  try {
    const { limit = 50, skip = 0 } = req.query;
    const actor = req.user;

    // Only admin can view dead letter messages
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view dead letter messages');
    }

    const messages = await Outbox.findDeadLetters(parseInt(limit))
      .skip(parseInt(skip));

    const total = await Outbox.countDocuments({ status: 'dead_letter' });

    return ok(res, {
      messages,
      pagination: {
        total,
        limit: parseInt(limit),
        skip: parseInt(skip),
        hasMore: total > parseInt(skip) + messages.length
      }
    }, 'Dead letter messages retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get dead letter messages');
  }
}

/**
 * Retry dead letter messages
 * POST /api/outbox/retry
 */
async function retryDeadLetters(req, res) {
  try {
    const { messageIds } = req.body;
    const actor = req.user;

    // Only admin can retry dead letter messages
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can retry dead letter messages');
    }

    if (!messageIds || !Array.isArray(messageIds)) {
      return error(res, 400, 'messageIds array is required');
    }

    const results = await OutboxService.retryDeadLetters(messageIds);
    
    const retried = results.filter(r => r.status === 'retried').length;
    const notFound = results.filter(r => r.status === 'not_found').length;
    const errors = results.filter(r => r.status === 'error').length;

    return ok(res, {
      results,
      summary: {
        total: results.length,
        retried,
        notFound,
        errors
      }
    }, `Retried ${retried} dead letter messages`);
  } catch (e) {
    return error(res, 400, e.message || 'Failed to retry dead letter messages');
  }
}

/**
 * Get scheduler status
 * GET /api/outbox/scheduler/status
 */
async function getSchedulerStatus(req, res) {
  try {
    const actor = req.user;

    // Only admin can view scheduler status
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view scheduler status');
    }

    const status = outboxScheduler.getStatus();
    return ok(res, status, 'Scheduler status retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get scheduler status');
  }
}

/**
 * Start scheduler
 * POST /api/outbox/scheduler/start
 */
async function startScheduler(req, res) {
  try {
    const { config } = req.body;
    const actor = req.user;

    // Only admin can control scheduler
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can control scheduler');
    }

    outboxScheduler.start(config);
    const status = outboxScheduler.getStatus();
    
    return ok(res, status, 'Scheduler started successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to start scheduler');
  }
}

/**
 * Stop scheduler
 * POST /api/outbox/scheduler/stop
 */
async function stopScheduler(req, res) {
  try {
    const actor = req.user;

    // Only admin can control scheduler
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can control scheduler');
    }

    outboxScheduler.stop();
    const status = outboxScheduler.getStatus();
    
    return ok(res, status, 'Scheduler stopped successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to stop scheduler');
  }
}

/**
 * Update scheduler configuration
 * PUT /api/outbox/scheduler/config
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

    outboxScheduler.updateConfig(config);
    const status = outboxScheduler.getStatus();
    
    return ok(res, status, 'Scheduler configuration updated successfully');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to update scheduler configuration');
  }
}

/**
 * Process messages immediately
 * POST /api/outbox/process
 */
async function processMessages(req, res) {
  try {
    const { type = 'pending', limit = 10 } = req.body;
    const actor = req.user;

    // Only admin can process messages immediately
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can process messages immediately');
    }

    if (!['pending', 'retry'].includes(type)) {
      return error(res, 400, 'Type must be either "pending" or "retry"');
    }

    const results = await outboxScheduler.processNow(type, parseInt(limit));
    
    const delivered = results.filter(r => r.status === 'delivered').length;
    const failed = results.filter(r => r.status === 'failed').length;

    return ok(res, {
      results,
      summary: {
        total: results.length,
        delivered,
        failed
      }
    }, `Processed ${results.length} ${type} messages`);
  } catch (e) {
    return error(res, 400, e.message || 'Failed to process messages');
  }
}

/**
 * Add test message to outbox
 * POST /api/outbox/test
 */
async function addTestMessage(req, res) {
  try {
    const { type, payload, destination } = req.body;
    const actor = req.user;

    // Only admin can add test messages
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can add test messages');
    }

    if (!type || !payload || !destination) {
      return error(res, 400, 'type, payload, and destination are required');
    }

    const message = await OutboxService.addMessage({
      type,
      payload,
      destination,
      correlationId: `test_${Date.now()}`,
      priority: 'normal',
      metadata: { test: true, addedBy: actor._id }
    });

    return ok(res, message, 'Test message added to outbox');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to add test message');
  }
}

module.exports = {
  getStats,
  getMessages,
  getDeadLetters,
  retryDeadLetters,
  getSchedulerStatus,
  startScheduler,
  stopScheduler,
  updateSchedulerConfig,
  processMessages,
  addTestMessage
};
