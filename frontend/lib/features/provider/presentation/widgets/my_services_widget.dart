import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/provider_service.dart';
import '../../../../shared/services/service_categories_data.dart';
import '../../../../shared/services/auth_service.dart';

class MyServicesWidget extends StatefulWidget {
  const MyServicesWidget({super.key});

  @override
  State<MyServicesWidget> createState() => _MyServicesWidgetState();
}

class _MyServicesWidgetState extends State<MyServicesWidget> {


  
  // Price editing state
  int? _editingServiceIndex;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _priceTypeController = TextEditingController();
  String _selectedCurrency = 'ILS';

  // Service creation state
  final TextEditingController _serviceTitleController = TextEditingController();
  final TextEditingController _serviceDescriptionController = TextEditingController();
  final TextEditingController _fieldDescriptionController = TextEditingController(); // New controller for field description
  final TextEditingController _newServicePriceController = TextEditingController();
  final TextEditingController _newServicePriceTypeController = TextEditingController();
  String _newServiceCurrency = 'ILS';
  String _selectedCategory = 'cleaning';
  String _selectedSubcategory = '';
  List<String> _currentSubcategories = [];

  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
    // Initialize current subcategories
    _currentSubcategories = ServiceCategoriesData.getSubcategoriesByCategory(_selectedCategory);
  }

  Future<void> _loadServices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('🔍 Debug: Loading services for current user...');
      
      // Check if user is authenticated
      final authService = Provider.of<AuthService>(context, listen: false);
      print('🔍 Debug: User authenticated: ${authService.isAuthenticated}');
      print('🔍 Debug: User token: ${authService.token != null ? "Present" : "Missing"}');
      
      final providerService = ProviderService();
      final services = await providerService.getUserServices();
      
      print('🔍 Debug: Received ${services.length} services from getUserServices()');
      
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      print('🔍 Debug: Error in _loadServices: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            
            // Responsive breakpoints
            final isDesktop = screenWidth > 1200;
            final isTablet = screenWidth > 768 && screenWidth <= 1200;
            final isMobile = screenWidth <= 768;
            
            return _buildMyServicesWidget(languageService, isMobile, isTablet, isDesktop, screenWidth);
          },
        );
      },
    );
  }

  Widget _buildMyServicesWidget(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with multi-edit controls
          _buildHeader(languageService, isMobile, isTablet, isDesktop),
          
          SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
          

          
          // Loading state
          if (_isLoading) _buildLoadingState(languageService, isMobile, isTablet, isDesktop),
          
          // Error state
          if (_error != null) _buildErrorState(languageService, isMobile, isTablet, isDesktop),
          
          // Services grid or empty state
          if (!_isLoading && _error == null) 
            _services.isEmpty 
              ? _buildEmptyState(languageService, isMobile, isTablet, isDesktop)
              : _buildServicesGrid(languageService, isMobile, isTablet, isDesktop, screenWidth),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and subtitle with Palestine element
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.getString('myServices', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.greyDark,
                    ),
                  ),
                  SizedBox(height: isMobile ? 2.0 : (isTablet ? 4.0 : 6.0)),
                  Text(
                    AppStrings.getString('manageYourServices', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // Palestine identity element
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0), 
                vertical: isMobile ? 4.0 : (isTablet ? 5.0 : 6.0)
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🇵🇸',
                    style: TextStyle(fontSize: isMobile ? 14.0 : (isTablet ? 15.0 : 16.0)),
                  ),
                  SizedBox(width: isMobile ? 4.0 : (isTablet ? 5.0 : 6.0)),
                                          Text(
                          AppStrings.getString('palestine', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
        
        // Action buttons
        Row(
          children: [
            // Add new service button
            Expanded(
              child: Container(
                height: isMobile ? 36 : (isTablet ? 40 : 44),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      _showAddServiceDialog(languageService);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: isMobile ? 16 : (isTablet ? 18 : 20),
                          color: AppColors.white,
                        ),
                        SizedBox(width: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                        Text(
                          AppStrings.getString('addService', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 12.0 : (isTablet ? 13.0 : 14.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ],
    );
  }



  Widget _buildEmptyState(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24.0 : (isTablet ? 32.0 : 40.0)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state icon
          Container(
            width: isMobile ? 80 : (isTablet ? 100 : 120),
            height: isMobile ? 80 : (isTablet ? 100 : 120),
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.work_outline,
              size: isMobile ? 40 : (isTablet ? 50 : 60),
              color: AppColors.grey,
            ),
          ),
          SizedBox(height: isMobile ? 16.0 : (isTablet ? 20.0 : 24.0)),
          
          // Empty state title
          Text(
            AppStrings.getString('noServicesYet', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : (isTablet ? 20.0 : 22.0),
              fontWeight: FontWeight.bold,
              color: AppColors.greyDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
          
          // Empty state description
          Text(
            AppStrings.getString('noServicesDescription', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : (isTablet ? 15.0 : 16.0),
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 24.0 : (isTablet ? 32.0 : 40.0)),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop, double screenWidth) {
    // Responsive grid configuration
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;
    
    if (isMobile) {
      crossAxisCount = 1; // Single column on mobile for better readability
      childAspectRatio = 2.8; // More compact cards on mobile
      crossAxisSpacing = 0.0; // No spacing needed for single column
      mainAxisSpacing = 12.0;
    } else if (isTablet) {
      crossAxisCount = 2; // Two columns on tablet
      childAspectRatio = 2.2;
      crossAxisSpacing = 12.0;
      mainAxisSpacing = 12.0;
    } else {
      crossAxisCount = 3; // Three columns on desktop
      childAspectRatio = 1.8;
      crossAxisSpacing = 16.0;
      mainAxisSpacing = 16.0;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(_services[index], index, languageService, isMobile, isTablet, isDesktop);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, int index, LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    final isActive = _getServiceStatus(service);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Navigate to service details
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 10.0 : (isTablet ? 12.0 : 14.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0), 
                          vertical: isMobile ? 3.0 : (isTablet ? 4.0 : 6.0)
                        ),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isMobile ? 4 : (isTablet ? 6 : 8),
                              height: isMobile ? 4 : (isTablet ? 6 : 8),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.success : AppColors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: isMobile ? 3.0 : (isTablet ? 4.0 : 6.0)),
                            Flexible(
                              child: Text(
                                isActive 
                                    ? AppStrings.getString('active', languageService.currentLanguage)
                                    : AppStrings.getString('inactive', languageService.currentLanguage),
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 9.0 : (isTablet ? 10.0 : 11.0),
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? AppColors.success : AppColors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
                
                // Service icon and name
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.work,
                        size: isMobile ? 16 : (isTablet ? 18 : 20),
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getServiceName(service, languageService),
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 14.0 : (isTablet ? 16.0 : 18.0),
                              fontWeight: FontWeight.bold,
                              color: AppColors.greyDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                
                // Price and stats
                Row(
                  children: [
                    // Price with edit button
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0), 
                          vertical: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                                                         Expanded(
                               child: Text(
                                 _getPriceDisplay(service, languageService),
                                 style: GoogleFonts.cairo(
                                   fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
                                   fontWeight: FontWeight.bold,
                                   color: AppColors.primary,
                                 ),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                            SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)),
                            GestureDetector(
                              onTap: () => _showPriceEditDialog(index, service, languageService),
                              child: Container(
                                padding: EdgeInsets.all(isMobile ? 2.0 : (isTablet ? 3.0 : 4.0)),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: isMobile ? 10 : (isTablet ? 12 : 14),
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // Stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Rating
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: isMobile ? 12 : (isTablet ? 14 : 16),
                              color: AppColors.warning,
                            ),
                            SizedBox(width: isMobile ? 2.0 : (isTablet ? 3.0 : 4.0)),
                            Text(
                              _getServiceRating(service).toString(),
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 11.0 : (isTablet ? 12.0 : 14.0),
                                fontWeight: FontWeight.bold,
                                color: AppColors.greyDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 1.0 : (isTablet ? 2.0 : 3.0)),
                        // Bookings
                        Text(
                          '${_getServiceBookings(service)} ${AppStrings.getString('bookings', languageService.currentLanguage)}',
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 9.0 : (isTablet ? 10.0 : 11.0),
                            color: AppColors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Individual service action buttons
                SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Activate/Deactivate button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleServiceStatus(index, service),
                        icon: Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          size: isMobile ? 14 : (isTablet ? 16 : 18),
                          color: AppColors.white,
                        ),
                        label: Text(
                          isActive 
                              ? AppStrings.getString('deactivate', languageService.currentLanguage)
                              : AppStrings.getString('activate', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0),
                            vertical: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)),
                    
                    // Delete button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteService(index, service),
                        icon: Icon(
                          Icons.delete,
                          size: isMobile ? 14 : (isTablet ? 16 : 18),
                          color: AppColors.white,
                        ),
                        label: Text(
                          AppStrings.getString('delete', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0),
                            vertical: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // Individual service action methods
  void _toggleServiceStatus(int index, Map<String, dynamic> service) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final isActive = _getServiceStatus(service);
    
    try {
      final providerService = ProviderService();
      final serviceId = service['_id'] as String;
      
      final success = isActive 
          ? await providerService.deactivateServices([serviceId])
          : await providerService.activateServices([serviceId]);
      
      if (!mounted) return;
      
      if (success) {
        // Reload services to reflect changes
        await _loadServices();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive 
                  ? AppStrings.getString('serviceDeactivatedSuccessfully', languageService.currentLanguage)
                  : AppStrings.getString('serviceActivatedSuccessfully', languageService.currentLanguage),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive 
                  ? AppStrings.getString('failedToDeactivateService', languageService.currentLanguage)
                  : AppStrings.getString('failedToActivateService', languageService.currentLanguage),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive 
                ? AppStrings.getString('failedToDeactivateService', languageService.currentLanguage)
                : AppStrings.getString('failedToActivateService', languageService.currentLanguage),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _deleteService(int index, Map<String, dynamic> service) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.getString('confirmDelete', languageService.currentLanguage),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${AppStrings.getString('deleteServiceConfirmation', languageService.currentLanguage)} "${_getServiceName(service, languageService)}"?',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.getString('cancel', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                color: AppColors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              AppStrings.getString('delete', languageService.currentLanguage),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final providerService = ProviderService();
      final serviceId = service['_id'] as String;
      
      final success = await providerService.deleteService(serviceId);
      
      if (!mounted) return;
      
      if (success) {
        // Reload services to reflect changes
        await _loadServices();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.getString('serviceDeletedSuccessfully', languageService.currentLanguage),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.getString('failedToDeleteService', languageService.currentLanguage),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.getString('failedToDeleteService', languageService.currentLanguage),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }



  Widget _buildLoadingState(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: isMobile ? 40.0 : (isTablet ? 60.0 : 80.0)),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: isMobile ? 16.0 : (isTablet ? 20.0 : 24.0)),
          Text(
            AppStrings.getString('loading', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : (isTablet ? 16.0 : 18.0),
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: isMobile ? 40.0 : (isTablet ? 60.0 : 80.0)),
          Icon(
            Icons.error_outline,
            size: isMobile ? 48.0 : (isTablet ? 56.0 : 64.0),
            color: AppColors.error,
          ),
          SizedBox(height: isMobile ? 16.0 : (isTablet ? 20.0 : 24.0)),
          Text(
            AppStrings.getString('errorLoadingServices', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : (isTablet ? 16.0 : 18.0),
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
          Text(
            _error ?? '',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 16.0 : (isTablet ? 20.0 : 24.0)),
          ElevatedButton(
            onPressed: _loadServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppStrings.getString('retry', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPriceEditDialog(int index, Map<String, dynamic> service, LanguageService languageService) {
    _editingServiceIndex = index;
    
    // Handle different data types for price amount
    final priceAmount = _safeParseAmount(service['price']?['amount'] ?? service['priceAmount'] ?? 0.0);
    _priceController.text = priceAmount.toString();
    _priceTypeController.text = service['price']?['type'] ?? service['priceType'] ?? 'hourly';
    _selectedCurrency = service['price']?['currency'] ?? service['currency'] ?? 'ILS';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildPriceEditDialog(languageService);
      },
    );
  }

  Widget _buildPriceEditDialog(LanguageService languageService) {
    return AlertDialog(
      title: Text(
        AppStrings.getString('editPrice', languageService.currentLanguage),
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.greyDark,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price amount
            Text(
              AppStrings.getString('price', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '25.0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            
            // Price type
            Text(
              AppStrings.getString('priceType', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _priceTypeController.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                DropdownMenuItem(
                  value: 'hourly',
                  child: Text(AppStrings.getString('hourly', languageService.currentLanguage)),
                ),
                DropdownMenuItem(
                  value: 'daily',
                  child: Text(AppStrings.getString('daily', languageService.currentLanguage)),
                ),
                DropdownMenuItem(
                  value: 'fixed',
                  child: Text(AppStrings.getString('fixed', languageService.currentLanguage)),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _priceTypeController.text = value;
                }
              },
            ),
            SizedBox(height: 16),
            
            // Currency
            Text(
              AppStrings.getString('currency', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                DropdownMenuItem(
                  value: 'ILS',
                  child: Text('₪ ILS'),
                ),
                DropdownMenuItem(
                  value: 'USD',
                  child: Text('\$ USD'),
                ),
                DropdownMenuItem(
                  value: 'EUR',
                  child: Text('€ EUR'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _resetPriceEditing();
          },
          child: Text(
            AppStrings.getString('cancel', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => _savePriceChanges(languageService),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            AppStrings.getString('save', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _savePriceChanges(LanguageService languageService) {
    final amount = double.tryParse(_priceController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.getString('invalidPrice', languageService.currentLanguage)),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_editingServiceIndex != null) {
      setState(() {
        final service = _services[_editingServiceIndex!];
        
        // Update the price object structure
        service['price'] = {
          'amount': amount,
          'type': _priceTypeController.text,
          'currency': _selectedCurrency,
        };
        
        // Also update the legacy fields for backward compatibility
        service['priceAmount'] = amount;
        service['priceType'] = _priceTypeController.text;
        service['currency'] = _selectedCurrency;
        
        // Update the display price string
        final currencySymbol = _getCurrencySymbol(_selectedCurrency);
        final priceTypeText = _getLocalizedPriceType(_priceTypeController.text, languageService);
        service['priceDisplay'] = '$currencySymbol${amount.toStringAsFixed(0)}/$priceTypeText';
      });
      
      // Call API to update service price
      _updateServicePrice(_editingServiceIndex!);
    }

    Navigator.of(context).pop();
    _resetPriceEditing();
  }

  void _resetPriceEditing() {
    _editingServiceIndex = null;
    _priceController.clear();
    _priceTypeController.clear();
    _selectedCurrency = 'ILS';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'ILS':
        return '₪';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '₪';
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

  String _getPriceDisplay(Map<String, dynamic> service, LanguageService languageService) {
    // Check if we have a priceDisplay field (from our updates)
    if (service['priceDisplay'] != null) {
      return service['priceDisplay'];
    }
    
    // Check if we have a price object
    if (service['price'] != null && service['price'] is Map) {
      final price = service['price'] as Map<String, dynamic>;
      
      // Handle different data types for amount
      final amount = _safeParseAmount(price['amount'] ?? 0.0);
      
      final type = price['type'] ?? 'hourly';
      final currency = price['currency'] ?? 'ILS';
      
      final currencySymbol = _getCurrencySymbol(currency);
      final priceTypeText = _getLocalizedPriceType(type, languageService);
      return '$currencySymbol${amount.toStringAsFixed(0)}/$priceTypeText';
    }
    
    // Fallback to legacy fields
    if (service['price'] != null && service['price'] is String) {
      return service['price'] as String;
    }
    
    // Default fallback
    return '₪0/hour';
  }

  String _getServiceName(Map<String, dynamic> service, LanguageService languageService) {
    // Check if we have a title field (from backend)
    if (service['title'] != null) {
      return service['title'] as String;
    }
    
    // Check if we have a name field (from legacy data)
    if (service['name'] != null) {
      return AppStrings.getString(service['name'], languageService.currentLanguage);
    }
    
    // Default fallback
    return 'Service';
  }

  bool _getServiceStatus(Map<String, dynamic> service) {
    // Check if we have an isActive field (from backend)
    if (service['isActive'] != null) {
      return service['isActive'] as bool;
    }
    
    // Check if we have a status field (from legacy data)
    if (service['status'] != null) {
      return service['status'] == 'active';
    }
    
    // Default to active
    return true;
  }

  double _getServiceRating(Map<String, dynamic> service) {
    // Check if we have a rating object (from backend)
    if (service['rating'] != null && service['rating'] is Map) {
      final rating = service['rating'] as Map<String, dynamic>;
      return (rating['average'] ?? 0.0) as double;
    }
    
    // Check if we have a rating field (from legacy data)
    if (service['rating'] != null && service['rating'] is num) {
      return (service['rating'] as num).toDouble();
    }
    
    // Default fallback
    return 0.0;
  }

  int _getServiceBookings(Map<String, dynamic> service) {
    // For now, return a default value since bookings might not be available
    // TODO: Implement actual booking count when the backend provides it
    return service['bookings'] ?? 0;
  }

  double _safeParseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  void _showAddServiceDialog(LanguageService languageService) {
    _serviceTitleController.clear();
    _serviceDescriptionController.clear();
    _newServicePriceController.clear();
    _newServicePriceTypeController.text = 'hourly';
    _newServiceCurrency = 'ILS';
    _selectedCategory = 'cleaning';
    _selectedSubcategory = '';
    // Initialize current subcategories
    _currentSubcategories = ServiceCategoriesData.getSubcategoriesByCategory(_selectedCategory);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildAddServiceDialog(languageService);
      },
    );
  }

  Widget _buildAddServiceDialog(LanguageService languageService) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setDialogState) {
        // Check if "Other" is selected in any field
        final hasOtherSelection = _selectedCategory == 'other' || _selectedSubcategory == 'other';
        
        return AlertDialog(
          title: Text(
            AppStrings.getString('addService', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.greyDark,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Service Category
            Text(
              'Service Category',
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                DropdownMenuItem(value: 'cleaning', child: Text('Cleaning')),
                DropdownMenuItem(value: 'childcare', child: Text('Childcare')),
                DropdownMenuItem(value: 'elderly', child: Text('Elderly Care')),
                DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                DropdownMenuItem(value: 'cooking', child: Text('Cooking')),
                DropdownMenuItem(value: 'organizing', child: Text('Organizing')),
                DropdownMenuItem(value: 'newhome', child: Text('New Home')),
                DropdownMenuItem(value: 'miscellaneous', child: Text('Miscellaneous')),
                DropdownMenuItem(value: 'other', child: Text('Other (Custom Category)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setDialogState(() {
                    _selectedCategory = value;
                    _selectedSubcategory = ''; // Reset subcategory when category changes
                    // Update the current subcategories list
                    if (value != 'other') {
                      _currentSubcategories = ServiceCategoriesData.getSubcategoriesByCategory(value);
                    } else {
                      _currentSubcategories = [];
                    }
                    // Auto-fill the service title with the category name
                    if (value != 'other') {
                      final categoryNames = {
                        'cleaning': 'Cleaning',
                        'childcare': 'Childcare',
                        'elderly': 'Elderly Care',
                        'maintenance': 'Maintenance',
                        'cooking': 'Cooking',
                        'organizing': 'Organizing',
                        'newhome': 'New Home',
                        'miscellaneous': 'Miscellaneous',
                      };
                      _serviceTitleController.text = categoryNames[value] ?? '';
                    } else {
                      _serviceTitleController.clear();
                    }
                  });
                }
              },
            ),
            SizedBox(height: 16),

            // Service Title (only shown for non-"Other" categories)
            if (_selectedCategory != 'other') ...[
              Text(
                'Service Title',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greyDark,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _serviceTitleController,
                decoration: InputDecoration(
                  hintText: 'Enter service title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Service description (always shown, required when "Other" is selected)
            Text(
              _selectedCategory == 'other'
                  ? 'Service Description *'
                  : AppStrings.getString('description', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: 8),
                          TextField(
                controller: _serviceDescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _selectedCategory == 'other' 
                      ? 'Describe your custom service (this will be the service title)'
                      : 'Describe what services you provide, your experience, and what customers can expect...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            SizedBox(height: 16),

                          // Field (subcategory) dropdown - only show when not "other" category
              if (_selectedCategory != 'other') ...[
                Text(
                  'Field',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyDark,
                  ),
                ),
                SizedBox(height: 8),
                // Create a new dropdown widget each time to force rebuild
                _buildSubcategoryDropdown(setDialogState),
              SizedBox(height: 16),

              // Description field (required when "Other" is selected)
              Text(
                _selectedSubcategory == 'other' ? 'Description *' : 'Description',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greyDark,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _fieldDescriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _selectedSubcategory == 'other' 
                      ? 'Please describe your custom field (required)'
                      : 'Enter field description...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              SizedBox(height: 8),
              // Field description
              if (_selectedSubcategory.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getSubcategoryDescription(_selectedSubcategory),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16),
            ],

            // Price amount
            Text(
              AppStrings.getString('price', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _newServicePriceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '25.0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            SizedBox(height: 16),

            // Price type
            Text(
              AppStrings.getString('priceType', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _newServicePriceTypeController.text,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                DropdownMenuItem(value: 'hourly', child: Text(AppStrings.getString('hourly', languageService.currentLanguage))),
                DropdownMenuItem(value: 'daily', child: Text(AppStrings.getString('daily', languageService.currentLanguage))),
                DropdownMenuItem(value: 'fixed', child: Text(AppStrings.getString('fixed', languageService.currentLanguage))),
              ],
              onChanged: (value) {
                if (value != null) {
                  _newServicePriceTypeController.text = value;
                }
              },
            ),
            SizedBox(height: 16),

            // Currency
            Text(
              AppStrings.getString('currency', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _newServiceCurrency,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: [
                DropdownMenuItem(value: 'ILS', child: Text('₪ ILS')),
                DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setDialogState(() {
                    _newServiceCurrency = value;
                  });
                }
              },
            ),
          ],
            ),
          ),
          actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _resetAddServiceForm();
          },
          child: Text(
            AppStrings.getString('cancel', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => _createNewService(languageService),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            AppStrings.getString('create', languageService.currentLanguage),
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

  void _resetAddServiceForm() {
    _serviceTitleController.clear();
    _serviceDescriptionController.clear();
    _fieldDescriptionController.clear();
    _newServicePriceController.clear();
    _newServicePriceTypeController.clear();
    _newServiceCurrency = 'ILS';
    _selectedCategory = 'cleaning';
    _selectedSubcategory = '';
  }

  void _createNewService(LanguageService languageService) {
    final description = _serviceDescriptionController.text.trim();
    final priceAmount = double.tryParse(_newServicePriceController.text);
    
    print('🔍 Debug: Creating new service...');
    print('🔍 Debug: Description: "$description"');
    print('🔍 Debug: Price amount: $priceAmount');
    print('🔍 Debug: Selected category: $_selectedCategory');
    print('🔍 Debug: Selected subcategory: $_selectedSubcategory');

    // Check if "Other" is selected in any field
    final hasOtherSelection = _selectedCategory == 'other' || _selectedSubcategory == 'other';

    // For "Other" category, use description as title
    // For other categories, use the category name as title if title is empty
    String title;
    if (_selectedCategory == 'other') {
      title = description;
    } else {
      title = _serviceTitleController.text.trim();
      if (title.isEmpty) {
        // Use category name as fallback title
        final categoryNames = {
          'cleaning': 'Cleaning Service',
          'childcare': 'Childcare Service',
          'elderly': 'Elderly Care Service',
          'maintenance': 'Maintenance Service',
          'cooking': 'Cooking Service',
          'organizing': 'Organizing Service',
          'newhome': 'New Home Service',
          'miscellaneous': 'Miscellaneous Service',
        };
        title = categoryNames[_selectedCategory] ?? 'Service';
      }
    }

    // Main service description is required for all services
    if (description.isEmpty || description == 'enterServiceDescription' || description == 'Enter service description') {
      print('🔍 Debug: Description validation failed - empty or placeholder');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a detailed description of your service'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Field description is only required when "Other" is selected in field dropdown
    final fieldDescription = _fieldDescriptionController.text.trim();
    if (_selectedSubcategory == 'other' && fieldDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a description for your custom field'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (priceAmount == null || priceAmount <= 0) {
      print('🔍 Debug: Price validation failed - amount: $priceAmount');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.getString('invalidPrice', languageService.currentLanguage)),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // If "Other" is selected, submit for admin approval
    if (hasOtherSelection) {
      print('🔍 Debug: Submitting custom service request for admin approval');
      _submitCustomServiceRequest(title, description, fieldDescription, priceAmount, languageService);
      return;
    }

    // Create the new service (only for predefined categories and fields)
    print('🔍 Debug: Creating regular service with title: "$title"');
    _addNewService(title, description, priceAmount, languageService);
  }

  // Map frontend categories to backend categories
  String _mapCategoryToBackend(String frontendCategory) {
    final categoryMapping = {
      'cleaning': 'cleaning',
      'childcare': 'caregiving',
      'elderly': 'elderly_support',
      'maintenance': 'maintenance',
      'cooking': 'caregiving', // Map cooking to caregiving
      'organizing': 'cleaning', // Map organizing to cleaning
      'newhome': 'furniture_moving', // Map newhome to furniture_moving
      'miscellaneous': 'maintenance', // Map miscellaneous to maintenance
      'other': 'other',
    };
    return categoryMapping[frontendCategory] ?? 'other';
  }

  Future<void> _addNewService(String title, String description, double priceAmount, LanguageService languageService) async {
    try {
      print('🔍 Debug: Starting _addNewService...');
      print('🔍 Debug: Title: "$title"');
      print('🔍 Debug: Description: "$description"');
      print('🔍 Debug: Price: $priceAmount');
      print('🔍 Debug: Category: $_selectedCategory');
      print('🔍 Debug: Subcategory: $_selectedSubcategory');
      
      // Map frontend category to backend category
      final backendCategory = _mapCategoryToBackend(_selectedCategory);
      print('🔍 Debug: Backend category: $backendCategory');
      
      final providerService = ProviderService();
      
      // Create service data with all required fields
      final serviceData = {
        'title': title,
        'description': description,
        'category': backendCategory,
        'subcategory': _selectedSubcategory,
        'price': {
          'amount': priceAmount,
          'type': _newServicePriceTypeController.text,
          'currency': _newServiceCurrency,
        },
        'isActive': true, // Service is active by default
      };
      
      final success = await providerService.createService(
        title: title,
        description: description,
        category: backendCategory,
        subcategory: _selectedSubcategory,
        price: {
          'amount': priceAmount,
          'type': _newServicePriceTypeController.text,
          'currency': _newServiceCurrency,
        },
      );

      if (!mounted) return;

      if (success) {
        // Reload services to show the new one
        await _loadServices();
        
        Navigator.of(context).pop();
        _resetAddServiceForm();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service created successfully and added to your dashboard!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Failed to create service');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create service: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateServicePrice(int serviceIndex) async {
    try {
      final service = _services[serviceIndex];
      final providerService = ProviderService();
      
      // Ensure amount is a number
      final amount = _safeParseAmount(service['price']['amount']);
      
      final success = await providerService.updateServicePrice(
        serviceId: service['_id']?.toString() ?? service['id'].toString(),
        price: {
          'amount': amount,
          'type': service['price']['type'],
          'currency': service['price']['currency'],
        },
      );
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Price updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        throw Exception('Failed to update price');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update price: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getSubcategoryDescription(String subcategory) {
    // Get the first service in this subcategory to use its description
    final services = ServiceCategoriesData.predefinedServices
        .where((service) => service.subcategory == subcategory)
        .toList();
    
    if (services.isNotEmpty) {
      return services.first.description;
    }
    
    // Fallback descriptions for subcategories
    final descriptions = {
      'bedroomCleaning': 'Professional bedroom cleaning including dusting, vacuuming, and sanitizing',
      'kitchenCleaning': 'Deep kitchen cleaning including appliances, countertops, and cabinets',
      'bathroomCleaning': 'Thorough bathroom cleaning and sanitization',
      'livingRoomCleaning': 'Living room cleaning and organization',
      'entranceCleaning': 'Entrance area cleaning and maintenance',
      'stairCleaning': 'Stair cleaning and maintenance',
      'garageCleaning': 'Comprehensive garage cleaning and organization',
      'postEventCleaning': 'Post-event cleanup and restoration',
      'homeBabysitting': 'Professional in-home childcare service',
      'homeworkHelp': 'Educational support and homework assistance',
      'schoolAccompaniment': 'Safe school transportation and accompaniment',
      'childrenMealPrep': 'Healthy meal preparation for children',
      'homeElderlyCare': 'Professional elderly care and support',
      'healthMonitoring': 'Regular health monitoring and check-ins',
      'electricalWork': 'Professional electrical work and repairs',
      'plumbingWork': 'Expert plumbing services and repairs',
      'carpentryWork': 'Quality carpentry and woodwork',
      'painting': 'Professional painting services',
      'applianceMaintenance': 'Appliance maintenance and repair',
      'aluminumWork': 'Professional aluminum work and installation',
      'mainDishes': 'Home-cooked main dishes preparation',
      'desserts': 'Delicious dessert preparation',
      'specialRequests': 'Custom cooking requests and special meals',
      'bedroomOrganizing': 'Bedroom organization and decluttering',
      'kitchenOrganizing': 'Kitchen organization and storage optimization',
      'livingRoomOrganizing': 'Living room organization and arrangement',
      'furnitureMoving': 'Safe and professional furniture moving',
      'packingUnpacking': 'Efficient packing and unpacking services',
      'kitchenSetup': 'Complete kitchen setup and organization',
      'preOccupancyRepairs': 'Pre-occupancy repairs and maintenance',
      'shoppingDelivery': 'Reliable shopping and delivery service',
      'billPayment': 'Convenient bill payment service',
    };
    
    return descriptions[subcategory] ?? 'Specialized service in this field';
  }

  Future<void> _submitCustomServiceRequest(String title, String description, String fieldDescription, double priceAmount, LanguageService languageService) async {
    try {
      final providerService = ProviderService();
      
      final success = await providerService.submitCustomServiceRequest(
        title: title,
        description: description,
        fieldDescription: fieldDescription,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        price: {
          'amount': priceAmount,
          'type': _newServicePriceTypeController.text,
          'currency': _newServiceCurrency,
        },
      );
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Custom service request submitted for admin approval. You will be notified once approved.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 4),
          ),
        );
        
        Navigator.of(context).pop();
        _resetAddServiceForm();
      } else {
        throw Exception('Failed to submit custom service request');
      }
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit custom service request: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildSubcategoryDropdown(StateSetter setDialogState) {
    return DropdownButtonFormField<String>(
      key: ValueKey('subcategory_${_selectedCategory}_${_currentSubcategories.length}'),
      value: null, // Always start with null
      decoration: InputDecoration(
        hintText: 'Select a field (optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: [
        // Add "Other" option
        DropdownMenuItem<String>(
          value: 'other',
          child: Text('Other'),
        ),
        // Add subcategories for the selected category
        ..._currentSubcategories.map((subcategory) {
          return DropdownMenuItem<String>(
            value: subcategory,
            child: Text(ServiceCategoriesData.getSubcategoryDisplayName(subcategory)),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setDialogState(() {
          _selectedSubcategory = value ?? '';
        });
      },
    );
  }
}
