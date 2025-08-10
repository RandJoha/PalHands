import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class ChatMessagesWidget extends StatefulWidget {
  const ChatMessagesWidget({super.key});

  @override
  State<ChatMessagesWidget> createState() => _ChatMessagesWidgetState();
}

class _ChatMessagesWidgetState extends State<ChatMessagesWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildChat(context, languageService);
      },
    );
  }

  Widget _buildChat(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat Messages',
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),
          
          // Chat threads
          _buildChatThreads(languageService),
        ],
      ),
    );
  }

  Widget _buildChatThreads(LanguageService languageService) {
    return Column(
      children: [
        _buildChatThread(
          providerName: 'Fatima Al-Zahra',
          lastMessage: 'I will arrive in 10 minutes',
          time: '2 min ago',
          unreadCount: 2,
          serviceName: 'Home Cleaning',
        ),
        SizedBox(height: 12.h),
        _buildChatThread(
          providerName: 'Mariam Hassan',
          lastMessage: 'Thank you for the booking',
          time: '1 hour ago',
          unreadCount: 0,
          serviceName: 'Elderly Care',
        ),
        SizedBox(height: 12.h),
        _buildChatThread(
          providerName: 'Aisha Mohammed',
                      lastMessage: AppStrings.getString('serviceCompleted', languageService.currentLanguage),
          time: AppStrings.getString('yesterday', languageService.currentLanguage),
          unreadCount: 0,
                      serviceName: AppStrings.getString('babysitting', languageService.currentLanguage),
        ),
      ],
    );
  }

  Widget _buildChatThread({
    required String providerName,
    required String lastMessage,
    required String time,
    required int unreadCount,
    required String serviceName,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24.sp,
                ),
              ),
              if (unreadCount > 0)
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
                        unreadCount.toString(),
                        style: GoogleFonts.cairo(
                          fontSize: 10.sp,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      providerName,
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  serviceName,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  lastMessage,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 