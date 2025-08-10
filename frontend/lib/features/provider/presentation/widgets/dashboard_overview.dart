import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class DashboardOverviewWidget extends StatefulWidget {
  const DashboardOverviewWidget({super.key});

  @override
  State<DashboardOverviewWidget> createState() => _DashboardOverviewWidgetState();
}

class _DashboardOverviewWidgetState extends State<DashboardOverviewWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildDashboardOverview(languageService);
      },
    );
  }

  Widget _buildDashboardOverview(LanguageService languageService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(languageService),
          
          const SizedBox(height: 32),
          
          // Quick Stats
          _buildQuickStats(languageService),
          
          const SizedBox(height: 32),
          
          // Recent Activity
          _buildRecentActivity(languageService),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Welcome message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.getString('welcomeBack', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.getString('providerDashboard', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${AppStrings.getString('thisWeek', languageService.currentLanguage)}: \$320',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Dashboard icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.dashboard,
              size: 40,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(LanguageService languageService) {
    final stats = [
      {
        'title': 'totalBookings',
        'value': '48',
        'change': '+12%',
        'isPositive': true,
        'icon': Icons.calendar_today,
        'color': AppColors.primary,
      },
      {
        'title': 'activeServices',
        'value': '4',
        'change': '+1',
        'isPositive': true,
        'icon': Icons.work,
        'color': AppColors.success,
      },
      {
        'title': 'totalEarnings',
        'value': '\$2,450',
        'change': '+8.5%',
        'isPositive': true,
        'icon': Icons.attach_money,
        'color': AppColors.warning,
      },
      {
        'title': 'averageRating',
        'value': '4.8',
        'change': '+0.2',
        'isPositive': true,
        'icon': Icons.star,
        'color': AppColors.primary,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('quickStats', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            return _buildStatCard(stats[index], languageService);
          },
        ),
      ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stat['color'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stat['icon'],
                    color: stat['color'],
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: stat['isPositive'] 
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stat['change'],
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: stat['isPositive'] ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(LanguageService languageService) {
    final activities = [
      {
        'type': 'booking',
        'title': 'newBooking',
        'description': 'newBookingDescription',
        'time': '2 hours ago',
        'icon': Icons.calendar_today,
        'color': AppColors.primary,
      },
      {
        'type': 'review',
        'title': 'newReview',
        'description': 'newReviewDescription',
        'time': '4 hours ago',
        'icon': Icons.star,
        'color': AppColors.warning,
      },
      {
        'type': 'payment',
        'title': 'paymentReceived',
        'description': 'paymentReceivedDescription',
        'time': '6 hours ago',
        'icon': Icons.payment,
        'color': AppColors.success,
      },
      {
        'type': 'service',
        'title': 'serviceCompleted',
        'description': 'serviceCompletedDescription',
        'time': '1 day ago',
        'icon': Icons.check_circle,
        'color': AppColors.success,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('recentActivity', languageService.currentLanguage),
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
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return _buildActivityCard(activities[index], languageService);
          },
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            // Activity icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: activity['color'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                activity['icon'],
                color: activity['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Activity details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.getString(activity['title'], languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.getString(activity['description'], languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity['time'],
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.grey,
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
