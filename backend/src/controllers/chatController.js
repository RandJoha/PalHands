const mongoose = require('mongoose');
const Chat = require('../models/Chat');
const Message = require('../models/Message');
const User = require('../models/User');
const Provider = require('../models/Provider');
const Notification = require('../models/Notification');
const { ok, error } = require('../utils/response');

// Get user's chat list
const getUserChats = async (req, res) => {
  try {
    const userId = req.user._id;
    const userRole = req.user.role;
    
    // console.log('🔍 Get user chats request:', { 
    //   userId: userId.toString(), 
    //   userRole,
    //   timestamp: new Date().toISOString()
    // });
    
    // Find chats where user is a participant
    const chats = await Chat.find({
      participants: userId,
      isActive: true
    })
    .sort({ 
      'lastMessage.timestamp': -1, 
      updatedAt: -1 
    });
    
    console.log(`🔍 Database query completed:`);
    console.log(`  - Query: participants: ${userId}, isActive: true`);
    console.log(`  - Sort: lastMessage.timestamp: -1, updatedAt: -1`);
    console.log(`  - Found ${chats.length} chats`);

    console.log(`📱 Found ${chats.length} chats for user ${userId.toString()}`);
    
    if (chats.length > 0) {
      console.log('📋 Raw chats data:');
      chats.forEach((chat, index) => {
        console.log(`  - Chat ${index + 1}:`);
        console.log(`    - ID: ${chat._id}`);
        console.log(`    - Participants: ${chat.participants.map(p => p.toString())}`);
        console.log(`    - Last message text: ${chat.lastMessage?.text || 'No message'}`);
        console.log(`    - Last message content: ${chat.lastMessage?.content || 'No content'}`);
        console.log(`    - Last message sender: ${chat.lastMessage?.sender || 'No sender'}`);
        console.log(`    - Last message timestamp: ${chat.lastMessage?.timestamp || 'No timestamp'}`);
        console.log(`    - Updated at: ${chat.updatedAt}`);
        console.log(`    - Service name: ${chat.serviceName || 'No service'}`);
        console.log(`    - Is new chat: ${!chat.lastMessage ? 'YES' : 'NO'}`);
        console.log(`    - Full lastMessage object:`, chat.lastMessage);
      });
    }

  // Populate participants manually - try User first, then Provider (supports provider-only participants)
    const populatedChats = await Promise.all(chats.map(async (chat) => {
      console.log(`🔍 Populating participants for chat ${chat._id}:`);
      console.log(`  - Raw participants: ${chat.participants.map(p => p.toString())}`);
      console.log(`  - Participants type: ${chat.participants.map(p => typeof p)}`);
      console.log(`  - Participants are ObjectIds: ${chat.participants.map(p => p instanceof mongoose.Types.ObjectId)}`);
      
      // Validate that participants are valid ObjectIds
      const validParticipants = chat.participants.filter(p => {
        const isValid = mongoose.Types.ObjectId.isValid(p);
        if (!isValid) {
          console.log(`  - ⚠️ Invalid participant ID: ${p} (type: ${typeof p})`);
        }
        return isValid;
      });
      
      if (validParticipants.length !== chat.participants.length) {
        console.log(`  - ⚠️ WARNING: ${chat.participants.length - validParticipants.length} invalid participant IDs found`);
      }
      
      const populatedParticipants = await Promise.all(validParticipants.map(async (participantId) => {
        console.log(`  - Looking up participant: ${participantId}`);
        let user = await User.findById(participantId).select('firstName lastName email profileImage role');
        if (user) {
          console.log(`  - Found user: ${user.firstName} ${user.lastName}`);
          return user;
        }
        const provider = await Provider.findById(participantId).select('firstName lastName email profileImage');
        if (provider) {
          console.log(`  - Found provider: ${provider.firstName} ${provider.lastName}`);
          return {
            _id: provider._id,
            firstName: provider.firstName,
            lastName: provider.lastName || '',
            email: provider.email,
            profileImage: provider.profileImage,
            role: 'provider'
          };
        }
        console.log(`  - ❌ Participant not found in User or Provider for ID: ${participantId}`);
        return null;
      }));

      // Populate last message sender (User first, then Provider)
      let populatedLastMessage = null;
      if (chat.lastMessage?.sender) {
        let lmUser = await User.findById(chat.lastMessage.sender).select('firstName lastName profileImage role');
        if (lmUser) {
          populatedLastMessage = lmUser;
        } else {
          const lmProv = await Provider.findById(chat.lastMessage.sender).select('firstName lastName profileImage');
          if (lmProv) {
            populatedLastMessage = {
              _id: lmProv._id,
              firstName: lmProv.firstName,
              lastName: lmProv.lastName || '',
              profileImage: lmProv.profileImage,
              role: 'provider'
            };
          }
        }
      }

      const result = {
        ...chat.toObject(),
        participants: populatedParticipants,
        lastMessage: chat.lastMessage ? (
          populatedLastMessage ? {
            ...(chat.lastMessage.toObject ? chat.lastMessage.toObject() : chat.lastMessage),
            sender: populatedLastMessage
          } : chat.lastMessage
        ) : null
      };
      
      console.log(`  - Populated result participants: ${result.participants.map(p => p ? `${p.firstName} ${p.lastName}` : 'NULL')}`);
      return result;
    }));

    // Transform chats to include participant info and unread counts
    const transformedChats = populatedChats.map(chat => {
      console.log(`🔄 Transforming chat ${chat._id}:`);
      console.log(`  - All participants: ${chat.participants.map(p => p ? `${p.firstName} ${p.lastName} (${p._id})` : 'NULL')}`);
      console.log(`  - Current user ID: ${userId}`);
      
      const otherParticipant = chat.participants.find(p => p._id.toString() !== userId.toString());
      console.log(`  - Other participant found: ${otherParticipant ? `${otherParticipant.firstName} ${otherParticipant.lastName}` : 'NOT FOUND'}`);
      
      if (!otherParticipant) {
        console.log(`  - ⚠️ WARNING: No other participant found for chat ${chat._id}`);
        console.log(`  - This might indicate a data integrity issue`);
      }
      
      const unreadCount = chat.unreadCounts.get(userId.toString()) || 0;
      
  const transformedChat = {
        _id: chat._id,
        participant: otherParticipant ? {
          _id: otherParticipant._id,
          name: `${otherParticipant.firstName} ${otherParticipant.lastName}`,
          email: otherParticipant.email,
          profileImage: otherParticipant.profileImage,
          role: otherParticipant.role || 'provider'
        } : {
          _id: 'unknown',
          name: 'Unknown Participant',
          email: 'unknown@example.com',
          profileImage: null,
          role: 'provider'
        },
        lastMessage: chat.lastMessage,
        unreadCount,
        serviceName: chat.serviceName,
        updatedAt: chat.updatedAt
      };
      
      console.log(`  - Transformed participant: ${transformedChat.participant.name}`);
      return transformedChat;
    });

    console.log(`📤 Returning ${transformedChats.length} transformed chats to frontend`);
    
    // Log each transformed chat with detailed participant info
    transformedChats.forEach((chat, index) => {
      console.log(`✅ Transformed chat ${index + 1}:`);
      console.log(`  - Chat ID: ${chat._id}`);
      console.log(`  - Participant ID: ${chat.participant._id}`);
      console.log(`  - Participant name: "${chat.participant.name}"`);
      console.log(`  - Participant email: ${chat.participant.email}`);
      console.log(`  - Participant role: ${chat.participant.role}`);
      console.log(`  - Last message: ${chat.lastMessage?.content || 'No message'}`);
      console.log(`  - Service name: ${chat.serviceName || 'No service'}`);
      console.log(`  - Full participant object:`, chat.participant);
    });
    
    // Also log the raw response being sent
    const responseData = { chats: transformedChats };
    console.log('📤 Final response data structure:', JSON.stringify(responseData, null, 2));
    
    // Always return success with chats array, even if empty
    return ok(res, responseData);
  } catch (err) {
    console.error('Get user chats error:', err);
    console.error('Error details:', {
      message: err.message,
      stack: err.stack,
      name: err.name
    });
    
    // If it's a specific error, provide more context
    if (err.message && err.message.includes('Cast to ObjectId failed')) {
      return error(res, 400, 'Invalid user ID format');
    }
    
    return error(res, 500, 'Failed to fetch chats');
  }
};

