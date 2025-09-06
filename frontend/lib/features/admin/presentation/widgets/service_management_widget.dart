import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/services_service.dart';
import '../../../../shared/services/service_categories_service.dart';
import '../../../../shared/services/auth_service.dart';

class ServiceManagementWidget extends StatefulWidget {
  const ServiceManagementWidget({super.key});

  @override
  State<ServiceManagementWidget> createState() => _ServiceManagementWidgetState();
}

class _ServiceManagementWidgetState extends State<ServiceManagementWidget> {
  bool _isLoading = false;
  List<ServiceModel> _services = [];
  List<ServiceCategoryModel> _categories = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';
  final ServicesService _servicesService = ServicesService();
  final ServiceCategoriesService _categoriesService = ServiceCategoriesService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadServices();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoriesService.getCategories();
      setState(() {
        _categories = categories;
      });
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
      
      final services = await _servicesService.getServices(
        category: _selectedCategory != 'all' ? _selectedCategory : null,
        q: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: 100, // Get more services for admin view
        authService: authService,
      );
      
      setState(() {
        _services = services;
        _isLoading = false;
      });
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
        return _buildServiceManagement(context, languageService);
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
            // Header - More compact
            _buildHeader(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
            
            // Services count
            _buildServicesCount(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 16 : screenWidth > 1024 ? 12 : 8),
            
            // Filters - Improved sizing
            _buildFilters(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
            
            // Services table
            Expanded(
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
          
          // Table body
          Expanded(
            child: ListView.builder(
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
    final TextEditingController customCategoryController = TextEditingController();

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
                    // Category dropdown
                    Text(
                      AppStrings.getString('category', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
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
                        ..._categories.map((category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(
                            category.name,
                            style: GoogleFonts.cairo(fontSize: 14),
                          ),
                        )),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text(
                            AppStrings.getString('other', languageService.currentLanguage),
                            style: GoogleFonts.cairo(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    
                    // Show custom category field when "Other" is selected
                    if (selectedCategory == 'other') ...[
                      SizedBox(height: 16),
                      Text(
                        'Category name',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: customCategoryController,
                        decoration: InputDecoration(
                          hintText: 'Enter custom category name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: GoogleFonts.cairo(fontSize: 14),
                      ),
                    ],
                    
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
                    
                    // Validate custom category name if "Other" is selected
                    if (selectedCategory == 'other' && customCategoryController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please enter a category name',
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
                      selectedCategory == 'other' ? customCategoryController.text.trim() : null,
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

  Future<void> _createService(String category, String serviceName, String description, String? customCategoryName, LanguageService languageService) async {
    try {
      // Get AuthService from Provider context
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Determine the final category to use
      final finalCategory = category == 'other' && customCategoryName != null 
          ? customCategoryName 
          : category;
      
      // Create the service via API
      final createdService = await _servicesService.createService(
        title: serviceName,
        description: description,
        category: finalCategory,
        subcategory: category == 'other' ? customCategoryName : null,
        authService: authService,
      );
      
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

} 