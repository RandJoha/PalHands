import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class SecurityWidget extends StatefulWidget {
  const SecurityWidget({super.key});

  @override
  State<SecurityWidget> createState() => _SecurityWidgetState();
}

class _SecurityWidgetState extends State<SecurityWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildSecurity(context, languageService);
      },
    );
  }

  Widget _buildSecurity(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),
          ListTile(
            leading: const Icon(Icons.lock, color: AppColors.primary),
            title: Text('Change Password', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: Text('Delete Account', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.primary),
            title: Text('Login History', style: GoogleFonts.cairo(fontSize: 16.sp)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
} 