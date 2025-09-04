import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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

class WebCategoryWidget extends StatefulWidget {
  const WebCategoryWidget({super.key});

  @override
  State<WebCategoryWidget> createState() => _WebCategoryWidgetState();
}

class _WebCategoryWidgetState extends State<WebCategoryWidget> {
  final CategorySelectionStore _store = CategorySelectionStore.instance;
  String? get _selectedCity => _store.selectedCity;
  set _selectedCity(String? v) => _store.selectedCity = v;
  String get _sortBy => _store.sortBy; // rating | price
  set _sortBy(String v) => _store.sortBy = v;
  String get _sortOrder => _store.sortOrder; // desc | asc
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
    // Default: load providers on first paint so users see providers immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshProviders();
    });
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
    if (!mounted) return; // guard against resize-induced dispose
    
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
        sortBy: _sortBy == 'rating' ? 'rating' : 'price',
        sortOrder: _sortOrder,
      );
      if (!mounted) return;
      setState(() {
        _providers = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
  
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
                // Side-by-side layout (providers left, services right) on wide screens
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1100;
                    if (wide) {
                      final isArabic = languageService.isArabic;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Directionality(
                          textDirection: TextDirection.ltr, // force LTR ordering so Arabic shows categories panel on the right
                          child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: isArabic
                              ? [
                                  // Providers left (for Arabic)
                                  Expanded(
                                    flex: 7,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFilterBar(languageService),
                                        const SizedBox(height: 12),
                                        _buildProvidersSection(languageService),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 420, minWidth: 360),
                                    child: _buildCategoriesPanel(languageService),
                                  ),
                                ]
                              : [
                                  // Categories left (for English)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 420, minWidth: 360),
                                    child: _buildCategoriesPanel(languageService),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 7,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFilterBar(languageService),
                                        const SizedBox(height: 12),
                                        _buildProvidersSection(languageService),
                                      ],
                                    ),
                                  ),
                                ],
                        ),
                        ),
                      );
                    }
                    // Narrow screens: show filters + "Our Services" pill and providers; hide the big categories grid
                    return Column(
                      children: [
                        _buildFilterBar(languageService, showServicesPill: true),
                        const SizedBox(height: 16),
                        _buildProvidersSection(languageService),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(LanguageService languageService, {bool showServicesPill = false}) {
    final cities = [
      'ramallah', 'nablus', 'jerusalem', 'hebron', 'bethlehem', 'gaza',
    ];
  final width = MediaQuery.of(context).size.width;
  final horizontalPad = width < 1200 ? 24.0 : 40.0;
    return Directionality(
      textDirection: languageService.textDirection,
      child: Container(
    padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected service chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedServiceKeys.map((s) {
                return Chip(
                  label: Text(AppStrings.getString(s, languageService.currentLanguage)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        for (final entry in _store.selectedServices.entries) {
                          entry.value.remove(s);
                        }
                      });
                      _debouncedRefreshProviders();
                    },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Controls row
      LayoutBuilder(
              builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1200; // raise threshold to prevent overflow band
        final controls = <Widget>[
                  // Location filter
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
                        setState(() {
                          _selectedCity = (val == null || val.isEmpty) ? null : val;
                        });
                        _debouncedRefreshProviders();
                      },
                    ),
                  ),
                  const SizedBox(width: 12, height: 12),
                  // Sort filter
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
                  const SizedBox(width: 12, height: 12),
                  // Reset button (outlined, unified style)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _store.reset();
                      });
                      _debouncedRefreshProviders();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: const StadiumBorder(),
                    ),
                    label: Text(AppStrings.getString('reset', languageService.currentLanguage)),
                  ),
                  if (showServicesPill)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: OutlinedButton.icon(
                        onPressed: () => _openServicesSelector(languageService),
                        icon: const Icon(Icons.filter_list, size: 18),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: const StadiumBorder(),
                          foregroundColor: const Color(0xFF9B4F3D),
                        ),
                        label: Text(AppStrings.getString('ourServices', languageService.currentLanguage)),
                      ),
                    ),
                ];

                return isNarrow
                    ? Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: controls)
                    : Row(children: controls.map((w) => Padding(padding: const EdgeInsets.only(right: 8), child: w)).toList());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openServicesSelector(LanguageService languageService) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(child: _buildCategoriesPanel(languageService, panelSetState: setDialogState)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabeled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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

  // Centralized categories list
  List<Map<String, dynamic>> _categories() {
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
    return categories;
  }

  // ignore: unused_element
  Widget _buildCategoriesGrid(LanguageService languageService) {
    final categories = _categories();

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

  // Compact right-side panel that mirrors the category/services selection
  Widget _buildCategoriesPanel(LanguageService languageService, {StateSetter? panelSetState}) {
    final categories = _categories();
    return Directionality(
      textDirection: languageService.textDirection,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(AppStrings.getString('allCategories', languageService.currentLanguage), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                        const SizedBox(height: 4),
        ...services.map((s) {
                          final sel = _store.selectedServices[id]!.contains(s);
                          return CheckboxListTile(
                            value: sel,
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: color,
                            dense: true,
                            title: Text(AppStrings.getString(s, languageService.currentLanguage)),
                            onChanged: (v) {
          // Rebuild either the embedded panel (side) or the dialog copy
          final fn = panelSetState ?? setState;
          fn(() {
                                if (v == true) {
                                  _store.selectedServices[id]!.add(s);
                                } else {
                                  _store.selectedServices[id]!.remove(s);
                                }
                              });
                              _debouncedRefreshProviders();
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
          ],
        ),
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
                  final isSelected = _store.selectedServices[categoryId]?.contains(service) ?? false;
                  
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
                              if (_store.selectedServices[categoryId] == null) {
                                _store.selectedServices[categoryId] = <String>{};
                              }
                              if (isSelected) {
                                _store.selectedServices[categoryId]!.remove(service);
                              } else {
                                _store.selectedServices[categoryId]!.add(service);
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
                  if (_store.selectedServices[category['id']]?.isNotEmpty == true)
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
                        '${_store.selectedServices[category['id']]!.length} ${AppStrings.getString('services', languageService.currentLanguage)} ${AppStrings.getString('selected', languageService.currentLanguage)}',
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

  Widget _buildProvidersSection(LanguageService languageService) {
    return Directionality(
      textDirection: languageService.textDirection,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(languageService.currentLanguage == 'ar' ? 'مقدمو الخدمة' : 'Service Providers', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_providers.isEmpty && !_loading && _error == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    languageService.currentLanguage == 'ar'
                        ? 'لا يوجد مزودون مطابقون حاليًا. جرّب تغيير عوامل التصفية.'
                        : 'No providers found. Try adjusting filters.',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount;
                if (constraints.maxWidth > 1400) crossAxisCount = 3; else if (constraints.maxWidth > 900) crossAxisCount = 2; else crossAxisCount = 1;
                // Use fixed mainAxisExtent to keep all cards the same height and avoid overflow
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    // Ensure uniform height; slightly taller for denser layouts
                    mainAxisExtent: crossAxisCount == 1
                        ? 360
                        : crossAxisCount == 2
                            ? 380
                            : 420,
                  ),
                  itemCount: _providers.length,
                  itemBuilder: (context, index) => _buildProviderCard(_providers[index], languageService),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderModel p, LanguageService languageService) {
    final lang = languageService.currentLanguage;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 6))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 28, backgroundColor: Colors.grey.shade200, backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null, child: p.avatarUrl == null ? const Icon(Icons.person, size: 28) : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        if (p.providerId != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '#${p.providerId}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(AppStrings.getString(p.city.toLowerCase(), lang), style: TextStyle(color: Colors.grey.shade700)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RatingBarIndicator(rating: p.ratingAverage, itemSize: 16, itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
                  Text('${p.ratingAverage.toStringAsFixed(1)} (${p.ratingCount})', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _kv(Icons.work_history, '${p.experienceYears} ${AppStrings.getString('years', lang)}'),
              _kv(Icons.language, _localizedLanguages(p.languages, lang).join(', ')),
              _kv(Icons.attach_money, '${p.hourlyRate.toStringAsFixed(0)} ${AppStrings.getString('hourly', lang)}'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: () {
              // Show more chips on web and avoid tooltip '+1'
              final maxVisible = 8;
              final visible = p.services.take(maxVisible).toList();
              final extras = p.services.length - visible.length;
              final chips = <Widget>[];
              chips.addAll(visible.map((s) => Chip(label: Text(AppStrings.getString(s, lang)))));
              // If there are still more, just append the rest without tooltip up to a safe cap
              if (extras > 0) {
                chips.addAll(p.services.skip(maxVisible).take(6).map((s) => Chip(label: Text(AppStrings.getString(s, lang)))));
              }
              return chips;
            }(),
          ),
          const Spacer(),
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
                  child: Text(AppStrings.getString('bookNow', lang)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: p.phone.isNotEmpty ? () => launchUrl(Uri(scheme: 'tel', path: p.phone)) : null,
                icon: const Icon(Icons.call),
                label: Text(AppStrings.getString('contact', lang)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  _openChatWithProvider(p);
                },
                icon: const Icon(Icons.chat),
                label: Text(AppStrings.getString('chat', lang)),
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
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.grey.shade800)),
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
              print('🔄 Web category widget - Message sent callback triggered');
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
} 