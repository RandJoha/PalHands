import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/models/chat.dart';

class ChatConversationWidget extends StatefulWidget {
  final ChatModel chat;
  final Function(ChatMessage)? onMessageSent;
  final bool showBackButton;
  final VoidCallback? onBack;

  const ChatConversationWidget({
    super.key,
    required this.chat,
    this.onMessageSent,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  State<ChatConversationWidget> createState() => _ChatConversationWidgetState();
}

class _ChatConversationWidgetState extends State<ChatConversationWidget> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _error;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void didUpdateWidget(ChatConversationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the chat has changed, reload messages and scroll to bottom
    if (oldWidget.chat.id != widget.chat.id) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      print('🔍 ChatConversationWidget: Loading messages for chat: ${widget.chat.id}');
      print('🔍 ChatConversationWidget: Auth service: ${authService.isAuthenticated}');
      
      final response = await _chatService.getChatMessages(
        widget.chat.id,
        authService: authService,
      );
      
      print('🔍 ChatConversationWidget: Response received: ${response.keys.toList()}');
      print('🔍 ChatConversationWidget: Response success: ${response['success']}');
      
      if (response['success'] == true) {
        final messagesData = response['data']['messages'] as List<dynamic>;
        print('🔍 ChatConversationWidget: Raw messages data: $messagesData');
        print('🔍 ChatConversationWidget: Messages count: ${messagesData.length}');
        
        final parsedMessages = messagesData.map((json) {
          print('🔍 ChatConversationWidget: Parsing message: $json');
          final message = ChatMessage.fromJson(json);
          print('🔍 ChatConversationWidget: Parsed message - content: "${message.content}", isMe: ${message.isMe}, sender: ${message.sender.name}');
          return message;
        }).toList();
        
        print('🔍 ChatConversationWidget: Final parsed messages count: ${parsedMessages.length}');
        
        setState(() {
          _messages = parsedMessages;
          _isLoading = false;
        });
        
        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        

      } else {
        print('❌ ChatConversationWidget: Failed to load messages: ${response['message']}');
        setState(() {
          _error = response['message'] ?? 'Failed to load messages';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ ChatConversationWidget: Error loading messages: $e');
      setState(() {
        _error = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    print('🔍 ChatConversationWidget: Sending message: "$message" to chat: ${widget.chat.id}');

    setState(() {
      _isSending = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await _chatService.sendMessage(
        widget.chat.id, 
        message,
        authService: authService,
      );
      
      print('🔍 ChatConversationWidget: Send message response: ${response.keys.toList()}');
      print('🔍 ChatConversationWidget: Send message success: ${response['success']}');
      
      if (response['success'] == true) {
        final messageData = response['data']['message'];
        print('🔍 ChatConversationWidget: Message data received: $messageData');
        
        final newMessage = ChatMessage.fromJson(messageData);
        print('🔍 ChatConversationWidget: Parsed new message - content: "${newMessage.content}", isMe: ${newMessage.isMe}');
        
        setState(() {
          _messages.add(newMessage);
          _isSending = false;
        });
        
        print('🔍 ChatConversationWidget: Message added to list. Total messages: ${_messages.length}');
        
        _messageController.clear();
        
        if (widget.onMessageSent != null) {
          widget.onMessageSent!(newMessage);
        }
        
        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        print('❌ ChatConversationWidget: Failed to send message: ${response['message']}');
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ ChatConversationWidget: Error sending message: $e');
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildChatConversation(context, languageService);
      },
    );
  }

  Widget _buildChatConversation(BuildContext context, LanguageService languageService) {
    return SizedBox.expand(
      child: Column(
        children: [
          // Chat header
          _buildChatHeader(languageService),
          
          // Messages area
          Expanded(
            child: _buildMessagesArea(languageService),
          ),
          
          // Message input
          _buildMessageInput(languageService),
        ],
      ),
    );
  }

  Widget _buildChatHeader(LanguageService languageService) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (widget.showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: widget.onBack ?? () {},
              tooltip: languageService.isArabic ? 'رجوع' : 'Back',
            )
          else
            SizedBox(width: 12.w),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.participant.name,
                  style: GoogleFonts.cairo(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.chat.serviceName != null)
                  Text(
                    widget.chat.serviceName!,
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(LanguageService languageService) {
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
            Icon(
              Icons.error_outline,
              size: 48.sp,
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
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48.sp,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16.h),
            Text(
              languageService.isArabic ? 'لا توجد رسائل بعد' : 'No messages yet',
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                color: AppColors.textLight,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              languageService.isArabic ? 'ابدأ المحادثة!' : 'Start the conversation!',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final isRtl = languageService.isArabic;
  return ListView.builder(
      controller: _scrollController,
      // Directional padding: smaller on the trailing side so bubbles can reach the edge
      padding: EdgeInsetsDirectional.only(
    start: isRtl ? 4.w : 8.w,
    end: isRtl ? 8.w : 2.w,
        top: 16.h,
        bottom: 16.h,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        // Force each item to occupy full width so bubbles can align to edges
        return SizedBox(
          width: double.infinity,
          child: _buildMessageBubble(message, languageService),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, LanguageService languageService) {
    final isMe = message.isMe;
  // Use LayoutBuilder to compute max bubble width from actual available space
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
    // Reserve space for the leading avatar on incoming messages and keep
    // only a tiny trailing gutter so bubbles reach the visual edge.
    final double avatar = 32.w;
    final double spacer = 8.w;
    final double trailingGutter = 2.w;
    final double usedByLeading = isMe ? 0.0 : (avatar + spacer);
    final double maxBubbleWidth = (total - usedByLeading - trailingGutter).clamp(0.0, total).toDouble();

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: isMe ? null : Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: GoogleFonts.cairo(
                          fontSize: 18.sp,
                          color: isMe ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatTime(message.createdAt),
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          color: isMe ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(LanguageService languageService) {
    return Container(
      // Reduce inner gutters while keeping comfortable touch targets
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // TODO: Add file attachment functionality
            },
            icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
          ),
          // Proper keyboard handling: Enter to send, Shift+Enter for newline
          Expanded(
            child: RawKeyboardListener(
              focusNode: FocusNode(debugLabel: 'chat-input'),
              onKey: (event) {
                if (event is! RawKeyDownEvent) return;
                final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey.keyLabel == '\n';
                if (isEnter && !event.isShiftPressed && !_isSending) {
                  _sendMessage();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: languageService.isArabic ? 'اكتب رسالة...' : 'Type a message...',
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 18.sp,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            onPressed: _isSending ? null : _sendMessage,
            icon: _isSending
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
