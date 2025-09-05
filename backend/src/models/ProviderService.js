const mongoose = require('mongoose');

// Reuse a simple time window schema (HH:mm strings in provider timezone)
const timeWindowSchema = new mongoose.Schema({ start: String, end: String }, { _id: false });

const weeklySchema = new mongoose.Schema({
  monday: [timeWindowSchema],
  tuesday: [timeWindowSchema],
  wednesday: [timeWindowSchema],
  thursday: [timeWindowSchema],
  friday: [timeWindowSchema],
  saturday: [timeWindowSchema],
  sunday: [timeWindowSchema]
}, { _id: false });

const providerServiceSchema = new mongoose.Schema({
  provider: { type: mongoose.Schema.Types.ObjectId, ref: 'Provider', required: true, index: true },
  // Reference to catalog Service (optional for now due to legacy string-based services)
  service: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: false, index: true },
  // Legacy/compat: key used in Provider.services (e.g., 'homeCleaning')
  serviceKey: { type: String, required: true, index: true },
  serviceTitle: { type: String, default: '' }, // denormalized for quick display
  category: { type: String, default: '' },

  // Provider-specific settings
  hourlyRate: { type: Number, required: true, min: 0 },
  experienceYears: { type: Number, required: true, min: 0 },

  // Publication & lifecycle
  status: { type: String, enum: ['active', 'inactive', 'deleted'], default: 'inactive', index: true },
  isPublished: { type: Boolean, default: false, index: true },

  // Emergency
  emergencyEnabled: { type: Boolean, default: false },
  emergencyTypes: [{ type: String }],

  // Optional per-service availability override
  timezone: { type: String, default: 'Asia/Jerusalem' },
  weekly: { type: weeklySchema, default: undefined },
  emergencyWeekly: { type: weeklySchema, default: undefined },
  exceptions: [{
    date: { type: String, required: true }, // YYYY-MM-DD in provider TZ
    windows: [timeWindowSchema] // empty means unavailable
  }],
  emergencyExceptions: [{
    date: { type: String, required: true },
    windows: [timeWindowSchema]
  }]
}, { timestamps: true });

// Each provider can have at most one entry per serviceKey
providerServiceSchema.index({ provider: 1, serviceKey: 1 }, { unique: true });

module.exports = mongoose.model('ProviderService', providerServiceSchema);
