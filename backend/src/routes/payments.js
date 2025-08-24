const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const controller = require('../controllers/payments');
const { celebrate, Joi, Segments } = require('celebrate');
const WebhookAuthMiddleware = require('../middleware/webhookAuth');
const rawBodyMiddleware = require('../middleware/rawBody');

const createPaymentValidator = celebrate({
  [Segments.BODY]: Joi.object({
    bookingId: Joi.string().hex().length(24).required(),
    method: Joi.string().valid('cash','credit_card','paypal','bank_transfer').optional(),
    notes: Joi.string().max(500).optional()
  })
});

const minimalCashPaymentValidator = celebrate({
  [Segments.BODY]: Joi.object({
    bookingId: Joi.string().hex().length(24).required(),
    notes: Joi.string().max(500).optional()
  })
});

const updatePaymentValidator = celebrate({
  [Segments.BODY]: Joi.object({
    status: Joi.string().valid('pending','paid','failed','refunded').required(),
    transactionId: Joi.string().allow('').optional(),
    notes: Joi.string().max(500).optional()
  })
});

const confirmPaymentValidator = celebrate({
  [Segments.BODY]: Joi.object({
    paymentMethodId: Joi.string().required(),
    returnUrl: Joi.string().uri().optional()
  })
});

const refundPaymentValidator = celebrate({
  [Segments.BODY]: Joi.object({
    amount: Joi.number().positive().optional(),
    reason: Joi.string().max(500).required()
  })
});

router.get('/methods', controller.getPaymentMethods);
router.get('/health', auth, checkRole(['admin']), controller.getPaymentHealth);
router.post('/', auth, checkRole(['client','admin']), createPaymentValidator, controller.createPayment);
router.post('/cash/minimal', auth, checkRole(['admin']), minimalCashPaymentValidator, controller.createMinimalCashPayment);
router.put('/:id/status', auth, checkRole(['admin']), updatePaymentValidator, controller.updatePaymentStatus);
router.post('/:id/confirm', auth, checkRole(['client','admin']), confirmPaymentValidator, controller.confirmPayment);
router.post('/:id/refund', auth, checkRole(['admin']), refundPaymentValidator, controller.refundPayment);
router.get('/:id/audit', auth, checkRole(['client','provider','admin']), controller.getPaymentAudit);
router.get('/audit/booking/:bookingId', auth, checkRole(['client','provider','admin']), controller.getBookingPaymentAudit);
router.get('/webhook/stats', auth, checkRole(['admin']), controller.getWebhookStats);

// Webhook routes are now handled in /api/webhooks
// This route is kept for backward compatibility but redirects to the new webhook system
router.post('/webhook', (req, res) => {
  res.status(301).json({ 
    message: 'Webhook endpoint moved to /api/webhooks/{processorType}',
    newEndpoints: {
      stripe: '/api/webhooks/stripe',
      paypal: '/api/webhooks/paypal',
      test: '/api/webhooks/test'
    }
  });
});

module.exports = router;
