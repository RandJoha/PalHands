const crypto = require('crypto');
const processorManager = require('../services/paymentProcessors/processorManager');

/**
 * Webhook Authentication Middleware
 * Handles signature verification and replay protection for payment webhooks
 */
class WebhookAuthMiddleware {
  /**
   * Middleware factory for webhook authentication
   * @param {string} processorType - Type of processor (stripe, paypal, etc.)
   * @returns {Function} Express middleware function
   */
  static createMiddleware(processorType) {
    return async (req, res, next) => {
      try {
        // Get the raw body for signature verification
        const rawBody = req.rawBody || req.body;
        const signature = req.headers['stripe-signature'] || req.headers['paypal-signature'] || req.headers['x-webhook-signature'];
        const webhookId = req.headers['stripe-webhook-id'] || req.headers['paypal-webhook-id'] || req.headers['x-webhook-id'];
        const timestamp = req.headers['stripe-timestamp'] || req.headers['paypal-timestamp'] || req.headers['x-webhook-timestamp'];

        // Check if webhook is enabled for this processor
        const webhookEnabled = process.env[`PAYMENT_${processorType.toUpperCase()}_ENABLED`] === 'true';
        if (!webhookEnabled) {
          console.log(`Webhook disabled for ${processorType}`);
          return res.status(200).json({ message: 'Webhook disabled' });
        }

        // Validate required headers
        if (!signature) {
          console.error(`Missing signature header for ${processorType} webhook`);
          return res.status(401).json({ error: 'Missing signature' });
        }

        // Check replay protection
        const replayCheck = await this.checkReplayProtection(processorType, webhookId, timestamp);
        if (!replayCheck.isValid) {
          console.error(`Replay attack detected for ${processorType} webhook:`, replayCheck.reason);
          return res.status(400).json({ error: 'Replay attack detected' });
        }

        // Verify signature
        const secret = process.env[`${processorType.toUpperCase()}_WEBHOOK_SECRET`];
        if (!secret) {
          console.error(`Missing webhook secret for ${processorType}`);
          return res.status(500).json({ error: 'Webhook configuration error' });
        }

        const isValidSignature = await processorManager.verifyWebhookSignature(
          processorType,
          rawBody,
          signature,
          secret
        );

        if (!isValidSignature) {
          console.error(`Invalid signature for ${processorType} webhook`);
          return res.status(401).json({ error: 'Invalid signature' });
        }

        // Store webhook data for processing
        req.webhookData = {
          processorType,
          rawBody,
          signature,
          webhookId,
          timestamp,
          verified: true
        };

        // Mark webhook as processed to prevent replay
        await this.markWebhookProcessed(processorType, webhookId, timestamp);

        next();
      } catch (error) {
        console.error(`Webhook authentication error for ${processorType}:`, error);
        return res.status(500).json({ error: 'Webhook authentication failed' });
      }
    };
  }

  /**
   * Check for replay attacks
   * @param {string} processorType - Type of processor
   * @param {string} webhookId - Webhook ID
   * @param {string} timestamp - Webhook timestamp
   * @returns {Object} Replay check result
   */
  static async checkReplayProtection(processorType, webhookId, timestamp) {
    try {
      // Check if webhook was already processed
      const WebhookLog = require('../models/WebhookLog');
      
      if (webhookId) {
        const existingLog = await WebhookLog.findOne({
          processorType,
          webhookId,
          processed: true
        });

        if (existingLog) {
          return {
            isValid: false,
            reason: 'Webhook already processed',
            webhookId
          };
        }
      }

      // Check timestamp (prevent old webhooks)
      if (timestamp) {
        const webhookTime = parseInt(timestamp) * 1000; // Convert to milliseconds
        const currentTime = Date.now();
        const maxAge = 5 * 60 * 1000; // 5 minutes

        if (currentTime - webhookTime > maxAge) {
          return {
            isValid: false,
            reason: 'Webhook too old',
            webhookTime: new Date(webhookTime),
            currentTime: new Date(currentTime),
            age: currentTime - webhookTime
          };
        }
      }

      return { isValid: true };
    } catch (error) {
      console.error('Replay protection check failed:', error);
      // Allow webhook to proceed if replay protection fails
      return { isValid: true };
    }
  }

  /**
   * Mark webhook as processed
   * @param {string} processorType - Type of processor
   * @param {string} webhookId - Webhook ID
   * @param {string} timestamp - Webhook timestamp
   */
  static async markWebhookProcessed(processorType, webhookId, timestamp) {
    try {
      const WebhookLog = require('../models/WebhookLog');
      
      await WebhookLog.create({
        processorType,
        webhookId: webhookId || `manual_${Date.now()}`,
        timestamp: timestamp ? parseInt(timestamp) : Math.floor(Date.now() / 1000),
        processed: true,
        processedAt: new Date()
      });
    } catch (error) {
      console.error('Failed to mark webhook as processed:', error);
      // Don't fail the webhook if logging fails
    }
  }

  /**
   * Log webhook processing
   * @param {string} processorType - Type of processor
   * @param {Object} event - Webhook event data
   * @param {Object} result - Processing result
   */
  static async logWebhookProcessing(processorType, event, result) {
    try {
      const WebhookLog = require('../models/WebhookLog');
      
      await WebhookLog.create({
        processorType,
        webhookId: event.id || `event_${Date.now()}`,
        eventType: event.type || 'unknown',
        eventData: event,
        processingResult: result,
        processed: true,
        processedAt: new Date(),
        success: result.success || false
      });
    } catch (error) {
      console.error('Failed to log webhook processing:', error);
    }
  }

  /**
   * Get webhook statistics
   * @param {string} processorType - Type of processor (optional)
   * @param {Object} options - Query options
   * @returns {Object} Webhook statistics
   */
  static async getWebhookStats(processorType = null, options = {}) {
    try {
      const WebhookLog = require('../models/WebhookLog');
      
      const query = {};
      if (processorType) {
        query.processorType = processorType;
      }

      const stats = await WebhookLog.aggregate([
        { $match: query },
        {
          $group: {
            _id: {
              processorType: '$processorType',
              eventType: '$eventType',
              success: '$success'
            },
            count: { $sum: 1 },
            lastProcessed: { $max: '$processedAt' }
          }
        },
        {
          $group: {
            _id: '$_id.processorType',
            events: {
              $push: {
                eventType: '$_id.eventType',
                success: '$_id.success',
                count: '$count',
                lastProcessed: '$lastProcessed'
              }
            },
            totalCount: { $sum: '$count' }
          }
        }
      ]);

      return stats;
    } catch (error) {
      console.error('Failed to get webhook stats:', error);
      return [];
    }
  }
}

module.exports = WebhookAuthMiddleware;
