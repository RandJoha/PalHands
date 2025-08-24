import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MyReviewsWidget extends StatefulWidget {
  const MyReviewsWidget({super.key});

  @override
  State<MyReviewsWidget> createState() => _MyReviewsWidgetState();
}

class _MyReviewsWidgetState extends State<MyReviewsWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildReviews(context, languageService);
      },
    );
  }

  Widget _buildReviews(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Reviews',
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 24.h),
          
          // Reviews list
          _buildReviewsList(),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return Column(
      children: [
        _buildReviewItem(
          providerName: 'Fatima Al-Zahra',
          serviceName: 'Home Cleaning',
          rating: 5,
          review: 'Excellent service! Very professional and thorough.',
          date: '2 days ago',
        ),
        SizedBox(height: 16.h),
        _buildReviewItem(
          providerName: 'Mariam Hassan',
          serviceName: 'Elderly Care',
          rating: 4,
          review: 'Good care for my mother. Would recommend.',
          date: '1 week ago',
        ),
      ],
    );
  }

  Widget _buildReviewItem({
    required String providerName,
    required String serviceName,
    required int rating,
    required String review,
    required String date,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: GoogleFonts.cairo(
                        fontSize: 16.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      serviceName,
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: AppColors.ratingFilled,
                    size: 20.sp,
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            review,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Handle edit review
                },
                child: Text(
                  'Edit Review',
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppColors.primary,
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