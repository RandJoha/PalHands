const Reconciliation = require('../models/Reconciliation');
const Payment = require('../models/Payment');
const processorManager = require('./paymentProcessors/processorManager');
const crypto = require('crypto');

/**
 * Reconciliation Service
 * Handles financial reconciliation between payment processors and internal records
 */
class ReconciliationService {
  /**
   * Create a new reconciliation job
   * @param {Object} options - Reconciliation options
   * @returns {Promise<Reconciliation>} Created reconciliation
   */
  static async createReconciliation({
    period = 'daily',
    startDate,
    endDate,
    processorType = 'all',
    createdBy = null
  }) {
    try {
      const reconciliationId = crypto.randomUUID();
      
      const reconciliation = new Reconciliation({
        reconciliationId,
        period,
        startDate: startDate || new Date(Date.now() - 24 * 60 * 60 * 1000), // Default to yesterday
        endDate: endDate || new Date(),
        processorType,
        expectedAmount: 0,
        actualAmount: 0,
        createdBy
      });

      await reconciliation.save();
      console.log(`Reconciliation created: ${reconciliationId} for ${period} period`);
      
      return reconciliation;
    } catch (error) {
      console.error('Failed to create reconciliation:', error);
      throw error;
    }
  }

  /**
   * Process a reconciliation job
   * @param {Reconciliation} reconciliation - Reconciliation to process
   * @returns {Promise<Object>} Processing result
   */
  static async processReconciliation(reconciliation) {
    try {
      await reconciliation.markProcessing();
      console.log(`Processing reconciliation: ${reconciliation.reconciliationId}`);

      // Get internal payment records
      const internalPayments = await this.getInternalPayments(
        reconciliation.startDate,
        reconciliation.endDate,
        reconciliation.processorType
      );

      // Get processor records
      const processorRecords = await this.getProcessorRecords(
        reconciliation.startDate,
        reconciliation.endDate,
        reconciliation.processorType
      );

      // Calculate expected amounts
      const expectedSummary = this.calculateExpectedSummary(internalPayments);
      
      // Calculate actual amounts
      const actualSummary = this.calculateActualSummary(processorRecords);

      // Update reconciliation with summary
      reconciliation.expectedAmount = expectedSummary.totalAmount;
      reconciliation.expectedTransactions = expectedSummary.transactionCount;
      reconciliation.actualAmount = actualSummary.totalAmount;
      reconciliation.actualTransactions = actualSummary.transactionCount;

      // Detect discrepancies
      const discrepancies = await this.detectDiscrepancies(
        internalPayments,
        processorRecords,
        reconciliation
      );

      // Add discrepancies to reconciliation
      for (const discrepancy of discrepancies) {
        await reconciliation.addDiscrepancy(discrepancy);
      }

      // Mark reconciliation as completed or with discrepancies
      if (discrepancies.length > 0) {
        await reconciliation.markDiscrepanciesFound();
        console.log(`Reconciliation ${reconciliation.reconciliationId} completed with ${discrepancies.length} discrepancies`);
      } else {
        await reconciliation.markCompleted();
        console.log(`Reconciliation ${reconciliation.reconciliationId} completed successfully`);
      }

      return {
        success: true,
        reconciliationId: reconciliation.reconciliationId,
        discrepancies: discrepancies.length,
        variance: reconciliation.calculateVariance()
      };
    } catch (error) {
      console.error(`Failed to process reconciliation ${reconciliation.reconciliationId}:`, error);
      await reconciliation.markFailed(error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * Get internal payment records for reconciliation period
   * @param {Date} startDate - Start date
   * @param {Date} endDate - End date
   * @param {string} processorType - Processor type filter
   * @returns {Promise<Array>} Internal payment records
   */
  static async getInternalPayments(startDate, endDate, processorType) {
    const query = {
      createdAt: { $gte: startDate, $lte: endDate }
    };

    if (processorType !== 'all') {
      query.method = this.mapProcessorTypeToMethod(processorType);
    }

    return await Payment.find(query)
      .populate('booking', 'bookingId service')
      .sort({ createdAt: 1 });
  }

  /**
   * Get processor records for reconciliation period
   * @param {Date} startDate - Start date
   * @param {Date} endDate - End date
   * @param {string} processorType - Processor type
   * @returns {Promise<Array>} Processor records
   */
  static async getProcessorRecords(startDate, endDate, processorType) {
    if (processorType === 'all') {
      // Get records from all enabled processors
      const records = [];
      const enabledProcessors = await processorManager.getEnabledProcessors();
      
      for (const processor of enabledProcessors) {
        try {
          const processorRecords = await processor.getTransactionHistory(startDate, endDate);
          records.push(...processorRecords.map(record => ({
            ...record,
            processorType: processor.name
          })));
        } catch (error) {
          console.error(`Failed to get records from ${processor.name}:`, error);
        }
      }
      
      return records;
    } else {
      // Get records from specific processor
      const processor = await processorManager.getProcessor(processorType);
      if (!processor) {
        throw new Error(`Processor ${processorType} not found or not enabled`);
      }
      
      return await processor.getTransactionHistory(startDate, endDate);
    }
  }

  /**
   * Calculate expected summary from internal payments
   * @param {Array} internalPayments - Internal payment records
   * @returns {Object} Expected summary
   */
  static calculateExpectedSummary(internalPayments) {
    const summary = {
      totalAmount: 0,
      transactionCount: 0,
      byStatus: {},
      byMethod: {}
    };

    for (const payment of internalPayments) {
      if (payment.status === 'paid') {
        summary.totalAmount += payment.amount;
        summary.transactionCount += 1;
      }

      // Group by status
      summary.byStatus[payment.status] = summary.byStatus[payment.status] || { count: 0, amount: 0 };
      summary.byStatus[payment.status].count += 1;
      summary.byStatus[payment.status].amount += payment.amount;

      // Group by method
      summary.byMethod[payment.method] = summary.byMethod[payment.method] || { count: 0, amount: 0 };
      summary.byMethod[payment.method].count += 1;
      summary.byMethod[payment.method].amount += payment.amount;
    }

    return summary;
  }

  /**
   * Calculate actual summary from processor records
   * @param {Array} processorRecords - Processor records
   * @returns {Object} Actual summary
   */
  static calculateActualSummary(processorRecords) {
    const summary = {
      totalAmount: 0,
      transactionCount: 0,
      byStatus: {},
      byProcessor: {}
    };

    for (const record of processorRecords) {
      if (record.status === 'succeeded' || record.status === 'completed') {
        summary.totalAmount += record.amount;
        summary.transactionCount += 1;
      }

      // Group by status
      summary.byStatus[record.status] = summary.byStatus[record.status] || { count: 0, amount: 0 };
      summary.byStatus[record.status].count += 1;
      summary.byStatus[record.status].amount += record.amount;

      // Group by processor
      const processor = record.processorType || 'unknown';
      summary.byProcessor[processor] = summary.byProcessor[processor] || { count: 0, amount: 0 };
      summary.byProcessor[processor].count += 1;
      summary.byProcessor[processor].amount += record.amount;
    }

    return summary;
  }

  /**
   * Detect discrepancies between internal and processor records
   * @param {Array} internalPayments - Internal payment records
   * @param {Array} processorRecords - Processor records
   * @param {Reconciliation} reconciliation - Reconciliation object
   * @returns {Promise<Array>} Discrepancies found
   */
  static async detectDiscrepancies(internalPayments, processorRecords, reconciliation) {
    const discrepancies = [];

    // Create lookup maps
    const internalMap = new Map();
    const processorMap = new Map();

    // Build internal payments map
    for (const payment of internalPayments) {
      const key = payment.transactionId || payment._id.toString();
      internalMap.set(key, payment);
    }

    // Build processor records map
    for (const record of processorRecords) {
      const key = record.transactionId || record.id;
      processorMap.set(key, record);
    }

    // Check for missing payments in processor
    for (const [key, payment] of internalMap) {
      if (payment.status === 'paid' && !processorMap.has(key)) {
        discrepancies.push({
          type: 'missing_payment',
          paymentId: payment._id,
          transactionId: payment.transactionId,
          expectedAmount: payment.amount,
          expectedStatus: payment.status,
          description: `Payment ${payment._id} marked as paid but not found in processor records`,
          severity: 'high'
        });
      }
    }

    // Check for duplicate payments in processor
    for (const [key, record] of processorMap) {
      const internalPayment = internalMap.get(key);
      if (!internalPayment) {
        discrepancies.push({
          type: 'duplicate_payment',
          transactionId: record.transactionId || record.id,
          actualAmount: record.amount,
          actualStatus: record.status,
          description: `Payment found in processor but not in internal records`,
          severity: 'critical'
        });
      } else {
        // Check for amount mismatches
        if (Math.abs(record.amount - internalPayment.amount) > 0.01) {
          discrepancies.push({
            type: 'amount_mismatch',
            paymentId: internalPayment._id,
            transactionId: record.transactionId || record.id,
            expectedAmount: internalPayment.amount,
            actualAmount: record.amount,
            description: `Amount mismatch for payment ${internalPayment._id}`,
            severity: 'high'
          });
        }

        // Check for status mismatches
        const expectedStatus = this.mapInternalStatusToProcessor(internalPayment.status);
        if (record.status !== expectedStatus) {
          discrepancies.push({
            type: 'status_mismatch',
            paymentId: internalPayment._id,
            transactionId: record.transactionId || record.id,
            expectedStatus: expectedStatus,
            actualStatus: record.status,
            description: `Status mismatch for payment ${internalPayment._id}`,
            severity: 'medium'
          });
        }
      }
    }

    return discrepancies;
  }

  /**
   * Map processor type to payment method
   * @param {string} processorType - Processor type
   * @returns {string} Payment method
   */
  static mapProcessorTypeToMethod(processorType) {
    const mapping = {
      'stripe': 'credit_card',
      'paypal': 'paypal',
      'cash': 'cash'
    };
    return mapping[processorType] || processorType;
  }

  /**
   * Map internal status to processor status
   * @param {string} internalStatus - Internal payment status
   * @returns {string} Processor status
   */
  static mapInternalStatusToProcessor(internalStatus) {
    const mapping = {
      'paid': 'succeeded',
      'pending': 'pending',
      'failed': 'failed',
      'refunded': 'refunded'
    };
    return mapping[internalStatus] || internalStatus;
  }

  /**
   * Get reconciliation statistics
   * @param {number} days - Number of days to look back
   * @returns {Promise<Object>} Statistics
   */
  static async getStats(days = 30) {
    try {
      const stats = await Reconciliation.getStats(days);
      return stats;
    } catch (error) {
      console.error('Failed to get reconciliation stats:', error);
      throw error;
    }
  }

  /**
   * Resolve a discrepancy
   * @param {string} reconciliationId - Reconciliation ID
   * @param {number} discrepancyIndex - Discrepancy index
   * @param {string} resolvedBy - User ID who resolved it
   * @param {string} notes - Resolution notes
   * @returns {Promise<Object>} Resolution result
   */
  static async resolveDiscrepancy(reconciliationId, discrepancyIndex, resolvedBy, notes) {
    try {
      const reconciliation = await Reconciliation.findOne({ reconciliationId });
      if (!reconciliation) {
        throw new Error('Reconciliation not found');
      }

      await reconciliation.resolveDiscrepancy(discrepancyIndex, resolvedBy, notes);
      
      return {
        success: true,
        reconciliationId,
        discrepancyIndex,
        resolved: true
      };
    } catch (error) {
      console.error('Failed to resolve discrepancy:', error);
      throw error;
    }
  }

  /**
   * Generate reconciliation report
   * @param {string} reconciliationId - Reconciliation ID
   * @returns {Promise<Object>} Report data
   */
  static async generateReport(reconciliationId) {
    try {
      const reconciliation = await Reconciliation.findOne({ reconciliationId })
        .populate('createdBy', 'firstName lastName email')
        .populate('discrepancies.paymentId', 'amount currency method status')
        .populate('discrepancies.resolvedBy', 'firstName lastName email');

      if (!reconciliation) {
        throw new Error('Reconciliation not found');
      }

      const variance = reconciliation.calculateVariance();
      
      return {
        reconciliation,
        variance,
        summary: {
          period: reconciliation.period,
          processorType: reconciliation.processorType,
          startDate: reconciliation.startDate,
          endDate: reconciliation.endDate,
          expectedAmount: reconciliation.expectedAmount,
          actualAmount: reconciliation.actualAmount,
          expectedTransactions: reconciliation.expectedTransactions,
          actualTransactions: reconciliation.actualTransactions,
          discrepancyCount: reconciliation.discrepancies.length,
          unresolvedDiscrepancies: reconciliation.discrepancies.filter(d => !d.resolved).length
        }
      };
    } catch (error) {
      console.error('Failed to generate reconciliation report:', error);
      throw error;
    }
  }
}

module.exports = ReconciliationService;
