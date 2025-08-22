import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MyBookingsWidget extends StatefulWidget {
  const MyBookingsWidget({super.key});

  @override
  State<MyBookingsWidget> createState() => _MyBookingsWidgetState();
}

class _MyBookingsWidgetState extends State<MyBookingsWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildBookings(context, languageService);
      },
    );
  }

  Widget _buildBookings(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Bookings',
                style: GoogleFonts.cairo(
                  fontSize: 24.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🇵🇸',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(width: 6.w),
                                            Text(
                          AppStrings.getString('palestine', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Filter tabs
          _buildFilterTabs(),
          SizedBox(height: 24.h),
          
          // Bookings list
          _buildBookingsList(),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab('Upcoming', true),
          ),
          Expanded(
            child: _buildFilterTab('Completed', false),
          ),
          Expanded(
            child: _buildFilterTab('Cancelled', false),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isActive) {
    return GestureDetector(
      onTap: () {
        // Handle filter change
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            color: isActive ? AppColors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return Column(
      children: [
        _buildBookingItem(
          serviceName: 'Home Cleaning',
          providerName: 'Fatima Al-Zahra',
          date: 'Tomorrow, 10:00 AM',
          status: 'Confirmed',
          statusColor: AppColors.success,
          price: '₪150',
        ),
        SizedBox(height: 16.h),
        _buildBookingItem(
          serviceName: 'Elderly Care',
          providerName: 'Mariam Hassan',
          date: 'Friday, 2:00 PM',
          status: 'Pending',
          statusColor: AppColors.warning,
          price: '₪200',
        ),
        SizedBox(height: 16.h),
        _buildBookingItem(
          serviceName: 'Babysitting',
          providerName: 'Aisha Mohammed',
          date: 'Yesterday, 3:00 PM',
          status: 'Completed',
          statusColor: AppColors.info,
          price: '₪120',
        ),
      ],
    );
  }

  Widget _buildBookingItem({
    required String serviceName,
    required String providerName,
    required String date,
    required String status,
    required Color statusColor,
    required String price,
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
                        fontSize: 18.sp,
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
                  SizedBox(height: 4.h),
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
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            date,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textLight,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Handle contact provider
                  },
                  icon: Icon(Icons.message, size: 16.sp),
                  label: Text(
                    'Contact',
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Removed Tracking button per requirements
            ],
          ),
        ],
      ),
    );
  }
} 