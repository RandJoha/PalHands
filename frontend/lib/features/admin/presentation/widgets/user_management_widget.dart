import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';

class UserManagementWidget extends StatefulWidget {
  const UserManagementWidget({super.key});

  @override
  State<UserManagementWidget> createState() => _UserManagementWidgetState();
}

class _UserManagementWidgetState extends State<UserManagementWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  String _selectedRole = 'all';
  String _selectedStatus = 'all';
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    setState(() {
      _users = [
        {
          'id': '1',
          'firstName': 'Ahmed',
          'lastName': 'Hassan',
          'email': 'ahmed.hassan@email.com',
          'phone': '+970-59-123-4567',
          'role': 'provider',
          'isActive': true,
          'isVerified': true,
          'rating': {'average': 4.8, 'count': 45},
          'createdAt': '2024-01-15T10:30:00Z',
          'profileImage': null,
        },
        {
          'id': '2',
          'firstName': 'Fatima',
          'lastName': 'Ali',
          'email': 'fatima.ali@email.com',
          'phone': '+970-59-987-6543',
          'role': 'client',
          'isActive': true,
          'isVerified': false,
          'rating': {'average': 0, 'count': 0},
          'createdAt': '2024-01-20T14:15:00Z',
          'profileImage': null,
        },
        {
          'id': '3',
          'firstName': 'Omar',
          'lastName': 'Khalil',
          'email': 'omar.khalil@email.com',
          'phone': '+970-59-555-1234',
          'role': 'provider',
          'isActive': false,
          'isVerified': true,
          'rating': {'average': 4.2, 'count': 23},
          'createdAt': '2024-01-10T09:45:00Z',
          'profileImage': null,
        },
      ];
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((user) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = '${user['firstName']} ${user['lastName']}'.toLowerCase();
        final email = user['email'].toLowerCase();
        final phone = user['phone'].toLowerCase();
        
        if (!name.contains(query) && 
            !email.contains(query) && 
            !phone.contains(query)) {
          return false;
        }
      }

      // Role filter
      if (_selectedRole != 'all' && user['role'] != _selectedRole) {
        return false;
      }

      // Status filter
      if (_selectedStatus != 'all') {
        final isActive = _selectedStatus == 'active';
        if (user['isActive'] != isActive) {
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
          
          // Users table
          Expanded(
            child: _buildUsersTable(),
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
                'User Management',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 22 : screenWidth > 1024 ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Manage platform users, verify providers, and monitor activity',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        
        // Add user button - More compact
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Show add user dialog
          },
          icon: const Icon(Icons.person_add, size: 18),
          label: Text(
            'Add User',
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
                      hintText: 'Search by name, email, or phone...',
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
                
                // Role filter - More compact
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Role',
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
                      DropdownMenuItem(value: 'all', child: Text('All Roles', style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'client', child: Text('Client', style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'provider', child: Text('Provider', style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'admin', child: Text('Admin', style: GoogleFonts.cairo(fontSize: 13))),
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
                    hintText: 'Search by name, email, or phone...',
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
                    // Role filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Role',
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
                          DropdownMenuItem(value: 'all', child: Text('All Roles', style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'client', child: Text('Client', style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'provider', child: Text('Provider', style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'admin', child: Text('Admin', style: GoogleFonts.cairo(fontSize: 13))),
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

  Widget _buildUsersTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              'No users found',
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
                Expanded(flex: 2, child: _buildHeaderCell('User')),
                Expanded(flex: 1, child: _buildHeaderCell('Role')),
                Expanded(flex: 1, child: _buildHeaderCell('Status')),
                if (screenWidth > 768) ...[
                  Expanded(flex: 1, child: _buildHeaderCell('Rating')),
                  Expanded(flex: 1, child: _buildHeaderCell('Joined')),
                ],
                Expanded(flex: 1, child: _buildHeaderCell('Actions')),
              ],
            ),
          ),
          
          // Table body
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return _buildUserRow(user);
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

  Widget _buildUserRow(Map<String, dynamic> user) {
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
          // User info - Balanced sizing
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 18 : 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user['firstName'].substring(0, 1).toUpperCase(),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth > 1400 ? 16 : screenWidth > 1024 ? 14 : 12,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 10 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user['firstName']} ${user['lastName']}',
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 15 : screenWidth > 1024 ? 14 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        user['email'],
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
          
          // Role - Balanced sizing
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 1400 ? 8 : 6,
                vertical: screenWidth > 1400 ? 4 : 3,
              ),
              decoration: BoxDecoration(
                color: _getRoleColor(user['role']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user['role'].toString().toUpperCase(),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 11 : screenWidth > 1024 ? 10 : 9,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(user['role']),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Status - Balanced sizing
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 1400 ? 8 : 6,
                vertical: screenWidth > 1400 ? 4 : 3,
              ),
              decoration: BoxDecoration(
                color: user['isActive'] 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user['isActive'] ? 'ACTIVE' : 'INACTIVE',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 11 : screenWidth > 1024 ? 10 : 9,
                  fontWeight: FontWeight.w600,
                  color: user['isActive'] ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Rating (hidden on mobile)
          if (screenWidth > 768) ...[
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    size: screenWidth > 1400 ? 14 : 12,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 4),
                  Text(
                    user['rating']['average'].toString(),
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 12 : 11,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Joined date (hidden on mobile)
          if (screenWidth > 768) ...[
            Expanded(
              flex: 1,
              child: Text(
                _formatDate(user['createdAt']),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 12 : 11,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ],
          
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Edit user
                  },
                  icon: Icon(
                    Icons.edit,
                    size: screenWidth > 1400 ? 18 : 16,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () {
                    // TODO: View user details
                  },
                  icon: Icon(
                    Icons.visibility,
                    size: screenWidth > 1400 ? 18 : 16,
                    color: AppColors.textLight,
                  ),
                  tooltip: 'View',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'provider':
        return AppColors.primary;
      case 'client':
        return AppColors.secondary;
      default:
        return AppColors.textLight;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
} 