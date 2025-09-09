const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    refPath: 'userRef',
    required: true
  },
  userRef: {
    type: String,
    enum: ['User', 'Provider'],
    default: 'User'
  },
  type: {
    type: String,
    required: true,
    enum: ['new_report', 'report_update', 'system_alert', 'new_message', 'new_booking_request', 'booking_confirmed', 'booking_cancelled', 'booking_cancelled_inactivation', 'booking_cancelled_service_deletion']
  },
  title: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },
  data: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },
  read: {
    type: Boolean,
    default: false
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high'],
    default: 'medium'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  readAt: {
    type: Date,
    default: null
  }
});

// Indexes for efficient querying
notificationSchema.index({ user: 1, read: 1 });
notificationSchema.index({ user: 1, createdAt: -1 });
notificationSchema.index({ createdAt: -1 });

// Pre-save hook to set readAt when marked as read
notificationSchema.pre('save', function(next) {
  if (this.isModified('read') && this.read && !this.readAt) {
    this.readAt = new Date();
  }
  next();
});

module.exports = mongoose.model('Notification', notificationSchema);
