import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MobileMyBookingsWidget extends StatefulWidget {
  const MobileMyBookingsWidget({super.key});

  @override
  State<MobileMyBookingsWidget> createState() => _MobileMyBookingsWidgetState();
}

class _MobileMyBookingsWidgetState extends State<MobileMyBookingsWidget> {
  int _selectedFilter = 0; // 0: Upcoming, 1: Completed, 2: Cancelled

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('myBookings', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          
          // Filter tabs
          _buildFilterTabs(),
          const SizedBox(height: 20),
          
          // Bookings list
          _buildBookingsList(),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterTab(AppStrings.getString('upcoming', languageService.currentLanguage), 0),
          ),
          Expanded(
            child: _buildFilterTab(AppStrings.getString('completed', languageService.currentLanguage), 1),
          ),
          Expanded(
            child: _buildFilterTab(AppStrings.getString('cancelled', languageService.currentLanguage), 2),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, int index) {
    final isActive = _selectedFilter == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: isActive ? AppColors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return Column(
      children: [
        _buildBookingItem(
          serviceName: AppStrings.getString('homeCleaning', languageService.currentLanguage),
          providerName: 'Fatima Al-Zahra',
          date: AppStrings.getString('tomorrow10AM', languageService.currentLanguage),
          status: AppStrings.getString('confirmed', languageService.currentLanguage),
          statusColor: AppColors.success,
          price: '₪150',
        ),
        const SizedBox(height: 16),
        _buildBookingItem(
          serviceName: AppStrings.getString('elderlyCare', languageService.currentLanguage),
          providerName: 'Mariam Hassan',
          date: AppStrings.getString('friday2PM', languageService.currentLanguage),
          status: AppStrings.getString('pending', languageService.currentLanguage),
          statusColor: AppColors.warning,
          price: '₪200',
        ),
        const SizedBox(height: 16),
        _buildBookingItem(
          serviceName: AppStrings.getString('babysitting', languageService.currentLanguage),
          providerName: 'Aisha Mohammed',
          date: AppStrings.getString('yesterday3PM', languageService.currentLanguage),
          status: AppStrings.getString('completed', languageService.currentLanguage),
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
                  Icons.cleaning_services,
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
                      serviceName,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      providerName,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
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
                      fontSize: 18,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            date,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textLight,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Handle contact provider
                  },
                  icon: const Icon(Icons.message, size: 16),
                  label: Text(
                    AppStrings.getString('contact', Provider.of<LanguageService>(context, listen: false).currentLanguage),
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Handle track booking
                  },
                  icon: const Icon(Icons.location_on, size: 16),
                  label: Text(
                    AppStrings.getString('track', Provider.of<LanguageService>(context, listen: false).currentLanguage),
                    style: GoogleFonts.cairo(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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