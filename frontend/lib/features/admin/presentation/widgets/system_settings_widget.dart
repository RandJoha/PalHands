import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

class SystemSettingsWidget extends StatelessWidget {
  const SystemSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.all(screenWidth > 1400 ? 24 : screenWidth > 1024 ? 20 : 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings,
              size: screenWidth > 1400 ? 80 : screenWidth > 1024 ? 70 : 60,
              color: AppColors.primary,
            ),
            SizedBox(height: screenWidth > 1400 ? 24 : screenWidth > 1024 ? 20 : 16),
            Text(
              'System Settings',
              style: GoogleFonts.cairo(
                fontSize: screenWidth > 1400 ? 32 : screenWidth > 1024 ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: screenWidth > 1400 ? 16 : screenWidth > 1024 ? 12 : 8),
            Text(
              'Manage platform settings, feature flags, and configurations',
              style: GoogleFonts.cairo(
                fontSize: screenWidth > 1400 ? 18 : screenWidth > 1024 ? 16 : 14,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth > 1400 ? 32 : screenWidth > 1024 ? 24 : 20),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 1400 ? 24 : screenWidth > 1024 ? 20 : 16,
                vertical: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 10 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction,
                    color: AppColors.secondary,
                    size: screenWidth > 1400 ? 24 : screenWidth > 1024 ? 20 : 18,
                  ),
                  SizedBox(width: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 10 : 8),
                  Text(
                    '⚙️ Coming Soon',
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 