// Get chat messages
const getChatMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;
    const { page = 1, limit = 50 } = req.query;
    const skip = (page - 1) * limit;

    // Verify user is participant in this chat
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
      isActive: true
    });

    if (!chat) {
      return error(res, 404, 'Chat not found');
    }

    // Get messages
    console.log('🔍 Backend - Fetching messages for chat:', {
      chatId: chatId.toString(),
      userId: userId.toString(),
      query: { chatId },
      skip,
      limit: parseInt(limit)
    });
    
    const messages = await Message.find({ chatId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));
      
    console.log('📱 Backend - Found messages:', {
      chatId: chatId.toString(),
      messageCount: messages.length,
      messageIds: messages.map(m => m._id.toString()),
      firstMessageContent: messages.length > 0 ? messages[0].content : 'None'
    });

    // Populate senders manually - try User first, then Provider
    const populatedMessages = await Promise.all(messages.map(async (message) => {
      let sender = await User.findById(message.sender).select('firstName lastName profileImage providerId role');
      if (!sender) {
        const prov = await Provider.findById(message.sender).select('firstName lastName profileImage');
        if (prov) {
          sender = {
            _id: prov._id,
            firstName: prov.firstName,
            lastName: prov.lastName || '',
            profileImage: prov.profileImage,
            providerId: undefined,
            role: 'provider'
          };
        }
      }
      return {
        ...message.toObject(),
        sender
      };
    }));

    // Mark messages as read for this user
    await Message.updateMany(
      {
        chatId,
        sender: { $ne: userId },
        'readBy.user': { $ne: userId }
      },
      {
        $push: {
          readBy: {
            user: userId,
            readAt: new Date()
          }
        },
        status: 'read'
      }
    );

    // Update unread count for this user
    await Chat.updateOne(
      { _id: chatId },
      { $set: { [`unreadCounts.${userId}`]: 0 } }
    );

    // Transform messages
    const transformedMessages = populatedMessages.map(message => {
      const sender = message.sender
        ? {
            _id: message.sender._id,
            name: `${message.sender.firstName} ${message.sender.lastName}`.trim(),
            profileImage: message.sender.profileImage,
            providerId: message.sender.providerId
          }
        : {
            _id: null,
            name: 'Unknown',
            profileImage: null,
            providerId: undefined
          };
      return {
        _id: message._id,
        content: message.content,
        messageType: message.messageType,
        attachment: message.attachment,
        sender,
        isMe: (message.sender && message.sender._id)
          ? message.sender._id.toString() === userId.toString()
          : false,
        status: message.status,
        createdAt: message.createdAt
      };
    });

    return ok(res, { 
      messages: transformedMessages.reverse(), // Reverse to get chronological order
      hasMore: messages.length === parseInt(limit)
    });
  } catch (err) {
    console.error('Get chat messages error:', err);
    return error(res, 500, 'Failed to fetch messages');
  }
};

