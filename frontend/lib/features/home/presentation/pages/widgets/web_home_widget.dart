
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../shared/services/language_service.dart';
import '../../../../../shared/services/auth_service.dart';
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
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Directionality(
            textDirection: languageService.textDirection,
            child: Row(
              children: [
                // Logo section - fixed width
                SizedBox(
                  width: 120,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.handshake,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          AppStrings.getString('appName', languageService.currentLanguage),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Navigation section - takes remaining space
                Expanded(
                  child: _buildResponsiveNavigation(languageService, constraints.maxWidth),
                ),
                
                // Language toggle - fixed width
                SizedBox(
                  width: 60,
                  child: GestureDetector(
                    onTap: () {
                      languageService.toggleLanguage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        languageService.currentLanguage == 'ar' ? 'EN' : 'العربية',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                
                // Authentication buttons
                const SizedBox(width: 16),
                _buildAuthButtons(languageService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveNavigation(LanguageService languageService, double availableWidth) {
    // Calculate how many navigation items we can fit
    int totalItems = 5;
    double itemWidth = availableWidth / totalItems;
    
    // Determine font size based on available width per item
    double fontSize = 10.0;
    if (itemWidth > 120) {
      fontSize = 14.0;
    } else if (itemWidth > 80) {
      fontSize = 12.0;
    } else if (itemWidth > 60) {
      fontSize = 11.0;
    } else {
      fontSize = 9.0;
    }
    
    // Get navigation items with appropriate text
    List<Map<String, String>> navItems = [
      {'key': 'home', 'text': AppStrings.getString('home', languageService.currentLanguage)},
      {'key': 'aboutUs', 'text': AppStrings.getString('aboutUs', languageService.currentLanguage)},
      {'key': 'ourServices', 'text': AppStrings.getString('ourServices', languageService.currentLanguage)},
      {'key': 'faqs', 'text': AppStrings.getString('faqs', languageService.currentLanguage)},
      {'key': 'contactUs', 'text': AppStrings.getString('contactUs', languageService.currentLanguage)},
    ];
    
    // Use shorter text for narrow screens
    if (itemWidth < 70) {
      for (int i = 0; i < navItems.length; i++) {
        if (navItems[i]['key'] == 'ourServices') {
          navItems[i]['text'] = languageService.currentLanguage == 'ar' ? 'الخدمات' : 'Services';
        } else if (navItems[i]['key'] == 'contactUs') {
          navItems[i]['text'] = languageService.currentLanguage == 'ar' ? 'تواصل' : 'Contact';
        } else if (navItems[i]['key'] == 'aboutUs') {
          navItems[i]['text'] = languageService.currentLanguage == 'ar' ? 'من نحن' : 'About';
        }
      }
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: navItems.map((item) => _buildCompactNavLink(
        item['text']!,
        fontSize,
        languageService,
      )).toList(),
    );
  }

  Widget _buildCompactNavLink(String text, double fontSize, LanguageService languageService) {
    return Expanded(
      child: TextButton(
        onPressed: () {
          // Navigate based on text content
          if (text == AppStrings.getString('ourServices', languageService.currentLanguage) ||
              text == 'الخدمات' ||
              text == 'Services') {
            Navigator.pushNamed(context, '/categories');
          } else if (text == AppStrings.getString('aboutUs', languageService.currentLanguage) ||
                     text == 'من نحن' ||
                     text == 'About') {
            Navigator.pushNamed(context, '/about');
          } else if (text == AppStrings.getString('faqs', languageService.currentLanguage)) {
            Navigator.pushNamed(context, '/faqs');
          } else if (text == AppStrings.getString('contactUs', languageService.currentLanguage) ||
                     text == 'تواصل' ||
                     text == 'Contact') {
            Navigator.pushNamed(context, '/contact');
          }
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildHeroBanner(LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFDF5EC),
            const Color(0xFFF5F5DC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Row(
          children: [
            // Hijab girl image - placeholder for now
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(140),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 120,
                color: AppColors.primary,
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
            style: TextStyle(
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
          child: Container(
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
                      Container(
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
            style: TextStyle(
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
        final containerHeight = 320.0; // Fixed height for service cards
        final framePadding = (containerWidth * 0.03).clamp(8.0, 15.0);
        
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/categories');
          },
          child: Container(
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
                      Container(
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
                onPressed: () {
                  Navigator.pushNamed(context, '/about');
                },
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

  Widget _buildAuthButtons(LanguageService languageService) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated) {
          // User is logged in - show dashboard button and user menu
          return Row(
            children: [

              
              // User menu
              PopupMenuButton<String>(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          authService.userFullName,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.getString('logout', languageService.currentLanguage),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'profile') {
                    // Navigate to appropriate dashboard based on user role
                    if (authService.isAdmin) {
                      Navigator.pushNamed(context, '/admin');
                    } else if (authService.isProvider) {
                      Navigator.pushNamed(context, '/provider');
                    } else {
                      Navigator.pushNamed(context, '/user');
                    }
                  } else if (value == 'logout') {
                    try {
                      await authService.logout();
                      if (mounted) {
                        // Navigate to home screen and clear all routes
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Logout failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          );
        } else {
          // User is not logged in - show login/register buttons
          return Row(
            children: [
              // Login button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  AppStrings.getString('login', languageService.currentLanguage),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Register button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  AppStrings.getString('signUp', languageService.currentLanguage),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
} 