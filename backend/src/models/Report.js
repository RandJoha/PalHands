const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  reporter: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  reporterRole: {
    type: String,
    enum: ['client', 'provider', 'admin'],
    default: 'client'
  },
  // Classify the type of submission to support both entity-related reports and general feedback
  reportCategory: {
    type: String,
    enum: ['user_issue', 'technical_issue', 'feature_suggestion', 'service_category_request', 'other'],
    default: 'user_issue'
  },
  reportedType: {
    type: String,
    required: false,
    enum: ['user', 'service', 'booking', 'review', 'payment']
  },
  reportedId: {
    type: mongoose.Schema.Types.ObjectId,
    required: false
  },
  // When reportedType is 'user', capture whether the target is a client or provider
  reportedUserRole: {
    type: String,
    enum: ['client', 'provider'],
    required: function () { return this.reportCategory === 'user_issue' && this.reportedType === 'user'; }
  },
  // Human-readable mapped to FE field "Service Name / Person"
  reportedName: { type: String, trim: true },
  // Only for user_issue category
  issueType: {
    type: String,
    required: function () { return this.reportCategory === 'user_issue'; },
    enum: [
      'unsafe',
  'harassment',
      'misleading',
      'inappropriate_behavior',
      'fraud',
      'spam',
      'payment_issue',
      'safety_concern',
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
  // Party info for user reports (disambiguation)
  partyInfo: {
    reporterName: { type: String, trim: true },
    reporterEmail: { type: String, trim: true, lowercase: true },
    reportedName: { type: String, trim: true },
    reportedEmail: { type: String, trim: true, lowercase: true }
  },
  // Optional linkage to known entities when available
  relatedBookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
  reportedServiceId: { type: mongoose.Schema.Types.ObjectId, ref: 'Service' },
  // Service Category Request specific fields
  serviceName: { type: String, trim: true },
  categoryFit: { type: String, trim: true },
  importanceReason: { type: String, trim: true },
  // Feature Suggestion fields
  ideaTitle: { type: String, trim: true, maxlength: 150 },
  communityBenefit: { type: String, trim: true, maxlength: 1000 },
  // Optional contact and context fields for non-entity submissions
  contactEmail: {
    type: String,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Invalid email']
  },
  contactName: { type: String, trim: true },
  subject: { type: String, trim: true, maxlength: 200 },
  requestedCategory: { type: String, trim: true, maxlength: 120 },
  // Technical issue optional metadata
  device: { type: String, trim: true, maxlength: 120 },
  os: { type: String, trim: true, maxlength: 120 },
  appVersion: { type: String, trim: true, maxlength: 60 },
  evidence: [{
    type: String, // URLs to uploaded evidence
    description: String
  }],
  status: {
    type: String,
    enum: ['pending', 'under_review', 'awaiting_user', 'investigating', 'resolved', 'dismissed'],
    default: 'pending'
  },
  statusHistory: [{
    from: { type: String },
    to: { type: String },
    at: { type: Date, default: Date.now },
    by: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }
  }],
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
        'warn_user',
        'user_suspended',
        'user_banned',
        'service_disabled',
        'booking_cancelled',
        'refund_issued',
        'no_action',
        'other'
      ]
    },
    reason: { type: String, trim: true },
    details: String,
    resolvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    resolvedAt: Date
  },
  // Idempotency support for create
  idempotencyKey: { type: String, trim: true, maxlength: 100 },
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
reportSchema.index({ reportCategory: 1, createdAt: -1 });
// Ensure uniqueness of idempotent creates per user
reportSchema.index({ reporter: 1, idempotencyKey: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('Report', reportSchema); 