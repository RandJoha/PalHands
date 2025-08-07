import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class BookingsWidget extends StatefulWidget {
  const BookingsWidget({super.key});

  @override
  State<BookingsWidget> createState() => _BookingsWidgetState();
}

class _BookingsWidgetState extends State<BookingsWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildBookingsWidget(languageService);
      },
    );
  }

  Widget _buildBookingsWidget(LanguageService languageService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AppStrings.getString('bookings', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.greyDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.getString('manageBookingsAppointments', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          // Stats Cards
          _buildStatsCards(languageService),
          
          const SizedBox(height: 32),
          
          // Recent Bookings
          _buildBookingsList(languageService),
        ],
      ),
    );
  }

  Widget _buildStatsCards(LanguageService languageService) {
    final stats = [
      {
        'title': 'pending',
        'count': '5',
        'color': AppColors.warning,
        'icon': Icons.schedule,
      },
      {
        'title': 'confirmed',
        'count': '12',
        'color': AppColors.success,
        'icon': Icons.check_circle,
      },
      {
        'title': 'completed',
        'count': '28',
        'color': AppColors.primary,
        'icon': Icons.done_all,
      },
      {
        'title': 'cancelled',
        'count': '3',
        'color': AppColors.error,
        'icon': Icons.cancel,
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
              stat['count'],
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
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList(LanguageService languageService) {
    final bookings = [
      {
        'id': '#BK001',
        'clientName': 'أحمد محمد',
        'service': 'homeCleaning',
        'date': '2024-12-15',
        'time': '10:00 AM',
        'status': 'pending',
        'amount': '\$50',
      },
      {
        'id': '#BK002',
        'clientName': 'Sarah Johnson',
        'service': 'homeBabysitting',
        'date': '2024-12-16',
        'time': '2:00 PM',
        'status': 'confirmed',
        'amount': '\$40',
      },
      {
        'id': '#BK003',
        'clientName': 'فاطمة علي',
        'service': 'homeElderlyCare',
        'date': '2024-12-14',
        'time': '9:00 AM',
        'status': 'completed',
        'amount': '\$60',
      },
      {
        'id': '#BK004',
        'clientName': 'Michael Brown',
        'service': 'homeCookingServices',
        'date': '2024-12-17',
        'time': '6:00 PM',
        'status': 'cancelled',
        'amount': '\$70',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('recentBookings', languageService.currentLanguage),
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
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _buildBookingCard(bookings[index], languageService);
          },
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, LanguageService languageService) {
    final statusColor = _getStatusColor(booking['status']);
    
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
            // Service icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.work,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Booking details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        booking['id'],
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppStrings.getString(booking['status'], languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking['clientName'],
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.getString(booking['service'], languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${AppStrings.getString('scheduledFor', languageService.currentLanguage)} ${booking['date']} at ${booking['time']}',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Amount and actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  booking['amount'],
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (booking['status'] == 'pending') ...[
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          AppStrings.getString('acceptBooking', languageService.currentLanguage),
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
                          AppStrings.getString('rejectBooking', languageService.currentLanguage),
                          style: GoogleFonts.cairo(fontSize: 12),
                        ),
                      ),
                    ] else ...[
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.message,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.success;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }
}
