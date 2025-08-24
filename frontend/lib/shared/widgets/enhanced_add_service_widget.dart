import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core imports
import '../../core/constants/app_colors.dart';

// Shared imports
import '../services/services_api_service.dart' hide ServiceCategory;
import '../services/custom_service_request_service.dart';
import '../services/service_categories_data.dart';
import '../services/auth_service.dart';

class EnhancedAddServiceWidget extends StatefulWidget {
  final VoidCallback? onServiceAdded;
  final VoidCallback? onRequestSubmitted;

  const EnhancedAddServiceWidget({
    super.key,
    this.onServiceAdded,
    this.onRequestSubmitted,
  });

  @override
  State<EnhancedAddServiceWidget> createState() => _EnhancedAddServiceWidgetState();
}

class _EnhancedAddServiceWidgetState extends State<EnhancedAddServiceWidget> {
  final _formKey = GlobalKey<FormState>();
  final _servicesApi = ServicesApiService();
  final _customRequestService = CustomServiceRequestService();


  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _additionalDetailsController = TextEditingController();

  // Form state
  String _selectedCategory = '';
  String _selectedService = '';
  String _selectedSubcategory = '';
  String _selectedPriceType = 'hourly';
  String _selectedCurrency = 'ILS';
  bool _isCustomService = false;
  bool _isLoading = false;
  String _statusMessage = '';

  // Available options
  List<ServiceCategory> _categories = [];
  List<PredefinedService> _predefinedServices = [];
  List<PredefinedService> _filteredServices = [];
  
  // Custom input fields
  String _customCategoryDescription = '';
  String _customServiceDescription = '';

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndServices();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _additionalDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _categories = ServiceCategoriesData.getAllCategories();
      _predefinedServices = ServiceCategoriesData.predefinedServices;
      _filteredServices = _predefinedServices;

      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first.id;
        _updateFilteredServices();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading categories: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateFilteredServices() {
    if (_selectedCategory.isNotEmpty && _selectedCategory != 'other') {
      // Map the new category names to the existing category IDs
      String categoryId = '';
      switch (_selectedCategory) {
        case 'Cleaning':
          categoryId = 'cleaning';
          break;
        case 'Elderly Support':
          categoryId = 'elderly-care';
          break;
        case 'Maintenance':
          categoryId = 'maintenance';
          break;
        case 'caregiving':
          categoryId = 'caregiving';
          break;
        case 'homeNursing':
          categoryId = 'home-nursing';
          break;
        default:
          categoryId = _selectedCategory;
      }
      _filteredServices = ServiceCategoriesData.getServicesByCategory(categoryId);
    } else {
      _filteredServices = _predefinedServices;
    }
    setState(() {});
  }



