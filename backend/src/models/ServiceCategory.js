const mongoose = require('mongoose');

// ServiceCategory model mapped to the 'servicecategories' collection
// This mirrors the schema used in utils/restoreFrontendData.js
const serviceCategorySchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true,
    index: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  nameKey: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: false,
    trim: true
  },
  icon: {
    type: String,
    default: 'category',
    trim: true
  },
  color: {
    type: String,
    default: '#9E9E9E',
    trim: true
  },
  services: [{
    type: String,
    trim: true
  }],
  isDynamic: {
    type: Boolean,
    default: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  sortOrder: { 
    type: Number, 
    default: 0 
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, { collection: 'servicecategories' });

// Index for efficient queries
serviceCategorySchema.index({ isActive: 1 });

module.exports = mongoose.models.ServiceCategory || mongoose.model('ServiceCategory', serviceCategorySchema);