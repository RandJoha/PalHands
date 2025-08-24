const mongoose = require('mongoose');

const paymentAuditSchema = new mongoose.Schema({
  payment: { type: mongoose.Schema.Types.ObjectId, ref: 'Payment', required: true },
  booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
  actor: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  actorType: { type: String, enum: ['client', 'provider', 'admin'], required: true },
  action: { type: String, enum: ['created', 'status_updated', 'refunded', 'cancelled'], required: true },
  oldStatus: { type: String, enum: ['pending', 'paid', 'failed', 'refunded'] },
  newStatus: { type: String, enum: ['pending', 'paid', 'failed', 'refunded'] },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'ILS' },
  method: { type: String, enum: ['cash', 'credit_card', 'paypal', 'bank_transfer'] },
  transactionId: { type: String },
  notes: { type: String },
  metadata: { type: mongoose.Schema.Types.Mixed },
  ipAddress: { type: String },
  userAgent: { type: String },
  createdAt: { type: Date, default: Date.now }
});

// Indexes for efficient querying
paymentAuditSchema.index({ payment: 1, createdAt: -1 });
paymentAuditSchema.index({ booking: 1, createdAt: -1 });
paymentAuditSchema.index({ actor: 1, createdAt: -1 });
paymentAuditSchema.index({ action: 1, createdAt: -1 });

module.exports = mongoose.model('PaymentAudit', paymentAuditSchema);
