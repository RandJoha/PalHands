const BasePaymentProcessor = require('./baseProcessor');

/**
 * Stripe Payment Processor
 * Handles Stripe payments with webhook support
 */
class StripeProcessor extends BasePaymentProcessor {
  constructor(config = {}) {
    super(config);
    this.name = 'StripeProcessor';
    this.stripe = null;
    this.isInitialized = false;
  }

  /**
   * Initialize the Stripe processor
   */
  async initialize() {
    try {
      // Dynamically import Stripe to avoid dependency issues
      const stripe = require('stripe');
      this.stripe = stripe(this.config.secretKey);
      
      // Test the connection
      await this.stripe.paymentMethods.list({ limit: 1 });
      
      this.isInitialized = true;
      console.log('Stripe payment processor initialized');
      return true;
    } catch (error) {
      console.error('Failed to initialize Stripe processor:', error.message);
      this.isInitialized = false;
      return false;
    }
  }

  /**
   * Create a payment intent
   * @param {Object} paymentData - Payment information
   * @returns {Object} Payment intent data
   */
  async createPayment(paymentData) {
    if (!this.isInitialized) {
      throw new Error('Stripe processor not initialized');
    }

    const validation = this.validatePaymentData(paymentData);
    if (!validation.isValid) {
      throw new Error(`Invalid payment data: ${validation.errors.join(', ')}`);
    }

    try {
      const amount = this.formatAmount(paymentData.amount, paymentData.currency);
      
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount,
        currency: paymentData.currency.toLowerCase(),
        description: paymentData.description || `Booking payment for ${paymentData.bookingId}`,
        metadata: {
          bookingId: paymentData.bookingId,
          processor: this.name,
          ...paymentData.metadata
        },
        automatic_payment_methods: {
          enabled: true,
        },
      });

