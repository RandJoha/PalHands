import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../shared/services/language_service.dart';
import '../../../../../shared/widgets/shared_navigation.dart';
import '../../../../../shared/widgets/shared_hero_section.dart';
import '../../../../../shared/services/responsive_service.dart';

class WebCategoryWidget extends StatefulWidget {
  const WebCategoryWidget({super.key});

  @override
  State<WebCategoryWidget> createState() => _WebCategoryWidgetState();
}

class _WebCategoryWidgetState extends State<WebCategoryWidget> {
  final Map<String, Set<String>> _selectedServices = {}; // Track selected services by category
  
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isCollapsed = context.read<ResponsiveService>().shouldCollapseNavigation(screenWidth);
        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC),
          drawer: isCollapsed ? const SharedMobileDrawer(currentPage: 'ourServices') : null,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Shared Navigation
                SharedNavigation(
                  currentPage: 'ourServices',
                  showAuthButtons: true,
                  isMobile: isCollapsed,
                ),
                // Shared Hero Section
                SharedHeroSections.servicesHero(
                  languageService: languageService,
                  isMobile: false,
                ),
                _buildCategoriesGrid(languageService),
                const SizedBox(height: 40),
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('allCategories', languageService.currentLanguage),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid based on available width
              int crossAxisCount;
              if (constraints.maxWidth > 1400) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 1000) {
                crossAxisCount = 3;
              } else if (constraints.maxWidth > 700) {
                crossAxisCount = 2;
              } else {
                crossAxisCount = 1;
              }
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: crossAxisCount == 1 ? 2.5 : 0.8,
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
        _showCategoryDetails(category, languageService);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: (category['color'] as Color).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Icon section
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: (category['color'] as Color).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Icon(
                category['icon'] as IconData,
                size: 48,
                color: category['color'] as Color,
              ),
            ),
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.getString(category['name'] as String, languageService.currentLanguage),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(category['services'] as List).length} ${AppStrings.getString('services', languageService.currentLanguage)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          AppStrings.getString('viewDetails', languageService.currentLanguage),
                          style: TextStyle(
                            fontSize: 14,
                            color: category['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
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
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => _buildCategoryDetailsDialog(category, languageService, setDialogState),
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

  Widget _buildCategoryDetailsDialog(Map<String, dynamic> category, LanguageService languageService, StateSetter setDialogState) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 600,
        height: 500,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: category['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.getString(category['name'] as String, languageService.currentLanguage),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.getString(category['description'] as String, languageService.currentLanguage),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Services list
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                ),
                itemCount: (category['services'] as List).length,
                itemBuilder: (context, index) {
                  final service = category['services'][index] as String;
                  final categoryId = category['id'] as String;
                  final isSelected = _selectedServices[categoryId]?.contains(service) ?? false;
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? (category['color'] as Color).withValues(alpha: 0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? (category['color'] as Color) : (category['color'] as Color).withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    constraints: const BoxConstraints(minHeight: 100),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setDialogState(() {
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
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Selected services count
                  if (_selectedServices[category['id']]?.isNotEmpty == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (category['color'] as Color).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${_selectedServices[category['id']]!.length} ${AppStrings.getString('services', languageService.currentLanguage)} ${AppStrings.getString('selected', languageService.currentLanguage)}',
                        style: TextStyle(
                          fontSize: 16,
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
      ),
    );
  }
} 