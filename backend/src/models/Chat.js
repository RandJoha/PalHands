const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
  // Participants in the chat
  participants: [{
    type: mongoose.Schema.Types.ObjectId,
    required: true
  }],
  
  // Participant types (User or Provider) - one for each participant
  participantTypes: [{
    type: String,
    required: true,
    enum: ['User', 'Provider']
  }],
  
  // Chat type (direct message between client and provider)
  chatType: {
    type: String,
    enum: ['direct'],
    default: 'direct'
  },
  
  // Related booking (optional - for context)
  bookingId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    required: false
  },
  
  // Service context
  serviceName: {
    type: String,
    required: false
  },
  
  // Last message info for chat list
  lastMessage: {
    text: String,
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      required: false
    },
    timestamp: {
      type: Date,
      default: Date.now
    }
  },
  
  // Unread message counts for each participant
  unreadCounts: {
    type: Map,
    of: Number,
    default: new Map()
  },
  
  // Chat status
  isActive: {
    type: Boolean,
    default: true
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

// Indexes for efficient querying
chatSchema.index({ participants: 1 });
chatSchema.index({ bookingId: 1 });
chatSchema.index({ 'lastMessage.timestamp': -1 });
chatSchema.index({ isActive: 1 });

// Update the updatedAt timestamp before saving
chatSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('Chat', chatSchema);
