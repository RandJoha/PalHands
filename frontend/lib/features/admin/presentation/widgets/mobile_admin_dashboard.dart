import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/auth_service.dart';

// Admin widgets
import 'dashboard_overview.dart';
import 'user_management_widget.dart';
import 'service_management_widget.dart';
import 'booking_management_widget.dart';
import 'reports_widget.dart';
import 'analytics_widget.dart';
import 'system_settings_widget.dart';

// Admin models
import '../../domain/models/admin_menu_item.dart';

class MobileAdminDashboard extends StatefulWidget {
  const MobileAdminDashboard({super.key});

  @override
  State<MobileAdminDashboard> createState() => _MobileAdminDashboardState();
}

class _MobileAdminDashboardState extends State<MobileAdminDashboard> {
  int _selectedIndex = 0;

  final List<AdminMenuItem> _menuItems = [
    AdminMenuItem(
      title: 'Overview',
      icon: Icons.dashboard,
      index: 0,
    ),
    AdminMenuItem(
      title: 'User Management',
      icon: Icons.people,
      index: 1,
    ),
    AdminMenuItem(
      title: 'Service Management',
      icon: Icons.business_center,
      index: 2,
    ),
    AdminMenuItem(
      title: 'Booking Management',
      icon: Icons.calendar_today,
      index: 3,
    ),
    AdminMenuItem(
      title: 'Reports & Disputes',
      icon: Icons.report_problem,
      index: 4,
    ),
    AdminMenuItem(
      title: 'Analytics',
      icon: Icons.analytics,
      index: 5,
    ),
    AdminMenuItem(
      title: 'System Settings',
      icon: Icons.settings,
      index: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildContent(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      titleSpacing: 0,
      title: Row(
        children: [
          // Palestinian flag colors accent - Smaller
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary, // Palestinian red
                  AppColors.secondary, // Golden
                  const Color(0xFF2E8B57), // Sea green
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
                  _menuItems[_selectedIndex].title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Admin Dashboard',
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
        // Notifications - Smaller
        IconButton(
          onPressed: () {
            // TODO: Show notifications
          },
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 20),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
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

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Drawer header - More compact
          DrawerHeader(
            decoration: BoxDecoration(
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
                        color: Colors.white.withOpacity(0.2),
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
                            'Admin Panel',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
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
                          backgroundColor: Colors.white.withOpacity(0.2),
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
                                'Administrator',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.8),
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
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
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
                  selectedTileColor: AppColors.primary.withOpacity(0.08),
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
              color: Colors.grey.withOpacity(0.05),
            ),
            child: Column(
              children: [
                // Logout button - More compact
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      await authService.logout();
                      if (mounted) {
                        Navigator.of(context).pushReplacementNamed('/login');
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
                const SizedBox(height: 8),
                
                // Footer text - Smaller
                Text(
                  'Palestinian Heritage',
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Connecting Communities',
                  style: GoogleFonts.cairo(
                    fontSize: 8,
                    color: AppColors.textLight.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final screenWidth = MediaQuery.of(context).size.width;
    
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
        const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard, size: 20),
          label: 'Overview',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people, size: 20),
          label: 'Users',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.business_center, size: 20),
          label: 'Services',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today, size: 20),
          label: 'Bookings',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.report_problem, size: 20),
          label: 'Reports',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics, size: 20),
          label: 'Analytics',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings, size: 20),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardOverview();
      case 1:
        return const UserManagementWidget();
      case 2:
        return const ServiceManagementWidget();
      case 3:
        return const BookingManagementWidget();
      case 4:
        return const ReportsWidget();
      case 5:
        return const AnalyticsWidget();
      case 6:
        return const SystemSettingsWidget();
      default:
        return const DashboardOverview();
    }
  }
} 