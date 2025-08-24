const mongoose = require('mongoose');

const webhookLogSchema = new mongoose.Schema({
  processorType: { 
    type: String, 
    required: true, 
    enum: ['stripe', 'paypal', 'cash'] 
  },
  webhookId: { 
    type: String, 
    required: true 
  },
  eventType: { 
    type: String, 
    required: true 
  },
  eventData: { 
    type: mongoose.Schema.Types.Mixed 
  },
  processingResult: { 
    type: mongoose.Schema.Types.Mixed 
  },
  timestamp: { 
    type: Number, 
    required: true 
  },
  processed: { 
    type: Boolean, 
    default: false 
  },
  processedAt: { 
    type: Date, 
    default: Date.now 
  },
  success: { 
    type: Boolean, 
    default: false 
  },
  error: { 
    type: String 
  },
  retryCount: { 
    type: Number, 
    default: 0 
  },
  lastRetryAt: { 
    type: Date 
  },
  metadata: { 
    type: mongoose.Schema.Types.Mixed 
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

// Indexes for efficient querying
webhookLogSchema.index({ processorType: 1, webhookId: 1 }, { unique: true });
webhookLogSchema.index({ processorType: 1, eventType: 1 });
webhookLogSchema.index({ processed: 1, success: 1 });
webhookLogSchema.index({ timestamp: 1 });
webhookLogSchema.index({ createdAt: 1 });
webhookLogSchema.index({ processedAt: 1 });

// Update timestamp on save
webhookLogSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static methods
webhookLogSchema.statics.findByWebhookId = function(processorType, webhookId) {
  return this.findOne({ processorType, webhookId });
};

webhookLogSchema.statics.findUnprocessed = function(processorType = null) {
  const query = { processed: false };
  if (processorType) {
    query.processorType = processorType;
  }
  return this.find(query).sort({ createdAt: 1 });
};

webhookLogSchema.statics.findFailed = function(processorType = null, limit = 100) {
  const query = { success: false, processed: true };
  if (processorType) {
    query.processorType = processorType;
  }
  return this.find(query).sort({ processedAt: -1 }).limit(limit);
};

webhookLogSchema.statics.getStats = function(processorType = null, days = 7) {
  const query = {};
  if (processorType) {
    query.processorType = processorType;
  }
  
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  query.createdAt = { $gte: startDate };

  return this.aggregate([
    { $match: query },
    {
      $group: {
        _id: {
          processorType: '$processorType',
          eventType: '$eventType',
          success: '$success'
        },
        count: { $sum: 1 },
        lastProcessed: { $max: '$processedAt' }
      }
    },
    {
      $group: {
        _id: '$_id.processorType',
        events: {
          $push: {
            eventType: '$_id.eventType',
            success: '$_id.success',
            count: '$count',
            lastProcessed: '$lastProcessed'
          }
        },
        totalCount: { $sum: '$count' }
      }
    }
  ]);
};

// Instance methods
webhookLogSchema.methods.markProcessed = function(result, success = true) {
  this.processed = true;
  this.processedAt = new Date();
  this.success = success;
  this.processingResult = result;
  if (!success && result && result.error) {
    this.error = result.error;
  }
  return this.save();
};

webhookLogSchema.methods.incrementRetry = function() {
  this.retryCount += 1;
  this.lastRetryAt = new Date();
  return this.save();
};

module.exports = mongoose.model('WebhookLog', webhookLogSchema);
