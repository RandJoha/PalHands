const mongoose = require('mongoose');

const savedProviderSchema = new mongoose.Schema({
  // User who saved this provider
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  
  // Provider being saved
  providerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Provider',
    required: true,
    index: true
  },
  
  // Provider data snapshot (to avoid complex joins)
  providerData: {
    firstName: {
      type: String,
      required: true,
      trim: true
    },
    lastName: {
      type: String,
      required: true,
      trim: true
    },
    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true
    },
    phone: {
      type: String,
      trim: true
    },
    // Provider's primary service
    primaryService: {
      title: String,
      description: String,
      hourlyRate: Number,
      category: String
    },
    // Provider's overall rating
    rating: {
      average: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
      },
      count: {
        type: Number,
        default: 0,
        min: 0
      }
    },
    // Provider's availability status
    isAvailable: {
      type: Boolean,
      default: true
    },
    // Provider's location info
    location: {
      city: String,
      address: String
    }
  },
  
  // When this provider was saved
  savedAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  
  // Additional metadata
  notes: {
    type: String,
    trim: true,
    maxlength: 500
  },
  
  // Tags for organization
  tags: [{
    type: String,
    trim: true,
    maxlength: 50
  }]
}, {
  timestamps: true
});

// Compound index to ensure unique user-provider pairs
savedProviderSchema.index({ userId: 1, providerId: 1 }, { unique: true });

// Index for efficient querying
savedProviderSchema.index({ userId: 1, savedAt: -1 });

// Virtual for full name
savedProviderSchema.virtual('providerData.fullName').get(function() {
  return `${this.providerData.firstName} ${this.providerData.lastName}`.trim();
});

// Ensure virtual fields are serialized
savedProviderSchema.set('toJSON', { virtuals: true });
savedProviderSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('SavedProvider', savedProviderSchema);