      return {
        success: true,
        paymentIntentId: paymentIntent.id,
        clientSecret: paymentIntent.client_secret,
        status: paymentIntent.status,
        amount: this.parseAmount(paymentIntent.amount, paymentData.currency),
        currency: paymentData.currency,
        method: 'stripe',
        created: paymentIntent.created,
        metadata: {
          processor: this.name,
          paymentType: 'stripe',
          ...paymentData.metadata
        }
      };
    } catch (error) {
      throw new Error(`Stripe payment creation failed: ${error.message}`);
    }
  }

  /**
   * Confirm a payment intent
   * @param {string} paymentIntentId - Payment intent ID
   * @param {Object} confirmationData - Confirmation data
   * @returns {Object} Confirmation result
   */
  async confirmPayment(paymentIntentId, confirmationData) {
    if (!this.isInitialized) {
      throw new Error('Stripe processor not initialized');
    }

    try {
      const paymentIntent = await this.stripe.paymentIntents.confirm(
        paymentIntentId,
        {
          payment_method: confirmationData.paymentMethodId,
          return_url: confirmationData.returnUrl,
        }
      );

      return {
        success: paymentIntent.status === 'succeeded',
        paymentIntentId: paymentIntent.id,
        status: paymentIntent.status,
        amount: this.parseAmount(paymentIntent.amount, paymentIntent.currency),
        currency: paymentIntent.currency.toUpperCase(),
        method: 'stripe',
        confirmedAt: new Date(),
        metadata: {
          processor: this.name,
          paymentType: 'stripe',
          ...confirmationData.metadata
        }
      };
    } catch (error) {
      throw new Error(`Stripe payment confirmation failed: ${error.message}`);
    }
  }

  /**
   * Process payment (not applicable for Stripe - use createPayment instead)
   * @param {Object} paymentData - Payment information
   * @returns {Object} Payment result
   */
  async processPayment(paymentData) {
    throw new Error('Stripe does not support immediate payments. Use createPayment() to create a payment intent.');
  }

  /**
   * Refund a payment
   * @param {string} paymentId - Payment intent ID
   * @param {number} amount - Amount to refund (optional)
   * @param {string} reason - Refund reason
   * @returns {Object} Refund result
   */
  async refundPayment(paymentId, amount = null, reason = '') {
    if (!this.isInitialized) {
      throw new Error('Stripe processor not initialized');
    }

    try {
      const refundData = {
        payment_intent: paymentId,
        reason: reason || 'requested_by_customer'
      };

      if (amount) {
        refundData.amount = this.formatAmount(amount, 'ILS'); // Assuming ILS for now
      }

      const refund = await this.stripe.refunds.create(refundData);

      return {
        success: true,
        refundId: refund.id,
        originalPaymentId: paymentId,
        amount: this.parseAmount(refund.amount, refund.currency),
        currency: refund.currency.toUpperCase(),
        status: refund.status,
        reason: refund.reason,
        processedAt: new Date(),
        metadata: {
          processor: this.name,
          paymentType: 'stripe',
          refundType: 'stripe'
        }
      };
    } catch (error) {
      throw new Error(`Stripe refund failed: ${error.message}`);
    }
  }

  /**
   * Get payment status
   * @param {string} paymentId - Payment intent ID
   * @returns {Object} Payment status information
   */
  async getPaymentStatus(paymentId) {
    if (!this.isInitialized) {
      throw new Error('Stripe processor not initialized');
    }

    try {
      const paymentIntent = await this.stripe.paymentIntents.retrieve(paymentId);
      
      return {
        paymentId: paymentIntent.id,
        status: paymentIntent.status,
        amount: this.parseAmount(paymentIntent.amount, paymentIntent.currency),
        currency: paymentIntent.currency.toUpperCase(),
        method: 'stripe',
        processor: this.name,
        lastChecked: new Date(),
        metadata: paymentIntent.metadata
      };
    } catch (error) {
      throw new Error(`Failed to get Stripe payment status: ${error.message}`);
    }
  }

  /**
   * Verify webhook signature
   * @param {string} payload - Raw webhook payload
   * @param {string} signature - Webhook signature
   * @param {string} secret - Webhook secret
   * @returns {boolean} True if signature is valid
   */
  async verifyWebhookSignature(payload, signature, secret) {
    try {
      const event = this.stripe.webhooks.constructEvent(payload, signature, secret);
      return !!event;
    } catch (error) {
      console.error('Webhook signature verification failed:', error.message);
      return false;
    }
  }

  /**
   * Process webhook event
   * @param {Object} event - Webhook event data
   * @returns {Object} Processing result
   */
  async processWebhookEvent(event) {
    try {
      switch (event.type) {
        case 'payment_intent.succeeded':
          return this.handlePaymentSucceeded(event.data.object);
        case 'payment_intent.payment_failed':
          return this.handlePaymentFailed(event.data.object);
        case 'charge.refunded':
          return this.handleRefundProcessed(event.data.object);
        default:
          return {
            success: true,
            event: event.type,
            message: 'Event processed but no specific handler'
          };
      }
    } catch (error) {
      return {
        success: false,
        error: error.message,
        event: event.type
      };
    }
  }

  /**
   * Handle payment succeeded event
   * @param {Object} paymentIntent - Payment intent object
   * @returns {Object} Processing result
   */
  async handlePaymentSucceeded(paymentIntent) {
    return {
      success: true,
      event: 'payment_intent.succeeded',
      paymentId: paymentIntent.id,
      status: 'paid',
      amount: this.parseAmount(paymentIntent.amount, paymentIntent.currency),
      currency: paymentIntent.currency.toUpperCase(),
      metadata: paymentIntent.metadata
    };
  }

  /**
   * Handle payment failed event
   * @param {Object} paymentIntent - Payment intent object
   * @returns {Object} Processing result
   */
  async handlePaymentFailed(paymentIntent) {
    return {
      success: false,
      event: 'payment_intent.payment_failed',
      paymentId: paymentIntent.id,
      status: 'failed',
      error: paymentIntent.last_payment_error?.message || 'Payment failed',
      metadata: paymentIntent.metadata
    };
  }

  /**
   * Handle refund processed event
   * @param {Object} charge - Charge object
   * @returns {Object} Processing result
   */
  async handleRefundProcessed(charge) {
    return {
      success: true,
      event: 'charge.refunded',
      paymentId: charge.payment_intent,
      refundId: charge.refunds?.data[0]?.id,
      status: 'refunded',
      amount: this.parseAmount(charge.amount_refunded, charge.currency),
      currency: charge.currency.toUpperCase(),
      metadata: charge.metadata
    };
  }

  /**
   * Get processor capabilities
   * @returns {Object} Capabilities object
   */
  getCapabilities() {
    return {
      supportsImmediatePayment: false,
      supportsPendingPayment: true,
      supportsRefunds: true,
      supportsWebhooks: true,
      supportedCurrencies: ['ILS', 'USD', 'EUR', 'GBP'],
      supportedMethods: ['credit_card', 'debit_card'],
      requiresManualConfirmation: true,
      supportsPartialRefunds: true
    };
  }

  /**
   * Validate Stripe payment data
   * @param {Object} paymentData - Payment data to validate
   * @returns {Object} Validation result { isValid: boolean, errors: Array }
   */
  validatePaymentData(paymentData) {
    const baseValidation = super.validatePaymentData(paymentData);
    if (!baseValidation.isValid) {
      return baseValidation;
    }

    const errors = [];
    
    // Stripe requires minimum amounts
    const minAmounts = {
      'ILS': 50, // 50 agorot
      'USD': 50, // 50 cents
      'EUR': 50, // 50 cents
      'GBP': 50  // 50 pence
    };
    
    const minAmount = minAmounts[paymentData.currency] || 50;
    if (paymentData.amount < minAmount) {
      errors.push(`Minimum amount for ${paymentData.currency} is ${minAmount}`);
    }

    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

module.exports = StripeProcessor;
