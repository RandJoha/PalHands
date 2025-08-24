import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core imports
import '../../core/constants/app_colors.dart';

// Shared imports
import '../services/services_api_service.dart' hide ServiceCategory;
import '../services/auth_service.dart';
import '../services/service_categories_data.dart';
import '../services/custom_service_request_service.dart';
import 'enhanced_add_service_widget.dart';
import 'custom_service_requests_widget.dart';

class ServicesIntegrationTest extends StatefulWidget {
  const ServicesIntegrationTest({super.key});

  @override
  State<ServicesIntegrationTest> createState() => _ServicesIntegrationTestState();
}

class _ServicesIntegrationTestState extends State<ServicesIntegrationTest> {
  final ServicesApiService _servicesApi = ServicesApiService();
  final CustomServiceRequestService _customRequestService = CustomServiceRequestService();
  
  ServicesResponse? _servicesResponse;
  List<ServiceCategory> _categories = [];
  List<CustomServiceRequest> _customRequests = [];
  Service? _selectedService;
  bool _isLoading = false;
  String _statusMessage = 'Ready to test services integration';
  String _searchQuery = '';
  int _currentPage = 1;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading initial data...';
    });

    try {
      // Load services, categories, and custom requests in parallel
      final futures = await Future.wait([
        _servicesApi.getServices(page: 1, limit: 5),
        _servicesApi.getServiceCategories(),
        _customRequestService.getMyCustomServiceRequests(),
      ]);

      setState(() {
        _servicesResponse = futures[0] as ServicesResponse;
        _categories = futures[1] as List<ServiceCategory>;
        _customRequests = futures[2] as List<CustomServiceRequest>;
        _statusMessage = 'Loaded ${_servicesResponse!.services.length} services, ${_categories.length} categories, and ${_customRequests.length} custom requests';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchServices() async {
    if (_searchQuery.isEmpty) {
      await _loadInitialData();
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Searching for "$_searchQuery"...';
    });

    try {
      final response = await _servicesApi.searchServices(_searchQuery, page: 1, limit: 10);
      setState(() {
        _servicesResponse = response;
        _currentPage = 1;
        _statusMessage = 'Found ${response.services.length} services for "$_searchQuery"';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreServices() async {
    if (_servicesResponse == null || !_servicesResponse!.hasNext) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading more services...';
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _servicesApi.getServices(page: nextPage, limit: 5);
      
      setState(() {
        _servicesResponse = ServicesResponse(
          services: [..._servicesResponse!.services, ...response.services],
          total: response.total,
          page: response.page,
          limit: response.limit,
          totalPages: response.totalPages,
          hasNext: response.hasNext,
          hasPrev: response.hasPrev,
        );
        _currentPage = nextPage;
        _statusMessage = 'Loaded ${response.services.length} more services';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load more services: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestService() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating test service...';
    });

    try {
      final service = await _servicesApi.createService(
        title: 'Test Service ${DateTime.now().millisecondsSinceEpoch}',
        description: 'This is a test service created via API integration',
        category: 'cleaning',
        price: 100.0,
        currency: 'ILS',
        location: 'Test Location',
        subcategory: 'testService',
      );

      setState(() {
        _statusMessage = 'Service created successfully! ID: ${service.id}, Price: ${service.price['amount']} ${service.price['currency']}';
        _isLoading = false;
      });

      // Refresh the services list
      await _loadInitialData();
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to create service: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTestService() async {
    if (_selectedService == null) {
      setState(() {
        _statusMessage = 'Please select a service first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Updating service...';
    });

    try {
      final updatedService = await _servicesApi.updateService(
        serviceId: _selectedService!.id,
        title: '${_selectedService!.title} (Updated)',
        description: 'This service was updated via API integration',
        price: (_selectedService!.price['amount'] ?? 0.0) + 10.0,
        currency: _selectedService!.price['currency'] ?? 'ILS',
      );

      setState(() {
        _selectedService = updatedService;
        _statusMessage = 'Service updated successfully! New price: ${updatedService.price['amount']} ${updatedService.price['currency']}';
        _isLoading = false;
      });

      // Refresh the services list
      await _loadInitialData();
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to update service: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTestService() async {
    if (_selectedService == null) {
      setState(() {
        _statusMessage = 'Please select a service first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting service...';
    });

    try {
      final success = await _servicesApi.deleteService(_selectedService!.id);
      
      if (success) {
        setState(() {
          _selectedService = null;
          _statusMessage = 'Service deleted successfully!';
          _isLoading = false;
        });

        // Refresh the services list
        await _loadInitialData();
      } else {
        setState(() {
          _statusMessage = 'Failed to delete service';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to delete service: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services API Integration Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Integration Status:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Search Section
            _buildSearchSection(),
            
            SizedBox(height: 24.h),
            
            // Tabs
            _buildTabs(),
            
            SizedBox(height: 24.h),
            
            // Tab Content
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Services',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onSubmitted: (_) => _searchServices(),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton(
                onPressed: _searchServices,
                child: Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, 'Services', Icons.category),
          ),
          Expanded(
            child: _buildTabButton(1, 'Add Service', Icons.add),
          ),
          Expanded(
            child: _buildTabButton(2, 'Custom Requests', Icons.pending_actions),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int tabIndex, String title, IconData icon) {
    final isSelected = _currentTab == tabIndex;
    return InkWell(
      onTap: () {
        setState(() {
          _currentTab = tabIndex;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.textSecondary,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildServicesTab();
      case 1:
        return _buildAddServiceTab();
      case 2:
        return _buildCustomRequestsTab();
      default:
        return _buildServicesTab();
    }
  }

  Widget _buildServicesTab() {
    return Column(
      children: [
        // API Test Buttons
        _buildApiTestSection(),
        
        SizedBox(height: 24.h),
        
        // Services List
        Expanded(
          child: _buildServicesList(),
        ),
      ],
    );
  }

  Widget _buildAddServiceTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Service',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Select a category, choose a service, or select "Others" for custom services that need admin approval.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EnhancedAddServiceWidget(
                      onServiceAdded: () {
                        _loadInitialData();
                        Navigator.of(context).pop();
                      },
                      onRequestSubmitted: () {
                        _loadInitialData();
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
                icon: Icon(Icons.add),
                label: Text('Add Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 24.h),
        
        // Predefined Services Preview
        Expanded(
          child: _buildPredefinedServicesPreview(),
        ),
      ],
    );
  }

  Widget _buildCustomRequestsTab() {
    return CustomServiceRequestsWidget(
      isAdmin: false,
    );
  }

  Widget _buildPredefinedServicesPreview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Predefined Services',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.builder(
              itemCount: ServiceCategoriesData.predefinedServices.length,
              itemBuilder: (context, index) {
                final service = ServiceCategoriesData.predefinedServices[index];
                final category = ServiceCategoriesData.getCategoryById(service.category);
                
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: category?.color != null 
                              ? Color(int.parse(category!.color!.replaceAll('#', '0xFF')))
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                            Text(
                              '${service.defaultPrice} ${service.currency}/hour • ${category?.name ?? service.category}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
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
        ],
      ),
    );
  }

  Widget _buildApiTestSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Test Actions',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createTestService,
                icon: Icon(Icons.add),
                label: Text('Create Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateTestService,
                icon: Icon(Icons.edit),
                label: Text('Update Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _deleteTestService,
                icon: Icon(Icons.delete),
                label: Text('Delete Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadInitialData,
                icon: Icon(Icons.refresh),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16.h),
            Text('Loading services...'),
          ],
        ),
      );
    }

    if (_servicesResponse == null || _servicesResponse!.services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category,
              size: 64.sp,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16.h),
            Text(
              'No services found',
              style: TextStyle(
                fontSize: 18.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services (${_servicesResponse!.total} total)',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: ListView.builder(
            itemCount: _servicesResponse!.services.length,
            itemBuilder: (context, index) {
              final service = _servicesResponse!.services[index];
              final isSelected = _selectedService?.id == service.id;
              
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      _selectedService = service;
                    });
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      service.title.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    service.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.description),
                      SizedBox(height: 4.h),
                                             Row(
                         children: [
                           Icon(Icons.category, size: 16.sp, color: AppColors.textLight),
                           SizedBox(width: 4.w),
                           Text(service.category),
                           SizedBox(width: 16.w),
                           Icon(Icons.star, size: 16.sp, color: AppColors.warning),
                           SizedBox(width: 4.w),
                           Text('${service.rating?['average']?.toStringAsFixed(1) ?? '0.0'} (${service.rating?['count'] ?? 0})'),
                         ],
                       ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                                             Text(
                         '${service.price['currency'] ?? 'ILS'} ${service.price['amount']?.toStringAsFixed(2) ?? '0.00'}',
                         style: TextStyle(
                           fontSize: 16.sp,
                           fontWeight: FontWeight.bold,
                           color: AppColors.primary,
                         ),
                       ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20.sp,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Load More Button
        if (_servicesResponse!.hasNext)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 16.h),
            child: ElevatedButton(
              onPressed: _loadMoreServices,
              child: Text('Load More Services'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.white,
              ),
            ),
          ),
      ],
    );
  }
}
