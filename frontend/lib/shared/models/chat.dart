class ChatModel {
  final String id;
  final ChatParticipant participant;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final String? serviceName;
  final DateTime updatedAt;

  const ChatModel({
    required this.id,
    required this.participant,
    this.lastMessage,
    required this.unreadCount,
    this.serviceName,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    print('🔍 ChatModel.fromJson: Parsing chat data: $json');
    
    final participant = ChatParticipant.fromJson(json['participant'] ?? {});
    print('🔍 ChatModel.fromJson: Parsed participant: ${participant.name} (${participant.id})');
    
    final lastMessage = json['lastMessage'] != null 
        ? _parseLastMessage(json['lastMessage']) 
        : null;
    print('🔍 ChatModel.fromJson: Last message: ${lastMessage?.content ?? 'None'}');
    
    final chat = ChatModel(
      id: json['_id']?.toString() ?? '',
      participant: participant,
      lastMessage: lastMessage,
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      serviceName: json['serviceName']?.toString(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
    
    print('🔍 ChatModel.fromJson: Created chat with ID: ${chat.id}, participant: ${chat.participant.name}');
    return chat;
  }

  // Helper method to parse lastMessage which has a different structure than ChatMessage
  static ChatMessage _parseLastMessage(Map<String, dynamic> json) {
    // Handle the sender data - it might be populated or just an ID
    Map<String, dynamic> senderData = {};
    if (json['sender'] != null) {
      if (json['sender'] is Map<String, dynamic>) {
        // Sender is already populated
        senderData = json['sender'] as Map<String, dynamic>;
      } else {
        // Sender is just an ID, create a minimal sender object
        senderData = {
          '_id': json['sender'].toString(),
          'name': 'Unknown',
          'email': '',
          'role': 'provider'
        };
      }
    }
    
    return ChatMessage(
      id: json['_id']?.toString() ?? '', // Use the message ID if available
      content: json['content']?.toString() ?? json['text']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'text',
      attachment: json['attachment'] as Map<String, dynamic>?,
      sender: ChatParticipant.fromJson(senderData),
      isMe: json['isMe'] == true, // Use the isMe field if available
      status: json['status']?.toString() ?? 'sent',
      createdAt: DateTime.tryParse(json['timestamp']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class ChatParticipant {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final int? providerId;
  final String role;

  const ChatParticipant({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.providerId,
    required this.role,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    print('🔍 ChatParticipant.fromJson: Parsing participant data: $json');
    
    final participant = ChatParticipant(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      providerId: json['providerId'] is int ? json['providerId'] : int.tryParse(json['providerId']?.toString() ?? ''),
      role: json['role']?.toString() ?? 'provider',
    );
    
    print('🔍 ChatParticipant.fromJson: Created participant: ${participant.name} (${participant.id})');
    return participant;
  }
}

class ChatMessage {
  final String id;
  final String content;
  final String messageType;
  final Map<String, dynamic>? attachment;
  final ChatParticipant sender;
  final bool isMe;
  final String status;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.messageType,
    this.attachment,
    required this.sender,
    required this.isMe,
    required this.status,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    print('🔍 ChatMessage.fromJson: Parsing message data: $json');
    
    final sender = ChatParticipant.fromJson(json['sender'] ?? {});
    print('🔍 ChatMessage.fromJson: Parsed sender: ${sender.name} (${sender.id})');
    
    final message = ChatMessage(
      id: json['_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'text',
      attachment: json['attachment'] as Map<String, dynamic>?,
      sender: sender,
      isMe: json['isMe'] == true,
      status: json['status']?.toString() ?? 'sent',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
    
    print('🔍 ChatMessage.fromJson: Created message: "${message.content}" from ${message.sender.name} (isMe: ${message.isMe})');
    return message;
  }
}
