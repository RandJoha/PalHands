import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class SupportHelpWidget extends StatefulWidget {
  const SupportHelpWidget({super.key});

  @override
  State<SupportHelpWidget> createState() => _SupportHelpWidgetState();
}

class _SupportHelpWidgetState extends State<SupportHelpWidget> {
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
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support & Help Center',
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.primary),
            title: Text('FAQs', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.support_agent, color: AppColors.primary),
            title: Text('Submit a Support Ticket', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.primary),
            title: Text('Previous Support Requests', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: AppColors.primary),
            title: Text('Live Chat with Support', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
} 