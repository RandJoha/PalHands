const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    default: ''
  },
  category: {
    type: String,
    required: true,
    enum: [
      'cleaning',
      'laundry',
      'caregiving',
      'furniture_moving',
      'elderly_support',
      'aluminum_work',
      'carpentry',
      'home_nursing',
      'maintenance',
      'other'
    ]
  },
  subcategory: {
    type: String,
    trim: true
  },
  provider: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
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

// Index for search functionality
serviceSchema.index({ title: 'text', description: 'text', category: 'text' });
serviceSchema.index({ 'location.serviceArea': 1, category: 1 });
serviceSchema.index({ 'rating.average': -1 });
serviceSchema.index({ 'location.geo': '2dsphere' });

module.exports = mongoose.model('Service', serviceSchema); 