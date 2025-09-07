const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const providerSchema = new mongoose.Schema({
  // Provider ID - 4 digit unique identifier starting from 1000
  providerId: {
    type: Number,
    unique: true,
  // Not required at validation time; it's auto-assigned in pre('save')
  required: false,
    min: 1000,
    max: 9999
  },
  
  // Authentication & Basic Profile (from User model)
  firstName: {
    type: String,
    required: true,
    trim: true
  },
  lastName: {
    type: String,
    required: false,
    trim: true,
    default: ''
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  role: {
    type: String,
    enum: ['provider'],
    default: 'provider'
  },
  phone: {
    type: String,
    required: true,
    unique: true
  },
  profileImage: {
    type: String,
    default: null
  },
  age: {
  type: Number,
  required: true,
  min: 0,
  max: 120
  },
  
  // Addresses (from User model)
  addresses: [
    new mongoose.Schema({
      type: {
        type: String,
        enum: ['home', 'work', 'other'],
        default: 'home'
      },
      street: { 
        type: String, 
        required: true,
        trim: true,
        validate: {
          validator: function(v){ return typeof v === 'string' && v.trim().length > 0; },
          message: 'Address street is required.'
        }
      },
      city: { type: String, default: '' },
      area: { type: String, default: '' },
      coordinates: {
        latitude: { type: Number, default: null },
        longitude: { type: Number, default: null }
      },
      isDefault: { type: Boolean, default: false }
    }, { _id: false })
  ],

  // Service Provider Specific Fields (from our enhanced schema)
  experienceYears: {
    type: Number,
    required: true,
    min: 0
  },
  languages: [{
    type: String,
    required: true
  }],
  hourlyRate: {
    type: Number,
    required: true,
    min: 0
  },
  services: [{
    type: String,
    required: true
  }],
  
  // Rating (merged from both schemas)
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
  
  // Reviews from clients
  reviews: [{
    title: { type: String, default: 'Review' },
    comment: { type: String, required: true },
    rating: { type: Number, min: 1, max: 5, required: true },
    clientId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    clientName: { type: String, required: true },
    bookingId: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
  }],
  
  // Location (enhanced from our schema)
  location: {
    address: {
      type: String,
      trim: true
    },
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  },
  
  // Status & Verification
  isActive: {
    type: Boolean,
    default: true
  },
  deactivationReason: {
    type: String,
    default: null
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  
  // Booking Statistics
  totalBookings: {
    type: Number,
    default: 0
  },
  completedBookings: {
    type: Number,
    default: 0
  },
  
  // Email verification fields (from User model)
  emailVerificationToken: {
    type: String,
    default: null
  },
  emailVerificationExpires: {
    type: Date,
    default: null
  },
  pendingEmail: {
    type: String,
    default: null,
    lowercase: true,
    trim: true
  },
  emailChangeToken: {
    type: String,
    default: null
  },
  emailChangeExpires: {
    type: Date,
    default: null
  },
  passwordResetToken: {
    type: String,
    default: null
  },
  passwordResetTokenHash: {
    type: String,
    default: null
  },
  passwordResetExpires: {
    type: Date,
    default: null
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Indexes for search functionality
providerSchema.index({ providerId: 1 }, { unique: true });
providerSchema.index({ firstName: 'text', lastName: 'text', city: 'text' });
providerSchema.index({ email: 1 }, { unique: true });
providerSchema.index({ phone: 1 }, { unique: true });
providerSchema.index({ city: 1 });
providerSchema.index({ 'rating.average': -1 });
providerSchema.index({ hourlyRate: 1 });
providerSchema.index({ isActive: 1 });
providerSchema.index({ services: 1 });
providerSchema.index({ 'addresses.isDefault': 1 });

// Auto-generate provider ID middleware
providerSchema.pre('save', async function(next) {
  // Only generate provider ID if it doesn't exist (new provider)
  if (!this.providerId) {
    try {
      // Find the highest existing provider ID
      const lastProvider = await this.constructor.findOne({}, { providerId: 1 })
        .sort({ providerId: -1 })
        .limit(1);
      
      // Start from 1000 if no providers exist, otherwise increment from the highest
      this.providerId = lastProvider ? lastProvider.providerId + 1 : 1000;
      
      // Ensure we don't exceed 9999
      if (this.providerId > 9999) {
        throw new Error('Maximum provider ID limit reached (9999)');
      }
    } catch (error) {
      return next(error);
    }
  }
  next();
});

// Password hashing middleware (from User model)
providerSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Enforce single default address middleware (from User model)
providerSchema.pre('save', function(next) {
  if (this.isModified('addresses') && this.addresses.length > 0) {
    let defaultCount = 0;
    let lastDefaultIndex = -1;
    
    // Count default addresses and track the last one
    this.addresses.forEach((address, index) => {
      if (address.isDefault) {
        defaultCount++;
        lastDefaultIndex = index;
      }
    });
    
    // If multiple defaults exist, keep only the last one
    if (defaultCount > 1) {
      this.addresses.forEach((address, index) => {
        address.isDefault = (index === lastDefaultIndex);
      });
    }
    
    // If no default exists and we have addresses, make the first one default
    if (defaultCount === 0 && this.addresses.length > 0) {
      this.addresses[0].isDefault = true;
    }
  }
  next();
});

// Compare password method (from User model)
providerSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('Provider', providerSchema);
