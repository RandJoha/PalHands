const BasePaymentProcessor = require('./baseProcessor');
const crypto = require('crypto');

/**
 * Cash Payment Processor
 * Handles cash payments with immediate confirmation
 */
class CashPaymentProcessor extends BasePaymentProcessor {
  constructor(config = {}) {
    super(config);
    this.name = 'CashPaymentProcessor';
  }

  /**
   * Initialize the processor
   */
  async initialize() {
    console.log('Cash payment processor initialized');
    return true;
  }

  /**
   * Process cash payment immediately
   * @param {Object} paymentData - Payment information
   * @returns {Object} Payment result
   */
  async processPayment(paymentData) {
    const validation = this.validatePaymentData(paymentData);
    if (!validation.isValid) {
      throw new Error(`Invalid payment data: ${validation.errors.join(', ')}`);
    }

    // Generate a unique transaction ID for cash payments
    const transactionId = this.generateTransactionId();
    
    // Cash payments are immediately successful and marked as paid
    const result = {
      success: true,
      transactionId,
      status: 'paid', // Always paid for cash
      amount: paymentData.amount,
      currency: paymentData.currency,
      method: 'cash',
      processedAt: new Date(),
      metadata: {
        processor: this.name,
        paymentType: 'cash',
        immediateConfirmation: true,
        requiresManualReconciliation: true, // Cash payments need manual reconciliation
        ...paymentData.metadata
      }
    };

    return result;
  }

  /**
   * Create a cash payment (same as process for cash)
   * @param {Object} paymentData - Payment information
   * @returns {Object} Payment result
   */
  async createPayment(paymentData) {
    return this.processPayment(paymentData);
  }

  /**
   * Confirm a cash payment (always successful for cash)
   * @param {string} paymentIntentId - Payment intent ID
   * @param {Object} confirmationData - Confirmation data
   * @returns {Object} Confirmation result
   */
  async confirmPayment(paymentIntentId, confirmationData) {
    return {
      success: true,
      transactionId: paymentIntentId,
      status: 'paid',
      confirmedAt: new Date(),
      metadata: {
        processor: this.name,
        paymentType: 'cash',
        ...confirmationData
      }
    };
  }

  /**
   * Refund a cash payment (manual process)
   * @param {string} paymentId - Payment ID
   * @param {number} amount - Amount to refund
   * @param {string} reason - Refund reason
   * @returns {Object} Refund result
   */
  async refundPayment(paymentId, amount = null, reason = '') {
    // For cash payments, refunds are manual and need admin approval
    const refundId = this.generateTransactionId();
    
    return {
      success: true,
      refundId,
      originalPaymentId: paymentId,
      amount: amount,
      reason,
      status: 'pending_manual_refund',
      processedAt: new Date(),
      metadata: {
        processor: this.name,
        paymentType: 'cash',
        refundType: 'manual',
        requiresAdminApproval: true
      }
    };
  }

  /**
   * Get payment status (always paid for cash)
   * @param {string} paymentId - Payment ID
   * @returns {Object} Payment status information
   */
  async getPaymentStatus(paymentId) {
    return {
      paymentId,
      status: 'paid',
      method: 'cash',
      processor: this.name,
      lastChecked: new Date()
    };
  }

  /**
   * Verify webhook signature (not applicable for cash)
   * @param {string} payload - Raw webhook payload
   * @param {string} signature - Webhook signature
   * @param {string} secret - Webhook secret
   * @returns {boolean} Always false for cash
   */
  async verifyWebhookSignature(payload, signature, secret) {
    // Cash payments don't use webhooks
    return false;
  }

  /**
   * Process webhook event (not applicable for cash)
   * @param {Object} event - Webhook event data
   * @returns {Object} Processing result
   */
  async processWebhookEvent(event) {
    return {
      success: false,
      error: 'Webhooks not supported for cash payments',
      processor: this.name
    };
  }

  /**
   * Get processor capabilities
   * @returns {Object} Capabilities object
   */
  getCapabilities() {
    return {
      supportsImmediatePayment: true,
      supportsPendingPayment: false,
      supportsRefunds: true,
      supportsWebhooks: false,
      supportedCurrencies: ['ILS', 'USD', 'EUR', 'GBP'],
      supportedMethods: ['cash'],
      requiresManualConfirmation: false,
      supportsPartialRefunds: true
    };
  }

  /**
   * Generate a unique transaction ID for cash payments
   * @returns {string} Unique transaction ID
   */
  generateTransactionId() {
    const timestamp = Date.now().toString();
    const random = crypto.randomBytes(8).toString('hex');
    return `CASH_${timestamp}_${random}`.toUpperCase();
  }

  /**
   * Validate cash payment data
   * @param {Object} paymentData - Payment data to validate
   * @returns {Object} Validation result { isValid: boolean, errors: Array }
   */
  validatePaymentData(paymentData) {
    const baseValidation = super.validatePaymentData(paymentData);
    if (!baseValidation.isValid) {
      return baseValidation;
    }

    const errors = [];
    
    // Cash payments require a minimum amount
    if (paymentData.amount < 1) {
      errors.push('Cash payment amount must be at least 1');
    }

    // Cash payments are typically in local currency
    if (paymentData.currency !== 'ILS') {
      errors.push('Cash payments are typically in ILS (Israeli Shekel)');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = CashPaymentProcessor;
