const mongoose = require('mongoose');

const outboxSchema = new mongoose.Schema({
  // Message identification
  messageId: { 
    type: String, 
    required: true, 
    unique: true 
  },
  correlationId: { 
    type: String, 
    required: true 
  },
  
  // Message details
  type: { 
    type: String, 
    required: true,
    enum: ['payment_webhook', 'email_notification', 'sms_notification', 'booking_update', 'payment_status_change']
  },
  payload: { 
    type: mongoose.Schema.Types.Mixed, 
    required: true 
  },
  metadata: { 
    type: mongoose.Schema.Types.Mixed 
  },
  
  // Delivery configuration
  destination: { 
    type: String, 
    required: true 
  },
  priority: { 
    type: String, 
    enum: ['low', 'normal', 'high', 'urgent'], 
    default: 'normal' 
  },
  scheduledAt: { 
    type: Date, 
    default: Date.now 
  },
  
  // Processing state
  status: { 
    type: String, 
    enum: ['pending', 'processing', 'delivered', 'failed', 'dead_letter'], 
    default: 'pending' 
  },
  attempts: { 
    type: Number, 
    default: 0 
  },
  maxAttempts: { 
    type: Number, 
    default: 3 
  },
  
  // Timing
  firstAttemptAt: { 
    type: Date 
  },
  lastAttemptAt: { 
    type: Date 
  },
  deliveredAt: { 
    type: Date 
  },
  nextRetryAt: { 
    type: Date 
  },
  
  // Error tracking
  lastError: { 
    type: String 
  },
  errorHistory: [{
    attempt: { type: Number },
    error: { type: String },
    timestamp: { type: Date, default: Date.now }
  }],
  
  // Dead letter queue
  deadLetterReason: { 
    type: String 
  },
  deadLetterAt: { 
    type: Date 
  },
  
  // Audit
  createdAt: { 
    type: Date, 
    default: Date.now 
  },
  updatedAt: { 
    type: Date, 
    default: Date.now 
  }
});

// Indexes for efficient querying
outboxSchema.index({ status: 1, scheduledAt: 1 });
outboxSchema.index({ status: 1, nextRetryAt: 1 });
outboxSchema.index({ correlationId: 1 });
outboxSchema.index({ messageId: 1 }, { unique: true });
outboxSchema.index({ type: 1, status: 1 });
outboxSchema.index({ priority: 1, scheduledAt: 1 });
outboxSchema.index({ createdAt: 1 });

// Update timestamp on save
outboxSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static methods
outboxSchema.statics.findPending = function(limit = 100) {
  return this.find({
    status: 'pending',
    scheduledAt: { $lte: new Date() }
  })
  .sort({ priority: -1, scheduledAt: 1 })
  .limit(limit);
};

outboxSchema.statics.findRetryable = function(limit = 100) {
  return this.find({
    status: 'failed',
    $expr: { $lt: ['$attempts', '$maxAttempts'] },
    nextRetryAt: { $lte: new Date() }
  })
  .sort({ nextRetryAt: 1 })
  .limit(limit);
};

outboxSchema.statics.findDeadLetters = function(limit = 100) {
  return this.find({
    status: 'dead_letter'
  })
  .sort({ deadLetterAt: -1 })
  .limit(limit);
};

outboxSchema.statics.getStats = function(days = 7) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  return this.aggregate([
    { $match: { createdAt: { $gte: startDate } } },
    {
      $group: {
        _id: {
          type: '$type',
          status: '$status'
        },
        count: { $sum: 1 },
        avgAttempts: { $avg: '$attempts' }
      }
    },
    {
      $group: {
        _id: '$_id.type',
        statuses: {
          $push: {
            status: '$_id.status',
            count: '$count',
            avgAttempts: '$avgAttempts'
          }
        },
        totalCount: { $sum: '$count' }
      }
    }
  ]);
};

// Instance methods
outboxSchema.methods.markProcessing = function() {
  this.status = 'processing';
  this.attempts += 1;
  this.lastAttemptAt = new Date();
  
  if (!this.firstAttemptAt) {
    this.firstAttemptAt = new Date();
  }
  
  return this.save();
};

outboxSchema.methods.markDelivered = function() {
  this.status = 'delivered';
  this.deliveredAt = new Date();
  return this.save();
};

outboxSchema.methods.markFailed = function(error, retryDelay = null) {
  this.status = 'failed';
  this.lastError = error;
  this.lastAttemptAt = new Date();
  
  // Add to error history
  this.errorHistory.push({
    attempt: this.attempts,
    error: error,
    timestamp: new Date()
  });
  
  // Calculate next retry time
  if (this.attempts < this.maxAttempts) {
    const delay = retryDelay || Math.pow(2, this.attempts) * 1000; // Exponential backoff
    this.nextRetryAt = new Date(Date.now() + delay);
  } else {
    // Move to dead letter queue
    this.status = 'dead_letter';
    this.deadLetterReason = `Max attempts (${this.maxAttempts}) exceeded`;
    this.deadLetterAt = new Date();
  }
  
  return this.save();
};

outboxSchema.methods.retry = function() {
  if (this.status === 'dead_letter') {
    this.status = 'pending';
    this.attempts = 0;
    this.errorHistory = [];
    this.deadLetterReason = null;
    this.deadLetterAt = null;
    this.nextRetryAt = null;
    return this.save();
  }
  return Promise.resolve(this);
};

module.exports = mongoose.model('Outbox', outboxSchema);
