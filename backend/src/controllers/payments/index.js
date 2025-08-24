const Payment = require('../../models/Payment');
const Booking = require('../../models/Booking');
const { ok, created, error } = require('../../utils/response');
const realtime = require('../../services/realtime');
const PaymentAuditService = require('../../services/paymentAudit');
const processorManager = require('../../services/paymentProcessors/processorManager');
const WebhookAuthMiddleware = require('../../middleware/webhookAuth');
const OutboxService = require('../../services/outbox');

// POST /api/payments
async function createPayment(req, res) {
  try {
    const { bookingId, method = 'cash', notes } = req.body;
    const actor = req.user;

    const booking = await Booking.findById(bookingId).populate('client');
    if (!booking) return error(res, 404, 'Booking not found');
    const isOwner = booking.client.toString() === actor._id.toString();
    if (!(actor.role === 'admin' || isOwner)) return error(res, 403, 'Not allowed to create payment for this booking');

    // Check if payment method is supported
    if (!processorManager.isMethodSupported(method)) {
      return error(res, 400, `Payment method '${method}' is not supported`);
    }

    const exists = await Payment.findOne({ booking: booking._id });
    if (exists) return ok(res, exists, 'Payment already exists');

    // Create payment record
    const payment = await Payment.create({
      booking: booking._id,
      amount: booking.pricing.totalAmount,
      currency: booking.pricing.currency || 'ILS',
      method,
      status: 'pending'
    });

    // Process payment using the appropriate processor
    const paymentData = {
      bookingId: booking._id.toString(),
      amount: payment.amount,
      currency: payment.currency,
      description: `Booking payment for ${booking.bookingId}`,
      metadata: {
        bookingId: booking._id.toString(),
        clientId: actor._id.toString(),
        notes
      }
    };

    let processorResult;
    try {
      if (method === 'cash') {
        // For cash payments, process immediately and mark as paid
        processorResult = await processorManager.processPayment(method, paymentData);
        
        // Ensure cash payments are marked as paid
        if (processorResult.success) {
          processorResult.status = 'paid';
        }
      } else {
        // For other methods, create payment intent
        processorResult = await processorManager.createPayment(method, paymentData);
      }
    } catch (processorError) {
      // If processor fails, update payment status to failed
      payment.status = 'failed';
      payment.metadata = { error: processorError.message };
      await payment.save();
      
      return error(res, 400, `Payment processing failed: ${processorError.message}`);
    }

    // Update payment with processor result
    payment.status = processorResult.status;
    payment.transactionId = processorResult.transactionId || processorResult.paymentIntentId;
    payment.metadata = { ...payment.metadata, ...processorResult.metadata };
    await payment.save();

    // Mirror to booking
    booking.payment = booking.payment || {};
    booking.payment.method = method;
    booking.payment.status = payment.status;
    if (payment.status === 'paid') {
      booking.payment.paidAt = new Date();
      if (booking.status === 'pending') {
        booking.status = 'confirmed';
      }
    }
    await booking.save();

    // Log payment creation
    await PaymentAuditService.logAction({
      payment,
      booking,
      actor,
      actorType: actor.role,
      action: 'created',
      oldStatus: null,
      newStatus: payment.status,
      amount: payment.amount,
      currency: payment.currency,
      method: payment.method,
      notes,
      ipAddress: req.ip,
      userAgent: req.get('User-Agent')
    });

    // Add to outbox for reliable delivery
    await OutboxService.addMessage({
      type: 'payment_status_change',
      payload: {
        paymentId: payment._id.toString(),
        oldStatus: null,
        newStatus: payment.status,
        notificationData: {
          booking: booking._id.toString(),
          method: payment.method,
          amount: payment.amount,
          currency: payment.currency
        }
      },
      destination: 'payment_notifications',
      correlationId: payment._id.toString(),
      priority: payment.status === 'paid' ? 'high' : 'normal'
    });

    // Emit real-time update
    realtime.emit('payment:created', {
      id: payment._id.toString(),
      booking: booking._id.toString(),
      status: payment.status,
      method: payment.method
    });

    return created(res, {
      payment,
      processorResult: method === 'cash' ? null : processorResult // Don't expose client secret for cash
    }, 'Payment created successfully');
  } catch (e) {
    console.error('createPayment error', e);
    return error(res, 400, e.message || 'Failed to create payment');
  }
}

