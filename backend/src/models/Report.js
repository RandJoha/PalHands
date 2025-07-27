const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  reporter: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  reportedType: {
    type: String,
    required: true,
    enum: ['user', 'service', 'booking', 'review', 'payment']
  },
  reportedId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  reason: {
    type: String,
    required: true,
    enum: [
      'inappropriate_behavior',
      'fake_service',
      'payment_issue',
      'safety_concern',
      'spam',
      'harassment',
      'fraud',
      'poor_quality',
      'no_show',
      'other'
    ]
  },
  description: {
    type: String,
    required: true,
    maxlength: 1000
  },
  evidence: [{
    type: String, // URLs to uploaded evidence
    description: String
  }],
  status: {
    type: String,
    enum: ['pending', 'investigating', 'resolved', 'dismissed'],
    default: 'pending'
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'urgent'],
    default: 'medium'
  },
  assignedAdmin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  adminNotes: [{
    admin: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    note: String,
    timestamp: {
      type: Date,
      default: Date.now
    }
  }],
  resolution: {
    action: {
      type: String,
      enum: [
        'warning_sent',
        'user_suspended',
        'user_banned',
        'service_disabled',
        'booking_cancelled',
        'refund_issued',
        'no_action',
        'other'
      ]
    },
    details: String,
    resolvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    resolvedAt: Date
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update timestamp on save
reportSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Index for efficient querying
reportSchema.index({ status: 1, priority: 1, createdAt: -1 });
reportSchema.index({ reportedType: 1, reportedId: 1 });
reportSchema.index({ reporter: 1, createdAt: -1 });
reportSchema.index({ assignedAdmin: 1, status: 1 });

module.exports = mongoose.model('Report', reportSchema); 