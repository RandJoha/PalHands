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
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            
            // Responsive breakpoints
            final isDesktop = screenWidth > 1200;
            final isTablet = screenWidth > 768 && screenWidth <= 1200;
            final isMobile = screenWidth <= 768;
            
            return _buildReviewsWidget(languageService, isMobile, isTablet, isDesktop, screenWidth);
          },
        );
      },
    );
  }

  Widget _buildReviewsWidget(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(languageService, isMobile, isTablet, isDesktop),
          
          SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
          
          // Reviews Overview
          _buildReviewsOverview(languageService, isMobile, isTablet, isDesktop, screenWidth),
          
          SizedBox(height: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0)),
          
          // Reviews List
          _buildReviewsList(languageService, isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and subtitle
        Text(
          AppStrings.getString('reviews', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0),
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        SizedBox(height: isMobile ? 2.0 : (isTablet ? 4.0 : 6.0)),
        Text(
          AppStrings.getString('manageClientReviewsFeedback', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
            color: AppColors.grey,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
        
        // Action buttons
        Row(
          children: [
            // Reply to all button
            Expanded(
              child: Container(
                height: isMobile ? 32 : (isTablet ? 36 : 40), // Reduced height
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      // TODO: Reply to all reviews
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.reply_all,
                          size: isMobile ? 14 : (isTablet ? 16 : 18), // Smaller icon
                          color: AppColors.white,
                        ),
                        SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)), // Reduced spacing
                        Text(
                          AppStrings.getString('replyToAll', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 11.0 : (isTablet ? 12.0 : 13.0), // Smaller font
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewsOverview(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop, double screenWidth) {
    final stats = [
      {
        'title': 'averageRating',
        'value': '4.8',
        'color': AppColors.success,
        'icon': Icons.star,
      },
      {
        'title': 'totalReviews',
        'value': '156',
        'color': AppColors.primary,
        'icon': Icons.rate_review,
      },
      {
        'title': 'positiveReviews',
        'value': '142',
        'color': AppColors.success,
        'icon': Icons.thumb_up,
      },
      {
        'title': 'pendingReplies',
        'value': '8',
        'color': AppColors.warning,
        'icon': Icons.pending_actions,
      },
    ];

    // Responsive grid configuration for stats cards - More compact design
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;
    
    if (isMobile) {
      crossAxisCount = 2; // 2x2 grid on mobile
      childAspectRatio = 2.5; // More compact cards on mobile
      crossAxisSpacing = 8.0;
      mainAxisSpacing = 8.0;
    } else if (isTablet) {
      crossAxisCount = 2; // 2x2 grid on tablet
      childAspectRatio = 2.2; // More compact cards on tablet
      crossAxisSpacing = 12.0;
      mainAxisSpacing = 12.0;
    } else {
      crossAxisCount = 4; // 4 columns on desktop
      childAspectRatio = 2.0; // More compact cards on desktop
      crossAxisSpacing = 16.0;
      mainAxisSpacing = 16.0;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        return _buildStatCard(stats[index], languageService, isMobile, isTablet, isDesktop);
      },
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat, LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)), // Reduced padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)), // Reduced icon container padding
              decoration: BoxDecoration(
                color: stat['color'].withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                stat['icon'],
                size: isMobile ? 18 : (isTablet ? 20 : 24), // Slightly smaller icons
                color: stat['color'],
              ),
            ),
            SizedBox(height: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)), // Reduced spacing
            Text(
              stat['value'],
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 16.0 : (isTablet ? 20.0 : 24.0), // Slightly smaller font
                fontWeight: FontWeight.bold,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: isMobile ? 1.0 : (isTablet ? 2.0 : 3.0)), // Reduced spacing
            Text(
              AppStrings.getString(stat['title'], languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 9.0 : (isTablet ? 10.0 : 11.0), // Slightly smaller font
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
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
        'service': 'babysitting',
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
        'service': 'elderlyCare',
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
        'service': 'homeCooking',
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
            fontSize: isMobile ? 18.0 : (isTablet ? 20.0 : 22.0),
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            return _buildReviewCard(reviews[index], languageService, isMobile, isTablet, isDesktop);
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : (isTablet ? 14.0 : 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with client info and rating
            Row(
              children: [
                // Client avatar
                CircleAvatar(
                  radius: isMobile ? 18 : (isTablet ? 20 : 24),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  child: Text(
                    review['clientName'][0].toUpperCase(),
                    style: GoogleFonts.cairo(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : (isTablet ? 16 : 18),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 10.0 : (isTablet ? 12.0 : 14.0)),
                
                // Client details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['clientName'],
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 14.0 : (isTablet ? 16.0 : 18.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.greyDark,
                        ),
                      ),
                      SizedBox(height: isMobile ? 2.0 : (isTablet ? 3.0 : 4.0)),
                      Text(
                        AppStrings.getString(review['service'], languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 11.0 : (isTablet ? 12.0 : 13.0),
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Rating
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0), 
                    vertical: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: isMobile ? 14 : (isTablet ? 16 : 18),
                        color: AppColors.warning,
                      ),
                      SizedBox(width: isMobile ? 3.0 : (isTablet ? 4.0 : 6.0)),
                      Text(
                        review['rating'].toString(),
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.greyDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
            
            // Review text
            Text(
              review['comment'],
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : (isTablet ? 13.0 : 14.0),
                color: AppColors.greyDark,
                height: 1.4,
              ),
            ),
            SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
            
            // Footer with date and actions
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: isMobile ? 12 : (isTablet ? 14 : 16),
                  color: AppColors.grey,
                ),
                SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)),
                Text(
                  review['date'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                    color: AppColors.grey,
                  ),
                ),
                const Spacer(),
                
                // Reply button
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0), 
                    vertical: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        // TODO: Reply to review
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply,
                            size: isMobile ? 14 : (isTablet ? 16 : 18),
                            color: AppColors.primary,
                          ),
                          SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)),
                          Text(
                            AppStrings.getString('reply', languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
