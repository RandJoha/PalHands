const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema({
  // Chat this message belongs to
  chatId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Chat',
    required: true
  },
  
  // Message sender
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    required: true
  },
  
  // Sender type (User or Provider)
  senderType: {
    type: String,
    required: true,
    enum: ['User', 'Provider']
  },
  
  // Message content
  content: {
    type: String,
    required: true,
    maxlength: 1000
  },
  
  // Message type
  messageType: {
    type: String,
    enum: ['text', 'image', 'file', 'system'],
    default: 'text'
  },
  
  // File attachment (for image/file messages)
  attachment: {
    url: String,
    filename: String,
    fileSize: Number,
    mimeType: String
  },
  
  // Message status
  status: {
    type: String,
    enum: ['sent', 'delivered', 'read'],
    default: 'sent'
  },
  
  // Read by recipients
  readBy: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      required: true
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }],
  
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
messageSchema.index({ chatId: 1, createdAt: -1 });
messageSchema.index({ sender: 1 });
messageSchema.index({ status: 1 });

// Update the updatedAt timestamp before saving
messageSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

module.exports = mongoose.model('Message', messageSchema);
