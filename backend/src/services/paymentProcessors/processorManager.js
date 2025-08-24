const CashPaymentProcessor = require('./cashProcessor');
const StripeProcessor = require('./stripeProcessor');

/**
 * Payment Processor Manager
 * Manages multiple payment processors and routes requests appropriately
 */
class PaymentProcessorManager {
  constructor() {
    this.processors = new Map();
    this.isInitialized = false;
  }

  /**
   * Initialize all enabled payment processors
   */
  async initialize() {
    try {
      console.log('Initializing payment processors...');
      
      // Initialize Cash Processor (always enabled unless explicitly disabled)
      if (process.env.PAYMENT_CASH_ENABLED !== 'false') {
        const cashProcessor = new CashPaymentProcessor();
        await cashProcessor.initialize();
        this.processors.set('cash', cashProcessor);
        console.log('✅ Cash payment processor initialized');
      } else {
        console.log('⚠️ Cash payment processor disabled via feature flag');
      }

      // Initialize Stripe Processor (if enabled via feature flag)
      if (process.env.PAYMENT_STRIPE_ENABLED === 'true') {
        const stripeConfig = {
          secretKey: process.env.STRIPE_SECRET_KEY,
          publishableKey: process.env.STRIPE_PUBLISHABLE_KEY
        };
        
        if (!stripeConfig.secretKey) {
          console.warn('⚠️ Stripe enabled but STRIPE_SECRET_KEY not provided');
        } else {
          const stripeProcessor = new StripeProcessor(stripeConfig);
          const initialized = await stripeProcessor.initialize();
          if (initialized) {
            this.processors.set('stripe', stripeProcessor);
            console.log('✅ Stripe payment processor initialized');
          } else {
            console.warn('⚠️ Stripe processor initialization failed');
          }
        }
      } else {
        console.log('⚠️ Stripe payment processor disabled via feature flag');
      }

      // Initialize PayPal Processor (if enabled via feature flag)
      if (process.env.PAYMENT_PAYPAL_ENABLED === 'true') {
        console.log('⚠️ PayPal processor not yet implemented');
        // TODO: Implement PayPal processor
      } else {
        console.log('⚠️ PayPal payment processor disabled via feature flag');
      }

      this.isInitialized = true;
      console.log(`Payment processor manager initialized with ${this.processors.size} processors`);
      
      // Log feature flag status
      this.logFeatureFlagStatus();
      
      return true;
    } catch (error) {
      console.error('Failed to initialize payment processors:', error);
      this.isInitialized = false;
      return false;
    }
  }

  /**
   * Get a specific processor by method
   * @param {string} method - Payment method
   * @returns {BasePaymentProcessor} Payment processor instance
   */
  getProcessor(method) {
    if (!this.isInitialized) {
      throw new Error('Payment processor manager not initialized');
    }

    const processor = this.processors.get(method);
    if (!processor) {
      throw new Error(`Payment processor for method '${method}' not found or not enabled`);
    }

    return processor;
  }

  /**
   * Get all available payment methods
   * @returns {Array} Array of available payment methods
   */
  getAvailableMethods() {
    if (!this.isInitialized) {
      return [];
    }

    const methods = [];
    for (const [method, processor] of this.processors) {
      const capabilities = processor.getCapabilities();
      methods.push({
        method,
        name: this.getMethodDisplayName(method),
        capabilities,
        supportedCurrencies: capabilities.supportedCurrencies,
        supportedMethods: capabilities.supportedMethods
      });
    }

    return methods;
  }

  /**
   * Get all enabled processors
   * @returns {Array} Array of enabled processor instances
   */
  getEnabledProcessors() {
    if (!this.isInitialized) {
      return [];
    }

    const enabledProcessors = [];
    for (const [method, processor] of this.processors) {
      enabledProcessors.push(processor);
    }

    return enabledProcessors;
  }

  /**
   * Get method display name
   * @param {string} method - Payment method
   * @returns {string} Display name
   */
  getMethodDisplayName(method) {
    const names = {
      'cash': 'Cash Payment',
      'stripe': 'Credit/Debit Card',
      'paypal': 'PayPal',
      'bank_transfer': 'Bank Transfer'
    };
    return names[method] || method;
  }

  /**
   * Check if a payment method is supported
   * @param {string} method - Payment method
   * @returns {boolean} True if supported
   */
  isMethodSupported(method) {
    return this.processors.has(method);
  }

