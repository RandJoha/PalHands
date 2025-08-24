const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const controller = require('../controllers/outbox');
const { celebrate, Joi, Segments } = require('celebrate');

// Validation schemas
const retryDeadLettersValidator = celebrate({
  [Segments.BODY]: Joi.object({
    messageIds: Joi.array().items(Joi.string()).required()
  })
});

const schedulerConfigValidator = celebrate({
  [Segments.BODY]: Joi.object({
    config: Joi.object({
      pendingIntervalMs: Joi.number().min(1000).max(60000),
      retryIntervalMs: Joi.number().min(5000).max(300000),
      cleanupIntervalMs: Joi.number().min(300000).max(7200000),
      batchSize: Joi.number().min(1).max(200),
      maxConcurrentBatches: Joi.number().min(1).max(10)
    }).required()
  })
});

const processMessagesValidator = celebrate({
  [Segments.BODY]: Joi.object({
    type: Joi.string().valid('pending', 'retry').default('pending'),
    limit: Joi.number().min(1).max(100).default(10)
  })
});

const addTestMessageValidator = celebrate({
  [Segments.BODY]: Joi.object({
    type: Joi.string().valid('payment_webhook', 'email_notification', 'sms_notification', 'booking_update', 'payment_status_change').required(),
    payload: Joi.object().required(),
    destination: Joi.string().required()
  })
});

// Routes - All require admin authentication
router.use(auth, checkRole(['admin']));

// Statistics and monitoring
router.get('/stats', controller.getStats);
router.get('/messages', controller.getMessages);
router.get('/dead-letters', controller.getDeadLetters);

// Message management
router.post('/retry', retryDeadLettersValidator, controller.retryDeadLetters);
router.post('/test', addTestMessageValidator, controller.addTestMessage);

// Scheduler control
router.get('/scheduler/status', controller.getSchedulerStatus);
router.post('/scheduler/start', controller.startScheduler);
router.post('/scheduler/stop', controller.stopScheduler);
router.put('/scheduler/config', schedulerConfigValidator, controller.updateSchedulerConfig);

// Immediate processing
router.post('/process', processMessagesValidator, controller.processMessages);

module.exports = router;
