import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MobileMyReviewsWidget extends StatefulWidget {
  const MobileMyReviewsWidget({super.key});

  @override
  State<MobileMyReviewsWidget> createState() => _MobileMyReviewsWidgetState();
}

class _MobileMyReviewsWidgetState extends State<MobileMyReviewsWidget> {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Reviews',
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          
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
        const SizedBox(height: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      serviceName,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
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
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: GoogleFonts.cairo(
                  fontSize: 12,
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
                    fontSize: 12,
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