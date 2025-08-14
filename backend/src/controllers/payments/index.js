const Payment = require('../../models/Payment');
const Booking = require('../../models/Booking');
const { ok, created, error } = require('../../utils/response');
const realtime = require('../../services/realtime');

// POST /api/payments
async function createPayment(req, res) {
  try {
    const { bookingId, method = 'cash' } = req.body;
    const actor = req.user;

    const booking = await Booking.findById(bookingId).populate('client');
    if (!booking) return error(res, 404, 'Booking not found');
    const isOwner = booking.client.toString() === actor._id.toString();
    if (!(actor.role === 'admin' || isOwner)) return error(res, 403, 'Not allowed to create payment for this booking');

    const exists = await Payment.findOne({ booking: booking._id });
    if (exists) return ok(res, exists, 'Payment already exists');

    const payment = await Payment.create({
      booking: booking._id,
      amount: booking.pricing.totalAmount,
      currency: booking.pricing.currency || 'ILS',
      method,
      status: 'pending'
    });

    // Mirror to booking
    booking.payment = booking.payment || {};
    booking.payment.method = method;
    booking.payment.status = 'pending';
    await booking.save();

    return created(res, payment, 'Payment created');
  } catch (e) {
    console.error('createPayment error', e);
    return error(res, 400, e.message || 'Failed to create payment');
  }
}

// PUT /api/payments/:id/status
async function updatePaymentStatus(req, res) {
  try {
    const { id } = req.params;
    const { status, transactionId } = req.body;
    const actor = req.user;

    const payment = await Payment.findById(id);
    if (!payment) return error(res, 404, 'Payment not found');

    // Only admin for now
    if (actor.role !== 'admin') return error(res, 403, 'Only admin can update payment status');

    payment.status = status;
    if (transactionId) payment.transactionId = transactionId;
    await payment.save();

    // Mirror to booking
    const booking = await Booking.findById(payment.booking);
    if (booking) {
      booking.payment = booking.payment || {};
      booking.payment.status = status;
      if (status === 'paid') booking.payment.paidAt = new Date();
      await booking.save();
    }
  realtime.emit('payment:status', { id: payment._id.toString(), booking: payment.booking.toString(), status: payment.status });
    return ok(res, payment, 'Payment status updated');
  } catch (e) {
    return error(res, 400, e.message || 'Failed to update payment status');
  }
}

// POST /api/payments/webhook (stub)
async function webhook(req, res) {
  return ok(res, {}, 'Webhook received');
}

module.exports = { createPayment, updatePaymentStatus, webhook };
