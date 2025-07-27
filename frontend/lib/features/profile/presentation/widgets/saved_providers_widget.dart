import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class SavedProvidersWidget extends StatefulWidget {
  const SavedProvidersWidget({super.key});

  @override
  State<SavedProvidersWidget> createState() => _SavedProvidersWidgetState();
}

class _SavedProvidersWidgetState extends State<SavedProvidersWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildProviders(context, languageService);
      },
    );
  }

  Widget _buildProviders(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('savedProviders', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),
          
          // Providers list
          _buildProvidersList(languageService),
        ],
      ),
    );
  }

  Widget _buildProvidersList(LanguageService languageService) {
    return Column(
      children: [
        _buildProviderItem(
          name: 'Fatima Al-Zahra',
          service: AppStrings.getString('homeCleaning', languageService.currentLanguage),
          rating: 4.8,
          price: '₪150',
          isAvailable: true,
          languageService: languageService,
        ),
        SizedBox(height: 16.h),
        _buildProviderItem(
          name: 'Mariam Hassan',
          service: AppStrings.getString('elderlyCare', languageService.currentLanguage),
          rating: 4.9,
          price: '₪200',
          isAvailable: true,
          languageService: languageService,
        ),
        SizedBox(height: 16.h),
        _buildProviderItem(
          name: 'Aisha Mohammed',
          service: AppStrings.getString('babysitting', languageService.currentLanguage),
          rating: 4.7,
          price: '₪120',
          isAvailable: false,
          languageService: languageService,
        ),
      ],
    );
  }

  Widget _buildProviderItem({
    required String name,
    required String service,
    required double rating,
    required String price,
    required bool isAvailable,
    required LanguageService languageService,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
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
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 30.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  service,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: AppColors.ratingFilled,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      rating.toString(),
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isAvailable ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        isAvailable ? AppStrings.getString('available', languageService.currentLanguage) : AppStrings.getString('unavailable', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: isAvailable ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              ElevatedButton(
                onPressed: isAvailable ? () {
                  // Handle book again
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                ),
                child: Text(
                  AppStrings.getString('bookAgain', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 