import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/models/chat.dart';
import 'chat_conversation_widget.dart';

class MobileChatMessagesWidget extends StatefulWidget {
  const MobileChatMessagesWidget({super.key});

  @override
  State<MobileChatMessagesWidget> createState() => _MobileChatMessagesWidgetState();
}

class _MobileChatMessagesWidgetState extends State<MobileChatMessagesWidget> {
  final ChatService _chatService = ChatService();
  List<ChatModel> _chats = [];
  bool _isLoading = true;
  String? _error;
  ChatModel? _selectedChat; // Add selected chat state

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (kDebugMode) {
      print('📱 Mobile chat messages widget - Loading chats...');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the auth service to ensure proper authentication
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (kDebugMode) {
        print('🔍 Mobile chat messages widget - Loading chats with auth service:');
        print('  - Is authenticated: ${authService.isAuthenticated}');
        print('  - Token present: ${authService.token != null}');
        print('  - Token length: ${authService.token?.length ?? 0}');
        print('  - Current user: ${authService.currentUser?['email'] ?? 'None'}');
      }
      
      final response = await _chatService.getUserChats(authService: authService);
      
      if (kDebugMode) {
        print('📱 Mobile chat messages widget - API response:');
        print('  - Status: ${response['success']}');
        print('  - Message: ${response['message'] ?? 'No message'}');
        print('  - Full response: $response');
      }
      
      if (response['success'] == true) {
        final chatsData = response['data']['chats'] as List<dynamic>;
        
        if (kDebugMode) {
          print('📱 Mobile chat messages widget - Raw chats data:');
          print('  - Number of chats: ${chatsData.length}');
          for (int i = 0; i < chatsData.length; i++) {
            final chat = chatsData[i];
            print('  - Chat $i:');
            print('    - ID: ${chat['_id']}');
            print('    - Participant: ${chat['participant']?['name'] ?? 'Unknown'}');
            print('    - Last message: ${chat['lastMessage']?['content'] ?? 'No message'}');
          }
        }
        
        setState(() {
          _chats = chatsData.map((json) {
            try {
              return ChatModel.fromJson(json);
            } catch (e) {
              if (kDebugMode) {
                print('❌ Mobile chat messages widget - Error parsing chat: $e');
              }
              // Return a default chat model to prevent crashes
              return ChatModel(
                id: json['_id']?.toString() ?? 'error',
                participant: ChatParticipant(
                  id: json['participant']?['_id']?.toString() ?? 'error',
                  name: json['participant']?['name']?.toString() ?? 'Unknown',
                  email: json['participant']?['email']?.toString() ?? '',
                  role: 'provider',
                ),
                lastMessage: null,
                unreadCount: 0,
                serviceName: null,
                updatedAt: DateTime.now(),
              );
            }
          }).toList();
          _isLoading = false;
        });
        
        if (kDebugMode) {
          print('📱 Mobile chat messages widget - Successfully loaded ${_chats.length} chats');
          print('  - All chat IDs: ${_chats.map((c) => '${c.id}:${c.participant.name}').join(', ')}');
          for (final chat in _chats) {
            print('  - ${chat.participant.name}: ${chat.lastMessage?.content ?? 'No message'}');
            print('    - Chat ID: ${chat.id}');
            print('    - Last message time: ${chat.lastMessage?.createdAt}');
            print('    - Updated at: ${chat.updatedAt}');
            print('    - Chat object hash: ${chat.hashCode}');
          }
        }
      } else {
        if (kDebugMode) {
          print('❌ Mobile chat messages widget - API returned error: ${response['message']}');
        }
        setState(() {
          _error = response['message'] ?? 'Failed to load chats';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mobile chat messages widget - Exception occurred: $e');
      }
      setState(() {
        _error = 'Failed to load chats: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildChat(context, languageService);
      },
    );
  }

  Widget _buildChat(BuildContext context, LanguageService languageService) {
    // New layout: 2 parts - left sidebar covers full width, bottom input at bottom
    return Column(
      children: [
        // Main content area - Chat list and conversation side by side
        Expanded(
          child: Row(
            children: [
              // Chat List (left side) - Fixed width for chat list
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    right: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        border: Border(
                          bottom: BorderSide(color: AppColors.border, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Chat Messages',
                            style: GoogleFonts.cairo(
                              fontSize: 22,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chat list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadChats,
                        child: SingleChildScrollView(
                          child: _buildChatThreads(languageService),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Conversation Area (right side) - Takes remaining width
              Expanded(
                child: Container(
                  color: AppColors.background,
                  child: _selectedChat != null
                      ? ChatConversationWidget(
                          chat: _selectedChat!,
                          onMessageSent: _handleMessageSent,
                        )
                      : _buildEmptyConversationArea(),
                ),
              ),
            ],
          ),
        ),
        

      ],
    );
  }

  Widget _buildEmptyConversationArea() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a chat to start messaging',
              style: GoogleFonts.cairo(
                fontSize: 22,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a conversation from the list on the left',
              style: GoogleFonts.cairo(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatThreads(LanguageService languageService) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.cairo(
                fontSize: 20,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No chats yet',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    // Return a list of chat threads with proper constraints
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildChatThread(
          chat: _chats[index],
          languageService: languageService,
        );
      },
    );
  }

  Widget _buildChatThread({
    required ChatModel chat,
    required LanguageService languageService,
  }) {
    final lastMessage = chat.lastMessage;
    final timeAgo = _getTimeAgo(chat.updatedAt);
    
    return GestureDetector(
      onTap: () {
        if (kDebugMode) {
          print('📱 Mobile chat messages widget - Chat selected: ${chat.id}');
          print('  - Participant: ${chat.participant.name}');
          print('  - Service: ${chat.serviceName}');
          print('  - Chat object hash: ${chat.hashCode}');
          print('  - All chats in list: ${_chats.map((c) => '${c.id}:${c.participant.name}').join(', ')}');
          print('  - Previous selected chat: ${_selectedChat?.id}:${_selectedChat?.participant.name}');
          print('  - Previous selected chat hash: ${_selectedChat?.hashCode}');
        }
        
        // Select the chat
        setState(() {
          _selectedChat = chat;
        });
        
        if (kDebugMode) {
          print('  - New selected chat hash: ${_selectedChat?.hashCode}');
        }
      },
              child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _selectedChat?.id == chat.id 
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedChat?.id == chat.id 
                  ? AppColors.primary
                  : AppColors.border,
              width: _selectedChat?.id == chat.id ? 2 : 1,
            ),
          ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                if (chat.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          chat.unreadCount.toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat.participant.name,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (chat.serviceName != null)
                    Text(
                      chat.serviceName!,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  if (chat.serviceName != null) const SizedBox(height: 4),
                  Text(
                    lastMessage?.content ?? 'No messages yet',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      color: chat.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 7).floor()} weeks ago';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _handleMessageSent(ChatMessage newMessage) {
    if (kDebugMode) {
      print('📱 Mobile chat messages widget - Message sent: ${newMessage.id}');
      print('  - Content: ${newMessage.content}');
      print('  - Chat ID: ${_selectedChat?.id}');
      print('  - Selected chat participant: ${_selectedChat?.participant.name}');
      print('  - Total chats in list: ${_chats.length}');
    }
    
    // Update the selected chat's last message and timestamp
    if (_selectedChat != null) {
      setState(() {
        // Find and update the chat in the list
        final chatIndex = _chats.indexWhere((chat) => chat.id == _selectedChat!.id);
        if (kDebugMode) {
          print('🔍 Mobile chat messages widget - Found chat at index: $chatIndex');
          print('  - Chat to update: ${_chats[chatIndex].participant.name}');
          print('  - Chat ID: ${_chats[chatIndex].id}');
        }
        
        if (chatIndex != -1) {
          // Create updated chat with new last message
          final updatedChat = ChatModel(
            id: _chats[chatIndex].id,
            participant: _chats[chatIndex].participant,
            lastMessage: newMessage,
            unreadCount: _chats[chatIndex].unreadCount,
            serviceName: _chats[chatIndex].serviceName,
            updatedAt: DateTime.now(),
          );
          
          // Update the chat in the list
          _chats[chatIndex] = updatedChat;
          
          // Update the selected chat reference
          _selectedChat = updatedChat;
          
          if (kDebugMode) {
            print('✅ Mobile chat messages widget - Chat updated with new message');
            print('  - Updated chat: ${updatedChat.participant.name}');
            print('  - New last message: ${newMessage.content}');
          }
        }
      });
    }
  }
} 