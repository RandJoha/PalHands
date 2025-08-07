import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class ReviewsWidget extends StatefulWidget {
  const ReviewsWidget({super.key});

  @override
  State<ReviewsWidget> createState() => _ReviewsWidgetState();
}

class _ReviewsWidgetState extends State<ReviewsWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildReviewsWidget(languageService);
      },
    );
  }

  Widget _buildReviewsWidget(LanguageService languageService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AppStrings.getString('reviews', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.greyDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.getString('manageReviewsRatings', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          // Reviews Overview
          _buildReviewsOverview(languageService),
          
          const SizedBox(height: 32),
          
          // Reviews List
          _buildReviewsList(languageService),
        ],
      ),
    );
  }

  Widget _buildReviewsOverview(LanguageService languageService) {
    final stats = [
      {
        'title': 'averageRating',
        'value': '4.8',
        'subtitle': 'outOf',
        'color': AppColors.primary,
        'icon': Icons.star,
      },
      {
        'title': 'totalReviews',
        'value': '156',
        'subtitle': '',
        'color': AppColors.success,
        'icon': Icons.rate_review,
      },
      {
        'title': 'positiveReviews',
        'value': '142',
        'subtitle': 'satisfied',
        'color': AppColors.success,
        'icon': Icons.thumb_up,
      },
      {
        'title': 'responseRate',
        'value': '95%',
        'subtitle': 'responded',
        'color': AppColors.warning,
        'icon': Icons.reply,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _buildStatCard(stats[index], languageService);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, LanguageService languageService) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              stat['icon'],
              size: 32,
              color: stat['color'],
            ),
            const SizedBox(height: 8),
            Text(
              stat['value'],
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.greyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.getString(stat['title'], languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (stat['subtitle'].isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                AppStrings.getString(stat['subtitle'], languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: AppColors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(LanguageService languageService) {
    final reviews = [
      {
        'id': '#RV001',
        'clientName': 'أحمد محمد',
        'service': 'homeCleaning',
        'rating': 5,
        'comment': languageService.isArabic 
            ? 'خدمة ممتازة جداً! كانت التنظيف احترافية ومهنية. سأحجز مرة أخرى بالتأكيد.'
            : 'Excellent service! The cleaning was professional and thorough. Will definitely book again.',
        'date': '2024-12-15',
        'status': 'responded',
      },
      {
        'id': '#RV002',
        'clientName': 'Sarah Johnson',
        'service': 'homeBabysitting',
        'rating': 4,
        'comment': languageService.isArabic
            ? 'مربية أطفال رائعة. أطفالي أحبوها وكانت صبورة جداً.'
            : 'Great babysitter. My kids loved her and she was very patient.',
        'date': '2024-12-14',
        'status': 'pending',
      },
      {
        'id': '#RV003',
        'clientName': 'فاطمة علي',
        'service': 'homeElderlyCare',
        'rating': 5,
        'comment': languageService.isArabic
            ? 'رعاية ممتازة لوالدتي. كانت الممرضة مهنية ومتعاطفة.'
            : 'Excellent care for my mother. The nurse was professional and compassionate.',
        'date': '2024-12-13',
        'status': 'responded',
      },
      {
        'id': '#RV004',
        'clientName': 'Michael Brown',
        'service': 'homeCookingServices',
        'rating': 4,
        'comment': languageService.isArabic
            ? 'طعام لذيذ وطازج. الشيف كان مهنياً ومهتماً بالتفاصيل.'
            : 'Delicious and fresh food. The chef was professional and detail-oriented.',
        'date': '2024-12-12',
        'status': 'pending',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('recentReviews', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            return _buildReviewCard(reviews[index], languageService);
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Client avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      review['clientName'][0],
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Client info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['clientName'],
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greyDark,
                        ),
                      ),
                      Text(
                        AppStrings.getString(review['service'], languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review['rating'] ? Icons.star : Icons.star_border,
                      size: 16,
                      color: index < review['rating'] ? AppColors.warning : AppColors.grey,
                    );
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Review comment
            Text(
              review['comment'],
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.greyDark,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Review actions
            Row(
              children: [
                Text(
                  review['date'],
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
                const Spacer(),
                if (review['status'] == 'pending') ...[
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      AppStrings.getString('respondToReview', languageService.currentLanguage),
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      AppStrings.getString('reportReview', languageService.currentLanguage),
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppStrings.getString('responded', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