// Send a message
const sendMessage = async (req, res) => {
  try {
    const { chatId } = req.params;
    const { content, messageType = 'text', attachment } = req.body;
    const userId = req.user._id;
    const userRole = req.user.role;

    console.log('💬 Send message request:', {
      chatId,
      content: content?.substring(0, 50) + (content?.length > 50 ? '...' : ''),
      messageType,
      userId: userId.toString(),
      userRole,
      timestamp: new Date().toISOString()
    });

    // Verify user is participant in this chat
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
      isActive: true
    });

    if (!chat) {
      console.log('❌ Chat not found:', chatId);
      return error(res, 404, 'Chat not found');
    }

    console.log('✅ Chat found:', {
      chatId: chat._id.toString(),
      participants: chat.participants.map(p => p.toString()),
      lastMessage: chat.lastMessage?.content || 'No previous message'
    });

    // Validate message content
    if (!content || content.trim().length === 0) {
      console.log('❌ Empty message content');
      return error(res, 400, 'Message content is required');
    }

    if (content.length > 1000) {
      console.log('❌ Message too long:', content.length);
      return error(res, 400, 'Message too long (max 1000 characters)');
    }

    // Create message
    const message = new Message({
      chatId,
      sender: userId,
      senderType: userRole === 'provider' ? 'Provider' : 'User',
      content: content.trim(),
      messageType,
      attachment: attachment || null
    });

    await message.save();
    console.log('✅ Message saved:', {
      messageId: message._id.toString(),
      content: message.content,
      sender: message.sender.toString(),
      createdAt: message.createdAt
    });

    // Update chat's last message and unread counts
    const otherParticipants = chat.participants.filter(p => p.toString() !== userId.toString());
    const unreadUpdates = {};
    otherParticipants.forEach(participantId => {
      const currentCount = chat.unreadCounts.get(participantId.toString()) || 0;
      unreadUpdates[participantId.toString()] = currentCount + 1;
    });

    console.log('📊 Unread count updates:', unreadUpdates);

    // Populate sender info for last message
    let sender = await User.findById(userId).select('firstName lastName profileImage');
    if (!sender) {
      const prov = await Provider.findById(userId).select('firstName lastName profileImage');
      if (prov) {
        sender = { _id: prov._id, firstName: prov.firstName, lastName: prov.lastName || '', profileImage: prov.profileImage };
      }
    }
    console.log('👤 Sender info:', {
      id: sender._id.toString(),
      name: `${sender.firstName} ${sender.lastName}`,
      email: sender.email
    });

    const updateResult = await Chat.updateOne(
      { _id: chatId },
      {
        lastMessage: {
          text: content,
          sender: userId,
          timestamp: new Date()
        },
        unreadCounts: unreadUpdates,
        updatedAt: new Date()
      }
    );

    console.log('✅ Chat updated:', {
      matchedCount: updateResult.matchedCount,
      modifiedCount: updateResult.modifiedCount,
      lastMessageContent: content,
      updatedAt: new Date()
    });

    // Create notifications for other participants - DISABLED
    // try {
    //   for (const participantId of otherParticipants) {
    //     // Skip if it's the sender
    //     if (participantId.toString() === userId.toString()) continue;
        
    //     // Get participant info
    //     const participant = await User.findById(participantId).select('firstName lastName role');
    //     if (!participant) continue;

    //     // Create notification
    //     const notification = new Notification({
    //       recipient: participantId,
    //       type: 'new_message',
    //       title: 'New Message',
    //       message: `You have a new message from ${sender.firstName} ${sender.lastName}`,
    //       data: {
    //         chatId: chatId,
    //         senderId: userId,
    //         senderName: `${sender.firstName} ${sender.lastName}`,
    //         messageContent: content.substring(0, 100) + (content.length > 100 ? '...' : ''),
    //         messageType: messageType
    //       },
    //       priority: 'medium'
    //     });

    //     await notification.save();
    //     console.log(`🔔 Notification created for ${participant.firstName} ${participant.lastName} (${participant.role})`);
    //   }
    // } catch (notificationError) {
    //   console.error('❌ Failed to create notifications:', notificationError);
    //   // Don't fail the message send if notifications fail
    // }

  // Populate sender info for response
  // Note: providers authenticate via providers collection; users via users collection
    let responseSender = await User.findById(userId).select('firstName lastName profileImage');
    if (!responseSender) {
      const prov = await Provider.findById(userId).select('firstName lastName profileImage');
      if (prov) {
        responseSender = { _id: prov._id, firstName: prov.firstName, lastName: prov.lastName || '', profileImage: prov.profileImage };
      }
    }

    const responseMessage = {
      _id: message._id,
      content: message.content,
      messageType: message.messageType,
      attachment: message.attachment,
      sender: {
        _id: responseSender._id,
        name: `${responseSender.firstName} ${responseSender.lastName}`,
        profileImage: responseSender.profileImage,
  providerId: undefined
      },
      isMe: true,
      status: message.status,
      createdAt: message.createdAt
    };

    return ok(res, { message: responseMessage });
  } catch (err) {
    console.error('Send message error:', err);
    return error(res, 500, 'Failed to send message');
  }
};

