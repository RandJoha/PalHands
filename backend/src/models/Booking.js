const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  bookingId: {
    type: String,
    unique: true,
    required: true
  },
  client: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  provider: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  service: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Service',
    required: true
  },
  serviceDetails: {
    title: String,
    description: String,
    category: String
  },
  schedule: {
    date: {
      type: Date,
      required: true
    },
    startTime: {
      type: String,
      required: true
    },
    endTime: {
      type: String,
      required: true
    },
  duration: Number, // in minutes
  startUtc: Date,
  endUtc: Date,
  timezone: String
  },
  location: {
    address: {
      type: String,
      required: true
    },
    coordinates: {
      latitude: Number,
      longitude: Number
    },
    instructions: String
  },
  pricing: {
    baseAmount: {
      type: Number,
      required: true
    },
    additionalCharges: [{
      description: String,
      amount: Number
    }],
    totalAmount: {
      type: Number,
      required: true
    },
    currency: {
      type: String,
      default: 'ILS'
    }
  },
  status: {
    type: String,
    enum: [
      'pending',
      'confirmed',
      'in_progress',
      'completed',
      'cancelled',
      'disputed'
    ],
    default: 'pending'
  },
  payment: {
    method: {
      type: String,
      enum: ['cash', 'credit_card', 'paypal', 'bank_transfer'],
      default: 'cash'
    },
    status: {
      type: String,
      enum: ['pending', 'paid', 'failed', 'refunded'],
      default: 'pending'
    },
    transactionId: String,
    paidAt: Date
  },
  notes: {
    clientNotes: String,
    providerNotes: String,
    adminNotes: String
  },
  cancellation: {
    cancelledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    reason: String,
    cancelledAt: Date,
    refundAmount: Number
  },
  completion: {
    completedAt: Date,
    clientConfirmation: {
      type: Boolean,
      default: false
    },
    providerConfirmation: {
      type: Boolean,
      default: false
    }
  },
  rating: {
    clientRating: {
      stars: {
        type: Number,
        min: 1,
        max: 5
      },
      comment: String,
      ratedAt: Date
    },
    providerRating: {
      stars: {
        type: Number,
        min: 1,
        max: 5
      },
      comment: String,
      ratedAt: Date
    }
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

// Generate unique booking ID before validation so 'required' passes
bookingSchema.pre('validate', function(next) {
  if (!this.bookingId) {
    this.bookingId = 'BK' + Date.now() + Math.random().toString(36).substr(2, 5).toUpperCase();
  }
  next();
});

// Maintain updatedAt timestamp on save
bookingSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Index for queries
bookingSchema.index({ client: 1, createdAt: -1 });
bookingSchema.index({ provider: 1, createdAt: -1 });
bookingSchema.index({ status: 1, 'schedule.date': 1 });
bookingSchema.index({ provider: 1, 'schedule.startUtc': 1, 'schedule.endUtc': 1 });
bookingSchema.index({ bookingId: 1 });

module.exports = mongoose.model('Booking', bookingSchema); 