  void _onServiceChanged(String? serviceId) {
    if (serviceId != null && serviceId != 'custom' && serviceId != 'others') {
      final service = ServiceCategoriesData.getServiceById(serviceId);
      if (service != null) {
        setState(() {
          _selectedService = serviceId;
          _isCustomService = false;
          _titleController.text = service.title;
          _descriptionController.text = service.description;
          _priceController.text = service.defaultPrice.toString();
          _selectedPriceType = service.priceType;
          _selectedCurrency = service.currency;
          _customServiceDescription = '';
        });
      }
    } else if (serviceId == 'custom') {
      setState(() {
        _selectedService = 'custom';
        _isCustomService = true;
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _customServiceDescription = '';
      });
    } else if (serviceId == 'others') {
      setState(() {
        _selectedService = 'others';
        _isCustomService = true;
        _titleController.clear();
        _descriptionController.clear();
        _priceController.clear();
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for custom category
    if (_selectedCategory == 'other' && _customCategoryDescription.trim().isEmpty) {
      setState(() {
        _statusMessage = 'Please provide a description for your custom category';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      if (_isCustomService || _selectedCategory == 'other' || _selectedService == 'others') {
        // Submit custom service request
        await _submitCustomServiceRequest();
      } else {
        // Create predefined service
        await _createPredefinedService();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPredefinedService() async {
    // Get the category name for the title
    final categoryName = _selectedCategory == 'other' 
        ? _customCategoryDescription.trim()
        : _categories.firstWhere((cat) => cat.id == _selectedCategory).name;
    
    final service = await _servicesApi.createService(
      title: categoryName,
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      price: double.parse(_priceController.text),
      currency: _selectedCurrency,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      subcategory: _selectedService.isNotEmpty && _selectedService != 'custom' 
          ? ServiceCategoriesData.getServiceById(_selectedService)?.subcategory 
          : null,
    );

    setState(() {
      _statusMessage = 'Service created successfully! ID: ${service.id}';
    });

    // Reset form
    _resetForm();
    
    // Callback
    widget.onServiceAdded?.call();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _submitCustomServiceRequest() async {
    // Get the category name for the title
    final categoryName = _selectedCategory == 'other' 
        ? _customCategoryDescription.trim()
        : _categories.firstWhere((cat) => cat.id == _selectedCategory).name;
    
    final request = await _customRequestService.submitCustomServiceRequest(
      title: categoryName,
      description: _selectedService == 'others' 
          ? _customServiceDescription.trim()
          : _descriptionController.text.trim(),
      category: _selectedCategory == 'other' 
          ? _customCategoryDescription.trim()
          : _selectedCategory,
      proposedPrice: double.parse(_priceController.text),
      currency: _selectedCurrency,
      location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
      additionalDetails: _additionalDetailsController.text.trim().isNotEmpty 
          ? _additionalDetailsController.text.trim() 
          : null,
    );

    setState(() {
      _statusMessage = 'Custom service request submitted successfully! ID: ${request.id}';
    });

    // Reset form
    _resetForm();
    
    // Callback
    widget.onRequestSubmitted?.call();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Custom service request submitted! Waiting for admin approval.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _locationController.clear();
    _additionalDetailsController.clear();
    setState(() {
      _selectedCategory = '';
      _selectedService = '';
      _selectedSubcategory = '';
      _isCustomService = false;
      _customCategoryDescription = '';
      _customServiceDescription = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: 600.w,
        constraints: BoxConstraints(maxHeight: 0.8.sh),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCustomService || _selectedCategory == 'other' || _selectedService == 'others' ? Icons.add_circle : Icons.category,
                    color: AppColors.white,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _isCustomService || _selectedCategory == 'other' || _selectedService == 'others' ? 'Request Custom Service' : 'Add Service',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColors.white),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Type Selection
                      _buildServiceTypeSelection(),
                      
                      SizedBox(height: 20.h),



                      // Service Selection
                      _buildServiceSelection(),
                      SizedBox(height: 20.h),

                      // Custom Category Description (shown when "other" is selected)
                      if (_selectedCategory == 'other') ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Category Description *',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextFormField(
                              onChanged: (value) {
                                setState(() {
                                  _customCategoryDescription = value;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Describe your custom category...',
                                hintText: 'What type of service category is this?',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (_selectedCategory == 'other' && (value == null || value.trim().isEmpty)) {
                                  return 'Please describe your custom category';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                      ],

                      // Form Fields
                      _buildFormFields(),
                      
                      SizedBox(height: 20.h),

                      // Status Message
                      if (_statusMessage.isNotEmpty)
                        _buildStatusMessage(),
                      
                      SizedBox(height: 20.h),

                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Selection',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to add a service:',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '1. Select a service category from the dropdown above\n'
                '2. Choose "Other (Custom Category)" for a custom category, or select a specific service\n'
                '3. Fill in the required details and submit',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildServiceSelection() {
    // If "other" category is selected, show custom service description field
    if (_selectedCategory == 'other') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Description *',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _customServiceDescription = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Describe your custom service...',
              hintText: 'What specific service will you provide?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
            maxLines: 3,
            validator: (value) {
              if (_selectedCategory == 'other' && (value == null || value.trim().isEmpty)) {
                return 'Please describe your custom service';
              }
              return null;
            },
          ),
        ],
      );
    }

    // For predefined categories, show service dropdown
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service *',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: _selectedService.isNotEmpty ? _selectedService : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          ),
          items: [
            ..._filteredServices.map((service) {
              return DropdownMenuItem<String>(
                value: service.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.title,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${service.defaultPrice} ${service.currency}/hour',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            DropdownMenuItem<String>(
              value: 'others',
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: AppColors.primary, size: 20.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Others (Custom Service)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: _onServiceChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a service';
            }
            return null;
          },
        ),
        
        // Custom service description field (shown when "Others" service is selected)
        if (_selectedService == 'others') ...[
          SizedBox(height: 12.h),
          TextFormField(
            onChanged: (value) {
              setState(() {
                _customServiceDescription = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Custom Service Description *',
              hintText: 'Describe your custom service...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
            maxLines: 3,
            validator: (value) {
              if (_selectedService == 'others' && (value == null || value.trim().isEmpty)) {
                return 'Please describe your custom service';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Service Category (Dropdown)
        DropdownButtonFormField<String>(
          value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
          decoration: InputDecoration(
            labelText: 'Service Category *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: [
            ..._categories.map((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              );
            }),
            DropdownMenuItem<String>(
              value: 'other',
              child: Text('Other (Custom Category)'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
                _selectedService = '';
                _selectedSubcategory = ''; // Reset subcategory when category changes
                _titleController.clear();
                _updateFilteredServices();
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a service category';
            }
            return null;
          },
        ),
        
        SizedBox(height: 16.h),
        
        SizedBox(height: 16.h),

        // Description (always shown, required when "Other" is selected)
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: _selectedCategory == 'other' ? 'Description *' : 'Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) {
            if (_selectedCategory == 'other' && (value == null || value.trim().isEmpty)) {
              return 'Please enter a description for your custom service';
            }
            return null;
          },
        ),
        
        SizedBox(height: 16.h),

        // Field (subcategory) dropdown - only show when not "other" category
        if (_selectedCategory != 'other') ...[
          Text(
            'Field',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: _selectedSubcategory.isNotEmpty ? _selectedSubcategory : null,
            decoration: InputDecoration(
              hintText: 'Select a field (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category_outlined),
            ),
                            items: [
                  // Add "None" option
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text('None'),
                  ),
                  // Add subcategories for the selected category
                  ...ServiceCategoriesData.getSubcategoriesByCategory(_selectedCategory).map((subcategory) {
                    return DropdownMenuItem<String>(
                      value: subcategory,
                      child: Text(ServiceCategoriesData.getSubcategoryDisplayName(subcategory)),
                    );
                  }).toList(), // Ensure it's converted to a list
                ],
            onChanged: (value) {
              setState(() {
                _selectedSubcategory = value ?? '';
              });
            },
          ),
          SizedBox(height: 8.h),
          // Field description
          if (_selectedSubcategory.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _getSubcategoryDescription(_selectedSubcategory),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16.h),
        ],
        
        SizedBox(height: 16.h),

        // Price and Type
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPriceType,
                decoration: InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriceType = value;
                    });
                  }
                },
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'ILS', child: Text('₪ ILS')),
                  DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('€ EUR')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCurrency = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16.h),

        // Location
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Service Area (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        
        SizedBox(height: 16.h),

        // Custom Service Description (when "Others" is selected)
        if (_selectedService == 'others') ...[
          TextFormField(
            onChanged: (value) {
              setState(() {
                _customServiceDescription = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Service Description *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              hintText: 'Describe the custom service you want to provide...',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please describe the custom service';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),
        ],

        // Additional Details (for custom services)
        if (_isCustomService) ...[
          TextFormField(
            controller: _additionalDetailsController,
            decoration: InputDecoration(
              labelText: 'Additional Details (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_add),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 16.h),
        ],
      ],
    );
  }

  Widget _buildStatusMessage() {
    Color messageColor = AppColors.textSecondary;
    if (_statusMessage.contains('successfully')) {
      messageColor = AppColors.success;
    } else if (_statusMessage.contains('Error')) {
      messageColor = AppColors.error;
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: messageColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: messageColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _statusMessage.contains('successfully') ? Icons.check_circle : Icons.info,
            color: messageColor,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _statusMessage,
              style: TextStyle(color: messageColor),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : Text(_isCustomService || _selectedCategory == 'other' || _selectedService == 'others' ? 'Submit Request' : 'Create Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
      ],
    );
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
}
