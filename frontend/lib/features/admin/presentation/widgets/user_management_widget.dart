import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/user_service.dart';
import '../../../../shared/services/auth_service.dart';

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
  final int _currentPage = 1;
  final int _totalPages = 1;
  
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _loadUsers();
  }

  void _onRoleChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedRole = value;
      });
      // if (kDebugMode) {
      //   print('🔍 Role filter changed to: $value');
      // }
      _loadUsers();
    }
  }

  void _onStatusChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedStatus = value;
      });
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get AuthService from Provider context
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // if (kDebugMode) {
      //   print('🔍 Loading users with filters:');
      //   print('  - Search: ${_searchQuery.isNotEmpty ? _searchQuery : "None"}');
      //   print('  - Role: ${_selectedRole != 'all' ? _selectedRole : "All"}');
      //   print('  - Status: ${_selectedStatus != 'all' ? _selectedStatus : "All"}');
      // }
      
      final response = await _userService.getAllUsers(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        role: _selectedRole != 'all' ? _selectedRole : null,
        status: _selectedStatus != 'all' ? _selectedStatus : null,
        page: _currentPage,
        limit: 100, // Get more users
        authService: authService,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final users = data['users'] as List<dynamic>;
        
        setState(() {
          _users = users.map((user) => Map<String, dynamic>.from(user)).toList();
          _isLoading = false;
        });
        
        // Debug: Print rating data for first user
        // if (kDebugMode && _users.isNotEmpty) {
        //   print('🔍 First user rating: ${_users[0]['rating']}');
        //   print('🔍 First user rating type: ${_users[0]['rating']?.runtimeType}');
        // }
      } else {
        setState(() {
          _isLoading = false;
        });
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Failed to load users',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load users: $e',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildUserManagement(context, languageService);
      },
    );
  }

  Widget _buildUserManagement(BuildContext context, LanguageService languageService) {
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
            
            // Filters - Improved sizing
            _buildFilters(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
            
            // Users table
            Expanded(
              child: _buildUsersTable(languageService),
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
                AppStrings.getString('userManagement', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 22 : screenWidth > 1024 ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                AppStrings.getString('managePlatformUsers', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        
        // Palestine identity element
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
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
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(width: 6.w),
              Text(
                AppStrings.getString('palestine', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        

      ],
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
                      hintText: AppStrings.getString('searchByNameEmailPhone', languageService.currentLanguage),
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
                    onChanged: _onRoleChanged,
                    decoration: InputDecoration(
                      labelText: AppStrings.getString('role', languageService.currentLanguage),
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
                      DropdownMenuItem(value: 'all', child: Text(AppStrings.getString('allRoles', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'client', child: Text(AppStrings.getString('client', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                      DropdownMenuItem(value: 'provider', child: Text(AppStrings.getString('provider', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                    ],
                  ),
                ),
                
                SizedBox(width: screenWidth > 1400 ? 12 : 10),
                
                // Status filter - More compact
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    onChanged: _onStatusChanged,
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
                    hintText: AppStrings.getString('searchByNameEmailPhone', languageService.currentLanguage),
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
                        onChanged: _onRoleChanged,
                        decoration: InputDecoration(
                          labelText: AppStrings.getString('role', languageService.currentLanguage),
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
                          DropdownMenuItem(value: 'all', child: Text(AppStrings.getString('allRoles', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'client', child: Text(AppStrings.getString('client', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                          DropdownMenuItem(value: 'provider', child: Text(AppStrings.getString('provider', languageService.currentLanguage), style: GoogleFonts.cairo(fontSize: 13))),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        onChanged: _onStatusChanged,
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

  Widget _buildUsersTable(LanguageService languageService) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.getString('noUsersFound', languageService.currentLanguage),
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
                Expanded(flex: 2, child: _buildHeaderCell(AppStrings.getString('user', languageService.currentLanguage))),
                Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('role', languageService.currentLanguage))),
                Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('status', languageService.currentLanguage))),
                if (screenWidth > 768) ...[
                  Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('rating', languageService.currentLanguage))),
                  Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('joined', languageService.currentLanguage))),
                ],
                Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('actions', languageService.currentLanguage))),
              ],
            ),
          ),
          
          // Table body
          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return _buildUserRow(user, languageService);
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

  Widget _buildUserRow(Map<String, dynamic> user, LanguageService languageService) {
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
                color: _getRoleColor(user['role']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getLocalizedRole(user['role'], languageService),
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
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user['isActive'] 
                  ? AppStrings.getString('active', languageService.currentLanguage).toUpperCase()
                  : AppStrings.getString('inactive', languageService.currentLanguage).toUpperCase(),
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
                  const SizedBox(width: 4),
                  Text(
                    _formatRating(user['rating']),
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
                    _showEditUserDialog(user, languageService);
                  },
                  icon: Icon(
                    Icons.edit,
                    size: screenWidth > 1400 ? 18 : 16,
                    color: AppColors.primary,
                  ),
                  tooltip: AppStrings.getString('edit', languageService.currentLanguage),
                ),
                if (user['isActive'] == true) ...[
                  IconButton(
                    onPressed: () {
                      _showInactivationDialog(user, languageService);
                    },
                    icon: Icon(
                      Icons.block,
                      size: screenWidth > 1400 ? 18 : 16,
                      color: Colors.red,
                    ),
                    tooltip: AppStrings.getString('inactivate', languageService.currentLanguage),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedRole(String role, LanguageService languageService) {
    switch (role) {
      case 'admin':
        return AppStrings.getString('admin', languageService.currentLanguage).toUpperCase();
      case 'provider':
        return AppStrings.getString('provider', languageService.currentLanguage).toUpperCase();
      case 'client':
        return AppStrings.getString('client', languageService.currentLanguage).toUpperCase();
      default:
        return role.toUpperCase();
    }
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
      return AppStrings.getString('na', 'en'); // Use English for date format
    }
  }

  String _formatRating(dynamic rating) {
    // if (kDebugMode) {
    //   print('🔍 Rating data: $rating');
    //   print('🔍 Rating type: ${rating.runtimeType}');
    // }
    
    // Handle null rating
    if (rating == null) {
      return '0.0';
    }
    
    // If rating is a number (direct value)
    if (rating is num) {
      return rating.toStringAsFixed(1);
    }
    
    // If rating is a string (convert to number)
    if (rating is String) {
      try {
        final numValue = double.parse(rating);
        return numValue.toStringAsFixed(1);
      } catch (e) {
        return '0.0';
      }
    }
    
    // If rating is a map with 'average' field (expected structure)
    if (rating is Map<String, dynamic>) {
      final average = rating['average'];
      if (average != null) {
        if (average is num) {
          return average.toStringAsFixed(1);
        }
        if (average is String) {
          try {
            final numValue = double.parse(average);
            return numValue.toStringAsFixed(1);
          } catch (e) {
            return '0.0';
          }
        }
      }
    }
    
    // Default fallback
    return '0.0';
  }

  void _showEditUserDialog(Map<String, dynamic> user, LanguageService languageService) {
    bool isActive = user['isActive'] ?? false;
    String selectedRole = user['role'] ?? 'client';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                '${AppStrings.getString('edit', languageService.currentLanguage)} ${user['firstName']} ${user['lastName']}',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status toggle
                  Row(
                    children: [
                      Text(
                        AppStrings.getString('status', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: isActive,
                        onChanged: (value) {
                          setState(() {
                            isActive = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      Text(
                        isActive 
                          ? AppStrings.getString('active', languageService.currentLanguage)
                          : AppStrings.getString('inactive', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Role dropdown
                  Text(
                    AppStrings.getString('role', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'client',
                        child: Text(AppStrings.getString('client', languageService.currentLanguage)),
                      ),
                      DropdownMenuItem(
                        value: 'provider',
                        child: Text(AppStrings.getString('provider', languageService.currentLanguage)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    AppStrings.getString('cancel', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _updateUserStatus(
                      userId: user['_id'],
                      isActive: isActive,
                      role: selectedRole,
                      languageService: languageService,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    AppStrings.getString('update', languageService.currentLanguage),
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

  void _showInactivationDialog(Map<String, dynamic> user, LanguageService languageService) {
    String reason = '';
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    AppStrings.getString('inactivateUser', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.getString('inactivateUserConfirmation', languageService.currentLanguage)} ${user['firstName']} ${user['lastName']}?',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.getString('inactivationImpact', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          user['role'] == 'provider' 
                            ? '• ${AppStrings.getString('allBookingsCancelled', languageService.currentLanguage)}\n• ${AppStrings.getString('accountDisabled', languageService.currentLanguage)}\n• ${AppStrings.getString('servicesRemoved', languageService.currentLanguage)}'
                            : '• ${AppStrings.getString('allBookingsCancelled', languageService.currentLanguage)}\n• ${AppStrings.getString('accountDisabled', languageService.currentLanguage)}',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.getString('reasonRequired', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: AppStrings.getString('enterInactivationReason', languageService.currentLanguage),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        setState(() {
                          reason = value;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    AppStrings.getString('cancel', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isProcessing || reason.trim().isEmpty
                      ? null
                      : () async {
                          setState(() {
                            isProcessing = true;
                          });
                          await _inactivateUser(
                            userId: user['_id'],
                            reason: reason.trim(),
                            languageService: languageService,
                          );
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          AppStrings.getString('inactivate', languageService.currentLanguage),
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

  Future<void> _inactivateUser({
    required String userId,
    required String reason,
    required LanguageService languageService,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get AuthService from Provider context
      final authService = Provider.of<AuthService>(context, listen: false);

      print('🚫 Frontend: Starting inactivation for user $userId with reason: $reason');

      final response = await _userService.inactivateUser(
        userId: userId,
        reason: reason,
        authService: authService,
      );

      print('🚫 Frontend: Received response: $response');

      if (response['success'] == true) {
        print('🚫 Frontend: Inactivation successful, updating UI');
        
        // Always refresh the user list to ensure UI is in sync with backend
        await _loadUsers();
        print('🚫 Frontend: Refreshed user list after inactivation');

        // Show success message with impact details
        final data = response['data'];
        final impact = data?['impact'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.getString('userInactivatedSuccessfully', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${AppStrings.getString('cancelledBookings', languageService.currentLanguage)}: ${impact?['cancelledBookings'] ?? 0}\n${AppStrings.getString('affectedUsers', languageService.currentLanguage)}: ${impact?['affectedUsers'] ?? 0}',
                    style: GoogleFonts.cairo(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        print('🚫 Frontend: Inactivation failed: ${response['message']}');
        
        // Check if user is already inactive - this means the operation actually succeeded
        if (response['alreadyInactive'] == true || response['message']?.contains('already inactive') == true) {
          print('🚫 Frontend: User already inactive, refreshing UI...');
          // Refresh the user list to show current state
          await _loadUsers();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'User successfully inactivated',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
            );
          }
        } else {
          // Show error message for other failures
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  response['message'] ?? AppStrings.getString('inactivationFailed', languageService.currentLanguage),
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('🚫 Frontend: Exception during inactivation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inactivation failed: ${e.toString()}',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserStatus({
    required String userId,
    required bool isActive,
    required String role,
    required LanguageService languageService,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get AuthService from Provider context
      final authService = Provider.of<AuthService>(context, listen: false);

      final response = await _userService.updateUserStatus(
        userId: userId,
        isActive: isActive,
        role: role,
        authService: authService,
      );

      if (response['success'] == true) {
        // Update the user in the local list
        final userIndex = _users.indexWhere((user) => user['_id'] == userId);
        if (userIndex != -1) {
          setState(() {
            _users[userIndex]['isActive'] = isActive;
            _users[userIndex]['role'] = role;
          });
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.getString('userUpdatedSuccessfully', languageService.currentLanguage),
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? AppStrings.getString('updateFailed', languageService.currentLanguage),
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.getString('updateFailed', languageService.currentLanguage),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 