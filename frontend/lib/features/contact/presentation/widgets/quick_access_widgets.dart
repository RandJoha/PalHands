import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';

class QuickAccessWidgets extends StatelessWidget {
  const QuickAccessWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Use different layouts based on screen width
        if (screenWidth < 600) {
          // Two column layout for mobile screens
          return Column(
            children: [
              // First row - 2 items
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAccessCard(
                      icon: Icons.question_answer,
                      title: AppStrings.getString('viewFAQs', languageService.currentLanguage),
                      subtitle: 'Find answers quickly',
                      onTap: () {
                        Navigator.pushNamed(context, '/faqs');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAccessCard(
                      icon: Icons.chat,
                      title: AppStrings.getString('liveChat', languageService.currentLanguage),
                      subtitle: 'Get instant help',
                      onTap: () {
                        _showLiveChatDialog(context, languageService);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row - 2 items
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAccessCard(
                      icon: Icons.chat_bubble,
                      title: AppStrings.getString('whatsappSupport', languageService.currentLanguage),
                      subtitle: 'Chat on WhatsApp',
                      onTap: () {
                        _launchWhatsApp();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAccessCard(
                      icon: Icons.contact_phone,
                      title: AppStrings.getString('traditionalContact', languageService.currentLanguage),
                      subtitle: 'Email & Phone',
                      onTap: () {
                        _showTraditionalContactDialog(context, languageService);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Two column layout for wider screens
          return Column(
            children: [
              // First row - 2 items
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAccessCard(
                      icon: Icons.question_answer,
                      title: AppStrings.getString('viewFAQs', languageService.currentLanguage),
                      subtitle: 'Find answers quickly',
                      onTap: () {
                        Navigator.pushNamed(context, '/faqs');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAccessCard(
                      icon: Icons.chat,
                      title: AppStrings.getString('liveChat', languageService.currentLanguage),
                      subtitle: 'Get instant help',
                      onTap: () {
                        _showLiveChatDialog(context, languageService);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row - 2 items
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAccessCard(
                      icon: Icons.chat_bubble,
                      title: AppStrings.getString('whatsappSupport', languageService.currentLanguage),
                      subtitle: 'Chat on WhatsApp',
                      onTap: () {
                        _launchWhatsApp();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAccessCard(
                      icon: Icons.contact_phone,
                      title: AppStrings.getString('traditionalContact', languageService.currentLanguage),
                      subtitle: 'Email & Phone',
                      onTap: () {
                        _showTraditionalContactDialog(context, languageService);
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: AppColors.primary,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveChatDialog(BuildContext context, LanguageService languageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.getString('liveChat', languageService.currentLanguage),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Live chat is coming soon!',
              style: GoogleFonts.cairo(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'For now, please use our contact form or WhatsApp support.',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showTraditionalContactDialog(BuildContext context, LanguageService languageService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.getString('traditionalContact', languageService.currentLanguage),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildContactOption(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'info@palhands.com',
              onTap: () {
                Navigator.of(context).pop();
                _launchEmail('info@palhands.com');
              },
            ),
            const SizedBox(height: 12),
            _buildContactOption(
              icon: Icons.phone,
              title: 'Phone',
              subtitle: '+970 59 123 4567',
              onTap: () {
                Navigator.of(context).pop();
                _launchPhone('+970591234567');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _launchWhatsApp() async {
    const phoneNumber = '+970591234567';
    const message = 'Hello! I need help with PalHands.';
    final url = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
} 