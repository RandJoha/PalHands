import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class MyServicesWidget extends StatefulWidget {
  const MyServicesWidget({super.key});

  @override
  State<MyServicesWidget> createState() => _MyServicesWidgetState();
}

class _MyServicesWidgetState extends State<MyServicesWidget> {
  bool _isMultiEditMode = false;
  Set<int> _selectedServices = {};

  final List<Map<String, dynamic>> _services = [
    {
      'id': 1,
      'name': 'Home Cleaning',
      'category': 'Cleaning',
      'price': '\$25/hour',
      'status': 'active',
      'rating': 4.8,
      'bookings': 12,
    },
    {
      'id': 2,
      'name': 'Elderly Care',
      'category': 'Care',
      'price': '\$30/hour',
      'status': 'active',
      'rating': 4.9,
      'bookings': 8,
    },
    {
      'id': 3,
      'name': 'Home Cooking',
      'category': 'Cooking',
      'price': '\$20/hour',
      'status': 'inactive',
      'rating': 4.7,
      'bookings': 5,
    },
    {
      'id': 4,
      'name': 'Babysitting',
      'category': 'Childcare',
      'price': '\$18/hour',
      'status': 'active',
      'rating': 4.6,
      'bookings': 15,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildMyServicesWidget(languageService);
      },
    );
  }

  Widget _buildMyServicesWidget(LanguageService languageService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with multi-edit controls
          _buildHeader(languageService),
          
          const SizedBox(height: 24),
          
          // Multi-edit action bar
          if (_isMultiEditMode) _buildMultiEditActionBar(languageService),
          
          if (_isMultiEditMode) const SizedBox(height: 16),
          
          // Services grid
          _buildServicesGrid(languageService),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.getString('myServices', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greyDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.getString('manageYourServices', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
        // Multi-edit toggle button
        Container(
          decoration: BoxDecoration(
            color: _isMultiEditMode ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isMultiEditMode ? AppColors.primary : AppColors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _isMultiEditMode = !_isMultiEditMode;
                  if (!_isMultiEditMode) {
                    _selectedServices.clear();
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isMultiEditMode ? Icons.close : Icons.edit,
                      size: 20,
                      color: _isMultiEditMode ? AppColors.white : AppColors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isMultiEditMode 
                          ? AppStrings.getString('cancel', languageService.currentLanguage)
                          : AppStrings.getString('multiEdit', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isMultiEditMode ? AppColors.white : AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Add new service button
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // TODO: Navigate to add service page
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 20,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.getString('addService', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
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
    );
  }

  Widget _buildMultiEditActionBar(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                fontSize: 14,
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
              ),
              const SizedBox(width: 8),
              _buildBulkActionButton(
                icon: Icons.pause,
                label: AppStrings.getString('deactivate', languageService.currentLanguage),
                onTap: _deactivateSelectedServices,
                languageService: languageService,
              ),
              const SizedBox(width: 8),
              _buildBulkActionButton(
                icon: Icons.delete,
                label: AppStrings.getString('delete', languageService.currentLanguage),
                onTap: _deleteSelectedServices,
                languageService: languageService,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: AppColors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
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

  Widget _buildServicesGrid(LanguageService languageService) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(_services[index], index, languageService);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, int index, LanguageService languageService) {
    final isSelected = _selectedServices.contains(index);
    final isActive = service['status'] == 'active';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            padding: const EdgeInsets.all(16),
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
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive 
                              ? AppStrings.getString('active', languageService.currentLanguage)
                              : AppStrings.getString('inactive', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive ? AppColors.success : AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Service name
                Text(
                  service['name'],
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greyDark,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Category
                Text(
                  service['category'],
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Price
                Text(
                  service['price'],
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                
                // Stats row
                Row(
                  children: [
                    // Rating
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          service['rating'].toString(),
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greyDark,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Bookings
                    Text(
                      '${service['bookings']} ${AppStrings.getString('bookings', languageService.currentLanguage)}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.grey,
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

  void _activateSelectedServices() {
    // TODO: Implement bulk activate
    setState(() {
      _isMultiEditMode = false;
      _selectedServices.clear();
    });
  }

  void _deactivateSelectedServices() {
    // TODO: Implement bulk deactivate
    setState(() {
      _isMultiEditMode = false;
      _selectedServices.clear();
    });
  }

  void _deleteSelectedServices() {
    // TODO: Implement bulk delete with confirmation
    setState(() {
      _isMultiEditMode = false;
      _selectedServices.clear();
    });
  }
}
