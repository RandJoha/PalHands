import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../shared/services/language_service.dart';
import '../../../../../shared/widgets/animated_handshake.dart';
import '../../../../../shared/widgets/tatreez_pattern.dart';

class WebHomeWidget extends StatefulWidget {
  const WebHomeWidget({Key? key}) : super(key: key);

  @override
  State<WebHomeWidget> createState() => _WebHomeWidgetState();
}

class _WebHomeWidgetState extends State<WebHomeWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC), // Soft off-white beige
          body: Stack(
            children: [
              // Background Tatreez patterns in all four corners
              Positioned(
                top: 0,
                left: 0,
                child: TatreezPattern(
                  size: 120,
                  color: const Color(0xFF8B0000), // Deep red
                  opacity: 0.3,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Transform.rotate(
                  angle: 1.5708, // 90 degrees
                  child: TatreezPattern(
                    size: 120,
                    color: const Color(0xFF8B0000),
                    opacity: 0.3,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Transform.rotate(
                  angle: 3.1416, // 180 degrees
                  child: TatreezPattern(
                    size: 120,
                    color: const Color(0xFF8B0000),
                    opacity: 0.3,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Transform.rotate(
                  angle: 4.7124, // 270 degrees
                  child: TatreezPattern(
                    size: 120,
                    color: const Color(0xFF8B0000),
                    opacity: 0.3,
                  ),
                ),
              ),
              
              // Main content
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(languageService),
                    _buildHeroBanner(languageService),
                    _buildCategoriesSection(languageService),
                    _buildPopularServicesSection(languageService),
                    _buildWhyPalHandsSection(languageService),
                    _buildOffersSection(languageService),
                    _buildContactSection(languageService),
                    _buildFooter(languageService),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Directionality(
        textDirection: languageService.textDirection,
        child: Row(
          children: [
            // Logo with hand icon and text
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.handshake,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppStrings.getString('appName', languageService.currentLanguage),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Navigation links
            Row(
              children: [
                _buildNavLink(AppStrings.getString('home', languageService.currentLanguage), languageService),
                _buildNavLink(AppStrings.getString('aboutUs', languageService.currentLanguage), languageService),
                _buildNavLink(AppStrings.getString('ourServices', languageService.currentLanguage), languageService),
                _buildNavLink(AppStrings.getString('faqs', languageService.currentLanguage), languageService),
                _buildNavLink(AppStrings.getString('contactUs', languageService.currentLanguage), languageService),
              ],
            ),
            const SizedBox(width: 20),
            // Language toggle
            GestureDetector(
              onTap: () {
                languageService.toggleLanguage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  languageService.currentLanguage == 'ar' ? 'EN' : 'العربية',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(String text, LanguageService languageService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () {
          // TODO: Navigate to respective pages
        },
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5EC), // Cream background
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Muted green half-circle background for illustration
          Positioned(
            left: -40,
            top: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF6B8E23), // Muted olive green
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),
          // Main content row
          Padding(
            padding: const EdgeInsets.all(40),
            child: Row(
              children: [
                // Illustration of woman with hijab and cleaning tools
                Container(
                  width: 250,
                  height: 250,
                  child: Stack(
                    children: [
                      // Woman with hijab
                      Positioned(
                        left: 50,
                        top: 50,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Red hijab
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      // Face
                      Positioned(
                        left: 55,
                        top: 55,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4C4), // Light skin tone
                            borderRadius: BorderRadius.circular(45),
                          ),
                        ),
                      ),
                      // Black long-sleeve shirt
                      Positioned(
                        left: 75,
                        top: 120,
                        child: Container(
                          width: 60,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      // Green apron
                      Positioned(
                        left: 60,
                        top: 115,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF228B22), // Green apron
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      // Red feather duster (right hand)
                      Positioned(
                        right: 30,
                        top: 100,
                        child: Container(
                          width: 35,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Red duster
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      // Red bucket (left hand)
                      Positioned(
                        left: 30,
                        bottom: 30,
                        child: Container(
                          width: 25,
                          height: 35,
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Red bucket
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 50),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hero title
                      Text(
                        AppStrings.getString('heroTitle', languageService.currentLanguage),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Text(
                        AppStrings.getString('professionalCleaningDescription', languageService.currentLanguage),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Book Now button
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to booking
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.getString('bookNow', languageService.currentLanguage),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(LanguageService languageService) {
    final categories = [
      {'icon': Icons.cleaning_services, 'name': 'cleaning'},
      {'icon': Icons.restaurant, 'name': 'homeCooking'},
      {'icon': Icons.child_care, 'name': 'childcare'},
      {'icon': Icons.elderly, 'name': 'elderlyCare'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.getString('categories', languageService.currentLanguage),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all categories
                },
                child: Text(
                  AppStrings.getString('viewAll', languageService.currentLanguage),
                  style: TextStyle(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 1.2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(
                categories[index]['icon'] as IconData,
                AppStrings.getString(categories[index]['name'] as String, languageService.currentLanguage),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String name) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.black,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServicesSection(LanguageService languageService) {
    final services = [
      {
        'name': 'houseCleaning',
        'icon': Icons.cleaning_services,
        'rating': 4.9,
        'reviews': 238,
        'image': null,
      },
      {
        'name': 'traditionalDishes',
        'icon': Icons.restaurant,
        'rating': 4.8,
        'reviews': 156,
        'image': 'grape_leaves', // Placeholder for real image
      },
      {
        'name': 'apartmentSetup',
        'icon': Icons.home,
        'rating': 4.7,
        'reviews': 89,
        'image': null,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('popularServices', languageService.currentLanguage),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: services.map((service) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildServiceCard(
                  AppStrings.getString(service['name'] as String, languageService.currentLanguage),
                  service['icon'] as IconData,
                  service['rating'] as double,
                  service['reviews'] as int,
                  service['image'] as String?,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String name, IconData icon, double rating, int reviews, String? image) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image or icon
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: image == 'grape_leaves'
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                      image: const DecorationImage(
                        image: NetworkImage('https://via.placeholder.com/300x200/8B0000/FFFFFF?text=Grape+Leaves'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 60,
                    color: AppColors.primary,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (index) => Icon(
                      index < rating.floor() ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    )),
                    const SizedBox(width: 8),
                    Text(
                      '($reviews)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyPalHandsSection(LanguageService languageService) {
    final features = [
      {
        'icon': Icons.security,
        'title': 'secureTrusted',
        'color': Colors.green,
      },
      {
        'icon': Icons.message,
        'title': 'directCommunication',
        'color': Colors.blue,
      },
      {
        'icon': Icons.flag,
        'title': 'palestinianIdentity',
        'color': AppColors.primary,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('whyPalHands', languageService.currentLanguage),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: features.map((feature) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      feature['icon'] as IconData,
                      size: 48,
                      color: feature['color'] as Color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.getString(feature['title'] as String, languageService.currentLanguage),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: 1,
        ),
      ),
      child: Directionality(
        textDirection: languageService.textDirection,
        child: Row(
          children: [
            Icon(
              Icons.local_offer,
              color: AppColors.primary,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppStrings.getString('cleaningDiscount', languageService.currentLanguage),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to provider registration
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppStrings.getString('registerAsProvider', languageService.currentLanguage),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              // TODO: Navigate to contact
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppStrings.getString('contactUs', languageService.currentLanguage),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Quick links
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.getString('home', languageService.currentLanguage),
                  style: TextStyle(color: AppColors.primary, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.getString('aboutUs', languageService.currentLanguage),
                  style: TextStyle(color: AppColors.primary, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.getString('ourServices', languageService.currentLanguage),
                  style: TextStyle(color: AppColors.primary, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.getString('privacyPolicy', languageService.currentLanguage),
                  style: TextStyle(color: AppColors.primary, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Social media icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.facebook, color: AppColors.primary, size: 32),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.message, color: AppColors.primary, size: 32),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.camera_alt, color: AppColors.primary, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Copyright
          Text(
            AppStrings.getString('copyright', languageService.currentLanguage),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 