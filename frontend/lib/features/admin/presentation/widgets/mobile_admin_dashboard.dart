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

// Admin widgets
import 'user_management_widget.dart';
import 'service_management_widget.dart';
import 'booking_management_widget.dart';
import 'reports_widget.dart';
import 'analytics_widget.dart';
import 'notification_widget.dart';
import '../../../profile/presentation/widgets/profile_settings_rich_widget.dart';

// Admin models
import '../../domain/models/admin_menu_item.dart';

class MobileAdminDashboard extends StatefulWidget {
  const MobileAdminDashboard({super.key});

  @override
  State<MobileAdminDashboard> createState() => _MobileAdminDashboardState();
}

class _MobileAdminDashboardState extends State<MobileAdminDashboard> {
  int _selectedIndex = 0;
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
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      appBar: _buildAppBar(languageService),
      drawer: _buildDrawer(languageService),
      body: _buildContent(),
      bottomNavigationBar: _buildBottomNavigation(languageService),
    );
  }

  PreferredSizeWidget _buildAppBar(LanguageService languageService) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      titleSpacing: 0,
      title: Row(
        children: [
          // Palestinian flag colors accent - Smaller
          Container(
            width: 3,
            height: 24,
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
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 8),
          
          // Title - More compact
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getMenuItems(languageService.currentLanguage)[_selectedIndex].title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppStrings.getString('adminDashboard', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Back to Main Menu Button
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/home');
          },
          icon: const Icon(
            Icons.home,
            color: AppColors.primary,
            size: 24,
          ),
          tooltip: 'Back to Main Menu',
        ),
        
        // Language toggle button
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => languageService.toggleLanguage(),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Language flag/icon
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: languageService.isArabic ? AppColors.primary : AppColors.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              languageService.isArabic ? 'ع' : 'EN',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Language text
                        Text(
                          languageService.isArabic
                            ? AppStrings.getString('arabicLanguage', 'ar')
                            : AppStrings.getString('englishLanguage', 'en'),
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Notifications - Smaller
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
              const Icon(Icons.notifications_outlined, size: 20),
              // Notification indicator - shows actual unread count
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Admin profile - More compact
        Consumer<AuthService>(
          builder: (context, authService, child) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Text(
                  authService.currentUser?['firstName']?.substring(0, 1).toUpperCase() ?? 'A',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawer(LanguageService languageService) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header - More compact
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and title - More compact
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PalHands',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            AppStrings.getString('adminPanel', languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Admin info - More compact
                Consumer<AuthService>(
                  builder: (context, authService, child) {
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            authService.currentUser?['firstName']?.substring(0, 1).toUpperCase() ?? 'A',
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${authService.currentUser?['firstName'] ?? 'Admin'} ${authService.currentUser?['lastName'] ?? ''}',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                AppStrings.getString('administrator', languageService.currentLanguage),
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Menu items - More compact
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _getMenuItems(languageService.currentLanguage).length,
              itemBuilder: (context, index) {
                final item = _getMenuItems(languageService.currentLanguage)[index];
                final isSelected = _selectedIndex == index;
                
                return ListTile(
                  dense: true,
                  leading: Icon(
                    item.icon,
                    color: isSelected ? AppColors.primary : AppColors.textLight,
                    size: 20,
                  ),
                  title: Text(
                    item.title,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    Navigator.pop(context); // Close drawer
                  },
                );
              },
            ),
          ),

          // Footer - More compact
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
            ),
            child: Column(
              children: [
                // Logout button - More compact
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.logout, size: 16),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(LanguageService languageService) {
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 8,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textLight,
      selectedLabelStyle: GoogleFonts.cairo(
        fontWeight: FontWeight.w600,
        fontSize: 10,
      ),
      unselectedLabelStyle: GoogleFonts.cairo(
        fontSize: 10,
      ),
        currentIndex: _selectedIndex.clamp(0, 6), // Updated to support 7 items (0-6)
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.people, size: 20),
          label: AppStrings.getString('userManagement', languageService.currentLanguage),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.business_center, size: 20),
          label: AppStrings.getString('serviceManagement', languageService.currentLanguage),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_today, size: 20),
          label: AppStrings.getString('bookingManagement', languageService.currentLanguage),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.report_problem, size: 20),
          label: AppStrings.getString('reportsDisputes', languageService.currentLanguage),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.analytics, size: 20),
          label: AppStrings.getString('analytics', languageService.currentLanguage),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.notifications, size: 20),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person, size: 20),
          label: AppStrings.getString('profileSettings', languageService.currentLanguage),
        ),
      ],
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