const ReconciliationService = require('./reconciliation');
const Reconciliation = require('../models/Reconciliation');

/**
 * Reconciliation Scheduler Service
 * Handles scheduled reconciliation jobs
 */
class ReconciliationScheduler {
  constructor() {
    this.isRunning = false;
    this.dailyInterval = null;
    this.weeklyInterval = null;
    this.monthlyInterval = null;
    this.config = {
      dailyIntervalMs: 24 * 60 * 60 * 1000, // 24 hours
      weeklyIntervalMs: 7 * 24 * 60 * 60 * 1000, // 7 days
      monthlyIntervalMs: 24 * 60 * 60 * 1000, // 1 day for development (instead of 30 days)
      batchSize: 5,
      maxConcurrentJobs: 2
    };
    
    // Prevent immediate execution on startup
    this.lastDailyRun = null;
    this.lastWeeklyRun = null;
    this.lastMonthlyRun = null;
    
    // Processing flags to prevent concurrent runs
    this.isProcessingDaily = false;
    this.isProcessingWeekly = false;
    this.isProcessingMonthly = false;
  }

  /**
   * Start the reconciliation scheduler
   * @param {Object} options - Configuration options
   */
  start(options = {}) {
    if (this.isRunning) {
      console.log('Reconciliation scheduler is already running');
      return;
    }

    // Update configuration
    this.config = { ...this.config, ...options };
    
    console.log('Starting reconciliation scheduler with config:', this.config);

    // Start daily reconciliation (runs every 24 hours)
    this.dailyInterval = setInterval(async () => {
      await this.runDailyReconciliation();
    }, this.config.dailyIntervalMs);

    // Start weekly reconciliation (runs every 7 days)
    this.weeklyInterval = setInterval(async () => {
      await this.runWeeklyReconciliation();
    }, this.config.weeklyIntervalMs);

    // Start monthly reconciliation (runs every 30 days)
    // Note: Using a longer interval for monthly to prevent immediate execution
    const monthlyIntervalMs = Math.max(this.config.monthlyIntervalMs, 24 * 60 * 60 * 1000); // At least 24 hours
    this.monthlyInterval = setInterval(async () => {
      await this.runMonthlyReconciliation();
    }, monthlyIntervalMs);

    // Set initial run times to prevent immediate execution
    this.lastDailyRun = new Date();
    this.lastWeeklyRun = new Date();
    this.lastMonthlyRun = new Date();

    this.isRunning = true;
    console.log('Reconciliation scheduler started successfully');
  }

  /**
   * Stop the reconciliation scheduler
   */
  stop() {
    if (!this.isRunning) {
      console.log('Reconciliation scheduler is not running');
      return;
    }

    console.log('Stopping reconciliation scheduler...');

    if (this.dailyInterval) {
      clearInterval(this.dailyInterval);
      this.dailyInterval = null;
    }

    if (this.weeklyInterval) {
      clearInterval(this.weeklyInterval);
      this.weeklyInterval = null;
    }

    if (this.monthlyInterval) {
      clearInterval(this.monthlyInterval);
      this.monthlyInterval = null;
    }

    this.isRunning = false;
    console.log('Reconciliation scheduler stopped');
  }

