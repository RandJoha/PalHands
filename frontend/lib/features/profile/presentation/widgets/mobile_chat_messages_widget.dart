import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MobileChatMessagesWidget extends StatefulWidget {
  const MobileChatMessagesWidget({super.key});

  @override
  State<MobileChatMessagesWidget> createState() => _MobileChatMessagesWidgetState();
}

class _MobileChatMessagesWidgetState extends State<MobileChatMessagesWidget> {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat Messages',
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          
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
        const SizedBox(height: 12),
        _buildChatThread(
          providerName: 'Mariam Hassan',
          lastMessage: 'Thank you for the booking',
          time: '1 hour ago',
          unreadCount: 0,
          serviceName: 'Elderly Care',
        ),
        const SizedBox(height: 12),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount.toString(),
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
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
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  serviceName,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastMessage,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
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