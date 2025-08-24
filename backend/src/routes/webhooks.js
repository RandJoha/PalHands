const express = require('express');
const router = express.Router();
const { auth, checkRole } = require('../middleware/auth');
const controller = require('../controllers/payments');
const WebhookAuthMiddleware = require('../middleware/webhookAuth');
const rawBodyMiddleware = require('../middleware/rawBody');

/**
 * Dynamic webhook route handler
 * Creates processor-specific webhook endpoints with security middleware
 */
function createWebhookRoutes() {
  // Stripe webhook
  router.post('/stripe', 
    rawBodyMiddleware,
    WebhookAuthMiddleware.createMiddleware('stripe'),
    controller.webhook
  );

  // PayPal webhook (when implemented)
  router.post('/paypal', 
    rawBodyMiddleware,
    WebhookAuthMiddleware.createMiddleware('paypal'),
    controller.webhook
  );

  // Generic webhook for testing (admin only)
  router.post('/test', 
    auth, 
    checkRole(['admin']),
    rawBodyMiddleware,
    async (req, res) => {
      try {
        const { processorType, event } = req.body;
        
        if (!processorType || !event) {
          return res.status(400).json({ error: 'processorType and event are required' });
        }

        // Simulate webhook processing for testing
        const result = await controller.webhook({
          ...req,
          params: { processorType },
          body: event,
          webhookData: { verified: true, processorType }
        }, res);

        return result;
      } catch (error) {
        return res.status(500).json({ error: error.message });
      }
    }
  );

  return router;
}

module.exports = createWebhookRoutes();
