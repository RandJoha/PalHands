import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MyServicesWidget extends StatefulWidget {
  const MyServicesWidget({super.key});

  @override
  State<MyServicesWidget> createState() => _MyServicesWidgetState();
}

class _MyServicesWidgetState extends State<MyServicesWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildServicesWidget(languageService);
      },
    );
  }

  Widget _buildServicesWidget(LanguageService languageService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AppStrings.getString('myServices', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.greyDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.getString('manageServiceOfferings', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          // Services Grid
          _buildServicesGrid(languageService),
          
          const SizedBox(height: 32),
          
          // Add Service Button
          _buildAddServiceButton(languageService),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(LanguageService languageService) {
    final services = [
      {
        'title': 'homeCleaning',
        'description': 'homeCleaningDescription',
        'status': 'active',
        'price': '\$25/hour',
        'icon': Icons.cleaning_services,
      },
      {
        'title': 'homeBabysitting',
        'description': 'homeBabysittingDescription',
        'status': 'active',
        'price': '\$20/hour',
        'icon': Icons.child_care,
      },
      {
        'title': 'homeElderlyCare',
        'description': 'homeElderlyCareDescription',
        'status': 'inactive',
        'price': '\$30/hour',
        'icon': Icons.elderly,
      },
      {
        'title': 'homeCookingServices',
        'description': 'homeCookingServicesDescription',
        'status': 'active',
        'price': '\$35/hour',
        'icon': Icons.restaurant,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(services[index], languageService);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, LanguageService languageService) {
    final isActive = service['status'] == 'active';
    
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    service['icon'],
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withValues(alpha: 0.1) : AppColors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppStrings.getString(service['status'], languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.success : AppColors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.getString(service['title'], languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.greyDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.getString(service['description'], languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  service['price'],
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.delete,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddServiceButton(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.getString('addNewService', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.getString('createNewServiceDescription', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppStrings.getString('addNewService', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
