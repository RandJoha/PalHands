import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../shared/services/language_service.dart';
import '../../../../../shared/widgets/shared_navigation.dart';
import '../../../../../shared/widgets/shared_hero_section.dart';
import '../../../../../shared/widgets/booking_dialog.dart';
import '../../../../../shared/services/responsive_service.dart';
import '../../../../../shared/services/provider_service.dart';
import '../../../../../shared/models/provider.dart';
import '../../../../../shared/services/chat_service.dart';
import '../../../../../shared/models/chat.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../../shared/services/category_selection_store.dart';
import '../../../../profile/presentation/widgets/chat_conversation_widget.dart';
import '../../../../../shared/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import '../../../../../shared/widgets/chat_form_dialog.dart';

class MobileCategoryWidget extends StatefulWidget {
  const MobileCategoryWidget({super.key});

  @override
  State<MobileCategoryWidget> createState() => _MobileCategoryWidgetState();
}

class _MobileCategoryWidgetState extends State<MobileCategoryWidget> with TickerProviderStateMixin {
  int _selectedIndex = 1; // Categories tab selected
  // Persisted filters across views
  final CategorySelectionStore _store = CategorySelectionStore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? get _selectedCity => _store.selectedCity;
  set _selectedCity(String? v) => _store.selectedCity = v;
  String get _sortBy => _store.sortBy;
  set _sortBy(String v) => _store.sortBy = v;
  String get _sortOrder => _store.sortOrder;
  set _sortOrder(String v) => _store.sortOrder = v;
  bool _loading = false;
  String? _error;
  List<ProviderModel> _providers = const [];
  final _providerService = ProviderService();
  final _chatService = ChatService();
  
  // Performance optimization: debounce API calls
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  
  // Cache for selected services to prevent unnecessary refreshes
  Set<String> _cachedSelectedServices = {};
  bool _hasInitialized = false;

  Set<String> get _selectedServiceKeys {
    final set = <String>{};
  for (final s in _store.selectedServices.values) {
      set.addAll(s);
    }
    return set;
  }