  /**
   * Get processor capabilities for a method
   * @param {string} method - Payment method
   * @returns {Object} Capabilities object
   */
  getMethodCapabilities(method) {
    const processor = this.getProcessor(method);
    return processor.getCapabilities();
  }

  /**
   * Create a payment using the appropriate processor
   * @param {string} method - Payment method
   * @param {Object} paymentData - Payment data
   * @returns {Object} Payment result
   */
  async createPayment(method, paymentData) {
    const processor = this.getProcessor(method);
    return await processor.createPayment(paymentData);
  }

  /**
   * Process a payment using the appropriate processor
   * @param {string} method - Payment method
   * @param {Object} paymentData - Payment data
   * @returns {Object} Payment result
   */
  async processPayment(method, paymentData) {
    const processor = this.getProcessor(method);
    return await processor.processPayment(paymentData);
  }

  /**
   * Confirm a payment using the appropriate processor
   * @param {string} method - Payment method
   * @param {string} paymentIntentId - Payment intent ID
   * @param {Object} confirmationData - Confirmation data
   * @returns {Object} Confirmation result
   */
  async confirmPayment(method, paymentIntentId, confirmationData) {
    const processor = this.getProcessor(method);
    return await processor.confirmPayment(paymentIntentId, confirmationData);
  }

  /**
   * Refund a payment using the appropriate processor
   * @param {string} method - Payment method
   * @param {string} paymentId - Payment ID
   * @param {number} amount - Amount to refund
   * @param {string} reason - Refund reason
   * @returns {Object} Refund result
   */
  async refundPayment(method, paymentId, amount = null, reason = '') {
    const processor = this.getProcessor(method);
    return await processor.refundPayment(paymentId, amount, reason);
  }

  /**
   * Get payment status using the appropriate processor
   * @param {string} method - Payment method
   * @param {string} paymentId - Payment ID
   * @returns {Object} Payment status
   */
  async getPaymentStatus(method, paymentId) {
    const processor = this.getProcessor(method);
    return await processor.getPaymentStatus(paymentId);
  }

  /**
   * Verify webhook signature using the appropriate processor
   * @param {string} method - Payment method
   * @param {string} payload - Raw webhook payload
   * @param {string} signature - Webhook signature
   * @param {string} secret - Webhook secret
   * @returns {boolean} True if signature is valid
   */
  async verifyWebhookSignature(method, payload, signature, secret) {
    const processor = this.getProcessor(method);
    return await processor.verifyWebhookSignature(payload, signature, secret);
  }

  /**
   * Process webhook event using the appropriate processor
   * @param {string} method - Payment method
   * @param {Object} event - Webhook event data
   * @returns {Object} Processing result
   */
  async processWebhookEvent(method, event) {
    const processor = this.getProcessor(method);
    return await processor.processWebhookEvent(event);
  }

  /**
   * Log feature flag status for all payment processors
   */
  logFeatureFlagStatus() {
    console.log('📋 Payment Processor Feature Flags Status:');
    console.log(`   Cash: ${process.env.PAYMENT_CASH_ENABLED !== 'false' ? '✅ Enabled' : '❌ Disabled'}`);
    console.log(`   Stripe: ${process.env.PAYMENT_STRIPE_ENABLED === 'true' ? '✅ Enabled' : '❌ Disabled'}`);
    console.log(`   PayPal: ${process.env.PAYMENT_PAYPAL_ENABLED === 'true' ? '✅ Enabled' : '❌ Disabled'}`);
    console.log(`   Audit: ${process.env.PAYMENT_AUDIT_ENABLED === 'true' ? '✅ Enabled' : '❌ Disabled'}`);
  }

  /**
   * Get health status of all processors
   * @returns {Object} Health status object
   */
  getHealthStatus() {
    const status = {
      initialized: this.isInitialized,
      processors: {},
      totalProcessors: this.processors.size,
      featureFlags: {
        cash: process.env.PAYMENT_CASH_ENABLED !== 'false',
        stripe: process.env.PAYMENT_STRIPE_ENABLED === 'true',
        paypal: process.env.PAYMENT_PAYPAL_ENABLED === 'true',
        audit: process.env.PAYMENT_AUDIT_ENABLED === 'true'
      }
    };

    for (const [method, processor] of this.processors) {
      status.processors[method] = {
        name: processor.name,
        initialized: processor.isInitialized !== undefined ? processor.isInitialized : true,
        capabilities: processor.getCapabilities()
      };
    }

    return status;
  }
}

// Create singleton instance
const processorManager = new PaymentProcessorManager();

module.exports = processorManager;
