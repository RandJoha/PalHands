import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/chat_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/models/chat.dart';

// Widget imports
import 'chat_conversation_widget.dart';

class ChatMessagesWidget extends StatefulWidget {
  const ChatMessagesWidget({super.key});

  @override
  State<ChatMessagesWidget> createState() => ChatMessagesWidgetState();
}

// Public State class to allow external access via GlobalKey (e.g., to refresh chats)
class ChatMessagesWidgetState extends State<ChatMessagesWidget> {
  final ChatService _chatService = ChatService();
  
  List<ChatModel> _chats = [];
  ChatModel? _selectedChat;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await _chatService.getUserChats(authService: authService);
      
      if (response['success'] == true) {
        final chatsData = response['data']['chats'] as List<dynamic>;
        final parsedChats = chatsData.map((json) => ChatModel.fromJson(json)).toList();
        
        setState(() {
          _chats = parsedChats;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load chats';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load chats: $e';
        _isLoading = false;
      });
    }
  }

  // Public method to allow parent widgets to trigger a refresh safely
  Future<void> refreshChats() async {
    await _loadChats();
  }

  void _openChat(ChatModel chat) {
    print('Opening chat: ${chat.participant.name} (ID: ${chat.id})');
    setState(() {
      _selectedChat = chat;
    });
    print('Selected chat set to: ${_selectedChat?.participant.name}');
  }

  void _handleMessageSent(ChatMessage message) {
    // Update the last message in the chat list
    setState(() {
      final chatIndex = _chats.indexWhere((chat) => chat.id == _selectedChat!.id);
      if (chatIndex != -1) {
        // Create a new chat object with updated values
        final updatedChat = ChatModel(
          id: _chats[chatIndex].id,
          participant: _chats[chatIndex].participant,
          lastMessage: message,
          unreadCount: _chats[chatIndex].unreadCount,
          serviceName: _chats[chatIndex].serviceName,
          updatedAt: DateTime.now(),
        );
        _chats[chatIndex] = updatedChat;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        // Force the chat to take all available space to avoid right-side gaps.
        return SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 768;
              // Compact layout (mobile): show either the list or the conversation fullscreen
              if (isCompact) {
                return _buildCompactChat(languageService);
              }

              // Wide layout (tablet/desktop): list + conversation side by side
              return _buildWideChat(languageService, constraints.maxWidth);
            },
          ),
        );
      },
    );
  }

  Widget _buildWideChat(LanguageService languageService, double maxWidth) {
    // Calculate a flexible list width (max 360, min 280)
    final listWidth = maxWidth.clamp(700, double.infinity) == maxWidth
        ? 300.0
        : (maxWidth * 0.28).clamp(280.0, 360.0);

    return Row(
      children: [
        // Chat List
        Container(
          width: listWidth,
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              right: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Column(
            children: [
              _buildListHeader(languageService),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadChats,
                  child: SingleChildScrollView(child: _buildChatThreads(languageService)),
                ),
              ),
            ],
          ),
        ),
        // Conversation Area
        Expanded(
          child: Container(
            color: AppColors.background,
            child: _selectedChat != null
                ? ChatConversationWidget(
                    key: ValueKey(_selectedChat!.id),
                    chat: _selectedChat!,
                    onMessageSent: _handleMessageSent,
                    showBackButton: false,
                  )
                : _buildEmptyConversationArea(),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactChat(LanguageService languageService) {
    // Show either list or conversation fullscreen
    if (_selectedChat == null) {
      return Column(
        children: [
          _buildListHeader(languageService),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadChats,
              child: SingleChildScrollView(child: _buildChatThreads(languageService)),
            ),
          ),
        ],
      );
    }

    return ChatConversationWidget(
      key: ValueKey(_selectedChat!.id),
      chat: _selectedChat!,
      onMessageSent: _handleMessageSent,
      showBackButton: true,
      onBack: () => setState(() => _selectedChat = null),
    );
  }

  Widget _buildListHeader(LanguageService languageService) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: const Border(
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
          Expanded(
            child: Text(
              languageService.isArabic ? 'رسائل الدردشة' : 'Chat Messages',
              style: GoogleFonts.cairo(
                fontSize: 22.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyConversationArea() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80.sp,
                color: AppColors.textLight,
              ),
              SizedBox(height: 16.h),
              Text(
                languageService.isArabic 
                    ? 'اختر محادثة لبدء المراسلة' 
                    : 'Select a chat to start messaging',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
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
              onPressed: _loadChats,
              child: Text(languageService.isArabic ? 'إعادة المحاولة' : 'Retry'),
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
            Icon(
              Icons.chat_bubble_outline,
              size: 48.sp,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16.h),
            Text(
              languageService.isArabic ? 'لا توجد محادثات بعد' : 'No chats yet',
              style: GoogleFonts.cairo(
                fontSize: 16.sp,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _chats.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
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
    
    // Get display name - handle empty or missing names
    final displayName = chat.participant.name.isNotEmpty 
        ? chat.participant.name 
        : (languageService.isArabic ? 'مستخدم غير معروف' : 'Unknown User');
    
    return GestureDetector(
      onTap: () {
        _openChat(chat);
      },
      child: Container(
        padding: EdgeInsets.all(16.w), // Reduced padding for more content space
        decoration: BoxDecoration(
          color: _selectedChat?.id == chat.id 
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: _selectedChat?.id == chat.id 
                ? AppColors.primary
                : AppColors.border,
            width: _selectedChat?.id == chat.id ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with unread badge
            Stack(
              children: [
                Container(
                  width: 45.w, // Slightly smaller avatar
                  height: 45.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(22.5.r),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 22.sp,
                  ),
                ),
                if (chat.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 20.w,
                      height: 20.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          chat.unreadCount.toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 16.w), // Reduced spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: GoogleFonts.cairo(
                            fontSize: 16.sp, // Slightly smaller font
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: 12.w), // Reduced spacing
                      Text(
                        timeAgo,
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp, // Smaller timestamp
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h), // Reduced spacing
                  if (chat.serviceName != null && chat.serviceName!.isNotEmpty)
                    Text(
                      chat.serviceName!,
                      style: GoogleFonts.cairo(
                        fontSize: 13.sp, // Smaller service name
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  SizedBox(height: 6.h), // Reduced spacing
                  if (lastMessage != null)
                    Text(
                      lastMessage.content,
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp, // Smaller last message
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
} 