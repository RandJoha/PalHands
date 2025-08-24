const OutboxService = require('./outbox');

/**
 * Outbox Scheduler Service
 * Handles background processing of outbox messages
 */
class OutboxScheduler {
  constructor() {
    this.isRunning = false;
    this.pendingInterval = null;
    this.retryInterval = null;
    this.cleanupInterval = null;
    this.config = {
      pendingIntervalMs: 5000, // 5 seconds
      retryIntervalMs: 30000,  // 30 seconds
      cleanupIntervalMs: 3600000, // 1 hour
      batchSize: 50,
      maxConcurrentBatches: 3
    };
  }

  /**
   * Start the outbox scheduler
   * @param {Object} options - Configuration options
   */
  start(options = {}) {
    if (this.isRunning) {
      console.log('Outbox scheduler is already running');
      return;
    }

    // Update configuration
    this.config = { ...this.config, ...options };
    
    console.log('Starting outbox scheduler with config:', this.config);

    // Start pending message processing
    this.pendingInterval = setInterval(async () => {
      await this.processPendingBatch();
    }, this.config.pendingIntervalMs);

    // Start retry message processing
    this.retryInterval = setInterval(async () => {
      await this.processRetryBatch();
    }, this.config.retryIntervalMs);

    // Start cleanup process
    this.cleanupInterval = setInterval(async () => {
      await this.cleanupOldMessages();
    }, this.config.cleanupIntervalMs);

    this.isRunning = true;
    console.log('Outbox scheduler started successfully');
  }

  /**
   * Stop the outbox scheduler
   */
  stop() {
    if (!this.isRunning) {
      console.log('Outbox scheduler is not running');
      return;
    }

    console.log('Stopping outbox scheduler...');

    if (this.pendingInterval) {
      clearInterval(this.pendingInterval);
      this.pendingInterval = null;
    }

    if (this.retryInterval) {
      clearInterval(this.retryInterval);
      this.retryInterval = null;
    }

    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }

    this.isRunning = false;
    console.log('Outbox scheduler stopped');
  }

  /**
   * Process a batch of pending messages
   */
  async processPendingBatch() {
    try {
      const results = await OutboxService.processPendingMessages(this.config.batchSize);
      
      if (results.length > 0) {
        const delivered = results.filter(r => r.status === 'delivered').length;
        const failed = results.filter(r => r.status === 'failed').length;
        
        console.log(`Processed ${results.length} pending messages: ${delivered} delivered, ${failed} failed`);
      }
    } catch (error) {
      console.error('Failed to process pending batch:', error);
    }
  }

  /**
   * Process a batch of retryable messages
   */
  async processRetryBatch() {
    try {
      const results = await OutboxService.processRetryableMessages(this.config.batchSize);
      
      if (results.length > 0) {
        const delivered = results.filter(r => r.status === 'delivered').length;
        const failed = results.filter(r => r.status === 'failed').length;
        
        console.log(`Processed ${results.length} retryable messages: ${delivered} delivered, ${failed} failed`);
      }
    } catch (error) {
      console.error('Failed to process retry batch:', error);
    }
  }

  /**
   * Clean up old delivered messages
   */
  async cleanupOldMessages() {
    try {
      const deletedCount = await OutboxService.cleanupOldMessages(30); // Keep 30 days
      
      if (deletedCount > 0) {
        console.log(`Cleaned up ${deletedCount} old delivered messages`);
      }
    } catch (error) {
      console.error('Failed to cleanup old messages:', error);
    }
  }

  /**
   * Get scheduler status
   * @returns {Object} Scheduler status
   */
  getStatus() {
    return {
      isRunning: this.isRunning,
      config: this.config,
      intervals: {
        pending: !!this.pendingInterval,
        retry: !!this.retryInterval,
        cleanup: !!this.cleanupInterval
      }
    };
  }

  /**
   * Update scheduler configuration
   * @param {Object} newConfig - New configuration
   */
  updateConfig(newConfig) {
    const oldConfig = { ...this.config };
    this.config = { ...this.config, ...newConfig };
    
    console.log('Outbox scheduler config updated:', {
      old: oldConfig,
      new: this.config
    });

    // Restart scheduler if running to apply new config
    if (this.isRunning) {
      this.stop();
      this.start();
    }
  }

  /**
   * Process messages immediately (for testing/debugging)
   * @param {string} type - Type of messages to process ('pending' or 'retry')
   * @param {number} limit - Maximum messages to process
   */
  async processNow(type = 'pending', limit = 10) {
    try {
      let results;
      
      if (type === 'pending') {
        results = await OutboxService.processPendingMessages(limit);
      } else if (type === 'retry') {
        results = await OutboxService.processRetryableMessages(limit);
      } else {
        throw new Error(`Invalid process type: ${type}`);
      }

      console.log(`Immediate processing of ${type} messages:`, results);
      return results;
    } catch (error) {
      console.error(`Failed to process ${type} messages immediately:`, error);
      throw error;
    }
  }
}

// Create singleton instance
const outboxScheduler = new OutboxScheduler();

module.exports = outboxScheduler;
