const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
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
    unique: true,
    lowercase: true,
    trim: true
  },
  // When changing email, we keep the current email active and store the new one here
  // until the user confirms via the verification link.
  pendingEmail: {
    type: String,
    default: null,
    lowercase: true,
    trim: true
  },
  phone: {
    type: String,
    required: true,
  unique: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  role: {
    type: String,
    enum: ['client', 'provider', 'admin'],
    default: 'client'
  },
  profileImage: {
    type: String,
    default: null
  },

  // New: support multiple saved addresses
  addresses: [
    new mongoose.Schema({
      type: {
        type: String,
        enum: ['home', 'work', 'other'],
        default: 'home'
      },
      street: { type: String, default: '' },
      city: { type: String, default: '' },
      area: { type: String, default: '' },
      coordinates: {
        latitude: { type: Number, default: null },
        longitude: { type: Number, default: null }
      },
      isDefault: { type: Boolean, default: false }
    }, { _id: false })
  ],
  // Optional: store age instead of exact DOB for privacy
  age: {
    type: Number,
    min: 0,
    max: 120,
    default: null
  },
  // GPS location preference
  useGpsLocation: {
    type: Boolean,
    default: false
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  emailVerificationToken: {
    type: String,
    default: null
  },
  emailVerificationExpires: {
    type: Date,
    default: null
  },
  // Dedicated email-change verification token/expiry
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
  // New: store a hashed version of reset token to avoid storing raw tokens in DB
  passwordResetTokenHash: {
    type: String,
    default: null
  },
  passwordResetExpires: {
    type: Date,
    default: null
  },
  isActive: {
    type: Boolean,
    default: true
  },
  deactivationReason: {
    type: String,
    default: null
  },
  rating: {
    average: {
      type: Number,
      default: 0
    },
    count: {
      type: Number,
      default: 0
    }
  },
  reviews: [{
    title: {
      type: String,
      default: 'Review'
    },
    comment: {
      type: String,
      required: true
    },
    rating: {
      type: Number,
      min: 1,
      max: 5,
      required: true
    },
    providerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Provider',
      required: true
    },
    providerName: {
      type: String,
      required: true
    },
    bookingId: {
      type: String,
      required: true
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Provider-specific fields (only used when role is 'provider')
  services: [{
    type: String,
    default: []
  }],
  experienceYears: {
    type: Number,
    min: 0,
    default: 0
  },
  languages: [{
    type: String,
    default: ['Arabic']
  }],
  hourlyRate: {
    type: Number,
    min: 0,
    default: 0
  },
  
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  },
  
  // Favorite providers
  favoriteProviders: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Provider'
  }]
});

// Ensure unique index for phone and email exist (in case of older deployments)
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ phone: 1 }, { unique: true });
// Helpful index if querying for defaults in future
userSchema.index({ 'addresses.isDefault': 1 });

// Password hashing middleware
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

// Enforce single default address middleware
userSchema.pre('save', function(next) {
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

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema); 