  /**
   * Run daily reconciliation
   */
  async runDailyReconciliation() {
    try {
      // Check if already processing
      if (this.isProcessingDaily) {
        console.log('Daily reconciliation skipped - already processing');
        return;
      }
      
      // Check if we should run (prevent duplicate runs)
      const now = new Date();
      if (this.lastDailyRun && (now - this.lastDailyRun) < this.config.dailyIntervalMs) {
        console.log('Daily reconciliation skipped - too soon since last run');
        return;
      }
      
      console.log('Starting daily reconciliation...');
      this.isProcessingDaily = true;
      this.lastDailyRun = now;
      
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);
      
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Create daily reconciliation for each processor type
      const processorTypes = ['all', 'stripe', 'paypal', 'cash'];
      
      for (const processorType of processorTypes) {
        try {
          const reconciliation = await ReconciliationService.createReconciliation({
            period: 'daily',
            startDate: yesterday,
            endDate: today,
            processorType
          });

          await this.processReconciliationJob(reconciliation);
        } catch (error) {
          console.error(`Failed to run daily reconciliation for ${processorType}:`, error);
        }
      }

      console.log('Daily reconciliation completed');
    } catch (error) {
      console.error('Failed to run daily reconciliation:', error);
    } finally {
      this.isProcessingDaily = false;
    }
  }

  /**
   * Run weekly reconciliation
   */
  async runWeeklyReconciliation() {
    try {
      // Check if already processing
      if (this.isProcessingWeekly) {
        console.log('Weekly reconciliation skipped - already processing');
        return;
      }
      
      // Check if we should run (prevent duplicate runs)
      const now = new Date();
      if (this.lastWeeklyRun && (now - this.lastWeeklyRun) < this.config.weeklyIntervalMs) {
        console.log('Weekly reconciliation skipped - too soon since last run');
        return;
      }
      
      console.log('Starting weekly reconciliation...');
      this.isProcessingWeekly = true;
      this.lastWeeklyRun = now;
      
      const lastWeek = new Date();
      lastWeek.setDate(lastWeek.getDate() - 7);
      lastWeek.setHours(0, 0, 0, 0);
      
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Create weekly reconciliation for all processors
      const reconciliation = await ReconciliationService.createReconciliation({
        period: 'weekly',
        startDate: lastWeek,
        endDate: today,
        processorType: 'all'
      });

      await this.processReconciliationJob(reconciliation);
      console.log('Weekly reconciliation completed');
    } catch (error) {
      console.error('Failed to run weekly reconciliation:', error);
    } finally {
      this.isProcessingWeekly = false;
    }
  }

  /**
   * Run monthly reconciliation
   */
  async runMonthlyReconciliation() {
    try {
      // Check if already processing
      if (this.isProcessingMonthly) {
        console.log('Monthly reconciliation skipped - already processing');
        return;
      }
      
      // Check if we should run (prevent duplicate runs)
      const now = new Date();
      if (this.lastMonthlyRun && (now - this.lastMonthlyRun) < this.config.monthlyIntervalMs) {
        console.log('Monthly reconciliation skipped - too soon since last run');
        return;
      }
      
      console.log('Starting monthly reconciliation...');
      this.isProcessingMonthly = true;
      this.lastMonthlyRun = now;
      
      const lastMonth = new Date();
      lastMonth.setMonth(lastMonth.getMonth() - 1);
      lastMonth.setDate(1);
      lastMonth.setHours(0, 0, 0, 0);
      
      const thisMonth = new Date();
      thisMonth.setDate(1);
      thisMonth.setHours(0, 0, 0, 0);

      // Create monthly reconciliation for all processors
      const reconciliation = await ReconciliationService.createReconciliation({
        period: 'monthly',
        startDate: lastMonth,
        endDate: thisMonth,
        processorType: 'all'
      });

      await this.processReconciliationJob(reconciliation);
      console.log('Monthly reconciliation completed');
    } catch (error) {
      console.error('Failed to run monthly reconciliation:', error);
    } finally {
      this.isProcessingMonthly = false;
    }
  }

  /**
   * Process a reconciliation job
   * @param {Reconciliation} reconciliation - Reconciliation to process
   */
  async processReconciliationJob(reconciliation) {
    try {
      console.log(`Processing reconciliation job: ${reconciliation.reconciliationId}`);
      
      const result = await ReconciliationService.processReconciliation(reconciliation);
      
      if (result.success) {
        console.log(`Reconciliation ${reconciliation.reconciliationId} completed successfully`);
        
        if (result.discrepancies > 0) {
          console.warn(`Reconciliation ${reconciliation.reconciliationId} found ${result.discrepancies} discrepancies`);
          
          // TODO: Send notification to admin about discrepancies
          await this.notifyDiscrepancies(reconciliation, result.discrepancies);
        }
      } else {
        console.error(`Reconciliation ${reconciliation.reconciliationId} failed:`, result.error);
      }
    } catch (error) {
      console.error(`Failed to process reconciliation job ${reconciliation.reconciliationId}:`, error);
    }
  }

  /**
   * Process pending reconciliation jobs
   * @param {number} limit - Maximum jobs to process
   * @returns {Promise<Array>} Processing results
   */
  async processPendingJobs(limit = 10) {
    const results = [];
    
    try {
      const pendingJobs = await Reconciliation.findPending(limit);
      console.log(`Processing ${pendingJobs.length} pending reconciliation jobs`);

      for (const job of pendingJobs) {
        try {
          const result = await ReconciliationService.processReconciliation(job);
          results.push({
            reconciliationId: job.reconciliationId,
            success: result.success,
            discrepancies: result.discrepancies || 0,
            error: result.error
          });
        } catch (error) {
          console.error(`Failed to process reconciliation job ${job.reconciliationId}:`, error);
          results.push({
            reconciliationId: job.reconciliationId,
            success: false,
            error: error.message
          });
        }
      }
    } catch (error) {
      console.error('Failed to process pending reconciliation jobs:', error);
      throw error;
    }

    return results;
  }

  /**
   * Notify about discrepancies (placeholder for future implementation)
   * @param {Reconciliation} reconciliation - Reconciliation with discrepancies
   * @param {number} discrepancyCount - Number of discrepancies
   */
  async notifyDiscrepancies(reconciliation, discrepancyCount) {
    try {
      // TODO: Implement notification system (email, Slack, etc.)
      console.log(`DISCREPANCY ALERT: ${discrepancyCount} discrepancies found in reconciliation ${reconciliation.reconciliationId}`);
      
      // For now, just log the alert
      // In the future, this could send emails, Slack messages, etc.
    } catch (error) {
      console.error('Failed to send discrepancy notification:', error);
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
        daily: !!this.dailyInterval,
        weekly: !!this.weeklyInterval,
        monthly: !!this.monthlyInterval
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
    
    console.log('Reconciliation scheduler config updated:', {
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
   * Run reconciliation immediately (for testing/debugging)
   * @param {string} period - Period type ('daily', 'weekly', 'monthly')
   * @param {string} processorType - Processor type
   */
  async runNow(period = 'daily', processorType = 'all') {
    try {
      let startDate, endDate;
      
      switch (period) {
        case 'daily':
          startDate = new Date();
          startDate.setDate(startDate.getDate() - 1);
          startDate.setHours(0, 0, 0, 0);
          endDate = new Date();
          endDate.setHours(0, 0, 0, 0);
          break;
        case 'weekly':
          startDate = new Date();
          startDate.setDate(startDate.getDate() - 7);
          startDate.setHours(0, 0, 0, 0);
          endDate = new Date();
          endDate.setHours(0, 0, 0, 0);
          break;
        case 'monthly':
          startDate = new Date();
          startDate.setMonth(startDate.getMonth() - 1);
          startDate.setDate(1);
          startDate.setHours(0, 0, 0, 0);
          endDate = new Date();
          endDate.setDate(1);
          endDate.setHours(0, 0, 0, 0);
          break;
        default:
          throw new Error(`Invalid period: ${period}`);
      }

      const reconciliation = await ReconciliationService.createReconciliation({
        period,
        startDate,
        endDate,
        processorType
      });

      const result = await this.processReconciliationJob(reconciliation);
      console.log(`Immediate reconciliation (${period}) completed:`, result);
      return result;
    } catch (error) {
      console.error(`Failed to run immediate reconciliation (${period}):`, error);
      throw error;
    }
  }
}

// Create singleton instance
const reconciliationScheduler = new ReconciliationScheduler();

module.exports = reconciliationScheduler;
