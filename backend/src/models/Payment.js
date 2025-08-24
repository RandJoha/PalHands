const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true, unique: true },
  amount: { type: Number, required: true },
  currency: { type: String, default: 'ILS' },
  method: { type: String, enum: ['cash', 'credit_card', 'paypal', 'bank_transfer'], default: 'cash' },
  status: { type: String, enum: ['pending', 'paid', 'failed', 'refunded'], default: 'pending' },
  transactionId: { type: String },
  metadata: { type: mongoose.Schema.Types.Mixed },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

paymentSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

paymentSchema.index({ booking: 1 });

module.exports = mongoose.model('Payment', paymentSchema);
