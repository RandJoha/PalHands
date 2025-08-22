const mongoose = require('mongoose');

const timeWindowSchema = new mongoose.Schema({ start: String, end: String }, { _id: false });

const availabilitySchema = new mongoose.Schema({
  provider: { type: mongoose.Schema.Types.ObjectId, ref: 'Provider', required: true, unique: true },
  timezone: { type: String, required: true, default: 'Asia/Jerusalem' },
  weekly: {
    monday: [timeWindowSchema],
    tuesday: [timeWindowSchema],
    wednesday: [timeWindowSchema],
    thursday: [timeWindowSchema],
    friday: [timeWindowSchema],
    saturday: [timeWindowSchema],
    sunday: [timeWindowSchema]
  },
  exceptions: [{
    date: { type: String, required: true }, // YYYY-MM-DD in provider TZ
    windows: [timeWindowSchema] // empty means unavailable
  }]
}, { timestamps: true });

module.exports = mongoose.model('Availability', availabilitySchema);
