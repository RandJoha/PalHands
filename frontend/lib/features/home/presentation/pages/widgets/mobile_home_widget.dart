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

class _MobileHomeWidgetState extends State<MobileHomeWidget> {
  int _selectedIndex = 0; // For bottom navigation

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
                  size: 80,
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
                    size: 80,
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
                    size: 80,
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
                    size: 80,
                    color: const Color(0xFF8B0000),
                    opacity: 0.3,
                  ),
                ),
              ),
              
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
            // Logo with hand icon and text
            Row(
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
            const Spacer(),
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

  Widget _buildHeroBanner(LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5EC), // Cream background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Muted green half-circle background for illustration
          Positioned(
            left: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF6B8E23), // Muted olive green
                borderRadius: BorderRadius.circular(70),
              ),
            ),
          ),
          // Main content row
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Illustration of woman with hijab and cleaning tools
                Container(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      // Woman with hijab
                      Positioned(
                        left: 15,
                        top: 15,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Red hijab
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      // Face
                      Positioned(
                        left: 17,
                        top: 17,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4C4), // Light skin tone
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      // Black long-sleeve shirt
                      Positioned(
                        left: 25,
                        top: 45,
                        child: Container(
                          width: 25,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      // Green apron
                      Positioned(
                        left: 20,
                        top: 42,
                        child: Container(
                          width: 35,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF228B22), // Green apron
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      // Red feather duster (right hand)
                      Positioned(
                        right: 8,
                        top: 35,
                        child: Container(
                          width: 18,
                          height: 25,
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Red duster
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      // Red bucket (left hand)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          width: 15,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary, // Red bucket
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
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
                  fontSize: 20,
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
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.black,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
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
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: services.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildServiceCard(
                    AppStrings.getString(services[index]['name'] as String, languageService.currentLanguage),
                    services[index]['icon'] as IconData,
                    services[index]['rating'] as double,
                    services[index]['reviews'] as int,
                    services[index]['image'] as String?,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String name, IconData icon, double rating, int reviews, String? image) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image or icon
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: image == 'grape_leaves'
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      image: const DecorationImage(
                        image: NetworkImage('https://via.placeholder.com/160x100/8B0000/FFFFFF?text=Grape+Leaves'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: 40,
                    color: AppColors.primary,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(5, (index) => Icon(
                      index < rating.floor() ? Icons.star : Icons.star_border,
                      size: 12,
                      color: Colors.amber,
                    )),
                    const SizedBox(width: 4),
                    Text(
                      '($reviews)',
                      style: TextStyle(
                        fontSize: 10,
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
                onPressed: () {},
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