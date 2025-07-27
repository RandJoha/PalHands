import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/language_service.dart';

// User dashboard widgets
import 'dashboard_home_widget.dart';
import 'my_bookings_widget.dart';
import 'chat_messages_widget.dart';
import 'payments_widget.dart';
import 'my_reviews_widget.dart';
import 'profile_settings_widget.dart';
import 'saved_providers_widget.dart';
import 'support_help_widget.dart';
import 'security_widget.dart';

// User models
import '../../domain/models/user_menu_item.dart';

// Mobile-specific widgets
import 'mobile_dashboard_home_widget.dart';
import 'mobile_my_bookings_widget.dart';
import 'mobile_chat_messages_widget.dart';
import 'mobile_payments_widget.dart';
import 'mobile_my_reviews_widget.dart';
import 'mobile_profile_settings_widget.dart';
import 'mobile_saved_providers_widget.dart';
import 'mobile_support_help_widget.dart';
import 'mobile_security_widget.dart';


class MobileUserDashboard extends StatefulWidget {
  const MobileUserDashboard({super.key});

  @override
  State<MobileUserDashboard> createState() => _MobileUserDashboardState();
}

class _MobileUserDashboardState extends State<MobileUserDashboard> {
  int _selectedIndex = 0;

  List<UserMenuItem> _getMenuItems(String languageCode) {
    return [
      UserMenuItem(
        title: AppStrings.getString('dashboardHome', languageCode),
        icon: Icons.dashboard,
        index: 0,
      ),
      UserMenuItem(
        title: AppStrings.getString('myBookings', languageCode),
        icon: Icons.calendar_today,
        index: 1,
        badge: '3',
      ),
      UserMenuItem(
        title: AppStrings.getString('chatMessages', languageCode),
        icon: Icons.chat,
        index: 2,
        badge: '2',
      ),
      UserMenuItem(
        title: AppStrings.getString('payments', languageCode),
        icon: Icons.payment,
        index: 3,
      ),
      UserMenuItem(
        title: AppStrings.getString('myReviews', languageCode),
        icon: Icons.star,
        index: 4,
      ),
      UserMenuItem(
        title: AppStrings.getString('profileSettings', languageCode),
        icon: Icons.person,
        index: 5,
      ),
      UserMenuItem(
        title: AppStrings.getString('savedProviders', languageCode),
        icon: Icons.favorite,
        index: 6,
      ),
      UserMenuItem(
        title: AppStrings.getString('supportHelp', languageCode),
        icon: Icons.help,
        index: 7,
      ),
      UserMenuItem(
        title: AppStrings.getString('security', languageCode),
        icon: Icons.security,
        index: 8,
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
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(languageService),
      drawer: _buildDrawer(languageService),
      body: _buildContent(),
      bottomNavigationBar: _buildBottomNavigation(languageService),
    );
  }

  PreferredSizeWidget _buildAppBar(LanguageService languageService) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      title: Row(
        children: [
          Icon(
            Icons.handshake,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'PalHands',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        // Notifications
        IconButton(
          onPressed: () {
            // Handle notifications
          },
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppColors.textSecondary,
                size: 24,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Language toggle
        PopupMenuButton<String>(
          icon: Icon(
            Icons.language,
            color: AppColors.textSecondary,
            size: 24,
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'en',
              child: Text(
                'English',
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
            PopupMenuItem(
              value: 'ar',
              child: Text(
                'العربية',
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            ),
          ],
          onSelected: (value) {
            // Handle language change
          },
        ),
      ],
    );
  }

  Widget _buildDrawer(LanguageService languageService) {
    final menuItems = _getMenuItems(languageService.currentLanguage);
    
    return Drawer(
      child: Container(
        color: AppColors.white,
        child: Column(
          children: [
            // Drawer header
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Ahmed Hassan',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Premium User',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppColors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Menu items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _buildDrawerMenuItem(item);
                },
              ),
            ),
            
            // Drawer footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: AppColors.error,
                      size: 20,
                    ),
                    title: Text(
                      AppStrings.getString('logout', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      // Handle logout
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerMenuItem(UserMenuItem item) {
    final isSelected = _selectedIndex == item.index;
    
    return ListTile(
      leading: Stack(
        children: [
          Icon(
            item.icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 20,
          ),
          if (item.badge != null)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.badge!,
                  style: GoogleFonts.cairo(
                    fontSize: 8,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        item.title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        if (mounted) {
          setState(() {
            _selectedIndex = item.index;
          });
        }
        Navigator.pop(context); // Close drawer
      },
    );
  }

  Widget _buildBottomNavigation(LanguageService languageService) {
    // Show bottom navigation only for main sections
    if (_selectedIndex > 4) return const SizedBox.shrink();
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.cairo(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      currentIndex: _selectedIndex,
      onTap: (index) {
        if (mounted) {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard, size: 20),
          label: AppStrings.getString('dashboardHome', languageService.currentLanguage),
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              Icon(Icons.calendar_today, size: 20),
              if (_selectedIndex != 1)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          label: AppStrings.getString('myBookings', languageService.currentLanguage),
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              Icon(Icons.chat, size: 20),
              if (_selectedIndex != 2)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          label: AppStrings.getString('chatMessages', languageService.currentLanguage),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payment, size: 20),
          label: AppStrings.getString('payments', languageService.currentLanguage),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, size: 20),
          label: AppStrings.getString('profile', languageService.currentLanguage),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const MobileDashboardHomeWidget();
      case 1:
        return const MobileMyBookingsWidget();
      case 2:
        return const MobileChatMessagesWidget();
      case 3:
        return const MobilePaymentsWidget();
      case 4:
        return const MobileMyReviewsWidget();
      case 5:
        return const MobileProfileSettingsWidget();
      case 6:
        return const MobileSavedProvidersWidget();
      case 7:
        return const MobileSupportHelpWidget();
      case 8:
        return const MobileSecurityWidget();
      default:
        return const MobileDashboardHomeWidget();
    }
  }
} 