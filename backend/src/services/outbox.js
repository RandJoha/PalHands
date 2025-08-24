const Outbox = require('../models/Outbox');
const crypto = require('crypto');

/**
 * Outbox Service
 * Manages reliable message dispatch with retry mechanisms and dead letter queue
 */
class OutboxService {
  /**
   * Add a message to the outbox
   * @param {Object} options - Message options
   * @returns {Promise<Outbox>} Created outbox message
   */
  static async addMessage({
    type,
    payload,
    destination,
    correlationId = null,
    priority = 'normal',
    scheduledAt = null,
    maxAttempts = 3,
    metadata = {}
  }) {
    try {
      const messageId = crypto.randomUUID();
      const correlation = correlationId || crypto.randomUUID();
      
      const outboxMessage = new Outbox({
        messageId,
        correlationId: correlation,
        type,
        payload,
        destination,
        priority,
        scheduledAt: scheduledAt || new Date(),
        maxAttempts,
        metadata
      });

      await outboxMessage.save();
      console.log(`Message added to outbox: ${messageId} (${type})`);
      
      return outboxMessage;
    } catch (error) {
      console.error('Failed to add message to outbox:', error);
      throw error;
    }
  }

  /**
   * Process pending messages
   * @param {number} limit - Maximum messages to process
   * @returns {Promise<Array>} Processing results
   */
  static async processPendingMessages(limit = 50) {
    const results = [];
    
    try {
      // Get pending messages
      const pendingMessages = await Outbox.findPending(limit);
      console.log(`Processing ${pendingMessages.length} pending messages`);

      for (const message of pendingMessages) {
        try {
          // Mark as processing
          await message.markProcessing();
          
          // Process the message
          const result = await this.processMessage(message);
          
          if (result.success) {
            await message.markDelivered();
            results.push({ messageId: message.messageId, status: 'delivered' });
          } else {
            await message.markFailed(result.error);
            results.push({ messageId: message.messageId, status: 'failed', error: result.error });
          }
        } catch (error) {
          console.error(`Failed to process message ${message.messageId}:`, error);
          await message.markFailed(error.message);
          results.push({ messageId: message.messageId, status: 'failed', error: error.message });
        }
      }
    } catch (error) {
      console.error('Failed to process pending messages:', error);
      throw error;
    }

    return results;
  }

  /**
   * Process retryable messages
   * @param {number} limit - Maximum messages to process
   * @returns {Promise<Array>} Processing results
   */
  static async processRetryableMessages(limit = 50) {
    const results = [];
    
    try {
      // Get retryable messages
      const retryableMessages = await Outbox.findRetryable(limit);
      console.log(`Processing ${retryableMessages.length} retryable messages`);

      for (const message of retryableMessages) {
        try {
          // Mark as processing
          await message.markProcessing();
          
          // Process the message
          const result = await this.processMessage(message);
          
          if (result.success) {
            await message.markDelivered();
            results.push({ messageId: message.messageId, status: 'delivered' });
          } else {
            await message.markFailed(result.error);
            results.push({ messageId: message.messageId, status: 'failed', error: result.error });
          }
        } catch (error) {
          console.error(`Failed to retry message ${message.messageId}:`, error);
          await message.markFailed(error.message);
          results.push({ messageId: message.messageId, status: 'failed', error: error.message });
        }
      }
    } catch (error) {
      console.error('Failed to process retryable messages:', error);
      throw error;
    }

    return results;
  }