// Create or get existing chat
const createOrGetChat = async (req, res) => {
  try {
    const { participantId, bookingId, serviceName } = req.body;
    const userId = req.user._id;
    const userRole = req.user.role;

    // console.log('Create or get chat request:', {
    //   participantId,
    //   bookingId,
    //   serviceName,
    //   userId,
    //   userRole
    // });

    // Validate participantId is a valid MongoDB ObjectId
    if (!participantId || typeof participantId !== 'string' || participantId.length !== 24) {
      console.log('Invalid participantId:', participantId);
      return error(res, 400, 'Invalid provider ID. Please select a valid provider.');
    }

    // Validate participant exists - support both User (role=provider) and Provider collection IDs
    let participantUser = await User.findById(participantId);
    let participantProvider = null;
    if (!participantUser) {
      participantProvider = await Provider.findById(participantId);
    }
    if (!participantUser && !participantProvider) {
      console.log('Participant not found in User or Provider:', participantId);
      return error(res, 404, 'Provider not found. Please select a valid provider.');
    }
    const participantObjectId = participantUser ? participantUser._id : participantProvider._id;
    console.log('Participant found:', participantObjectId);

    // Check if chat already exists
    let chat = await Chat.findOne({
      participants: { $all: [userId, participantObjectId] },
      isActive: true
    });

    if (!chat) {
      console.log('Creating new chat');
      // Create new chat
      chat = new Chat({
        participants: [userId, participantObjectId],
        participantTypes: [userRole === 'provider' ? 'Provider' : 'User', 'Provider'],
        bookingId: bookingId || null,
        serviceName: serviceName || null,
        unreadCounts: new Map(),
        lastMessage: null, // Explicitly set to null for new chats
        updatedAt: new Date() // Set current timestamp so it appears in chat list
      });

      await chat.save();
      console.log('New chat created:', chat._id);
    } else {
      console.log('Existing chat found:', chat._id);
    }

    // Populate participant info manually
    const populatedParticipants = await Promise.all(chat.participants.map(async (pId, index) => {
      let u = await User.findById(pId).select('firstName lastName email profileImage role');
      if (u) return u;
      const prov = await Provider.findById(pId).select('firstName lastName email profileImage');
      if (prov) {
        return { _id: prov._id, firstName: prov.firstName, lastName: prov.lastName || '', email: prov.email, profileImage: prov.profileImage, role: 'provider' };
      }
      return null;
    }));

    console.log('Populated participants:', populatedParticipants.map(p => ({ id: p._id, name: `${p.firstName} ${p.lastName}` })));

    const otherParticipant = populatedParticipants.find(p => p._id.toString() !== userId.toString());
    
    if (!otherParticipant) {
      console.error('Other participant not found in populated participants');
      return error(res, 500, 'Failed to find chat participant');
    }

    console.log('Other participant found:', otherParticipant._id);
    
  const responseChat = {
      _id: chat._id,
      participant: {
        _id: otherParticipant._id,
        name: `${otherParticipant.firstName} ${otherParticipant.lastName}`,
        email: otherParticipant.email,
        profileImage: otherParticipant.profileImage,
        role: otherParticipant.role || 'provider'
      },
      lastMessage: chat.lastMessage,
      unreadCount: chat.unreadCounts.get(userId.toString()) || 0,
      serviceName: chat.serviceName,
      updatedAt: chat.updatedAt
    };

    console.log('Sending response:', { chatId: responseChat._id, participantName: responseChat.participant.name });
    return ok(res, { chat: responseChat });
  } catch (err) {
    console.error('Create or get chat error:', err);
    return error(res, 500, 'Failed to create or get chat');
  }
};

// Mark messages as read
const markMessagesAsRead = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user._id;

    // Verify user is participant in this chat
    const chat = await Chat.findOne({
      _id: chatId,
      participants: userId,
      isActive: true
    });

    if (!chat) {
      return error(res, 404, 'Chat not found');
    }

    // Mark unread messages as read
    await Message.updateMany(
      {
        chatId,
        sender: { $ne: userId },
        'readBy.user': { $ne: userId }
      },
      {
        $push: {
          readBy: {
            user: userId,
            readAt: new Date()
          }
        },
        status: 'read'
      }
    );

    // Reset unread count for this user
    await Chat.updateOne(
      { _id: chatId },
      { $set: { [`unreadCounts.${userId}`]: 0 } }
    );

    return ok(res, { message: 'Messages marked as read' });
  } catch (err) {
    console.error('Mark messages as read error:', err);
    return error(res, 500, 'Failed to mark messages as read');
  }
};

module.exports = {
  getUserChats,
  getChatMessages,
  sendMessage,
  createOrGetChat,
  markMessagesAsRead
};
