import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MobileSupportHelpWidget extends StatefulWidget {
  const MobileSupportHelpWidget({super.key});

  @override
  State<MobileSupportHelpWidget> createState() => _MobileSupportHelpWidgetState();
}

class _MobileSupportHelpWidgetState extends State<MobileSupportHelpWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildSupport(context, languageService);
      },
    );
  }

  Widget _buildSupport(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support & Help Center',
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.help_outline, color: AppColors.primary),
            title: Text('FAQs', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.support_agent, color: AppColors.primary),
            title: Text('Submit a Support Ticket', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.history, color: AppColors.primary),
            title: Text('Previous Support Requests', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.chat, color: AppColors.primary),
            title: Text('Live Chat with Support', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
} 