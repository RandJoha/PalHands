import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class DashboardHomeWidget extends StatefulWidget {
  const DashboardHomeWidget({super.key});

  @override
  State<DashboardHomeWidget> createState() => _DashboardHomeWidgetState();
}

class _DashboardHomeWidgetState extends State<DashboardHomeWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildDashboard(context, languageService);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          _buildWelcomeSection(languageService),
          SizedBox(height: 24.h),
          
          // Quick stats
          _buildQuickStats(languageService),
          SizedBox(height: 24.h),
          
          // Alerts section
          _buildAlertsSection(languageService),
          SizedBox(height: 24.h),
          
          // Upcoming bookings
          _buildUpcomingBookings(languageService),
          SizedBox(height: 24.h),
          
          // Quick actions
          _buildQuickActions(languageService),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(LanguageService languageService) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.getString('welcomeBack', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    color: AppColors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Ahmed Hassan',
                  style: GoogleFonts.cairo(
                    fontSize: 28.sp,
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'You have 3 upcoming bookings this week',
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: Icon(
              Icons.person,
              size: 40.sp,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(LanguageService languageService) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.calendar_today,
            title: 'Upcoming',
            value: '3',
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            title: 'Completed',
            value: '12',
            color: AppColors.success,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStatCard(
            icon: Icons.star,
            title: 'Reviews',
            value: '8',
            color: AppColors.secondary,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite,
            title: 'Favorites',
            value: '5',
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(LanguageService languageService) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: AppColors.warning,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Alerts & Notifications',
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildAlertItem(
            icon: Icons.payment,
            title: 'Payment Pending',
            message: 'You have a pending payment for booking #1234',
            color: AppColors.warning,
          ),
          SizedBox(height: 12.h),
          _buildAlertItem(
            icon: Icons.schedule,
            title: 'Booking Reminder',
            message: 'Your cleaning service is scheduled for tomorrow at 10:00 AM',
            color: AppColors.info,
          ),
          SizedBox(height: 12.h),
          _buildAlertItem(
            icon: Icons.chat,
            title: 'Unread Messages',
            message: 'You have 2 unread messages from your service provider',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                message,
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingBookings(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Bookings',
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to bookings
              },
              child: Text(
                'View All',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _buildBookingCard(
          serviceName: 'Home Cleaning',
          providerName: 'Fatima Al-Zahra',
          date: 'Tomorrow, 10:00 AM',
          status: 'Confirmed',
          statusColor: AppColors.success,
        ),
        SizedBox(height: 12.h),
        _buildBookingCard(
          serviceName: 'Elderly Care',
          providerName: 'Mariam Hassan',
          date: 'Friday, 2:00 PM',
          status: 'Pending',
          statusColor: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildBookingCard({
    required String serviceName,
    required String providerName,
    required String date,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
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
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Icon(
              Icons.cleaning_services,
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
                  serviceName,
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  providerName,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  date,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              status,
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle,
                                  title: AppStrings.getString('bookAgain', languageService.currentLanguage),
                                  subtitle: AppStrings.getString('scheduleNewService', languageService.currentLanguage),
                color: AppColors.primary,
                onTap: () {
                  // Navigate to booking
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_month,
                title: 'View Calendar',
                subtitle: 'Check availability',
                color: AppColors.info,
                onTap: () {
                  // Navigate to calendar
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildActionCard(
                icon: Icons.star_rate,
                title: 'Rate Provider',
                subtitle: 'Share your experience',
                color: AppColors.secondary,
                onTap: () {
                  // Navigate to rating
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 