  @override
  void initState() {
    super.initState();
    // Comment out animations to improve performance
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
    
    // Default: load providers after first frame to show initial list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshProviders();
    });
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
                          _buildFilterBar(languageService, showServicesPill: true),
                          const SizedBox(height: 12),
                          // Categories grid is intentionally hidden on mobile; selection is via the Services pill
                          _buildProvidersSection(languageService),
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

  Widget _buildFilterBar(LanguageService languageService, {bool showServicesPill = false}) {
    final cities = ['ramallah', 'nablus', 'jerusalem', 'hebron', 'bethlehem', 'gaza'];
    return Directionality(
      textDirection: languageService.textDirection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
      children: _selectedServiceKeys.map((s) => Chip(
                label: Text(AppStrings.getString(s, languageService.currentLanguage)),
                onDeleted: () {
                  setState(() {
        for (final entry in _store.selectedServices.entries) {
                      entry.value.remove(s);
                    }
                  });
                  _debouncedRefreshProviders();
                },
              )).toList(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildLabeled(
                  AppStrings.getString('location', languageService.currentLanguage),
                  DropdownButton<String>(
                    value: _selectedCity ?? '',
                    hint: Text(AppStrings.getString('selectYourLocation', languageService.currentLanguage)),
                    items: [
                      DropdownMenuItem<String>(value: '', child: Text(AppStrings.getString('all', languageService.currentLanguage))),
                      ...cities.map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(AppStrings.getString(c, languageService.currentLanguage)),
                      )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCity = (val == null || val.isEmpty) ? null : val);
                      _debouncedRefreshProviders();
                    },
                  ),
                ),
                _buildLabeled(
                  AppStrings.getString('sort', languageService.currentLanguage),
                  DropdownButton<String>(
                    value: _sortBy + '_' + _sortOrder,
                    items: [
                      DropdownMenuItem(value: 'rating_desc', child: Text('${AppStrings.getString('rating', languageService.currentLanguage)} ↓')),
                      DropdownMenuItem(value: 'rating_asc', child: Text('${AppStrings.getString('rating', languageService.currentLanguage)} ↑')),
                      DropdownMenuItem(value: 'price_asc', child: Text('${AppStrings.getString('price', languageService.currentLanguage)} ↑')),
                      DropdownMenuItem(value: 'price_desc', child: Text('${AppStrings.getString('price', languageService.currentLanguage)} ↓')),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      final parts = val.split('_');
                      setState(() {
                        _sortBy = parts[0];
                        _sortOrder = parts[1];
                      });
                      _debouncedRefreshProviders();
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _store.selectedServices.clear();
                      _selectedCity = null;
                      _sortBy = 'rating';
                      _sortOrder = 'desc';
                    });
                    _debouncedRefreshProviders();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                  label: Text(AppStrings.getString('reset', languageService.currentLanguage)),
                ),
                if (showServicesPill)
                  OutlinedButton.icon(
                    onPressed: () {
                      // Open the same bottom sheet used for category details but as an entry point
                      _openMobileServicesSheet(languageService);
                    },
                    icon: const Icon(Icons.filter_list),
                    style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                    label: Text(AppStrings.getString('ourServices', languageService.currentLanguage)),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _openMobileServicesSheet(LanguageService languageService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildCategoriesPanelMobile(languageService, setSheetState),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // A compact categories/services selector for mobile similar to the web panel
  Widget _buildCategoriesPanelMobile(LanguageService languageService, StateSetter setSheetState) {
    final categories = _categories();
    return Directionality(
      textDirection: languageService.textDirection,
      child: CheckboxTheme(
        data: CheckboxTheme.of(context).copyWith(
          side: BorderSide(color: Colors.grey.shade500, width: 1.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list),
              const SizedBox(width: 8),
              Text(AppStrings.getString('ourServices', languageService.currentLanguage), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final color = cat['color'] as Color;
                final services = (cat['services'] as List).cast<String>();
                final id = cat['id'] as String;
                _store.selectedServices.putIfAbsent(id, () => <String>{});
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withValues(alpha: 0.25))),
                  elevation: 0,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: idx == 0,
                      iconColor: color,
                      collapsedIconColor: color,
                      title: Text(AppStrings.getString(cat['name'] as String, languageService.currentLanguage), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          children: [
                        ...services.map((s) {
                          final sel = _store.selectedServices[id]!.contains(s);
                          return CheckboxListTile(
                            value: sel,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: color,
            dense: false,
                            title: Text(AppStrings.getString(s, languageService.currentLanguage)),
                            onChanged: (v) {
                              // Update parent data and rebuild the sheet UI
                              if (v == true) {
                                _store.selectedServices[id]!.add(s);
                              } else {
                                _store.selectedServices[id]!.remove(s);
                              }
                              setSheetState(() {});
                            },
                          );
                        }).toList(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.getString('close', languageService.currentLanguage)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _debouncedRefreshProviders();
                  },
                  child: Text(AppStrings.getString('bookNow', languageService.currentLanguage)),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  // Centralized categories list (mirrors web version)
  List<Map<String, dynamic>> _categories() {
    return const [
      {
        'id': 'cleaning',
        'name': 'cleaningServices',
        'icon': Icons.cleaning_services,
        'color': Color(0xFF4CAF50),
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
        'color': Color(0xFF2196F3),
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
        'color': Color(0xFFFF9800),
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
        'color': Color(0xFF9C27B0),
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
        'color': Color(0xFF607D8B),
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
        'color': Color(0xFF795548),
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
        'color': Color(0xFFE91E63),
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
        'color': Color(0xFF00BCD4),
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
  }

  Widget _buildLabeled(String label, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: child,
        ),
      ],
    );
  }

  // ignore: unused_element
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
                  final isSelected = _store.selectedServices[categoryId]?.contains(service) ?? false;
                  
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
                        Checkbox(
                          value: isSelected,
                          activeColor: category['color'] as Color,
                          onChanged: (v) {
                            setModalState(() {
                              if (_store.selectedServices[categoryId] == null) {
                                _store.selectedServices[categoryId] = <String>{};
                              }
                              if (v == true) {
                                _store.selectedServices[categoryId]!.add(service);
                              } else {
                                _store.selectedServices[categoryId]!.remove(service);
                              }
                            });
                          },
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
                if (_store.selectedServices[category['id']]?.isNotEmpty == true)
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
                      '${_store.selectedServices[category['id']]!.length} ${AppStrings.getString('services', languageService.currentLanguage)} ${AppStrings.getString('selected', languageService.currentLanguage)}',
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
                        onPressed: _store.selectedServices[category['id']]?.isNotEmpty == true
                            ? () {
                                Navigator.pop(context);
                                _debouncedRefreshProviders();
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

  // Debounced version for filter changes to avoid excessive API calls
  void _debouncedRefreshProviders() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        _refreshProviders();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshProviders() async {
    if (!mounted) return;
    
    // Check if selected services have actually changed
    final currentServices = _selectedServiceKeys;
    if (_hasInitialized && setEquals(currentServices, _cachedSelectedServices)) {
      return; // No change, don't refresh
    }
    
    _cachedSelectedServices = Set.from(currentServices);
    _hasInitialized = true;
    
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Since we're in frontend-only mode, this should be instant with cached mock data
      final data = await _providerService.fetchProviders(
        servicesAny: currentServices.toList(),
        city: _selectedCity,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (!mounted) return;
      setState(() => _providers = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildProvidersSection(LanguageService languageService) {
    final lang = languageService.currentLanguage;
    
    return Directionality(
      textDirection: languageService.textDirection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang == 'ar' ? 'مقدمو الخدمة' : 'Service Providers', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            if (_providers.isEmpty && !_loading && _error == null) 
              const Center(child: Text('Select services to see providers')),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => _buildProviderTile(_providers[index], lang),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: _providers.length,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile(ProviderModel p, String lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        if (p.providerId != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '#${p.providerId}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(AppStrings.getString(p.city.toLowerCase(), lang), style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RatingBarIndicator(rating: p.ratingAverage, itemSize: 14, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
                  Text('${p.ratingAverage.toStringAsFixed(1)} (${p.ratingCount})', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: () {
              final maxVisible = 3;
              final visible = p.services.take(maxVisible).toList();
              final extras = p.services.length - visible.length;
              final chips = <Widget>[];
              chips.addAll(visible.map((s) => Chip(label: Text(AppStrings.getString(s, lang), style: const TextStyle(fontSize: 11)))));
              if (extras > 0) {
                final hidden = p.services.skip(maxVisible).take(12).map((s) => AppStrings.getString(s, lang)).toList();
                final tooltip = hidden.join(', ');
                chips.add(Tooltip(
                  message: tooltip,
                  waitDuration: const Duration(milliseconds: 300),
                  child: Chip(label: Text('+$extras', style: const TextStyle(fontSize: 11))),
                ));
              }
              return chips;
            }(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => BookingDialog(
                        provider: p,
                        selectedService: _selectedServiceKeys.isNotEmpty 
                            ? _selectedServiceKeys.first 
                            : null,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: Text(AppStrings.getString('bookNow', lang)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: p.phone.isNotEmpty ? () => launchUrl(Uri(scheme: 'tel', path: p.phone)) : null,
                icon: const Icon(Icons.call, size: 18),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                label: Text(AppStrings.getString('contact', lang)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _openChatWithProvider(p);
                },
                icon: const Icon(Icons.chat, size: 18),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                label: Text(AppStrings.getString('chat', lang)),
              ),
              // Debug button for authentication testing
              if (kDebugMode)
                OutlinedButton.icon(
                  onPressed: () => _debugAuthStatus(),
                  icon: const Icon(Icons.bug_report, size: 18),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                  label: const Text('Debug Auth'),
                ),
            ],
          )
        ],
      ),
    );
  }

  Widget _kv(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
      ],
    );
  }

  // Language localization for display purposes without altering provider names
  List<String> _localizedLanguages(List<String> langs, String langCode) {
    final arMap = {
      'arabic': 'العربية',
      'english': 'الإنجليزية',
      'hebrew': 'عبري',
      'turkish': 'التركية',
      'french': 'الفرنسية',
      'spanish': 'الإسبانية',
    };
  final hideTurkish = context.read<LanguageService>().hideTurkishForProviders;
  final filtered = hideTurkish
    ? langs.where((l) => l.toLowerCase().trim() != 'turkish').toList()
    : List<String>.from(langs);
  return filtered.map((l) {
      final key = l.toLowerCase().trim();
      if (langCode == 'ar') return arMap[key] ?? l;
      return l;
    }).toList();
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

  // Open chat with provider
  Future<void> _openChatWithProvider(ProviderModel provider) async {
    try {
      // Check if user is authenticated first - use Provider to get the shared AuthService instance
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated) {
        // Show login dialog
        final shouldLogin = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Login Required'),
            content: Text('You need to be logged in to chat with providers. Would you like to login now?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Login'),
              ),
            ],
          ),
        );

        if (shouldLogin == true) {
          // Navigate to login page
          Navigator.of(context).pushNamed('/login');
        }
        return;
      }

      // Debug: Print authentication status
      if (kDebugMode) {
        print('🔍 Chat debug - Authentication check:');
        print('  - Is authenticated: ${authService.isAuthenticated}');
        print('  - Token present: ${authService.token != null}');
        print('  - Token length: ${authService.token?.length ?? 0}');
        print('  - Current user: ${authService.currentUser?['email'] ?? 'None'}');
        if (authService.token != null) {
          print('  - Token preview: ${authService.token!.substring(0, 30)}...');
        }
      }

      // Show chat form dialog
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => ChatFormDialog(
          provider: provider,
          onMessageSent: () {
            if (kDebugMode) {
              print('🔄 Mobile category widget - Message sent callback triggered');
            }
            // This will refresh the chat list when the user navigates to the chat tab
            // The actual refresh happens in the chat messages widget
          },
        ),
      );
    } catch (e) {
      // Show error message with more details
      String errorMessage = 'Failed to open chat';
      if (e.toString().contains('401')) {
        errorMessage = 'Authentication failed. Please login again.';
      } else if (e.toString().contains('Failed to create/get chat')) {
        errorMessage = 'Unable to start chat. Please try again.';
      } else {
        errorMessage = 'Error: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _debugAuthStatus() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (kDebugMode) {
      print('🔍 Debug Auth Status:');
      print('  - Is authenticated: ${authService.isAuthenticated}');
      print('  - Token present: ${authService.token != null}');
      print('  - Token length: ${authService.token?.length ?? 0}');
      print('  - Current user: ${authService.currentUser?['email'] ?? 'None'}');
      if (authService.token != null) {
        print('  - Token preview: ${authService.token!.substring(0, 30)}...');
      }
    }
    
    if (authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Authenticated as: ${authService.currentUser?['email'] ?? 'Unknown'}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ User is NOT authenticated.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 