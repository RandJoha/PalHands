import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Shared imports
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/provider.dart';

class ChatFormDialog extends StatefulWidget {
  final ProviderModel provider;
  final VoidCallback? onMessageSent;

  const ChatFormDialog({
    super.key,
    required this.provider,
    this.onMessageSent,
  });

  @override
  State<ChatFormDialog> createState() => _ChatFormDialogState();
}

class _ChatFormDialogState extends State<ChatFormDialog> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    if (kDebugMode) {
      print('🚀 Chat form dialog - Starting to send message...');
      print('  - Message content: "${_messageController.text.trim()}"');
      print('  - Provider ID: ${widget.provider.id}');
      print('  - Provider name: ${widget.provider.name}');
      print('  - Provider services: ${widget.provider.services}');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (kDebugMode) {
        print('🔍 Chat form dialog - Auth service info:');
        print('  - Is authenticated: ${authService.isAuthenticated}');
        print('  - Token present: ${authService.token != null}');
        print('  - Current user: ${authService.currentUser?['email'] ?? 'None'}');
      }
      
      // Create or get chat first
      if (kDebugMode) {
        print('📱 Chat form dialog - Creating/getting chat...');
      }
      
      final chatResponse = await _chatService.createOrGetChat(
        widget.provider.id,
        serviceName: widget.provider.services.isNotEmpty ? widget.provider.services.first : null,
        authService: authService,
      );

      if (kDebugMode) {
        print('📱 Chat form dialog - Chat creation response:');
        print('  - Success: ${chatResponse['success']}');
        print('  - Message: ${chatResponse['message'] ?? 'No message'}');
        print('  - Chat ID: ${chatResponse['data']?['chat']?['_id'] ?? 'No chat ID'}');
      }

      if (chatResponse['success'] == true) {
        final chatId = chatResponse['data']['chat']['_id'];
        
        if (kDebugMode) {
          print('📱 Chat form dialog - Sending message to chat: $chatId');
        }
        
        // Send the message
        final messageResponse = await _chatService.sendMessage(
          chatId,
          _messageController.text.trim(),
          authService: authService,
        );

        if (kDebugMode) {
          print('📱 Chat form dialog - Message sending response:');
          print('  - Success: ${messageResponse['success']}');
          print('  - Message: ${messageResponse['message'] ?? 'No message'}');
        }

        if (messageResponse['success'] == true) {
          if (kDebugMode) {
            print('✅ Chat form dialog - Message sent successfully!');
            print('  - Calling onMessageSent callback...');
          }
          
          // Close dialog and show success message
          Navigator.of(context).pop();
          
          // Call the callback to refresh chat list
          widget.onMessageSent?.call();
          
          if (kDebugMode) {
            print('✅ Chat form dialog - Success message shown');
          }
          
          // Show success message with multiple options
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Message sent successfully!'),
                  SizedBox(height: 4),
                  Text('Click "View Chat" to see your message in the chat list.', 
                       style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'Refresh Now',
                textColor: Colors.white,
                onPressed: () {
                  if (kDebugMode) {
                    print('🔄 Chat form dialog - User clicked "Refresh Now" button');
                  }
                  widget.onMessageSent?.call();
                },
              ),
            ),
          );
          
          // Also show a more prominent dialog with options
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Message Sent!'),
              content: const Text('Your message has been sent successfully. Would you like to view it in the chat list?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Stay Here'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to user dashboard chat tab and refresh
                    Navigator.of(context).pushNamed('/user?tab=chats').then((_) {
                      if (kDebugMode) {
                        print('🔄 Chat form dialog - Navigating to user dashboard chat tab and refreshing');
                      }
                      // Add a small delay to ensure navigation completes
                      Future.delayed(const Duration(milliseconds: 500), () {
                        widget.onMessageSent?.call();
                      });
                    });
                  },
                  child: const Text('View Chat'),
                ),
              ],
            ),
          );
        } else {
          if (kDebugMode) {
            print('❌ Chat form dialog - Failed to send message: ${messageResponse['message']}');
          }
          setState(() {
            _error = messageResponse['message'] ?? 'Failed to send message';
            _isLoading = false;
          });
        }
      } else {
        if (kDebugMode) {
          print('❌ Chat form dialog - Failed to create chat: ${chatResponse['message']}');
        }
        setState(() {
          _error = chatResponse['message'] ?? 'Failed to create chat';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Chat form dialog - Exception occurred: $e');
      }
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final lang = languageService.currentLanguage;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Container(
            width: 400.w,
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                            widget.provider.name,
                            style: GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (widget.provider.services.isNotEmpty)
                            Text(
                              widget.provider.services.first,
                              style: GoogleFonts.cairo(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20.h),
                
                // Title
                Text(
                  AppStrings.getString('sendMessage', lang),
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Message input
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: AppStrings.getString('typeMessage', lang),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: EdgeInsets.all(12.w),
                  ),
                ),
                
                if (_error != null) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 20.h),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Text(
                          AppStrings.getString('cancel', lang),
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                AppStrings.getString('send', lang),
                                style: GoogleFonts.cairo(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
