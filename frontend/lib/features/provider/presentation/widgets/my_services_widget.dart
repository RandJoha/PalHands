import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/my_services_service.dart';

class MyServicesWidget extends StatefulWidget {
  const MyServicesWidget({super.key});

  @override
  State<MyServicesWidget> createState() => _MyServicesWidgetState();
}

class _MyServicesWidgetState extends State<MyServicesWidget> {
  bool _isMultiEditMode = false;
  final Set<int> _selectedServices = {};
  bool _showEmergencyOnly = false;
  final _svc = MyServicesService();
  bool _loading = true;
  String? _error;
  String? _providerId;
  List<ProviderServiceItem> _items = const [];
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final id = auth.currentUser?['_id']?.toString();
      setState(() { _providerId = id; _loading = true; _error = null; });
      if (id == null || id.isEmpty) {
        setState(() { _error = 'Not authenticated as provider'; _loading = false; });
        return;
      }
      final items = await _svc.list(id);
      final mapped = items.map((it) => {
        'name': it.serviceTitle.isNotEmpty ? it.serviceTitle : it.serviceKey,
        'price': '${it.hourlyRate.toStringAsFixed(0)} ILS/hour',
        'status': it.status,
        'emergency': it.emergencyEnabled,
        'rating': 0.0,
        'bookings': 0,
      }).toList();
      setState(() { _items = items; _services = mapped; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load services'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            
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
          
          // Multi-edit action bar
          if (_isMultiEditMode) _buildMultiEditActionBar(languageService, isMobile, isTablet, isDesktop),
          
          if (_isMultiEditMode) SizedBox(height: isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
          
          // Services grid
          if (_loading) 
            Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: AppColors.primary)),
            ))
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(_error!, style: GoogleFonts.cairo(color: AppColors.error)),
            )
          else
            _buildServicesGrid(languageService, isMobile, isTablet, isDesktop, screenWidth),
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
                      // TODO: Navigate to add service page
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
            SizedBox(width: isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
            // Emergency filter toggle
            Container(
              height: isMobile ? 36 : (isTablet ? 40 : 44),
              decoration: BoxDecoration(
                color: _showEmergencyOnly ? AppColors.error : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showEmergencyOnly ? AppColors.error : AppColors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _showEmergencyOnly = !_showEmergencyOnly;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning,
                          size: isMobile ? 14 : (isTablet ? 15 : 16),
                          color: _showEmergencyOnly ? AppColors.white : AppColors.grey,
                        ),
                        SizedBox(width: 6),
                        Text(
                          AppStrings.getString('emergencyOnly', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                            fontWeight: FontWeight.w600,
                            color: _showEmergencyOnly ? AppColors.white : AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
            // Multi-edit toggle button
            Container(
              height: isMobile ? 36 : (isTablet ? 40 : 44),
              decoration: BoxDecoration(
                color: _isMultiEditMode ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isMultiEditMode ? AppColors.primary : AppColors.grey.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: _isMultiEditMode ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _isMultiEditMode = !_isMultiEditMode;
                      if (!_isMultiEditMode) {
                        _selectedServices.clear();
                      }
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isMultiEditMode ? Icons.close : Icons.edit,
                        size: isMobile ? 16 : (isTablet ? 18 : 20),
                        color: _isMultiEditMode ? AppColors.white : AppColors.grey,
                      ),
                      SizedBox(width: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                      Text(
                        _isMultiEditMode 
                            ? AppStrings.getString('cancel', languageService.currentLanguage)
                            : AppStrings.getString('multiEdit', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 12.0 : (isTablet ? 13.0 : 14.0),
                          fontWeight: FontWeight.w600,
                          color: _isMultiEditMode ? AppColors.white : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiEditActionBar(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : (isTablet ? 14.0 : 16.0)),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Selection info
          Expanded(
            child: Text(
              '${_selectedServices.length} ${AppStrings.getString('selected', languageService.currentLanguage)}',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : (isTablet ? 13.0 : 14.0),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          // Bulk actions
          Row(
            children: [
              _buildBulkActionButton(
                icon: Icons.play_arrow,
                label: AppStrings.getString('activate', languageService.currentLanguage),
                onTap: _activateSelectedServices,
                languageService: languageService,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(width: isMobile ? 6.0 : (isTablet ? 7.0 : 8.0)),
              _buildBulkActionButton(
                icon: Icons.pause,
                label: AppStrings.getString('deactivate', languageService.currentLanguage),
                onTap: _deactivateSelectedServices,
                languageService: languageService,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
              ),
              SizedBox(width: isMobile ? 6.0 : (isTablet ? 7.0 : 8.0)),
              _buildBulkActionButton(
                icon: Icons.delete,
                label: AppStrings.getString('delete', languageService.currentLanguage),
                onTap: _deleteSelectedServices,
                languageService: languageService,
                isMobile: isMobile,
                isTablet: isTablet,
                isDesktop: isDesktop,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LanguageService languageService,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive ? AppColors.error : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0), 
              vertical: isMobile ? 6.0 : (isTablet ? 7.0 : 8.0)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isMobile ? 14 : (isTablet ? 15 : 16),
                  color: AppColors.white,
                ),
                SizedBox(width: isMobile ? 3.0 : (isTablet ? 3.5 : 4.0)),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
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

  final items = _showEmergencyOnly ? _services.where((s) => (s['emergency'] ?? false) == true).toList() : _services;
  return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(items[index], index, languageService, isMobile, isTablet, isDesktop);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, int index, LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    final isSelected = _selectedServices.contains(index);
    final isActive = service['status'] == 'active';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.grey.withValues(alpha: 0.1), width: 1),
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
            if (_isMultiEditMode) {
              setState(() {
                if (isSelected) {
                  _selectedServices.remove(index);
                } else {
                  _selectedServices.add(index);
                }
              });
            } else {
              // TODO: Navigate to service details
            }
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 10.0 : (isTablet ? 12.0 : 14.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with checkbox and status
                Row(
                  children: [
                    if (_isMultiEditMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedServices.add(index);
                            } else {
                              _selectedServices.remove(index);
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)),
                    ],
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
                            AppStrings.getString(service['name'], languageService.currentLanguage),
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
                    // Price
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0), 
                        vertical: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service['price'],
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
                              service['rating'].toString(),
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
                          '${service['bookings']} ${AppStrings.getString('bookings', languageService.currentLanguage)}',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _activateSelectedServices() {
    if (_providerId == null) return;
    Future.microtask(() async {
      for (final idx in _selectedServices) {
        if (idx >= 0 && idx < _items.length) {
          await _svc.update(_providerId!, _items[idx].id, { 'status': 'active' });
        }
      }
      await _bootstrap();
      if (mounted) setState(() { _isMultiEditMode = false; _selectedServices.clear(); });
    });
  }

  void _deactivateSelectedServices() {
    if (_providerId == null) return;
    Future.microtask(() async {
      for (final idx in _selectedServices) {
        if (idx >= 0 && idx < _items.length) {
          await _svc.update(_providerId!, _items[idx].id, { 'status': 'inactive', 'isPublished': false });
        }
      }
      await _bootstrap();
      if (mounted) setState(() { _isMultiEditMode = false; _selectedServices.clear(); });
    });
  }

  void _deleteSelectedServices() {
    if (_providerId == null) return;
    Future.microtask(() async {
      for (final idx in _selectedServices) {
        if (idx >= 0 && idx < _items.length) {
          await _svc.remove(_providerId!, _items[idx].id);
        }
      }
      await _bootstrap();
      if (mounted) setState(() { _isMultiEditMode = false; _selectedServices.clear(); });
    });
  }
}
