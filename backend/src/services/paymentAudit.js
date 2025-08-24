const PaymentAudit = require('../models/PaymentAudit');

class PaymentAuditService {
  /**
   * Log a payment action for audit purposes
   */
  static async logAction({
    payment,
    booking,
    actor,
    actorType,
    action,
    oldStatus,
    newStatus,
    amount,
    currency,
    method,
    transactionId,
    notes,
    metadata,
    ipAddress,
    userAgent
  }) {
    try {
      const auditEntry = new PaymentAudit({
        payment: payment._id || payment,
        booking: booking._id || booking,
        actor: actor._id || actor,
        actorType,
        action,
        oldStatus,
        newStatus,
        amount,
        currency,
        method,
        transactionId,
        notes,
        metadata,
        ipAddress,
        userAgent
      });

      await auditEntry.save();
      return auditEntry;
    } catch (error) {
      console.error('Payment audit logging failed:', error);
      // Don't throw - audit logging should not break payment flow
      return null;
    }
  }

  /**
   * Get payment audit trail
   */
  static async getAuditTrail(paymentId, options = {}) {
    const { limit = 50, skip = 0, sort = { createdAt: -1 } } = options;
    
    return await PaymentAudit.find({ payment: paymentId })
      .populate('actor', 'firstName lastName email')
      .sort(sort)
      .limit(limit)
      .skip(skip);
  }

  /**
   * Get booking payment audit trail
   */
  static async getBookingAuditTrail(bookingId, options = {}) {
    const { limit = 50, skip = 0, sort = { createdAt: -1 } } = options;
    
    return await PaymentAudit.find({ booking: bookingId })
      .populate('actor', 'firstName lastName email')
      .populate('payment', 'amount currency method status')
      .sort(sort)
      .limit(limit)
      .skip(skip);
  }

  /**
   * Get user payment audit trail
   */
  static async getUserAuditTrail(userId, options = {}) {
    const { limit = 50, skip = 0, sort = { createdAt: -1 } } = options;
    
    return await PaymentAudit.find({ actor: userId })
      .populate('payment', 'amount currency method status')
      .populate('booking', 'bookingId service')
      .sort(sort)
      .limit(limit)
      .skip(skip);
  }
}

module.exports = PaymentAuditService;
