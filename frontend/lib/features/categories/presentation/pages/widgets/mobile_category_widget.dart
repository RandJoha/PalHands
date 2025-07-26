import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../shared/services/language_service.dart';
import '../../../../../shared/widgets/tatreez_pattern.dart';

class MobileCategoryWidget extends StatefulWidget {
  const MobileCategoryWidget({Key? key}) : super(key: key);

  @override
  State<MobileCategoryWidget> createState() => _MobileCategoryWidgetState();
}

class _MobileCategoryWidgetState extends State<MobileCategoryWidget> {
  int _selectedIndex = 1; // Categories tab selected
  Map<String, Set<String>> _selectedServices = {}; // Track selected services by category

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC),
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
                          _buildHeroSection(languageService),
                          _buildCategoriesGrid(languageService),
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
            // Back button
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Center(
                child: Text(
                  AppStrings.getString('categories', languageService.currentLanguage),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.category,
                    title: AppStrings.getString('categories', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                    },
                    isSelected: true,
                  ),
                  _buildDrawerItem(
                    icon: Icons.info,
                    title: AppStrings.getString('aboutUs', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to about us
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.cleaning_services,
                    title: AppStrings.getString('ourServices', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to services
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.question_answer,
                    title: AppStrings.getString('faqs', languageService.currentLanguage),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to FAQs
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
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon, 
        color: isSelected ? AppColors.primary : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primary : Colors.black,
        ),
        textAlign: TextAlign.start,
      ),
      onTap: onTap,
      tileColor: isSelected ? AppColors.primary.withOpacity(0.1) : null,
    );
  }

  Widget _buildHeroSection(LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            const Color(0xFF6B8E23).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Directionality(
        textDirection: languageService.textDirection,
        child: Column(
          children: [
            Icon(
              Icons.category,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.getString('allServices', languageService.currentLanguage),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.getString('connectWithTrustedServiceProvider', languageService.currentLanguage),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(LanguageService languageService) {
    final categories = [
      {
        'id': 'cleaning',
        'name': 'cleaningServices',
        'icon': Icons.cleaning_services,
        'color': const Color(0xFF4CAF50),
        'description': 'cleaningServicesDescription',
        'services': [
          'bedroomCleaning',
          'livingRoomCleaning',
          'kitchenCleaning',
          'bathroomCleaning',
          'windowCleaning',
          'doorCabinetCleaning',
          'floorCleaning',
          'carpetCleaning',
          'furnitureCleaning',
          'gardenCleaning',
          'entranceCleaning',
          'stairCleaning',
          'garageCleaning',
          'postEventCleaning',
          'postConstructionCleaning',
          'apartmentCleaning',
          'regularCleaning',
        ],
      },
      {
        'id': 'organizing',
        'name': 'organizingServices',
        'icon': Icons.folder_open,
        'color': const Color(0xFF2196F3),
        'description': 'organizingServicesDescription',
        'services': [
          'bedroomOrganizing',
          'kitchenOrganizing',
          'closetOrganizing',
          'storageOrganizing',
          'livingRoomOrganizing',
          'postPartyOrganizing',
          'fullHouseOrganizing',
          'childrenOrganizing',
        ],
      },
      {
        'id': 'cooking',
        'name': 'homeCookingServices',
        'icon': Icons.restaurant,
        'color': const Color(0xFFFF9800),
        'description': 'homeCookingServicesDescription',
        'services': [
          'mainDishes',
          'desserts',
          'specialRequests',
        ],
      },
      {
        'id': 'childcare',
        'name': 'childCareServices',
        'icon': Icons.child_care,
        'color': const Color(0xFF9C27B0),
        'description': 'childCareServicesDescription',
        'services': [
          'homeBabysitting',
          'schoolAccompaniment',
          'homeworkHelp',
          'educationalActivities',
          'childrenMealPrep',
          'sickChildCare',
        ],
      },
      {
        'id': 'elderly',
        'name': 'personalElderlyCare',
        'icon': Icons.elderly,
        'color': const Color(0xFF607D8B),
        'description': 'personalElderlyCareDescription',
        'services': [
          'homeElderlyCare',
          'medicalTransport',
          'healthMonitoring',
          'medicationAssistance',
          'emotionalSupport',
          'mobilityAssistance',
        ],
      },
      {
        'id': 'maintenance',
        'name': 'maintenanceRepair',
        'icon': Icons.build,
        'color': const Color(0xFF795548),
        'description': 'maintenanceRepairDescription',
        'services': [
          'electricalWork',
          'plumbingWork',
          'aluminumWork',
          'carpentryWork',
          'painting',
          'hangingItems',
          'satelliteInstallation',
          'applianceMaintenance',
        ],
      },
      {
        'id': 'newhome',
        'name': 'newHomeServices',
        'icon': Icons.home,
        'color': const Color(0xFFE91E63),
        'description': 'newHomeServicesDescription',
        'services': [
          'furnitureMoving',
          'packingUnpacking',
          'furnitureWrapping',
          'newHomeArrangement',
          'newApartmentCleaning',
          'preOccupancyRepairs',
          'kitchenSetup',
          'applianceInstallation',
        ],
      },
      {
        'id': 'miscellaneous',
        'name': 'miscellaneousErrands',
        'icon': Icons.miscellaneous_services,
        'color': const Color(0xFF00BCD4),
        'description': 'miscellaneousErrandsDescription',
        'services': [
          'documentDelivery',
          'shoppingDelivery',
          'specialErrands',
          'billPayment',
          'prescriptionPickup',
        ],
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('allCategories', languageService.currentLanguage),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(
                categories[index],
                languageService,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category, LanguageService languageService) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to category details
        _showCategoryDetails(category, languageService);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: (category['color'] as Color).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Icon section
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: (category['color'] as Color).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Icon(
                category['icon'] as IconData,
                size: 40,
                color: category['color'] as Color,
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.getString(category['name'] as String, languageService.currentLanguage),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(category['services'] as List).length} ${AppStrings.getString('services', languageService.currentLanguage)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          AppStrings.getString('viewDetails', languageService.currentLanguage),
                          style: TextStyle(
                            fontSize: 12,
                            color: category['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: category['color'] as Color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDetails(Map<String, dynamic> category, LanguageService languageService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildCategoryDetailsSheet(category, languageService, setModalState),
      ),
    );
  }

  Widget _buildCategoryDetailsSheet(Map<String, dynamic> category, LanguageService languageService, StateSetter setModalState) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (category['color'] as Color).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category['color'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.getString(category['name'] as String, languageService.currentLanguage),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.getString(category['description'] as String, languageService.currentLanguage),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Services list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: (category['services'] as List).length,
              itemBuilder: (context, index) {
                final service = category['services'][index] as String;
                final categoryId = category['id'] as String;
                final isSelected = _selectedServices[categoryId]?.contains(service) ?? false;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? (category['color'] as Color).withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? (category['color'] as Color) : (category['color'] as Color).withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  constraints: const BoxConstraints(minHeight: 80),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (_selectedServices[categoryId] == null) {
                              _selectedServices[categoryId] = <String>{};
                            }
                            if (isSelected) {
                              _selectedServices[categoryId]!.remove(service);
                            } else {
                              _selectedServices[categoryId]!.add(service);
                            }
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected ? (category['color'] as Color) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? (category['color'] as Color) : Colors.grey[400]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.getString(service, languageService.currentLanguage),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? (category['color'] as Color) : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                _getServiceDescription(service, languageService.currentLanguage),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Selected services count
                if (_selectedServices[category['id']]?.isNotEmpty == true)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (category['color'] as Color).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${_selectedServices[category['id']]!.length} ${AppStrings.getString('services', languageService.currentLanguage)} ${AppStrings.getString('selected', languageService.currentLanguage)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: category['color'] as Color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: category['color'] as Color,
                          side: BorderSide(color: category['color'] as Color),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.getString('close', languageService.currentLanguage),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedServices[category['id']]?.isNotEmpty == true
                            ? () {
                                Navigator.pop(context);
                                // TODO: Navigate to booking with selected services
                                print('Selected services: ${_selectedServices[category['id']]}');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: category['color'] as Color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppStrings.getString('bookNow', languageService.currentLanguage),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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

  String _getServiceDescription(String serviceKey, String language) {
    // Map service keys to their description keys
    final descriptionMap = {
      'bedroomCleaning': 'bedroomCleaningDesc',
      'livingRoomCleaning': 'livingRoomCleaningDesc',
      'kitchenCleaning': 'kitchenCleaningDesc',
      'bathroomCleaning': 'bathroomCleaningDesc',
      'windowCleaning': 'windowCleaningDesc',
      'doorCabinetCleaning': 'doorCabinetCleaningDesc',
      'floorCleaning': 'floorCleaningDesc',
      'carpetCleaning': 'carpetCleaningDesc',
      'furnitureCleaning': 'furnitureCleaningDesc',
      'gardenCleaning': 'gardenCleaningDesc',
      'entranceCleaning': 'entranceCleaningDesc',
      'stairCleaning': 'stairCleaningDesc',
      'garageCleaning': 'garageCleaningDesc',
      'postEventCleaning': 'postEventCleaningDesc',
      'postConstructionCleaning': 'postConstructionCleaningDesc',
      'apartmentCleaning': 'apartmentCleaningDesc',
      'regularCleaning': 'regularCleaningDesc',
    };

    final descriptionKey = descriptionMap[serviceKey];
    if (descriptionKey != null) {
      return AppStrings.getString(descriptionKey, language);
    }
    
    // Default description if no specific one is found
    return AppStrings.getString('serviceDescription', language);
  }

  Widget _buildBottomNavigationBar(LanguageService languageService) {
    final items = [
      {'icon': Icons.home, 'label': 'home'},
      {'icon': Icons.category, 'label': 'categories'},
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
                  // TODO: Navigate to respective screens
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.getString(item['label'] as String, languageService.currentLanguage),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? AppColors.primary : Colors.grey[600],
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
} 