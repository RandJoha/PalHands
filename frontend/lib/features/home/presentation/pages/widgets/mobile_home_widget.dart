import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../shared/services/language_service.dart';
import '../../../../../shared/widgets/animated_handshake.dart';
import '../../../../../shared/widgets/tatreez_pattern.dart';

class MobileHomeWidget extends StatefulWidget {
  const MobileHomeWidget({Key? key}) : super(key: key);

  @override
  State<MobileHomeWidget> createState() => _MobileHomeWidgetState();
}

class _MobileHomeWidgetState extends State<MobileHomeWidget> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _bannerController;
  late AnimationController _cardController;
  late Animation<double> _bannerAnimation;
  late Animation<double> _cardAnimation; // For bottom navigation

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _bannerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeInOut,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));
    
    _bannerController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC), // Soft off-white beige
          drawer: _buildDrawer(languageService),
          body: Stack(
            children: [
              
              // Main content
              Column(
                children: [
                  _buildHeader(languageService),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeroBanner(languageService),
                          _buildCategoriesSection(languageService),
                          _buildPopularServicesSection(languageService),
                          _buildWhyPalHandsSection(languageService),
                          _buildOffersSection(languageService),
                          _buildContactSection(languageService),
                          _buildFooter(languageService),
                          const SizedBox(height: 80), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(languageService),
        );
      },
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            // Hamburger menu
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.menu,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Logo with hand icon and text
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.handshake,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.getString('appName', languageService.currentLanguage),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildDrawer(LanguageService languageService) {
    return Drawer(
      child: Directionality(
        textDirection: languageService.textDirection,
        child: Column(
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.handshake,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.getString('appName', languageService.currentLanguage),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Navigation items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: AppStrings.getString('home', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info,
                    title: AppStrings.getString('aboutUs', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/about');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.cleaning_services,
                    title: AppStrings.getString('ourServices', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/categories');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.question_answer,
                    title: AppStrings.getString('faqs', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/faqs');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.contact_support,
                    title: AppStrings.getString('contactUs', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to contact
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.privacy_tip,
                    title: AppStrings.getString('privacyPolicy', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to privacy policy
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.start,
      ),
      onTap: onTap,
    );
  }

  Widget _buildHeroBanner(LanguageService languageService) {
    return AnimatedBuilder(
      animation: _bannerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _bannerAnimation.value)),
          child: Opacity(
            opacity: _bannerAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFDF5EC),
                    const Color(0xFFF5F5DC),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Hijab girl image - placeholder for now
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 20),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Description
                          Text(
                            AppStrings.getString('professionalCleaningDescription', languageService.currentLanguage),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Book Now button
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Navigate to booking
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppStrings.getString('bookNow', languageService.currentLanguage),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                        Text(
            AppStrings.getString('categories', languageService.currentLanguage),
            style: TextStyle(
              fontSize: 24,
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
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8, // Reduced from 16 to 8
              mainAxisSpacing: 8, // Reduced from 16 to 8
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _cardAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * _cardAnimation.value),
                    child: Opacity(
                      opacity: _cardAnimation.value,
                      child: _buildCategoryCard(
                        categories[index]['icon'] as IconData,
                        AppStrings.getString(categories[index]['name'] as String, languageService.currentLanguage),
                        categories[index]['image'] as String,
                      ),
                    ),
                  );
                },
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
        final framePadding = (containerSize * 0.03).clamp(6.0, 15.0); // 3% padding with min/max limits
        final iconSize = containerSize * 0.5; // 50% of container for icon
        final fontSize = (containerSize * 0.08).clamp(10.0, 18.0); // Responsive font size
        
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/categories');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 180, // Increased from 150 to 180
            height: 180, // Increased from 150 to 180
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('popularServices', languageService.currentLanguage),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              
              // All mobile sizes - Rectangular frames in three rows
              return Column(
                children: services.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _buildServiceCard(
                      AppStrings.getString(service['name'] as String, languageService.currentLanguage),
                      service['icon'] as IconData,
                      service['rating'] as double,
                      service['reviews'] as int,
                      service['image'] as String?,
                      index,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String name, IconData icon, double rating, int reviews, String? image, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use rectangular frames for all mobile sizes
        String frameType = 'service_frame_rectangle.png';

        // Calculate responsive sizes based on available space
        final containerWidth = constraints.maxWidth;
        final containerHeight = 200.0; // Fixed height for mobile service cards
        final framePadding = (containerWidth * 0.04).clamp(8.0, 16.0);
        
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
                    fit: BoxFit.fill,
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
                        width: (containerWidth * 0.25).clamp(40.0, 80.0), // 25% with larger limits
                        height: (containerWidth * 0.25).clamp(40.0, 80.0), // 25% with larger limits
                        child: Image.asset(
                          'assets/images/$image',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: (containerWidth * 0.025).clamp(4.0, 8.0)), // Responsive spacing with limits
                      // Service name
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: (containerWidth * 0.045).clamp(12.0, 18.0),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: (containerWidth * 0.02).clamp(3.0, 6.0)), // Responsive spacing with limits
                      // Rating and reviews
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(5, (index) => Icon(
                            index < rating.floor() ? Icons.star : Icons.star_border,
                            size: (containerWidth * 0.03).clamp(10.0, 16.0),
                            color: Colors.amber,
                          )),
                          SizedBox(width: (containerWidth * 0.02).clamp(3.0, 5.0)),
                          Text(
                            '($reviews)',
                            style: TextStyle(
                              fontSize: (containerWidth * 0.025).clamp(8.0, 14.0),
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

  Widget _buildBottomNavigationBar(LanguageService languageService) {
    final items = [
      {'icon': Icons.home, 'label': 'home'},
      {'icon': Icons.search, 'label': 'browse'},
      {'icon': Icons.list_alt, 'label': 'myRequests'},
      {'icon': Icons.chat, 'label': 'chat'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _selectedIndex;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? AppColors.primary : Colors.black,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.getString(item['label'] as String, languageService.currentLanguage),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? AppColors.primary : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('whyPalHands', languageService.currentLanguage),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: features.map((feature) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        feature['icon'] as IconData,
                        size: 32,
                        color: feature['color'] as Color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.getString(feature['title'] as String, languageService.currentLanguage),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersSection(LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.getString('cleaningDiscount', languageService.currentLanguage),
                style: const TextStyle(
                  fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to provider registration
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppStrings.getString('registerAsProvider', languageService.currentLanguage),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              // TODO: Navigate to contact
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppStrings.getString('contactUs', languageService.currentLanguage),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/about');
                },
                child: Text(
                  AppStrings.getString('aboutUs', languageService.currentLanguage),
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.getString('ourServices', languageService.currentLanguage),
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.getString('privacyPolicy', languageService.currentLanguage),
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Social media icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.facebook, color: AppColors.primary),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.message, color: AppColors.primary),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.camera_alt, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Copyright
          Text(
            AppStrings.getString('copyright', languageService.currentLanguage),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 