// PUT /api/payments/:id/status
async function updatePaymentStatus(req, res) {
  try {
    const { id } = req.params;
    const { status, transactionId, notes } = req.body;
    const actor = req.user;

    const payment = await Payment.findById(id).populate('booking');
    if (!payment) return error(res, 404, 'Payment not found');

    // Only admin for now
    if (actor.role !== 'admin') return error(res, 403, 'Only admin can update payment status');

    const oldStatus = payment.status;
    payment.status = status;
    if (transactionId) payment.transactionId = transactionId;
    await payment.save();

    // Mirror to booking
    const booking = await Booking.findById(payment.booking);
    if (booking) {
      booking.payment = booking.payment || {};
      booking.payment.status = status;
      if (status === 'paid') {
        booking.payment.paidAt = new Date();
        // Update booking status to confirmed when payment is completed
        if (booking.status === 'pending') {
          booking.status = 'confirmed';
        }
      }
      await booking.save();
    }

    // Log payment status update
    await PaymentAuditService.logAction({
      payment,
      booking: payment.booking,
      actor,
      actorType: actor.role,
      action: 'status_updated',
      oldStatus,
      newStatus: status,
      amount: payment.amount,
      currency: payment.currency,
      method: payment.method,
      transactionId,
      notes,
      ipAddress: req.ip,
      userAgent: req.get('User-Agent')
    });

    // Add to outbox for reliable delivery
    await OutboxService.addMessage({
      type: 'payment_status_change',
      payload: {
        paymentId: payment._id.toString(),
        oldStatus: oldStatus,
        newStatus: status,
        notificationData: {
          booking: payment.booking?._id.toString(),
          method: payment.method,
          amount: payment.amount,
          currency: payment.currency
        }
      },
      destination: 'payment_notifications',
      correlationId: payment._id.toString(),
      priority: status === 'paid' ? 'high' : 'normal'
    });

    realtime.emit('payment:status', { 
      id: payment._id.toString(), 
      booking: payment.booking.toString(), 
      status: payment.status 
    });

    return ok(res, payment, 'Payment status updated');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to update payment status');
  }
}

// POST /api/payments/webhook
async function webhook(req, res) {
  try {
    const { processorType } = req.params;
    const event = req.body;
    
    if (!req.webhookData || !req.webhookData.verified) {
      return res.status(401).json({ error: 'Webhook not verified' });
    }

    console.log(`Processing ${processorType} webhook:`, event.type);

    // Process webhook event using the appropriate processor
    const result = await processorManager.processWebhookEvent(processorType, event);

    // Log webhook processing
    await WebhookAuthMiddleware.logWebhookProcessing(processorType, event, result);

    // Handle payment status updates based on webhook result
    if (result.success && result.paymentId) {
      try {
        const payment = await Payment.findOne({ 
          transactionId: result.paymentId 
        }).populate('booking');

        if (payment) {
          const oldStatus = payment.status;
          payment.status = result.status;
          payment.metadata = { 
            ...payment.metadata, 
            webhookEvent: event.type,
            webhookProcessedAt: new Date()
          };
          await payment.save();

          // Update booking status if payment is completed
          if (result.status === 'paid' && payment.booking) {
            payment.booking.payment = payment.booking.payment || {};
            payment.booking.payment.status = 'paid';
            payment.booking.payment.paidAt = new Date();
            if (payment.booking.status === 'pending') {
              payment.booking.status = 'confirmed';
            }
            await payment.booking.save();
          }

          // Log payment status update
          await PaymentAuditService.logAction({
            payment,
            booking: payment.booking,
            actor: { _id: 'system', role: 'system' }, // System actor for webhook updates
            actorType: 'system',
            action: 'status_updated',
            oldStatus,
            newStatus: result.status,
            amount: payment.amount,
            currency: payment.currency,
            method: payment.method,
            notes: `Webhook update: ${event.type}`,
            metadata: {
              webhookEvent: event.type,
              processorType
            }
          });

          // Emit real-time update
          realtime.emit('payment:webhook_update', {
            id: payment._id.toString(),
            booking: payment.booking?._id.toString(),
            status: result.status,
            method: payment.method,
            event: event.type
          });
        }
      } catch (paymentError) {
        console.error('Failed to update payment from webhook:', paymentError);
        // Don't fail the webhook if payment update fails
      }
    }

    // Return success to webhook provider
    return res.status(200).json({ 
      received: true, 
      processed: result.success,
      event: event.type 
    });
  } catch (error) {
    console.error('Webhook processing error:', error);
    
    // Log failed webhook processing
    if (req.webhookData) {
      await WebhookAuthMiddleware.logWebhookProcessing(
        req.webhookData.processorType, 
        req.body, 
        { success: false, error: error.message }
      );
    }

    // Return 200 to webhook provider to prevent retries
    return res.status(200).json({ 
      received: true, 
      processed: false,
      error: error.message 
    });
  }
}

