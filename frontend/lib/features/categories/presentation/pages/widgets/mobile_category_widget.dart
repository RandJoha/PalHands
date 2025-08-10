import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../shared/services/language_service.dart';
import '../../../../../shared/widgets/shared_navigation.dart';
import '../../../../../shared/widgets/shared_hero_section.dart';
import '../../../../../shared/services/responsive_service.dart';

class MobileCategoryWidget extends StatefulWidget {
  const MobileCategoryWidget({super.key});

  @override
  State<MobileCategoryWidget> createState() => _MobileCategoryWidgetState();
}

class _MobileCategoryWidgetState extends State<MobileCategoryWidget> with TickerProviderStateMixin {
  int _selectedIndex = 1; // Categories tab selected
  final Map<String, Set<String>> _selectedServices = {}; // Track selected services by category
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // _bannerController = AnimationController(
    //   duration: const Duration(milliseconds: 1500),
    //   vsync: this,
    // );
    // _cardController = AnimationController(
    //   duration: const Duration(milliseconds: 800),
    //   vsync: this,
    // );
    
    // _bannerAnimation = Tween<double>(
    //   begin: 0.0,
    //   end: 1.0,
    // ).animate(CurvedAnimation(
    //   parent: _bannerController,
    //   curve: Curves.easeInOut,
    // ));
    
    // _cardAnimation = Tween<double>(
    //   begin: 0.0,
    //   end: 1.0,
    // ).animate(CurvedAnimation(
    //   parent: _cardController,
    //   curve: Curves.easeOutBack,
    // ));
    
    // _bannerController.forward();
    // _cardController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ResponsiveService>(
      builder: (context, languageService, responsiveService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
  final shouldUseMobileLayout = responsiveService.shouldUseMobileLayout(screenWidth);
  final isCollapsed = responsiveService.shouldCollapseNavigation(screenWidth);
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFFDF5EC),
          drawer: (shouldUseMobileLayout || isCollapsed) ? const SharedMobileDrawer(currentPage: 'ourServices') : null,
          body: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Shared Navigation
                  SharedNavigation(
                    currentPage: 'ourServices',
                    showAuthButtons: false,
                    onMenuTap: (shouldUseMobileLayout || isCollapsed) ? () {
                      _scaffoldKey.currentState?.openDrawer();
                    } : null,
                    isMobile: shouldUseMobileLayout || isCollapsed,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Shared Hero Section
                          SharedHeroSections.servicesHero(
                            languageService: languageService,
                            isMobile: shouldUseMobileLayout,
                          ),
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
          bottomNavigationBar: shouldUseMobileLayout ? _buildBottomNavigationBar(languageService) : null,
        );
      },
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
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid based on available width
              int crossAxisCount;
              if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth > 400) {
                crossAxisCount = 2;
              } else {
                crossAxisCount = 1;
              }
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: crossAxisCount == 1 ? 2.0 : 0.85,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryCard(
                    categories[index],
                    languageService,
                  );
                },
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
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: (category['color'] as Color).withValues(alpha: 0.3),
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
                color: (category['color'] as Color).withValues(alpha: 0.1),
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
      height: MediaQuery.of(context).size.height * 0.85,
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
              color: (category['color'] as Color).withValues(alpha: 0.1),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate((category['services'] as List).length, (index) {
                  final service = category['services'][index] as String;
                  final categoryId = category['id'] as String;
                  final isSelected = _selectedServices[categoryId]?.contains(service) ?? false;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? (category['color'] as Color).withValues(alpha: 0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? (category['color'] as Color) : (category['color'] as Color).withValues(alpha: 0.2),
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
                                ? const Icon(
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
                              Text(
                                _getServiceDescription(service, languageService.currentLanguage),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
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
                      color: (category['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (category['color'] as Color).withValues(alpha: 0.3),
                        width: 1,
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
                          side: BorderSide(color: category['color'] as Color, width: 1),
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
      // Cleaning services
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
      // Organizing services
      'bedroomOrganizing': 'bedroomOrganizingDesc',
      'kitchenOrganizing': 'kitchenOrganizingDesc',
      'closetOrganizing': 'closetOrganizingDesc',
      'storageOrganizing': 'storageOrganizingDesc',
      'livingRoomOrganizing': 'livingRoomOrganizingDesc',
      'postPartyOrganizing': 'postPartyOrganizingDesc',
      'fullHouseOrganizing': 'fullHouseOrganizingDesc',
      'childrenOrganizing': 'childrenOrganizingDesc',
      // Cooking services
      'mainDishes': 'mainDishesDesc',
      'desserts': 'dessertsDesc',
      'specialRequests': 'specialRequestsDesc',
      // Childcare services
      'homeBabysitting': 'homeBabysittingDesc',
      'schoolAccompaniment': 'schoolAccompanimentDesc',
      'homeworkHelp': 'homeworkHelpDesc',
      'educationalActivities': 'educationalActivitiesDesc',
      'childrenMealPrep': 'childrenMealPrepDesc',
      'sickChildCare': 'sickChildCareDesc',
      // Elderly care services
      'homeElderlyCare': 'homeElderlyCareDesc',
      'medicalTransport': 'medicalTransportDesc',
      'healthMonitoring': 'healthMonitoringDesc',
      'medicationAssistance': 'medicationAssistanceDesc',
      'emotionalSupport': 'emotionalSupportDesc',
      'mobilityAssistance': 'mobilityAssistanceDesc',
      // Maintenance services
      'electricalWork': 'electricalWorkDesc',
      'plumbingWork': 'plumbingWorkDesc',
      'aluminumWork': 'aluminumWorkDesc',
      'carpentryWork': 'carpentryWorkDesc',
      'painting': 'paintingDesc',
      'hangingItems': 'hangingItemsDesc',
      'satelliteInstallation': 'satelliteInstallationDesc',
      'applianceMaintenance': 'applianceMaintenanceDesc',
      // New home services
      'furnitureMoving': 'furnitureMovingDesc',
      'packingUnpacking': 'packingUnpackingDesc',
      'furnitureWrapping': 'furnitureWrappingDesc',
      'newHomeArrangement': 'newHomeArrangementDesc',
      'newApartmentCleaning': 'newApartmentCleaningDesc',
      'preOccupancyRepairs': 'preOccupancyRepairsDesc',
      'kitchenSetup': 'kitchenSetupDesc',
      'applianceInstallation': 'applianceInstallationDesc',
      // Miscellaneous services
      'documentDelivery': 'documentDeliveryDesc',
      'shoppingDelivery': 'shoppingDeliveryDesc',
      'specialErrands': 'specialErrandsDesc',
      'billPayment': 'billPaymentDesc',
      'prescriptionPickup': 'prescriptionPickupDesc',
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
            color: Colors.black.withValues(alpha: 0.1),
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
                  
                  // Navigate to respective screens
                  switch (index) {
                    case 0: // Home
                      Navigator.pushReplacementNamed(context, '/home');
                      break;
                    case 1: // Categories (current page)
                      // Already on categories page
                      break;
                    case 2: // My Requests
                      // TODO: Navigate to my requests page
                      break;
                    case 3: // Chat
                      // TODO: Navigate to chat page
                      break;
                  }
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