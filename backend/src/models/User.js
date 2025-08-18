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
  // Legacy single address (kept for backward compatibility)
  address: {
    street: String,
    city: String,
    area: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
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
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
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

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema); 