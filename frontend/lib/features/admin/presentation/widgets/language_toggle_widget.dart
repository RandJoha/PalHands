import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class LanguageToggleWidget extends StatelessWidget {
  final bool isCollapsed;
  final double screenWidth;

  const LanguageToggleWidget({
    super.key,
    required this.isCollapsed,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final isArabic = languageService.isArabic;
        
        if (isCollapsed) {
          return _buildCollapsedToggle(context, languageService, isArabic);
        } else {
          return _buildExpandedToggle(context, languageService, isArabic);
        }
      },
    );
  }

  Widget _buildCollapsedToggle(BuildContext context, LanguageService languageService, bool isArabic) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => languageService.toggleLanguage(),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language flag/icon
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isArabic ? AppColors.primary : AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      isArabic ? 'ع' : 'EN',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedToggle(BuildContext context, LanguageService languageService, bool isArabic) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => languageService.toggleLanguage(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Language flag/icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isArabic ? AppColors.primary : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      isArabic ? 'ع' : 'EN',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: 10),
                
                // Language text
                Expanded(
                  child: Text(
                    isArabic 
                      ? AppStrings.getString('arabicLanguage', 'ar')
                      : AppStrings.getString('englishLanguage', 'en'),
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                
                // Toggle icon
                Icon(
                  Icons.language,
                  color: AppColors.primary,
                  size: screenWidth > 1400 ? 18 : 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 