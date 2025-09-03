const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  category: {
    type: String,
    required: true,
    enum: [
      'cleaning',
      'organizing',
      'cooking',
      'childcare',
      'elderly',
      'maintenance',
      'newhome',
      'miscellaneous',
      // Legacy categories
      'laundry',
      'caregiving',
      'furniture_moving',
      'elderly_support',
      'aluminum_work',
      'carpentry',
      'home_nursing',
      'other'
    ]
  },
  subcategory: {
    type: String,
    trim: true
  },
  provider: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Provider',
    required: false // Allow null initially, will be set during linking
  },
  price: {
    amount: {
      type: Number,
      required: true
    },
    type: {
      type: String,
      enum: ['hourly', 'fixed', 'daily'],
      required: true
    },
    currency: {
      type: String,
      default: 'ILS'
    }
  },
  duration: {
    estimated: Number, // in minutes
    flexible: {
      type: Boolean,
      default: true
    }
  },
  availability: {
    days: [{
      type: String,
      enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
    }],
    timeSlots: [{
      start: String, // "09:00"
      end: String    // "17:00"
    }],
    flexible: {
      type: Boolean,
      default: true
    }
  },
  location: {
    serviceArea: {
      type: String,
      required: true
    },
    radius: {
      type: Number,
      default: 10 // kilometers
    },
    onSite: {
      type: Boolean,
      default: true
    },
    remote: {
      type: Boolean,
      default: false
    },
    // Optional geo point for proximity search
    geo: {
      type: {
        type: String,
        enum: ['Point'],
        default: undefined
      },
      coordinates: {
        type: [Number], // [lng, lat]
        default: undefined
      }
    }
  },
  images: [{
    url: String,
    alt: String
  }],
  requirements: [String],
  equipment: [String],
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
  totalBookings: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  featured: {
    type: Boolean,
    default: false
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

// Emergency booking configuration
serviceSchema.add({
  emergencyEnabled: { type: Boolean, default: false },
  emergencyLeadTimeMinutes: { type: Number, default: 120 }, // default 2 hours
  emergencySurcharge: {
    type: {
      type: String,
      enum: ['flat', 'percent'],
      default: 'flat'
    },
    amount: { type: Number, default: 0 } // flat in currency or percent value
  }
});

// Emergency specialization: which emergency task types this service is certified for
serviceSchema.add({
  emergencyTypes: [{ type: String }], // e.g. ['elderly_care','medicine_pickup','acquire_item']
  // Multiplier to apply to hourly rate when booked as emergency (e.g. 1.5 = +50%)
  emergencyRateMultiplier: { type: Number, default: 1.5 }
});

// Index for search functionality
serviceSchema.index({ title: 'text', description: 'text', category: 'text' });
serviceSchema.index({ 'location.serviceArea': 1, category: 1 });
serviceSchema.index({ 'rating.average': -1 });
serviceSchema.index({ 'location.geo': '2dsphere' });

module.exports = mongoose.model('Service', serviceSchema); 