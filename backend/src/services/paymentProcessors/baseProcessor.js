/**
 * Base Payment Processor Class
 * Defines the interface that all payment processors must implement
 */
class BasePaymentProcessor {
  constructor(config = {}) {
    this.config = config;
    this.name = this.constructor.name;
  }

  /**
   * Initialize the processor (called during app startup)
   */
  async initialize() {
    throw new Error('initialize() method must be implemented by subclass');
  }

  /**
   * Create a payment intent/transaction
   * @param {Object} paymentData - Payment information
   * @param {string} paymentData.bookingId - Booking ID
   * @param {number} paymentData.amount - Amount in smallest currency unit
   * @param {string} paymentData.currency - Currency code (e.g., 'ILS', 'USD')
   * @param {string} paymentData.description - Payment description
   * @param {Object} paymentData.metadata - Additional metadata
   * @returns {Object} Payment intent/transaction data
   */
  async createPayment(paymentData) {
    throw new Error('createPayment() method must be implemented by subclass');
  }

  /**
   * Process a payment (for immediate payments like cash)
   * @param {Object} paymentData - Payment information
   * @returns {Object} Payment result
   */
  async processPayment(paymentData) {
    throw new Error('processPayment() method must be implemented by subclass');
  }

  /**
   * Confirm a payment (for pending payments)
   * @param {string} paymentIntentId - Payment intent ID
   * @param {Object} confirmationData - Confirmation data
   * @returns {Object} Confirmation result
   */
  async confirmPayment(paymentIntentId, confirmationData) {
    throw new Error('confirmPayment() method must be implemented by subclass');
  }

  /**
   * Refund a payment
   * @param {string} paymentId - Payment ID
   * @param {number} amount - Amount to refund (optional, full amount if not specified)
   * @param {string} reason - Refund reason
   * @returns {Object} Refund result
   */
  async refundPayment(paymentId, amount = null, reason = '') {
    throw new Error('refundPayment() method must be implemented by subclass');
  }

  /**
   * Get payment status
   * @param {string} paymentId - Payment ID
   * @returns {Object} Payment status information
   */
  async getPaymentStatus(paymentId) {
    throw new Error('getPaymentStatus() method must be implemented by subclass');
  }

  /**
   * Verify webhook signature
   * @param {string} payload - Raw webhook payload
   * @param {string} signature - Webhook signature
   * @param {string} secret - Webhook secret
   * @returns {boolean} True if signature is valid
   */
  async verifyWebhookSignature(payload, signature, secret) {
    throw new Error('verifyWebhookSignature() method must be implemented by subclass');
  }

  /**
   * Process webhook event
   * @param {Object} event - Webhook event data
   * @returns {Object} Processing result
   */
  async processWebhookEvent(event) {
    throw new Error('processWebhookEvent() method must be implemented by subclass');
  }

  /**
   * Get processor capabilities
   * @returns {Object} Capabilities object
   */
  getCapabilities() {
    return {
      supportsImmediatePayment: false,
      supportsPendingPayment: false,
      supportsRefunds: false,
      supportsWebhooks: false,
      supportedCurrencies: [],
      supportedMethods: []
    };
  }

  /**
   * Validate payment data
   * @param {Object} paymentData - Payment data to validate
   * @returns {Object} Validation result { isValid: boolean, errors: Array }
   */
  validatePaymentData(paymentData) {
    const errors = [];
    
    if (!paymentData.amount || paymentData.amount <= 0) {
      errors.push('Invalid amount');
    }
    
    if (!paymentData.currency) {
      errors.push('Currency is required');
    }
    
    if (!paymentData.bookingId) {
      errors.push('Booking ID is required');
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }

  /**
   * Format amount for processor (convert to smallest currency unit)
   * @param {number} amount - Amount in major currency units
   * @param {string} currency - Currency code
   * @returns {number} Amount in smallest currency unit
   */
  formatAmount(amount, currency) {
    // Most processors expect amounts in smallest currency unit (cents, agorot, etc.)
    const multipliers = {
      'ILS': 100, // Shekel to agorot
      'USD': 100, // Dollar to cents
      'EUR': 100, // Euro to cents
      'GBP': 100  // Pound to pence
    };
    
    const multiplier = multipliers[currency] || 100;
    return Math.round(amount * multiplier);
  }

  /**
   * Parse amount from processor (convert from smallest currency unit)
   * @param {number} amount - Amount in smallest currency unit
   * @param {string} currency - Currency code
   * @returns {number} Amount in major currency units
   */
  parseAmount(amount, currency) {
    const multipliers = {
      'ILS': 100,
      'USD': 100,
      'EUR': 100,
      'GBP': 100
    };
    
    const multiplier = multipliers[currency] || 100;
    return amount / multiplier;
  }
}

module.exports = BasePaymentProcessor;
