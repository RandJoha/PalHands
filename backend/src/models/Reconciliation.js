const mongoose = require('mongoose');

const reconciliationSchema = new mongoose.Schema({
  // Reconciliation identification
  reconciliationId: { 
    type: String, 
    required: true, 
    unique: true 
  },
  period: { 
    type: String, 
    required: true,
    enum: ['daily', 'weekly', 'monthly', 'custom']
  },
  
  // Time period
  startDate: { 
    type: Date, 
    required: true 
  },
  endDate: { 
    type: Date, 
    required: true 
  },
  
  // Processor information
  processorType: { 
    type: String, 
    required: true,
    enum: ['stripe', 'paypal', 'cash', 'all']
  },
  
  // Financial summary
  expectedAmount: { 
    type: Number, 
    required: true 
  },
  actualAmount: { 
    type: Number, 
    required: true 
  },
  currency: { 
    type: String, 
    default: 'ILS' 
  },
  
  // Transaction counts
  expectedTransactions: { 
    type: Number, 
    default: 0 
  },
  actualTransactions: { 
    type: Number, 
    default: 0 
  },
  
  // Discrepancies
  discrepancies: [{
    type: { 
      type: String, 
      enum: ['missing_payment', 'duplicate_payment', 'amount_mismatch', 'status_mismatch', 'processor_error'],
      required: true 
    },
    paymentId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'Payment' 
    },
    transactionId: { 
      type: String 
    },
    expectedAmount: { 
      type: Number 
    },
    actualAmount: { 
      type: Number 
    },
    expectedStatus: { 
      type: String 
    },
    actualStatus: { 
      type: String 
    },
    description: { 
      type: String 
    },
    severity: { 
      type: String, 
      enum: ['low', 'medium', 'high', 'critical'], 
      default: 'medium' 
    },
    resolved: { 
      type: Boolean, 
      default: false 
    },
    resolvedAt: { 
      type: Date 
    },
    resolvedBy: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User' 
    },
    resolutionNotes: { 
      type: String 
    }
  }],
  
  // Reconciliation status
  status: { 
    type: String, 
    enum: ['pending', 'processing', 'completed', 'failed', 'discrepancies_found'], 
    default: 'pending' 
  },
  
  // Processing details
  startedAt: { 
    type: Date 
  },
  completedAt: { 
    type: Date 
  },
  processingDuration: { 
    type: Number // milliseconds
  },
  
  // Error tracking
  error: { 
    type: String 
  },
  retryCount: { 
    type: Number, 
    default: 0 
  },
  maxRetries: { 
    type: Number, 
    default: 3 
  },
  
  // Audit
  createdBy: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User' 
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
reconciliationSchema.index({ reconciliationId: 1 }, { unique: true });
reconciliationSchema.index({ period: 1, startDate: 1, endDate: 1 });
reconciliationSchema.index({ processorType: 1, status: 1 });
reconciliationSchema.index({ status: 1, createdAt: 1 });
reconciliationSchema.index({ 'discrepancies.resolved': 1 });
reconciliationSchema.index({ createdAt: 1 });

// Update timestamp on save
reconciliationSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static methods
reconciliationSchema.statics.findPending = function(limit = 10) {
  return this.find({
    status: 'pending',
    $expr: { $lt: ['$retryCount', '$maxRetries'] }
  })
  .sort({ createdAt: 1 })
  .limit(limit);
};

reconciliationSchema.statics.findWithDiscrepancies = function(limit = 50) {
  return this.find({
    status: 'discrepancies_found',
    'discrepancies.resolved': false
  })
  .sort({ createdAt: -1 })
  .limit(limit);
};

reconciliationSchema.statics.getStats = function(days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);
  
  return this.aggregate([
    { $match: { createdAt: { $gte: startDate } } },
    {
      $group: {
        _id: {
          period: '$period',
          processorType: '$processorType',
          status: '$status'
        },
        count: { $sum: 1 },
        totalDiscrepancies: { $sum: { $size: '$discrepancies' } },
        avgProcessingDuration: { $avg: '$processingDuration' }
      }
    },
    {
      $group: {
        _id: '$_id.period',
        processors: {
          $push: {
            processorType: '$_id.processorType',
            status: '$_id.status',
            count: '$count',
            totalDiscrepancies: '$totalDiscrepancies',
            avgProcessingDuration: '$avgProcessingDuration'
          }
        },
        totalCount: { $sum: '$count' }
      }
    }
  ]);
};

// Instance methods
reconciliationSchema.methods.markProcessing = function() {
  this.status = 'processing';
  this.startedAt = new Date();
  this.retryCount += 1;
  return this.save();
};

reconciliationSchema.methods.markCompleted = function() {
  this.status = 'completed';
  this.completedAt = new Date();
  this.processingDuration = this.completedAt - this.startedAt;
  return this.save();
};

reconciliationSchema.methods.markFailed = function(error) {
  this.status = 'failed';
  this.error = error;
  this.completedAt = new Date();
  this.processingDuration = this.completedAt - this.startedAt;
  return this.save();
};

reconciliationSchema.methods.markDiscrepanciesFound = function() {
  this.status = 'discrepancies_found';
  this.completedAt = new Date();
  this.processingDuration = this.completedAt - this.startedAt;
  return this.save();
};

reconciliationSchema.methods.addDiscrepancy = function(discrepancy) {
  this.discrepancies.push(discrepancy);
  return this.save();
};

reconciliationSchema.methods.resolveDiscrepancy = function(discrepancyIndex, resolvedBy, notes) {
  if (this.discrepancies[discrepancyIndex]) {
    this.discrepancies[discrepancyIndex].resolved = true;
    this.discrepancies[discrepancyIndex].resolvedAt = new Date();
    this.discrepancies[discrepancyIndex].resolvedBy = resolvedBy;
    this.discrepancies[discrepancyIndex].resolutionNotes = notes;
  }
  return this.save();
};

reconciliationSchema.methods.calculateVariance = function() {
  return {
    amountVariance: this.actualAmount - this.expectedAmount,
    amountVariancePercentage: this.expectedAmount > 0 ? 
      ((this.actualAmount - this.expectedAmount) / this.expectedAmount) * 100 : 0,
    transactionVariance: this.actualTransactions - this.expectedTransactions,
    discrepancyCount: this.discrepancies.length,
    unresolvedDiscrepancies: this.discrepancies.filter(d => !d.resolved).length
  };
};

module.exports = mongoose.model('Reconciliation', reconciliationSchema);