  /**
   * Process a single message based on its type
   * @param {Outbox} message - Outbox message to process
   * @returns {Promise<Object>} Processing result
   */
  static async processMessage(message) {
    try {
      switch (message.type) {
        case 'payment_webhook':
          return await this.processPaymentWebhook(message);
        
        case 'email_notification':
          return await this.processEmailNotification(message);
        
        case 'sms_notification':
          return await this.processSmsNotification(message);
        
        case 'booking_update':
          return await this.processBookingUpdate(message);
        
        case 'payment_status_change':
          return await this.processPaymentStatusChange(message);
        
        default:
          throw new Error(`Unknown message type: ${message.type}`);
      }
    } catch (error) {
      console.error(`Failed to process message ${message.messageId}:`, error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Process payment webhook message
   * @param {Outbox} message - Outbox message
   * @returns {Promise<Object>} Processing result
   */
  static async processPaymentWebhook(message) {
    try {
      const { processorType, event, webhookUrl } = message.payload;
      
      // Make HTTP request to webhook URL
      const response = await fetch(webhookUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Signature': this.generateWebhookSignature(event, processorType),
          'X-Webhook-Id': message.messageId,
          'X-Webhook-Timestamp': Math.floor(Date.now() / 1000).toString()
        },
        body: JSON.stringify(event)
      });

      if (!response.ok) {
        throw new Error(`Webhook failed with status ${response.status}: ${response.statusText}`);
      }

      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Process email notification message
   * @param {Outbox} message - Outbox message
   * @returns {Promise<Object>} Processing result
   */
  static async processEmailNotification(message) {
    try {
      const { to, subject, template, data } = message.payload;
      
      // Use existing mailer service
      const mailer = require('./mailer');
      await mailer.sendEmail(to, subject, template, data);
      
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Process SMS notification message
   * @param {Outbox} message - Outbox message
   * @returns {Promise<Object>} Processing result
   */
  static async processSmsNotification(message) {
    try {
      const { to, message: smsMessage } = message.payload;
      
      // TODO: Implement SMS service integration
      console.log(`SMS to ${to}: ${smsMessage}`);
      
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Process booking update message
   * @param {Outbox} message - Outbox message
   * @returns {Promise<Object>} Processing result
   */
  static async processBookingUpdate(message) {
    try {
      const { bookingId, updateType, data } = message.payload;
      
      // TODO: Implement booking update logic
      console.log(`Booking update ${updateType} for ${bookingId}:`, data);
      
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Process payment status change message
   * @param {Outbox} message - Outbox message
   * @returns {Promise<Object>} Processing result
   */
  static async processPaymentStatusChange(message) {
    try {
      const { paymentId, oldStatus, newStatus, notificationData } = message.payload;
      
      // TODO: Implement payment status change notifications
      console.log(`Payment ${paymentId} status changed from ${oldStatus} to ${newStatus}`);
      
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Generate webhook signature for security
   * @param {Object} payload - Webhook payload
   * @param {string} processorType - Processor type
   * @returns {string} Generated signature
   */
  static generateWebhookSignature(payload, processorType) {
    const secret = process.env[`${processorType.toUpperCase()}_WEBHOOK_SECRET`];
    if (!secret) {
      throw new Error(`Missing webhook secret for ${processorType}`);
    }
    
    const payloadString = JSON.stringify(payload);
    return crypto
      .createHmac('sha256', secret)
      .update(payloadString)
      .digest('hex');
  }

  /**
   * Get outbox statistics
   * @param {number} days - Number of days to look back
   * @returns {Promise<Object>} Statistics
   */
  static async getStats(days = 7) {
    try {
      const stats = await Outbox.getStats(days);
      return stats;
    } catch (error) {
      console.error('Failed to get outbox stats:', error);
      throw error;
    }
  }

  /**
   * Retry dead letter messages
   * @param {Array<string>} messageIds - Message IDs to retry
   * @returns {Promise<Array>} Retry results
   */
  static async retryDeadLetters(messageIds) {
    const results = [];
    
    try {
      for (const messageId of messageIds) {
        try {
          const message = await Outbox.findOne({ messageId, status: 'dead_letter' });
          if (message) {
            await message.retry();
            results.push({ messageId, status: 'retried' });
          } else {
            results.push({ messageId, status: 'not_found' });
          }
        } catch (error) {
          results.push({ messageId, status: 'error', error: error.message });
        }
      }
    } catch (error) {
      console.error('Failed to retry dead letters:', error);
      throw error;
    }

    return results;
  }

  /**
   * Clean up old delivered messages
   * @param {number} days - Keep messages older than this many days
   * @returns {Promise<number>} Number of messages deleted
   */
  static async cleanupOldMessages(days = 30) {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - days);
      
      const result = await Outbox.deleteMany({
        status: 'delivered',
        deliveredAt: { $lt: cutoffDate }
      });
      
      console.log(`Cleaned up ${result.deletedCount} old delivered messages`);
      return result.deletedCount;
    } catch (error) {
      console.error('Failed to cleanup old messages:', error);
      throw error;
    }
  }
}

module.exports = OutboxService;
