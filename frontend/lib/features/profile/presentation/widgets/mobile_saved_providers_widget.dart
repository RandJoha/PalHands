import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MobileSavedProvidersWidget extends StatefulWidget {
  const MobileSavedProvidersWidget({super.key});

  @override
  State<MobileSavedProvidersWidget> createState() => _MobileSavedProvidersWidgetState();
}

class _MobileSavedProvidersWidgetState extends State<MobileSavedProvidersWidget> {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('savedProviders', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 24,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          
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
        const SizedBox(height: 16),
        _buildProviderItem(
          name: 'Mariam Hassan',
          service: AppStrings.getString('elderlyCare', languageService.currentLanguage),
          rating: 4.9,
          price: '₪200',
          isAvailable: true,
          languageService: languageService,
        ),
        const SizedBox(height: 16),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.ratingFilled,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAvailable ? AppStrings.getString('available', languageService.currentLanguage) : AppStrings.getString('unavailable', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
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
                  fontSize: 18,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isAvailable ? () {
                  // Handle book again
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  AppStrings.getString('bookAgain', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
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