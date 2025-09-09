import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/api_config.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/services_service.dart';
import '../../../../shared/services/service_categories_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/category_refresh_notifier.dart';

class ServiceManagementWidget extends StatefulWidget {
  const ServiceManagementWidget({super.key});

  @override
  State<ServiceManagementWidget> createState() => _ServiceManagementWidgetState();
}

class _ServiceManagementWidgetState extends State<ServiceManagementWidget> {
  // Silence console logs from this widget
  static const bool _adminLogsEnabled = false;
  bool _isLoading = false;
  List<ServiceModel> _services = [];
  List<ServiceCategoryModel> _categories = [];
  List<Map<String, dynamic>> _adminCategories = []; // Categories with counts from admin API
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  final ServicesService _servicesService = ServicesService();
  final ServiceCategoriesService _categoriesService = ServiceCategoriesService();
  
  // Timer for periodic category refresh
  Timer? _categoryRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadServices();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _categoryRefreshTimer?.cancel();
    super.dispose();
  }

  /// Start periodic refresh to keep categories up-to-date
  void _startPeriodicRefresh() {
    _categoryRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        if (kDebugMode && _adminLogsEnabled) {
          print('🔄 Periodic category refresh triggered');
        }
        _refreshCategories();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh categories when dependencies change (e.g., when returning to this page)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshCategories();
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      // Force refresh from database to get latest categories
      final categories = await _categoriesService.getCategories(forceRefresh: true);
      setState(() {
        _categories = categories;
      });
      
      if (kDebugMode && _adminLogsEnabled) {
        print('🔄 Categories refreshed: ${categories.length} categories loaded');
        for (final category in categories) {
          print('  - ${category.name} (${category.id})');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load categories: $e',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      if (kDebugMode) {
        print('❌ Error loading categories: $e');
      }
    }
  }

  /// Force refresh categories from database
  Future<void> _refreshCategories() async {
    if (kDebugMode && _adminLogsEnabled) {
      print('🔄 Force refreshing categories...');
    }
    
    // Clear cache and force refresh
    _categoriesService.clearCache();
    await _loadCategories();
    
    // Trigger a rebuild to ensure UI updates
    if (mounted) {
      setState(() {
        // This will trigger a rebuild of the dropdown
      });
    }
    
    if (kDebugMode && _adminLogsEnabled) {
      print('✅ Categories refresh completed - UI updated');
    }
  }

  /// Enhanced refresh with multiple strategies to ensure dynamic updates
  Future<void> _forceDynamicRefresh() async {
    if (kDebugMode && _adminLogsEnabled) {
      print('🚀 Starting dynamic category refresh...');
    }
    
    try {
      // Strategy 1: Clear all caches
      _categoriesService.clearCache();
      
      // Strategy 2: Force refresh from database
      final freshCategories = await _categoriesService.getCategories(forceRefresh: true);
      
      // Strategy 3: Update state and trigger rebuild
      if (mounted) {
        setState(() {
          _categories = freshCategories;
        });
      }
      
      // Strategy 4: Force refresh categories with services
      await _categoriesService.refreshCategoriesWithServices();
      
      // Strategy 5: Final state update
      if (mounted) {
        setState(() {
          // Force another rebuild to ensure dropdown updates
        });
      }
      
      if (kDebugMode && _adminLogsEnabled) {
        print('✅ Dynamic refresh completed - ${freshCategories.length} categories loaded');
        for (final category in freshCategories) {
          print('  📂 ${category.name} (${category.id})');
        }
      }
    } catch (e) {
      if (kDebugMode && _adminLogsEnabled) {
        print('❌ Error in dynamic refresh: $e');
      }
      // Fallback to regular refresh
      await _refreshCategories();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadServices();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadServices();
  }

  void _onStatusChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get AuthService from Provider context
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Fetch admin service data which includes categories with counts
      await _loadAdminServiceData(authService);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load services: $e',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAdminServiceData(AuthService authService) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authService.token != null) 'Authorization': 'Bearer ${authService.token}',
      };

      // Build query parameters
      final queryParams = <String, String>{};
      if (_selectedCategory != 'all') queryParams['category'] = _selectedCategory;
      if (_selectedStatus != 'all') queryParams['status'] = _selectedStatus;
      if (_searchQuery.isNotEmpty) queryParams['location'] = _searchQuery;
      queryParams['limit'] = '100';

      final uri = Uri.parse('${ApiConfig.baseUrl}/admin/services')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final responseData = data['data'];
          
          // Parse services
          final servicesData = responseData['services'] as List<dynamic>;
          if (kDebugMode && _adminLogsEnabled) {
            print('🔍 Raw services data: ${servicesData.length} items');
            if (servicesData.isNotEmpty) {
              print('🔍 First service data: ${servicesData[0]}');
            }
          }
          
          final services = <ServiceModel>[];
          for (int i = 0; i < servicesData.length; i++) {
            try {
              final service = ServiceModel.fromJson(servicesData[i]);
              services.add(service);
            } catch (e) {
              if (kDebugMode && _adminLogsEnabled) {
                print('❌ Error parsing service $i: $e');
                print('❌ Service data: ${servicesData[i]}');
              }
            }
          }
          
          // Parse categories with counts
          final categoriesData = responseData['categories'] as List<dynamic>;
          final adminCategories = categoriesData.map((json) => Map<String, dynamic>.from(json)).toList();
          
          if (kDebugMode && _adminLogsEnabled) {
            print('🔍 Categories loaded: ${adminCategories.length}');
            for (var cat in adminCategories) {
              print('🔍 Category: ${cat['name']} (ID: ${cat['id']}) - Count: ${cat['serviceCount']}');
            }
          }
          
          setState(() {
            _services = services;
            _adminCategories = adminCategories;
            _isLoading = false;
          });
          
          if (kDebugMode && _adminLogsEnabled) {
            print('✅ Loaded ${services.length} services and ${adminCategories.length} categories');
            print('🔍 Services data: ${services.map((s) => s.title).toList()}');
            print('🔍 Filtered services: ${_filteredServices.length}');
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to load admin service data');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode && _adminLogsEnabled) {
        print('❌ Error loading admin service data: $e');
      }
      rethrow;
    }
  }

  List<ServiceModel> get _filteredServices {
    return _services.where((service) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = service.title.toLowerCase();
        final description = service.description.toLowerCase();
        final providerName = service.provider?.fullName.toLowerCase() ?? '';
        
        if (!title.contains(query) && 
            !description.contains(query) && 
            !providerName.contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'all' && service.category != _selectedCategory) {
        return false;
      }

      // Status filter
      if (_selectedStatus != 'all') {
        final isActive = _selectedStatus == 'active';
        if (service.isActive != isActive) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return SingleChildScrollView(
          child: _buildServiceManagement(context, languageService),
        );
      },
    );
  }

  Widget _buildServiceManagement(BuildContext context, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isArabic = languageService.isArabic;
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
            
            // Categories with counts
            _buildCategoriesDisplay(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 16 : screenWidth > 1024 ? 12 : 8),
            
            // Services count
            _buildServicesCount(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 16 : screenWidth > 1024 ? 12 : 8),
            
            // Filters
            _buildFilters(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
            
            // Services table - Fixed height for proper scrolling
            SizedBox(
              height: 500, // Fixed height to ensure scrolling works
              child: _buildServicesTable(languageService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.getString('serviceManagement', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 22 : screenWidth > 1024 ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                AppStrings.getString('manageServiceListings', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        
        // Add service button - More compact
        ElevatedButton.icon(
          onPressed: () {
            _showAddServiceDialog(languageService);
          },
          icon: const Icon(Icons.add_business, size: 18),
          label: Text(
            AppStrings.getString('addService', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 1400 ? 16 : 14, 
              vertical: screenWidth > 1400 ? 10 : 8
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        
        SizedBox(width: 8),
        
        // Add category button
        ElevatedButton.icon(
          onPressed: () {
            _showAddCategoryDialog(languageService);
          },
          icon: const Icon(Icons.category, size: 18),
          label: Text(
            'Add Category',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 1400 ? 16 : 14, 
              vertical: screenWidth > 1400 ? 10 : 8
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        
        SizedBox(width: 8),
        
        // Refresh categories button
        ElevatedButton.icon(
          onPressed: () async {
            await _forceDynamicRefresh();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Categories refreshed dynamically', style: GoogleFonts.cairo()),
                backgroundColor: Colors.green,
              ),
            );
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(
            'Refresh',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 1400 ? 16 : 14, 
              vertical: screenWidth > 1400 ? 10 : 8
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesCount(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalServices = _services.length;
    final filteredServices = _filteredServices.length;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 16 : screenWidth > 1024 ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth > 1400 ? 10 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Red warning icon
          Container(
            width: screenWidth > 1400 ? 24 : 22,
            height: screenWidth > 1400 ? 24 : 22,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning,
              size: screenWidth > 1400 ? 16 : 14,
              color: Colors.white,
            ),
          ),
          SizedBox(width: screenWidth > 1400 ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.getString('totalServices', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  filteredServices == totalServices 
                    ? '$totalServices ${AppStrings.getString('services', languageService.currentLanguage)}'
                    : '$filteredServices ${AppStrings.getString('of', languageService.currentLanguage)} $totalServices ${AppStrings.getString('services', languageService.currentLanguage)}',
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 14 : 13,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
          ] else ...[
            // Large orange/red colored number
            Text(
              totalServices.toString(),
              style: GoogleFonts.cairo(
                fontSize: screenWidth > 1400 ? 32 : 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B35), // Orange-red color
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesDisplay(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 16 : screenWidth > 1024 ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth > 1400 ? 10 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category,
                size: screenWidth > 1400 ? 20 : 18,
                color: AppColors.primary,
              ),
              SizedBox(width: screenWidth > 1400 ? 8 : 6),
              Text(
                'Service Categories',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth > 1400 ? 12 : 10),
          
          // Categories grid
          if (_adminCategories.isEmpty && !_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No categories found',
                  style: GoogleFonts.cairo(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate responsive grid parameters
                final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                                     constraints.maxWidth > 800 ? 3 : 2;
                final childAspectRatio = constraints.maxWidth > 1200 ? 2.4 : 1.8; // Even more height for content
                final spacing = constraints.maxWidth > 1400 ? 12.0 : 10.0;
                
                return GridView.builder(
                    // Let the grid grow with content so it remains visible on smaller screens
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: _adminCategories.length,
                    itemBuilder: (context, index) {
                      final category = _adminCategories[index];
                      // Support both new (serviceCount) and legacy (count) keys
                      final count = category['serviceCount'] ?? category['count'] ?? 0;
                      final name = category['name'] ?? 'Unknown';
                      final color = category['color'] ?? '#9E9E9E';
                      final icon = category['icon'] ?? 'category';
                      // Dynamic sizing based on the computed grid cell width
                      final cellWidth = (constraints.maxWidth / crossAxisCount) - spacing;
                      final double scale = ((cellWidth / 360).clamp(0.85, 1.15)).toDouble();
                      final double pad = (12 * scale).clamp(10, 16);
                      final double iconCircle = (28 * scale).clamp(22, 34);
                      final double iconSize = (iconCircle * 0.55).clamp(12, 18);
                      final double nameFont = (13 * scale).clamp(11, 16);
                      final double countFont = (11 * scale).clamp(9, 13);
                      final double vSpace1 = (8 * scale).clamp(6, 12);
                      final double vSpace2 = (6 * scale).clamp(4, 10);
                      
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Make the card fill the grid cell so the delete button aligns to its corner
                          Positioned.fill(
                            child: Container(
                              padding: EdgeInsets.all(pad),
                              decoration: BoxDecoration(
                                color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(int.parse(color.replaceFirst('#', '0xFF'))).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Category icon
                                Container(
                                  width: iconCircle,
                                  height: iconCircle,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconData(icon),
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: vSpace1),
                                
                                // Category name
                                Flexible(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.cairo(
                                      fontSize: nameFont,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: vSpace2),
                                
                                // Service count
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (6 * scale).clamp(5, 9),
                                    vertical: (2 * scale).clamp(1, 3),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                                    borderRadius: BorderRadius.circular(10), // Slightly smaller radius
                                  ),
                                  child: Text(
                                    '$count',
                                    style: GoogleFonts.cairo(
                                      fontSize: countFont,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                              ),
                            ),
                          ),
                          // Delete button aligned to the card's top-right edge
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => _showCategoryDeleteConfirmation(context, category, languageService),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
              },
            ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'folder_open':
        return Icons.folder_open;
      case 'restaurant':
        return Icons.restaurant;
      case 'child_care':
        return Icons.child_care;
      case 'elderly':
        return Icons.elderly;
      case 'handyman':
        return Icons.handyman;
      case 'home':
        return Icons.home;
      case 'miscellaneous_services':
        return Icons.miscellaneous_services;
      default:
        return Icons.category;
    }
  }

  Widget _buildFilters(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 16 : screenWidth > 1024 ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth > 1400 ? 10 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('filters', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: screenWidth > 1400 ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: screenWidth > 1400 ? 12 : 10),
          
          // Responsive filter layout
          if (screenWidth > 768) ...[
            // Desktop/Tablet: Horizontal layout
            Row(
              children: [
                // Search - More compact
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: AppStrings.getString('searchServices', languageService.currentLanguage),
                      hintStyle: GoogleFonts.cairo(
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: screenWidth > 1400 ? 10 : 8,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(width: screenWidth > 1400 ? 12 : 10),
                
                // Category filter - More compact
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    onChanged: (value) => _onCategoryChanged(value!),
                    decoration: InputDecoration(
                      labelText: AppStrings.getString('category', languageService.currentLanguage),
                      labelStyle: GoogleFonts.cairo(
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: screenWidth > 1400 ? 10 : 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all', 
                        child: Text(
                          AppStrings.getString('allCategories', languageService.currentLanguage), 
                          style: GoogleFonts.cairo(fontSize: 13)
                        )
                      ),
                      ..._categories.map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          category.name,
                          style: GoogleFonts.cairo(fontSize: 13)
                        ),
                      )),
                    ],
                  ),
                ),
                
                SizedBox(width: screenWidth > 1400 ? 12 : 10),
                
                // Status filter - More compact
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    onChanged: (value) => _onStatusChanged(value!),
                    decoration: InputDecoration(
                      labelText: AppStrings.getString('status', languageService.currentLanguage),
                      labelStyle: GoogleFonts.cairo(
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: screenWidth > 1400 ? 10 : 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(AppStrings.getString('allStatus', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'active', child: Text(AppStrings.getString('active', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'inactive', child: Text(AppStrings.getString('inactive', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mobile: Vertical layout
            Column(
              children: [
                // Search
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: AppStrings.getString('searchServices', languageService.currentLanguage),
                    hintStyle: GoogleFonts.cairo(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Filters row
                Row(
                  children: [
                    // Category filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        onChanged: (value) => _onCategoryChanged(value!),
                        decoration: InputDecoration(
                          labelText: AppStrings.getString('category', languageService.currentLanguage),
                          labelStyle: GoogleFonts.cairo(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all', 
                            child: Text(
                              AppStrings.getString('allCategories', languageService.currentLanguage), 
                              style: GoogleFonts.cairo(fontSize: 13)
                            )
                          ),
                          ..._categories.map((category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(
                              category.name,
                              style: GoogleFonts.cairo(fontSize: 13)
                            ),
                          )),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        onChanged: (value) => _onStatusChanged(value!),
                        decoration: InputDecoration(
                          labelText: AppStrings.getString('status', languageService.currentLanguage),
                          labelStyle: GoogleFonts.cairo(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text(AppStrings.getString('allStatus', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'active', child: Text(AppStrings.getString('active', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'inactive', child: Text(AppStrings.getString('inactive', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServicesTable(LanguageService languageService) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business_center_outlined,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.getString('noServicesFound', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth > 1400 ? 10 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header - More compact
          Container(
            padding: EdgeInsets.all(screenWidth > 1400 ? 14 : 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth > 1400 ? 10 : 8),
                topRight: Radius.circular(screenWidth > 1400 ? 10 : 8),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildHeaderCell(AppStrings.getString('service', languageService.currentLanguage))),
                if (screenWidth > 768) ...[
                  Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('category', languageService.currentLanguage))),
                ],
                Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('status', languageService.currentLanguage))),
                Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('actions', languageService.currentLanguage))),
              ],
            ),
          ),
          
          // Table body - Full height with proper scrolling
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                return _buildServiceRow(service, languageService);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: screenWidth > 1400 ? 14 : 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildServiceRow(ServiceModel service, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 16 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Service info - Balanced sizing
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: screenWidth > 1400 ? 40 : screenWidth > 1024 ? 36 : 32,
                  height: screenWidth > 1400 ? 40 : screenWidth > 1024 ? 36 : 32,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(service.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getCategoryIcon(service.category),
                    color: _getCategoryColor(service.category),
                    size: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 18 : 16,
                  ),
                ),
                SizedBox(width: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 10 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 15 : screenWidth > 1024 ? 14 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        service.description,
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 13 : screenWidth > 1024 ? 12 : 11,
                          color: AppColors.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Category (hidden on mobile) - Balanced sizing
          if (screenWidth > 768) ...[
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth > 1400 ? 8 : 6,
                  vertical: screenWidth > 1400 ? 4 : 3,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(service.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getLocalizedCategoryLabel(service.category, languageService).toUpperCase(),
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 11 : screenWidth > 1024 ? 10 : 9,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(service.category),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          
          // Status - Balanced sizing
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 1400 ? 8 : 6,
                vertical: screenWidth > 1400 ? 4 : 3,
              ),
              decoration: BoxDecoration(
                color: service.isActive 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                service.isActive 
                  ? AppStrings.getString('active', languageService.currentLanguage).toUpperCase()
                  : AppStrings.getString('inactive', languageService.currentLanguage).toUpperCase(),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 11 : screenWidth > 1024 ? 10 : 9,
                  fontWeight: FontWeight.w600,
                  color: service.isActive ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Edit service
                  },
                  icon: Icon(
                    Icons.push_pin_outlined,
                    size: screenWidth > 1400 ? 18 : 16,
                    color: AppColors.primary,
                  ),
                  tooltip: AppStrings.getString('edit', languageService.currentLanguage),
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(service, languageService),
                  icon: Icon(
                    Icons.delete_outline,
                    size: screenWidth > 1400 ? 18 : 16,
                    color: Colors.red,
                  ),
                  tooltip: AppStrings.getString('delete', languageService.currentLanguage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedCategoryLabel(String category, LanguageService languageService) {
    // Try to find the category in the loaded categories
    try {
      final categoryModel = _categories.firstWhere((cat) => cat.id == category);
      return categoryModel.name;
    } catch (e) {
      // Fallback to hardcoded labels if category not found
      switch (category) {
        case 'cleaning':
          return AppStrings.getString('cleaning', languageService.currentLanguage);
        case 'elderly_support':
          return AppStrings.getString('elderlySupport', languageService.currentLanguage);
        case 'maintenance':
          return AppStrings.getString('maintenance', languageService.currentLanguage);
        default:
          return category;
      }
    }
  }

  String _getLocalizedPriceType(String type, LanguageService languageService) {
    switch (type) {
      case 'hourly':
        return AppStrings.getString('hourly', languageService.currentLanguage);
      case 'daily':
        return AppStrings.getString('daily', languageService.currentLanguage);
      case 'fixed':
        return AppStrings.getString('fixed', languageService.currentLanguage);
      default:
        return type;
    }
  }

  Color _getCategoryColor(String category) {
    // Try to find the category in the loaded categories
    try {
      final categoryModel = _categories.firstWhere((cat) => cat.id == category);
      return Color(ServiceCategoriesService.getColorFromString(categoryModel.color));
    } catch (e) {
      // Fallback to hardcoded colors if category not found
      switch (category) {
        case 'cleaning':
          return Colors.blue;
        case 'elderly_support':
          return Colors.orange;
        case 'maintenance':
          return Colors.green;
        default:
          return AppColors.textLight;
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    // Try to find the category in the loaded categories
    try {
      final categoryModel = _categories.firstWhere((cat) => cat.id == category);
      return _getIconFromString(categoryModel.icon);
    } catch (e) {
      // Fallback to hardcoded icons if category not found
      switch (category) {
        case 'cleaning':
          return Icons.cleaning_services;
        case 'elderly_support':
          return Icons.elderly;
        case 'maintenance':
          return Icons.build;
        default:
          return Icons.business_center;
      }
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'folder_open':
        return Icons.folder_open;
      case 'restaurant':
        return Icons.restaurant;
      case 'child_care':
        return Icons.child_care;
      case 'elderly':
        return Icons.elderly;
      case 'handyman':
        return Icons.handyman;
      case 'home':
        return Icons.home;
      case 'miscellaneous_services':
        return Icons.miscellaneous_services;
      default:
        return Icons.business_center;
    }
  }

  void _showAddServiceDialog(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    String selectedCategory = _categories.isNotEmpty ? _categories.first.id : 'cleaning'; // Default selection
    final TextEditingController serviceNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    // Refresh categories before showing dialog to ensure latest data
    _refreshCategories();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                AppStrings.getString('addService', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              content: SizedBox(
                width: screenWidth > 1400 ? 500 : 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category dropdown with refresh button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppStrings.getString('category', languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await _refreshCategories();
                            setState(() {
                              // Trigger dialog rebuild to show updated categories
                            });
                          },
                          icon: Icon(Icons.refresh, size: 18, color: AppColors.primary),
                          tooltip: 'Refresh categories',
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: [
                        ..._categories.map((category) {
                          if (kDebugMode && _adminLogsEnabled) {
                            print('📋 Adding category to dropdown: ${category.name} (${category.id})');
                          }
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(
                              category.name,
                              style: GoogleFonts.cairo(fontSize: 14),
                            ),
                          );
                        }),
                      ],
                    ),
                    
                    
                    SizedBox(height: 16),
                    
                    // Service name field
                    Text(
                      'Service name',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: serviceNameController,
                      decoration: InputDecoration(
                        hintText: AppStrings.getString('enterServiceName', languageService.currentLanguage),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: GoogleFonts.cairo(fontSize: 14),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Description field
                    Text(
                      AppStrings.getString('description', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: AppStrings.getString('enterDescription', languageService.currentLanguage),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      style: GoogleFonts.cairo(fontSize: 14),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    AppStrings.getString('cancel', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (serviceNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppStrings.getString('pleaseEnterServiceName', languageService.currentLanguage),
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    if (descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppStrings.getString('pleaseEnterDescription', languageService.currentLanguage),
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    
                    // TODO: Implement service creation
                    _createService(
                      selectedCategory,
                      serviceNameController.text.trim(),
                      descriptionController.text.trim(),
                      languageService,
                    );
                    
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppStrings.getString('addService', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createService(String category, String serviceName, String description, LanguageService languageService) async {
    try {
      // Get AuthService from Provider context
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Use the selected category directly
      final finalCategory = category;
      
      // Create the service via API
      if (kDebugMode) {
        print('🔧 Creating service: "$serviceName" with category: "$finalCategory"');
      }
      
      final createdService = await _servicesService.createService(
        title: serviceName,
        description: description,
        category: finalCategory,
        authService: authService,
      );
      
      if (kDebugMode) {
        print('🔧 Service created: ${createdService?.title} with category: ${createdService?.category}');
      }
      
      if (createdService != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Service "$serviceName" created successfully in category "$finalCategory"',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the services list to show the new service
        _loadServices();
        
        // Clear category cache to ensure new services appear in categories
        _categoriesService.clearCache();
        
        // Force refresh categories with services from database
        try {
          // First check if the service exists
          final serviceExists = await _categoriesService.checkServiceExists('clean all', authService: authService);
          
          // If it's a cleaning service, force add it to cleaning category
          if (serviceName.toLowerCase().contains('clean')) {
            await _categoriesService.forceAddServiceToCategory(serviceName, 'cleaning', authService: authService);
          }
          
          // Force refresh category widgets if they exist
          if (mounted) {
            // Try to find and refresh category widgets
            final context = this.context;
            if (context.mounted) {
              // This will trigger a rebuild of any category widgets that are listening
              setState(() {});
            }
          }
          
          final refreshedCategories = await _categoriesService.refreshCategoriesWithServices();
          if (kDebugMode) {
            print('✅ Categories refreshed with new services from database');
            print('📂 Refreshed categories: ${refreshedCategories.length}');
            for (final cat in refreshedCategories) {
              print('  - ${cat.name}: ${cat.actualServices?.length ?? 0} services');
              if (cat.id == 'cleaning') {
                print('    Cleaning services:');
                for (final service in cat.actualServices ?? []) {
                  print('      * "${service.title}"');
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error refreshing categories: $e');
          }
        }
      } else {
        throw Exception('Service creation returned null');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create service: ${e.toString()}',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddCategoryDialog(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    final TextEditingController categoryNameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add New Category',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth > 1400 ? 18 : 16,
            ),
          ),
          content: SizedBox(
            width: screenWidth > 1400 ? 400 : 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Name
                Text(
                  'Category Name *',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: categoryNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter category name (e.g., Pet Care Services)',
                    hintStyle: GoogleFonts.cairo(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: screenWidth > 1400 ? 12 : 10,
                    ),
                  ),
                  style: GoogleFonts.cairo(fontSize: 14),
                ),
                
                SizedBox(height: 16),
                
                // Description
                Text(
                  'Description',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter category description (optional)',
                    hintStyle: GoogleFonts.cairo(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: screenWidth > 1400 ? 12 : 10,
                    ),
                  ),
                  style: GoogleFonts.cairo(fontSize: 14),
                ),
                
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.cairo(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (categoryNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a category name',
                        style: GoogleFonts.cairo(),
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                _createCategory(
                  categoryNameController.text.trim(),
                  descriptionController.text.trim(),
                  languageService,
                );
                
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Create Category',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createCategory(String name, String description, LanguageService languageService) async {
    try {
      // Get AuthService from Provider context
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (kDebugMode) {
        print('🔧 Creating category: "$name"');
      }
      
      final createdCategory = await _categoriesService.createCategory(
        name: name,
        description: description.isNotEmpty ? description : null,
        authService: authService,
      );
      
      if (createdCategory != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Category "$name" created successfully',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Force dynamic refresh to show the new category immediately
        await _forceDynamicRefresh();
        
        // Notify other widgets that categories have been updated
        CategoryRefreshNotifier().notifyRefresh();
        
        if (kDebugMode) {
          print('✅ Category created successfully: ${createdCategory.name}');
          print('📢 Notified all widgets of category refresh');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create category: ${e.toString()}',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      
      if (kDebugMode) {
        print('❌ Error creating category: $e');
      }
    }
  }

  void _showDeleteConfirmation(ServiceModel service, LanguageService languageService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Service',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${service.title}"? This action cannot be undone.',
            style: GoogleFonts.cairo(
              color: AppColors.textDark,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.cairo(
                  color: AppColors.textLight,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteService(service, languageService);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.cairo(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteService(ServiceModel service, LanguageService languageService) async {
    try {
      // Get AuthService from Provider context
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (kDebugMode) {
        print('🗑️ Deleting service: "${service.title}" (ID: ${service.id})');
      }
      
      final success = await _servicesService.deleteService(
        serviceId: service.id,
        authService: authService,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Service "${service.title}" deleted successfully',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the services list to remove the deleted service
        _loadServices();
        
        // Clear category cache to ensure changes are reflected
        _categoriesService.clearCache();
        
        if (kDebugMode) {
          print('✅ Service deleted successfully');
        }
      } else {
        throw Exception('Delete operation returned false');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete service: ${e.toString()}',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      
      if (kDebugMode) {
        print('❌ Error deleting service: $e');
      }
    }
  }

  /// Show delete confirmation dialog for categories
  void _showCategoryDeleteConfirmation(BuildContext context, Map<String, dynamic> category, LanguageService languageService) {
    final categoryName = category['name'] ?? 'Unknown';
    final serviceCount = category['serviceCount'] ?? 0;
    
    if (kDebugMode) {
      print('🗑️ Delete confirmation for category: $category');
      print('🗑️ Category ID: ${category['id']}');
      print('🗑️ Category name: $categoryName');
      print('🗑️ Service count: $serviceCount');
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Category',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete the category "$categoryName"?',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              if (serviceCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '⚠️ This category has $serviceCount service(s). Deleting it will also remove all associated services.',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.cairo(
                  color: AppColors.textLight,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCategory(category);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Delete category from both frontend and database
  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;
      
      if (token == null) {
        throw Exception('Authentication required');
      }

      final categoryId = category['id'];
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      // Delete from database
      final deleteUri = Uri.parse('${ApiConfig.baseUrl}/admin/categories/$categoryId');
      
      if (kDebugMode) {
        print('🗑️ Deleting category: $categoryId');
        print('🗑️ Delete URL: $deleteUri');
        print('🗑️ Headers: $headers');
      }
      
      final deleteResponse = await http.delete(deleteUri, headers: headers);
      
      if (kDebugMode) {
        print('🗑️ Delete response status: ${deleteResponse.statusCode}');
        print('🗑️ Delete response body: ${deleteResponse.body}');
      }

      if (deleteResponse.statusCode == 200) {
        // Remove from frontend list
        setState(() {
          _adminCategories.removeWhere((cat) => cat['id'] == categoryId);
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Category "${category['name']}" deleted successfully',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh the data to update service counts
        await _loadAdminServiceData(authService);
      } else {
        final errorData = json.decode(deleteResponse.body);
        throw Exception(errorData['message'] ?? 'Failed to delete category');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting category: ${e.toString()}',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

} 