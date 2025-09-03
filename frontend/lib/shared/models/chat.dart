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
    return ChatModel(
      id: json['_id']?.toString() ?? '',
      participant: ChatParticipant.fromJson(json['participant'] ?? {}),
      lastMessage: json['lastMessage'] != null 
          ? _parseLastMessage(json['lastMessage']) 
          : null,
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
      serviceName: json['serviceName']?.toString(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // Helper method to parse lastMessage which has a different structure than ChatMessage
  static ChatMessage _parseLastMessage(Map<String, dynamic> json) {
    return ChatMessage(
      id: '', // Last message doesn't have an ID
      content: json['content']?.toString() ?? json['text']?.toString() ?? '',
      messageType: 'text',
      attachment: null,
      sender: ChatParticipant.fromJson(json['sender'] ?? {}),
      isMe: false, // We don't know if it's from the current user in this context
      status: 'sent',
      createdAt: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
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
    return ChatParticipant(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      providerId: json['providerId'] is int ? json['providerId'] : int.tryParse(json['providerId']?.toString() ?? ''),
      role: json['role']?.toString() ?? 'provider',
    );
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
    return ChatMessage(
      id: json['_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'text',
      attachment: json['attachment'] as Map<String, dynamic>?,
      sender: ChatParticipant.fromJson(json['sender'] ?? {}),
      isMe: json['isMe'] == true,
      status: json['status']?.toString() ?? 'sent',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