// GET /api/payments/methods
async function getPaymentMethods(req, res) {
  try {
    const methods = processorManager.getAvailableMethods();
    return ok(res, methods, 'Available payment methods retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get payment methods');
  }
}

// POST /api/payments/:id/confirm
async function confirmPayment(req, res) {
  try {
    const { id } = req.params;
    const { paymentMethodId, returnUrl } = req.body;
    const actor = req.user;

    const payment = await Payment.findById(id).populate('booking');
    if (!payment) return error(res, 404, 'Payment not found');

    // Check permissions
    const isOwner = payment.booking.client.toString() === actor._id.toString();
    if (!(actor.role === 'admin' || isOwner)) {
      return error(res, 403, 'Not authorized to confirm this payment');
    }

    // Check if payment method is supported
    if (!processorManager.isMethodSupported(payment.method)) {
      return error(res, 400, `Payment method '${payment.method}' is not supported`);
    }

    // Confirm payment using processor
    const confirmationData = {
      paymentMethodId,
      returnUrl,
      metadata: {
        confirmedBy: actor._id.toString(),
        confirmedAt: new Date().toISOString()
      }
    };

    const result = await processorManager.confirmPayment(
      payment.method,
      payment.transactionId,
      confirmationData
    );

    if (result.success) {
      // Update payment status
      const oldStatus = payment.status;
      payment.status = result.status;
      payment.metadata = { ...payment.metadata, ...result.metadata };
      await payment.save();

      // Update booking status
      if (result.status === 'paid') {
        payment.booking.payment = payment.booking.payment || {};
        payment.booking.payment.status = 'paid';
        payment.booking.payment.paidAt = new Date();
        if (payment.booking.status === 'pending') {
          payment.booking.status = 'confirmed';
        }
        await payment.booking.save();
      }

      // Log payment confirmation
      await PaymentAuditService.logAction({
        payment,
        booking: payment.booking,
        actor,
        actorType: actor.role,
        action: 'status_updated',
        oldStatus,
        newStatus: result.status,
        amount: payment.amount,
        currency: payment.currency,
        method: payment.method,
        notes: 'Payment confirmed',
        ipAddress: req.ip,
        userAgent: req.get('User-Agent')
      });

      // Emit real-time update
      realtime.emit('payment:confirmed', {
        id: payment._id.toString(),
        booking: payment.booking._id.toString(),
        status: result.status,
        method: payment.method
      });
    }

    return ok(res, { payment, result }, 'Payment confirmation processed');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to confirm payment');
  }
}

// GET /api/payments/webhook/stats
async function getWebhookStats(req, res) {
  try {
    const { processorType, days = 7 } = req.query;
    const actor = req.user;

    // Only admin can view webhook stats
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view webhook statistics');
    }

    const stats = await WebhookAuthMiddleware.getWebhookStats(processorType, { days: parseInt(days) });
    return ok(res, stats, 'Webhook statistics retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get webhook statistics');
  }
}

// POST /api/payments/:id/refund
async function refundPayment(req, res) {
  try {
    const { id } = req.params;
    const { amount, reason } = req.body;
    const actor = req.user;

    const payment = await Payment.findById(id).populate('booking');
    if (!payment) return error(res, 404, 'Payment not found');

    // Only admin can refund payments
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can refund payments');
    }

    // Check if payment method supports refunds
    const capabilities = processorManager.getMethodCapabilities(payment.method);
    if (!capabilities.supportsRefunds) {
      return error(res, 400, `Payment method '${payment.method}' does not support refunds`);
    }

    // Process refund using processor
    const result = await processorManager.refundPayment(
      payment.method,
      payment.transactionId,
      amount,
      reason
    );

    if (result.success) {
      // Update payment status
      payment.status = 'refunded';
      payment.metadata = { ...payment.metadata, refund: result };
      await payment.save();

      // Log refund
      await PaymentAuditService.logAction({
        payment,
        booking: payment.booking,
        actor,
        actorType: actor.role,
        action: 'refunded',
        oldStatus: 'paid',
        newStatus: 'refunded',
        amount: payment.amount,
        currency: payment.currency,
        method: payment.method,
        notes: `Refund: ${reason}`,
        ipAddress: req.ip,
        userAgent: req.get('User-Agent')
      });

      // Emit real-time update
      realtime.emit('payment:refunded', {
        id: payment._id.toString(),
        booking: payment.booking._id.toString(),
        amount: result.amount,
        reason
      });
    }

    return ok(res, { payment, result }, 'Payment refund processed');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to refund payment');
  }
}

