const mongoose = require('mongoose');

const systemSettingSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true
  },
  value: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  type: {
    type: String,
    enum: ['string', 'number', 'boolean', 'json', 'array'],
    required: true
  },
  category: {
    type: String,
    enum: [
      'general',
      'payment',
      'booking',
      'notification',
      'security',
      'feature_flags',
      'maintenance',
      'analytics'
    ],
    required: true
  },
  description: {
    type: String,
    required: true
  },
  isPublic: {
    type: Boolean,
    default: false
  },
  isEditable: {
    type: Boolean,
    default: true
  },
  validation: {
    min: Number,
    max: Number,
    pattern: String,
    required: Boolean
  },
  lastModifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  lastModifiedAt: {
    type: Date,
    default: Date.now
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Update timestamp on save
systemSettingSchema.pre('save', function(next) {
  this.lastModifiedAt = Date.now();
  next();
});

// Index for efficient querying
systemSettingSchema.index({ key: 1 });
systemSettingSchema.index({ category: 1 });
systemSettingSchema.index({ isPublic: 1 });

module.exports = mongoose.model('SystemSetting', systemSettingSchema); 