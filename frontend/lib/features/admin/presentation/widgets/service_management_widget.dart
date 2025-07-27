import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

class ServiceManagementWidget extends StatefulWidget {
  const ServiceManagementWidget({super.key});

  @override
  State<ServiceManagementWidget> createState() => _ServiceManagementWidgetState();
}

class _ServiceManagementWidgetState extends State<ServiceManagementWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _services = [];
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    setState(() {
      _services = [
        {
          'id': '1',
          'title': 'Professional Home Cleaning',
          'description': 'Complete home cleaning service with eco-friendly products',
          'category': 'cleaning',
          'provider': {
            'firstName': 'Ahmed',
            'lastName': 'Hassan',
            'email': 'ahmed.hassan@email.com',
          },
          'price': {'amount': 150, 'currency': 'ILS', 'type': 'hourly'},
          'isActive': true,
          'featured': true,
          'rating': {'average': 4.8, 'count': 45},
          'totalBookings': 89,
          'createdAt': '2024-01-15T10:30:00Z',
        },
        {
          'id': '2',
          'title': 'Elderly Care & Support',
          'description': 'Compassionate care for elderly family members',
          'category': 'elderly_support',
          'provider': {
            'firstName': 'Fatima',
            'lastName': 'Ali',
            'email': 'fatima.ali@email.com',
          },
          'price': {'amount': 200, 'currency': 'ILS', 'type': 'daily'},
          'isActive': true,
          'featured': false,
          'rating': {'average': 4.9, 'count': 23},
          'totalBookings': 34,
          'createdAt': '2024-01-20T14:15:00Z',
        },
        {
          'id': '3',
          'title': 'Home Maintenance & Repairs',
          'description': 'General home maintenance and repair services',
          'category': 'maintenance',
          'provider': {
            'firstName': 'Omar',
            'lastName': 'Khalil',
            'email': 'omar.khalil@email.com',
          },
          'price': {'amount': 120, 'currency': 'ILS', 'type': 'fixed'},
          'isActive': false,
          'featured': false,
          'rating': {'average': 4.2, 'count': 12},
          'totalBookings': 15,
          'createdAt': '2024-01-10T09:45:00Z',
        },
      ];
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredServices {
    return _services.where((service) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = service['title'].toLowerCase();
        final description = service['description'].toLowerCase();
        final providerName = '${service['provider']['firstName']} ${service['provider']['lastName']}'.toLowerCase();
        
        if (!title.contains(query) && 
            !description.contains(query) && 
            !providerName.contains(query)) {
          return false;
        }
      }

      // Category filter
      if (_selectedCategory != 'all' && service['category'] != _selectedCategory) {
        return false;
      }

      // Status filter
      if (_selectedStatus != 'all') {
        final isActive = _selectedStatus == 'active';
        if (service['isActive'] != isActive) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Padding(
      padding: EdgeInsets.all(screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - More compact
          _buildHeader(),
          
          SizedBox(height: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
          
          // Filters - Improved sizing
          _buildFilters(),
          
          SizedBox(height: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
          
          // Services table
          Expanded(
            child: _buildServicesTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Management',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 22 : screenWidth > 1024 ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Manage service listings, approve providers, and monitor quality',
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
            // TODO: Show add service dialog
          },
          icon: const Icon(Icons.add_business, size: 18),
          label: Text(
            'Add Service',
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

  Widget _buildFilters() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 16 : screenWidth > 1024 ? 14 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth > 1400 ? 10 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search services...',
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
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Category',
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
                      DropdownMenuItem(value: 'all', child: Text('All Categories', style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'cleaning', child: Text('Cleaning', style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'elderly_support', child: Text('Elderly Support', style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'maintenance', child: Text('Maintenance', style: GoogleFonts.cairo(fontSize: 13))),
                    ],
                  ),
                ),
                
                SizedBox(width: screenWidth > 1400 ? 12 : 10),
                
                // Status filter - More compact
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Status',
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
                      DropdownMenuItem(value: 'all', child: Text('All Status', style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'active', child: Text('Active', style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive', style: GoogleFonts.cairo(fontSize: 13))),
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search services...',
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
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Category',
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
                          DropdownMenuItem(value: 'all', child: Text('All Categories', style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'cleaning', child: Text('Cleaning', style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'elderly_support', child: Text('Elderly Support', style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'maintenance', child: Text('Maintenance', style: GoogleFonts.cairo(fontSize: 13))),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Status',
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
                          DropdownMenuItem(value: 'all', child: Text('All Status', style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'active', child: Text('Active', style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive', style: GoogleFonts.cairo(fontSize: 13))),
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

  Widget _buildServicesTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              'No services found',
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
            color: Colors.black.withOpacity(0.04),
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
                Expanded(flex: 2, child: _buildHeaderCell('Service')),
                Expanded(flex: 1, child: _buildHeaderCell('Provider')),
                if (screenWidth > 768) ...[
                  Expanded(flex: 1, child: _buildHeaderCell('Category')),
                  Expanded(flex: 1, child: _buildHeaderCell('Price')),
                  Expanded(flex: 1, child: _buildHeaderCell('Rating')),
                ],
                Expanded(flex: 1, child: _buildHeaderCell('Status')),
                Expanded(flex: 1, child: _buildHeaderCell('Actions')),
              ],
            ),
          ),
          
          // Table body
          Expanded(
            child: ListView.builder(
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                return _buildServiceRow(service);
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

  Widget _buildServiceRow(Map<String, dynamic> service) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 16 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.08),
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
                    color: _getCategoryColor(service['category']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getCategoryIcon(service['category']),
                    color: _getCategoryColor(service['category']),
                    size: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 18 : 16,
                  ),
                ),
                SizedBox(width: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 10 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['title'],
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 15 : screenWidth > 1024 ? 14 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        service['description'],
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
          
          // Provider - Balanced sizing
          Expanded(
            flex: 1,
            child: Text(
              '${service['provider']['firstName']} ${service['provider']['lastName']}',
              style: GoogleFonts.cairo(
                fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
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
                  color: _getCategoryColor(service['category']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getCategoryLabel(service['category']).toUpperCase(),
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 11 : screenWidth > 1024 ? 10 : 9,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(service['category']),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          
          // Price (hidden on mobile) - Balanced sizing
          if (screenWidth > 768) ...[
            Expanded(
              flex: 1,
              child: Text(
                '₪${service['price']['amount']}/${service['price']['type']}',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 13 : screenWidth > 1024 ? 12 : 11,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
          
          // Rating (hidden on mobile) - Balanced sizing
          if (screenWidth > 768) ...[
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    size: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 12 : 11,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${service['rating']['average']} (${service['rating']['count']})',
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 11 : 10,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
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
                color: service['isActive'] 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                service['isActive'] ? 'ACTIVE' : 'INACTIVE',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 11 : screenWidth > 1024 ? 10 : 9,
                  fontWeight: FontWeight.w600,
                  color: service['isActive'] ? Colors.green : Colors.red,
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
                    // TODO: View service details
                  },
                  icon: Icon(
                    Icons.visibility,
                    size: screenWidth > 1400 ? 18 : 16,
                    color: AppColors.textLight,
                  ),
                  tooltip: 'View',
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Edit service
                  },
                  icon: Icon(
                    Icons.edit,
                    size: screenWidth > 1400 ? 18 : 16,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Edit',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
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

  IconData _getCategoryIcon(String category) {
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

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'cleaning':
        return 'Cleaning';
      case 'elderly_support':
        return 'Elderly Support';
      case 'maintenance':
        return 'Maintenance';
      default:
        return category;
    }
  }
} 