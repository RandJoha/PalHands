const mongoose = require('mongoose');

const adminActionSchema = new mongoose.Schema({
  admin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  action: {
    type: String,
    required: true,
    enum: [
      'user_ban',
      'user_unban',
      'user_verify',
      'user_promote',
      'user_demote',
      'service_approve',
      'service_reject',
      'service_feature',
      'booking_cancel',
      'booking_refund',
      'payment_adjust',
      'review_delete',
      'review_flag',
      'category_create',
      'category_update',
      'category_delete',
      'system_setting_change',
      'maintenance_mode_toggle',
      'broadcast_message',
      'report_resolve',
      'dispute_resolve'
    ]
  },
  targetType: {
    type: String,
    required: true,
    enum: ['user', 'service', 'booking', 'payment', 'review', 'category', 'system', 'report']
  },
  targetId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  details: {
    before: mongoose.Schema.Types.Mixed,
    after: mongoose.Schema.Types.Mixed,
    reason: String,
    notes: String
  },
  ipAddress: String,
  userAgent: String,
  timestamp: {
    type: Date,
    default: Date.now
  },
  status: {
    type: String,
    enum: ['success', 'failed', 'pending'],
    default: 'success'
  },
  errorMessage: String
});

// Index for efficient querying
adminActionSchema.index({ admin: 1, timestamp: -1 });
adminActionSchema.index({ action: 1, timestamp: -1 });
adminActionSchema.index({ targetType: 1, targetId: 1 });
adminActionSchema.index({ timestamp: -1 });

module.exports = mongoose.model('AdminAction', adminActionSchema); 