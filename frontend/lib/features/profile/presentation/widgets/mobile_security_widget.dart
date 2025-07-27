import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MobileSecurityWidget extends StatefulWidget {
  const MobileSecurityWidget({super.key});

  @override
  State<MobileSecurityWidget> createState() => _MobileSecurityWidgetState();
}

class _MobileSecurityWidgetState extends State<MobileSecurityWidget> {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security',
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.lock, color: AppColors.primary),
            title: Text('Change Password', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: AppColors.error),
            title: Text('Delete Account', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.history, color: AppColors.primary),
            title: Text('Login History', style: GoogleFonts.cairo(fontSize: 16)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
} 