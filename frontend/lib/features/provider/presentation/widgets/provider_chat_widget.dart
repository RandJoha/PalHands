import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/models/chat.dart';

class ProviderChatWidget extends StatefulWidget {
  final VoidCallback? onChatOpened;
  
  const ProviderChatWidget({super.key, this.onChatOpened});

  @override
  State<ProviderChatWidget> createState() => _ProviderChatWidgetState();
}

class _ProviderChatWidgetState extends State<ProviderChatWidget> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Add scroll controller
  final FocusNode _inputFocus = FocusNode();
  
  List<ChatModel> _chats = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMessages = false;
  String? _error;
  ChatModel? _selectedChat;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadProviderChats();
    _testAuthentication();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose(); // Dispose scroll controller
  _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadProviderChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the authenticated AuthService instance from Provider
      final authService = Provider.of<AuthService>(context, listen: false);
      
      print('Provider chat widget - Loading chats for provider');
      print('  - Auth service instance: ${authService.hashCode}');
      print('  - Is authenticated: ${authService.isAuthenticated}');
      print('  - Token present: ${authService.token != null}');
      print('  - Current user: ${authService.currentUser?['email'] ?? 'None'}');
      
      // Pass the authService to get proper authentication headers
      final response = await _chatService.getUserChats(authService: authService);
      print('Provider chat widget - Response received: ${response.keys.toList()}');
      
      if (mounted) {
        try {
          if (response['success'] == true && response['data'] != null) {
            final chatsData = response['data']['chats'] as List?;
            if (chatsData != null) {
              final chats = chatsData.map((chatData) {
                try {
                  return ChatModel.fromJson(chatData);
                } catch (parseError) {
                  print('Error parsing chat data: $parseError');
                  print('Chat data: $chatData');
                  return null;
                }
              }).whereType<ChatModel>().toList();
              
              setState(() {
                _chats = chats;
                _isLoading = false;
              });
            } else {
              setState(() {
                _chats = [];
                _isLoading = false;
              });
            }
          } else {
            setState(() {
              _chats = [];
              _isLoading = false;
            });
          }
        } catch (parseError) {
          print('Error parsing response: $parseError');
          print('Response: $response');
          setState(() {
            _chats = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load chats: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadChatMessages() async {
    if (_selectedChat == null) return;

    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      print('Provider chat widget - Loading messages for chat: ${_selectedChat!.id}');
      
      final response = await _chatService.getChatMessages(
        _selectedChat!.id,
        authService: authService,
      );
      
      if (mounted && response['success'] == true) {
        final messagesData = response['data']['messages'] as List?;
        if (messagesData != null) {
          final messages = messagesData.map((messageData) {
            try {
              return ChatMessage.fromJson(messageData);
            } catch (parseError) {
              print('Error parsing message data: $parseError');
              return null;
            }
          }).whereType<ChatMessage>().toList();
          
          setState(() {
            _messages = messages;
            _isLoadingMessages = false;
          });
          
          // Scroll to bottom after loading messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
          
          // Also try scrolling after a longer delay to ensure everything is rendered
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else {
          setState(() {
            _messages = [];
            _isLoadingMessages = false;
          });
        }
      } else {
        setState(() {
          _messages = [];
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      print('Provider chat widget - Error loading messages: $e');
      if (mounted) {
        setState(() {
          _messages = [];
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _testAuthentication() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      print('🔍 Provider chat widget - Testing authentication:');
      print('  - Auth service instance: ${authService.hashCode}');
      print('  - Is authenticated: ${authService.isAuthenticated}');
      print('  - Token present: ${authService.token != null}');
      print('  - Token length: ${authService.token?.length ?? 0}');
      print('  - Current user: ${authService.currentUser?['email'] ?? 'None'}');
      print('  - User role: ${authService.currentUser?['role'] ?? 'None'}');
      
      if (authService.token != null) {
        print('  - Token preview: ${authService.token!.substring(0, authService.token!.length > 30 ? 30 : authService.token!.length)}...');
      }
      
      // Test the chat API endpoint to verify authentication
      try {
        final response = await _chatService.getUserChats(authService: authService);
        print('✅ Provider chat widget - Authentication test successful');
        print('  - Response keys: ${response.keys.toList()}');
        print('  - Success: ${response['success']}');
      } catch (apiError) {
        print('❌ Provider chat widget - Authentication test failed: $apiError');
      }
    } catch (e) {
      print('❌ Provider chat widget - Authentication test error: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedChat == null || _messageController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final message = _messageController.text.trim();
      
      print('Provider chat widget - Sending message: $message');
      print('  - Chat ID: ${_selectedChat!.id}');
      print('  - Auth service: ${authService.hashCode}');
      print('  - Is authenticated: ${authService.isAuthenticated}');
      print('  - Token present: ${authService.token != null}');
      print('  - Current user: ${authService.currentUser?['email'] ?? 'None'}');
      
      final response = await _chatService.sendMessage(
        _selectedChat!.id,
        message,
        authService: authService,
      );
      
      print('Provider chat widget - Send message response: ${response.keys.toList()}');
      print('  - Success: ${response['success']}');
      print('  - Message: ${response['message']}');
      
      if (mounted && response['success'] == true) {
        print('Provider chat widget - Message sent successfully');
        _messageController.clear();
        
        // Refresh the messages to show the new message
        await _loadChatMessages();
        
        // Also refresh the chat list to update last message
        await _loadProviderChats();
      } else {
        print('Provider chat widget - Failed to send message: ${response['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: ${response['message'] ?? 'Unknown error'}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('Provider chat widget - Error sending message: $e');
      print('  - Error type: ${e.runtimeType}');
      print('  - Error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState()
                  : _buildChatList(languageService),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColors.error,
          ),
          SizedBox(height: 16.h),
          Text(
            _error!,
            style: GoogleFonts.cairo(
              fontSize: 16.sp,
              color: AppColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadProviderChats,
                         child: Consumer<LanguageService>(
               builder: (context, languageService, child) {
                 return Text(languageService.isArabic ? 'إعادة المحاولة' : 'Retry');
               },
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(LanguageService languageService) {
    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64.sp,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16.h),
                         Consumer<LanguageService>(
               builder: (context, languageService, child) {
                 return Text(
                   languageService.isArabic ? 'لا توجد محادثات بعد' : 'No chats yet',
                   style: GoogleFonts.cairo(
                     fontSize: 18.sp,
                     color: AppColors.textLight,
                     fontWeight: FontWeight.w500,
                   ),
                 );
               },
             ),
            SizedBox(height: 8.h),
            Text(
                                      languageService.isArabic 
                            ? 'ابدأ بتقديم الخدمات لاستقبال رسائل الدردشة' 
                            : 'Start providing services to receive chat messages',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // If a chat is selected, show the conversation
    if (_selectedChat != null) {
      return _buildChatConversation();
    }

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat,
                color: AppColors.primary,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                                        languageService.isArabic ? 'رسائل الدردشة للمزود' : 'Provider Chat Messages',
                style: GoogleFonts.cairo(
                  fontSize: 20.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Back button to return to chat list
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedChat = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to chat list',
              ),
            ],
          ),
        ),
        
        // Chat list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadProviderChats,
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                final isSelected = _selectedChat?.id == chat.id;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.w),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      chat.participant.name,
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),
                        Text(
                          chat.serviceName ?? 'Service',
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (chat.lastMessage != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            chat.lastMessage!.content,
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (chat.unreadCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '${chat.unreadCount}',
                              style: GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatTimeAgo(chat.updatedAt),
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedChat = chat;
                        _messages = [];
                      });
                      _loadChatMessages();
                      
                      // Notify parent that a chat was opened (for notification updates)
                      widget.onChatOpened?.call();
                      
                      // Scroll to bottom after a short delay to ensure messages are loaded
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted && _scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatConversation() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Column(
          children: [
            // Chat header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedChat = null;
                      });
                    },
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to chat list',
                  ),
                  SizedBox(width: 12.w),
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedChat!.participant.name,
                          style: GoogleFonts.cairo(
                            fontSize: 18.sp,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _selectedChat!.serviceName ?? 'Service',
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Messages area
            Expanded(
              child: Container(
                color: AppColors.background,
                child: _isLoadingMessages
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64.sp,
                                  color: AppColors.textLight,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  languageService.isArabic ? 'لا توجد رسائل بعد' : 'No messages yet',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18.sp,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  languageService.isArabic 
                                      ? 'ابدأ المحادثة مع ${_selectedChat!.participant.name}'
                                      : 'Start the conversation with ${_selectedChat!.participant.name}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController, // Add scroll controller
                            padding: EdgeInsets.all(16.w),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = message.isMe;
                              
                              return Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                child: Row(
                                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    if (!isMe) ...[
                                      CircleAvatar(
                                        radius: 16.r,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                        child: Icon(
                                          Icons.person,
                                          size: 16.sp,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                    ],
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 12.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isMe ? AppColors.primary : AppColors.white,
                                          borderRadius: BorderRadius.circular(16.r),
                                          border: Border.all(
                                            color: isMe ? AppColors.primary : AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          message.content,
                                          style: GoogleFonts.cairo(
                                            fontSize: 14.sp,
                                            color: isMe ? AppColors.white : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isMe) ...[
                                      SizedBox(width: 8.w),
                                      CircleAvatar(
                                        radius: 16.r,
                                        backgroundColor: AppColors.primary,
                                        child: Icon(
                                          Icons.person,
                                          size: 16.sp,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
            
            // Message input area
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: RawKeyboardListener(
                      focusNode: _inputFocus,
                      onKey: (RawKeyEvent event) {
                        if (event is RawKeyDownEvent) {
                          final isEnter = event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey.keyLabel == '\\n';
                          final isShift = event.isShiftPressed;
                          if (isEnter && !isShift) {
                            _sendMessage();
                          }
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _inputFocus,
                          autofocus: false,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: languageService.isArabic ? 'اكتب رسالة...' : 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                          ),
                          maxLines: null,
                          onSubmitted: (_) => _sendMessage(),
                          onEditingComplete: () {},
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      color: _isSending ? AppColors.textSecondary : AppColors.primary,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: IconButton(
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: AppColors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