// POST /api/payments/cash/minimal
async function createMinimalCashPayment(req, res) {
  try {
    const { bookingId, notes } = req.body;
    const actor = req.user;

    const booking = await Booking.findById(bookingId).populate('client');
    if (!booking) return error(res, 404, 'Booking not found');
    
    // Only admin can create minimal cash payments
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can create minimal cash payments');
    }

    // Check if payment already exists
    const existingPayment = await Payment.findOne({ booking: booking._id });
    if (existingPayment) {
      return error(res, 400, 'Payment already exists for this booking');
    }

    // Create minimal cash payment
    const payment = await Payment.create({
      booking: booking._id,
      amount: booking.pricing.totalAmount,
      currency: booking.pricing.currency || 'ILS',
      method: 'cash',
      status: 'paid', // Immediately marked as paid
      transactionId: `CASH_MIN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      metadata: {
        paymentType: 'minimal_cash',
        createdBy: actor._id.toString(),
        notes,
        immediateConfirmation: true,
        requiresManualReconciliation: true
      }
    });

    // Update booking payment status
    booking.payment = booking.payment || {};
    booking.payment.method = 'cash';
    booking.payment.status = 'paid';
    booking.payment.paidAt = new Date();
    if (booking.status === 'pending') {
      booking.status = 'confirmed';
    }
    await booking.save();

    // Log payment creation with audit trail
    await PaymentAuditService.logAction({
      payment,
      booking,
      actor,
      actorType: actor.role,
      action: 'created_minimal_cash',
      oldStatus: null,
      newStatus: 'paid',
      amount: payment.amount,
      currency: payment.currency,
      method: payment.method,
      notes: `Minimal cash payment: ${notes}`,
      ipAddress: req.ip,
      userAgent: req.get('User-Agent')
    });

    // Add to outbox for reliable delivery
    await OutboxService.addMessage({
      type: 'payment_status_change',
      payload: {
        paymentId: payment._id.toString(),
        oldStatus: null,
        newStatus: 'paid',
        notificationData: {
          booking: booking._id.toString(),
          method: payment.method,
          amount: payment.amount,
          currency: payment.currency,
          paymentType: 'minimal_cash'
        }
      },
      destination: 'payment_notifications',
      correlationId: payment._id.toString(),
      priority: 'high'
    });

    // Emit real-time update
    realtime.emit('payment:minimal_cash_created', {
      id: payment._id.toString(),
      booking: booking._id.toString(),
      status: payment.status,
      method: payment.method,
      amount: payment.amount
    });

    return created(res, payment, 'Minimal cash payment created successfully');
  } catch (e) {
    console.error('createMinimalCashPayment error', e);
    return error(res, 400, e.message || 'Failed to create minimal cash payment');
  }
}

// GET /api/payments/:id/audit
async function getPaymentAudit(req, res) {
  try {
    const { id } = req.params;
    const { limit = 50, skip = 0 } = req.query;
    const actor = req.user;

    const payment = await Payment.findById(id);
    if (!payment) return error(res, 404, 'Payment not found');

    // Check permissions
    const booking = await Booking.findById(payment.booking);
    if (!booking) return error(res, 404, 'Booking not found');
    
    const isOwner = booking.client.toString() === actor._id.toString();
    const isProvider = booking.provider.toString() === actor._id.toString();
    if (!(actor.role === 'admin' || isOwner || isProvider)) {
      return error(res, 403, 'Not authorized to view payment audit');
    }

    const auditTrail = await PaymentAuditService.getAuditTrail(id, {
      limit: parseInt(limit),
      skip: parseInt(skip)
    });

    return ok(res, auditTrail, 'Payment audit trail retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get payment audit');
  }
}

// GET /api/payments/audit/booking/:bookingId
async function getBookingPaymentAudit(req, res) {
  try {
    const { bookingId } = req.params;
    const { limit = 50, skip = 0 } = req.query;
    const actor = req.user;

    const booking = await Booking.findById(bookingId);
    if (!booking) return error(res, 404, 'Booking not found');
    
    const isOwner = booking.client.toString() === actor._id.toString();
    const isProvider = booking.provider.toString() === actor._id.toString();
    if (!(actor.role === 'admin' || isOwner || isProvider)) {
      return error(res, 403, 'Not authorized to view booking payment audit');
    }

    const auditTrail = await PaymentAuditService.getBookingAuditTrail(bookingId, {
      limit: parseInt(limit),
      skip: parseInt(skip)
    });

    return ok(res, auditTrail, 'Booking payment audit trail retrieved');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to get booking payment audit');
  }
}

// GET /api/payments/health
async function getPaymentHealth(req, res) {
  try {
    const actor = req.user;

    // Only admin can view payment health
    if (actor.role !== 'admin') {
      return error(res, 403, 'Only admin can view payment health status');
    }

    // Get processor manager health
    const processorHealth = processorManager.getHealthStatus();

    // Get outbox scheduler status
    const outboxScheduler = require('../../services/outboxScheduler');
    const outboxStatus = outboxScheduler.getStatus();

    // Get reconciliation scheduler status
    const reconciliationScheduler = require('../../services/reconciliationScheduler');
    const reconciliationStatus = reconciliationScheduler.getStatus();

    // Get outbox statistics
    const outboxStats = await OutboxService.getStats(7);

    // Get reconciliation statistics
    const reconciliationStats = await require('../../services/reconciliation').getStats(7);

    // Get webhook statistics
    const webhookStats = await WebhookAuthMiddleware.getWebhookStats(null, { days: 7 });

    const healthStatus = {
      timestamp: new Date().toISOString(),
      overall: {
        status: 'healthy',
        message: 'Payment system is operational'
      },
      processors: {
        status: processorHealth.initialized ? 'healthy' : 'unhealthy',
        details: processorHealth,
        message: processorHealth.initialized 
          ? `${processorHealth.totalProcessors} processors initialized` 
          : 'Processor manager not initialized'
      },
      featureFlags: {
        status: 'info',
        details: processorHealth.featureFlags,
        message: 'Feature flags status'
      },
      outbox: {
        status: outboxStatus.isRunning ? 'healthy' : 'unhealthy',
        details: outboxStatus,
        stats: outboxStats,
        message: outboxStatus.isRunning 
          ? 'Outbox scheduler is running' 
          : 'Outbox scheduler is not running'
      },
      reconciliation: {
        status: reconciliationStatus.isRunning ? 'healthy' : 'unhealthy',
        details: reconciliationStatus,
        stats: reconciliationStats,
        message: reconciliationStatus.isRunning 
          ? 'Reconciliation scheduler is running' 
          : 'Reconciliation scheduler is not running'
      },
      webhooks: {
        status: 'info',
        details: webhookStats,
        message: 'Webhook processing statistics'
      },
      environment: {
        nodeEnv: process.env.NODE_ENV || 'development',
        paymentCashEnabled: process.env.PAYMENT_CASH_ENABLED !== 'false',
        paymentStripeEnabled: process.env.PAYMENT_STRIPE_ENABLED === 'true',
        paymentPaypalEnabled: process.env.PAYMENT_PAYPAL_ENABLED === 'true',
        paymentAuditEnabled: process.env.PAYMENT_AUDIT_ENABLED === 'true',
        webhookReplayProtection: process.env.WEBHOOK_REPLAY_PROTECTION_ENABLED === 'true'
      }
    };

    // Determine overall status
    const hasUnhealthyComponents = [
      healthStatus.processors.status,
      healthStatus.outbox.status,
      healthStatus.reconciliation.status
    ].some(status => status === 'unhealthy');

    if (hasUnhealthyComponents) {
      healthStatus.overall.status = 'degraded';
      healthStatus.overall.message = 'Payment system has some issues';
    }

    return ok(res, healthStatus, 'Payment health status retrieved');
  } catch (e) {
    return error(res, 500, e.message || 'Failed to get payment health status');
  }
}

module.exports = { 
  createPayment, 
  createMinimalCashPayment,
  updatePaymentStatus, 
  webhook, 
  getPaymentAudit, 
  getBookingPaymentAudit,
  getPaymentMethods,
  confirmPayment,
  refundPayment,
  getWebhookStats,
  getPaymentHealth
};
