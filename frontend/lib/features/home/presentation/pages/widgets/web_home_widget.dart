
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../shared/services/language_service.dart';
import '../../../../../shared/services/responsive_service.dart';
import '../../../../../shared/widgets/shared_navigation.dart';
import '../../../../../shared/widgets/shared_hero_section.dart';

class WebHomeWidget extends StatefulWidget {
  const WebHomeWidget({super.key});

  @override
  State<WebHomeWidget> createState() => _WebHomeWidgetState();
}

class _WebHomeWidgetState extends State<WebHomeWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ResponsiveService>(
      builder: (context, languageService, responsiveService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
  final shouldUseMobileLayout = responsiveService.shouldUseMobileLayout(screenWidth);
  final isCollapsed = responsiveService.shouldCollapseNavigation(screenWidth);
        
        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC), // Soft off-white beige
          drawer: (shouldUseMobileLayout || isCollapsed) ? const SharedMobileDrawer(currentPage: 'home') : null,
          body: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width,
            ),
            child: Stack(
              children: [
                // Main content
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width,
                    ),
                    child: Column(
                      children: [
                        // Shared Navigation
                        SharedNavigation(
                          currentPage: 'home',
                          showAuthButtons: true,
                          isMobile: shouldUseMobileLayout || isCollapsed,
                        ),
                        // Shared Hero Section
                        SharedHeroSections.homeHero(
                          languageService: languageService,
                          isMobile: shouldUseMobileLayout,
                        ),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection(LanguageService languageService) {
    final categories = [
      {'icon': Icons.cleaning_services, 'name': 'cleaning', 'image': 'cleaning_icon.png'},
      {'icon': Icons.restaurant, 'name': 'homeCooking', 'image': 'home_cooking_icon.png'},
      {'icon': Icons.child_care, 'name': 'childcare', 'image': 'babysitting_icon.png'},
      {'icon': Icons.elderly, 'name': 'elderlyCare', 'image': 'elderly_care_icon.png'},
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
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/categories');
                },
                child: Text(
                  AppStrings.getString('viewAll', languageService.currentLanguage),
                  style: const TextStyle(
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
              crossAxisSpacing: 32,
              mainAxisSpacing: 32,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(
                categories[index]['icon'] as IconData,
                AppStrings.getString(categories[index]['name'] as String, languageService.currentLanguage),
                categories[index]['image'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String name, String imagePath) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available space
        final containerSize = constraints.maxWidth;
        final framePadding = (containerSize * 0.03).clamp(8.0, 20.0); // 3% padding with min/max limits
        final iconSize = containerSize * 0.5; // 50% of container for icon
        final fontSize = (containerSize * 0.08).clamp(12.0, 20.0); // Responsive font size
        
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/categories');
          },
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              children: [
                // Frame image as background - responsive padding
                Positioned(
                  top: framePadding,
                  left: framePadding,
                  right: framePadding,
                  bottom: framePadding,
                  child: Image.asset(
                    'assets/images/category_frame.png',
                    fit: BoxFit.contain,
                  ),
                ),
                // Content in the center
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Category image - responsive size
                      SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: Image.asset(
                          'assets/images/$imagePath',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: containerSize * 0.03), // Reduced spacing between icon and text
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularServicesSection(LanguageService languageService) {
    final services = [
      {
        'name': 'houseCleaning',
        'icon': Icons.cleaning_services,
        'rating': 4.9,
        'reviews': 238,
        'image': 'cleaning_popular_service.png',
      },
      {
        'name': 'traditionalDishes',
        'icon': Icons.restaurant,
        'rating': 4.8,
        'reviews': 156,
        'image': 'traditional_dishes_popular_service.png',
      },
      {
        'name': 'apartmentSetup',
        'icon': Icons.home,
        'rating': 4.7,
        'reviews': 89,
        'image': 'apartment_setup_popular_service.png',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('popularServices', languageService.currentLanguage),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: services.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildServiceCard(
                    AppStrings.getString(service['name'] as String, languageService.currentLanguage),
                    service['icon'] as IconData,
                    service['rating'] as double,
                    service['reviews'] as int,
                    service['image'] as String?,
                    index, // Pass the index to determine frame type
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String name, IconData icon, double rating, int reviews, String? image, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine frame type based on screen width
        String frameType;
        final screenWidth = MediaQuery.of(context).size.width;
        
        if (screenWidth > 1200) {
          // Large screens - use rectangle frames
          frameType = 'service_frame_rectangle.png';
        } else if (screenWidth > 800) {
          // Medium screens - use square frames
          frameType = 'service_frame_square.png';
        } else {
          // Small screens - use vertical frames
          frameType = 'service_frame_vertical.png';
        }

        // Calculate responsive sizes based on available space
        final containerWidth = constraints.maxWidth;
        const containerHeight = 320.0; // Fixed height for service cards
        final framePadding = (containerWidth * 0.03).clamp(8.0, 15.0);
        
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/categories');
          },
          child: SizedBox(
            height: containerHeight,
            child: Stack(
              children: [
                // Frame image as background
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/$frameType',
                    fit: BoxFit.contain,
                  ),
                ),
                // Content inside the frame
                Positioned(
                  top: framePadding,
                  left: framePadding,
                  right: framePadding,
                  bottom: framePadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Service icon
                      SizedBox(
                        width: (containerWidth * 0.35).clamp(40.0, 80.0), // 35% with limits
                        height: (containerWidth * 0.35).clamp(40.0, 80.0), // 35% with limits
                        child: Image.asset(
                          'assets/images/$image',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: (containerWidth * 0.02).clamp(4.0, 8.0)), // Responsive spacing with limits
                      // Service name
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: (containerWidth * 0.06).clamp(12.0, 18.0),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: (containerWidth * 0.015).clamp(2.0, 6.0)), // Responsive spacing with limits
                      // Rating and reviews
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(5, (index) => Icon(
                            index < rating.floor() ? Icons.star : Icons.star_border,
                            size: (containerWidth * 0.03).clamp(10.0, 14.0),
                            color: Colors.amber,
                          )),
                          SizedBox(width: (containerWidth * 0.015).clamp(2.0, 4.0)),
                          Text(
                            '($reviews)',
                            style: TextStyle(
                              fontSize: (containerWidth * 0.025).clamp(8.0, 12.0),
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
          ),
        );
      },
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
                      color: Colors.black.withValues(alpha: 0.1),
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
        color: AppColors.primary.withValues(alpha: 0.1),
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
            const Icon(
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
              side: const BorderSide(color: AppColors.primary),
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
                  style: const TextStyle(color: AppColors.primary, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/about');
                },
                child: Text(
                  AppStrings.getString('aboutUs', languageService.currentLanguage),
                  style: const TextStyle(color: AppColors.primary, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.getString('ourServices', languageService.currentLanguage),
                  style: const TextStyle(color: AppColors.primary, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.getString('privacyPolicy', languageService.currentLanguage),
                  style: const TextStyle(color: AppColors.primary, fontSize: 16),
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
                icon: const Icon(Icons.facebook, color: AppColors.primary, size: 32),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.message, color: AppColors.primary, size: 32),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt, color: AppColors.primary, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
} 