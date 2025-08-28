import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/notification_service.dart';

// Admin widgets
import 'admin_sidebar.dart';
import 'user_management_widget.dart';
import 'service_management_widget.dart';
import 'booking_management_widget.dart';
import 'reports_widget.dart';
import 'analytics_widget.dart';
import 'notification_widget.dart';
import '../../../profile/presentation/widgets/profile_settings_rich_widget.dart';

// Admin models
import '../../domain/models/admin_menu_item.dart';

class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({super.key});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  int _unreadNotificationCount = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadUnreadNotificationCount();
    
    // Refresh notification count every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadUnreadNotificationCount();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh count when dashboard becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUnreadNotificationCount();
      }
    });
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final response = await _notificationService.getUnreadCount();
      if (response['success'] == true && mounted) {
        setState(() {
          _unreadNotificationCount = response['data']['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load unread notification count: $e');
      }
    }
  }

  List<AdminMenuItem> _getMenuItems(String languageCode) {
    return [
      AdminMenuItem(
        title: AppStrings.getString('userManagement', languageCode),
        icon: Icons.people,
        index: 0,
      ),
      AdminMenuItem(
        title: AppStrings.getString('serviceManagement', languageCode),
        icon: Icons.business_center,
        index: 1,
      ),
      AdminMenuItem(
        title: AppStrings.getString('bookingManagement', languageCode),
        icon: Icons.calendar_today,
        index: 2,
      ),
      AdminMenuItem(
        title: AppStrings.getString('reportsDisputes', languageCode),
        icon: Icons.report_problem,
        index: 3,
      ),
      AdminMenuItem(
        title: AppStrings.getString('analytics', languageCode),
        icon: Icons.analytics,
        index: 4,
      ),
      // New: Notifications
      AdminMenuItem(
        title: 'Notifications',
        icon: Icons.notifications,
        index: 5,
      ),
      // New: Profile Settings (reuse client profile page)
      AdminMenuItem(
        title: AppStrings.getString('profileSettings', languageCode),
        icon: Icons.person,
        index: 6,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildDashboard(context, languageService);
      },
    );
  }

  Widget _buildDashboard(BuildContext context, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    final menuItems = _getMenuItems(languageService.currentLanguage);
    
    // Auto-collapse sidebar on medium screens for better content space
    if (screenWidth <= 1200 && !_isSidebarCollapsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isSidebarCollapsed = true;
        });
      });
    }
    
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: Row(
        children: [
          // Sidebar - Reduced width and better responsive behavior
          AdminSidebar(
            menuItems: menuItems,
            selectedIndex: _selectedIndex,
            isCollapsed: _isSidebarCollapsed,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            onToggleCollapse: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
          ),

          // Main content - More space allocation
          Expanded(
            child: Column(
              children: [
                // Header - Reduced height for better proportions
                _buildHeader(),
                
                // Content with proper padding
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildHeaderContent(context, languageService);
      },
    );
  }

  Widget _buildHeaderContent(BuildContext context, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth > 1400 ? 80 : 70, // Reduced height
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title with better proportions
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth > 1400 ? 32 : 24),
              child: Row(
                children: [
                  // Palestinian flag colors accent - smaller
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary, // Palestinian red
                          AppColors.secondary, // Golden
                          Color(0xFF2E8B57), // Sea green
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: screenWidth > 1400 ? 20 : 16),
                  
                  // Title text - better sizing
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getMenuItems(languageService.currentLanguage)[_selectedIndex].title,
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 28 : 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        AppStrings.getString('adminDashboard', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 16 : 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Admin info and actions - more compact
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth > 1400 ? 32 : 24),
            child: Row(
              children: [
                // Back to Main Menu Button
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
                  icon: Icon(
                    Icons.home,
                    size: screenWidth > 1400 ? 26 : 24,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Back to Main Menu',
                ),

                SizedBox(width: screenWidth > 1400 ? 20 : 16),

                // Notifications
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 5; // Switch to notifications tab
                    });
                    // Refresh unread count when notifications tab is opened
                    _loadUnreadNotificationCount();
                  },
                  icon: Stack(
                    children: [
                      Icon(Icons.notifications_outlined, 
                           size: screenWidth > 1400 ? 26 : 24),
                      // Notification indicator - shows actual unread count
                      if (_unreadNotificationCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'Notifications',
                ),

                SizedBox(width: screenWidth > 1400 ? 20 : 16),

                // Admin profile - more compact
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: screenWidth > 1400 ? 24 : 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            authService.currentUser?['firstName']?.substring(0, 1).toUpperCase() ?? 'A',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth > 1400 ? 18 : 16,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth > 1400 ? 12 : 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${authService.currentUser?['firstName'] ?? 'Admin'} ${authService.currentUser?['lastName'] ?? ''}',
                              style: GoogleFonts.cairo(
                                fontSize: screenWidth > 1400 ? 16 : 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              AppStrings.getString('administrator', languageService.currentLanguage),
                              style: GoogleFonts.cairo(
                                fontSize: screenWidth > 1400 ? 12 : 10,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(width: screenWidth > 1400 ? 20 : 16),

                // Logout button
                IconButton(
                  onPressed: () async {
                    try {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      await authService.logout();
                      if (mounted) {
                        // Navigate to home screen and clear all routes
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Logout failed: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.logout, 
                            size: screenWidth > 1400 ? 26 : 24),
                  tooltip: AppStrings.getString('logout', languageService.currentLanguage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const UserManagementWidget();
      case 1:
        return const ServiceManagementWidget();
      case 2:
        return const BookingManagementWidget();
      case 3:
        return const ReportsWidget();
      case 4:
        return const AnalyticsWidget();
      case 5:
        return const NotificationWidget();
      case 6:
        return const ProfileSettingsRichWidget();
      default:
        return const UserManagementWidget();
    }
  }
} 