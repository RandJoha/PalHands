import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/auth_service.dart';

// Widget imports
import 'my_services_widget.dart';
import 'bookings_widget.dart';
import 'earnings_widget.dart';
import 'reviews_widget.dart';

import '../../../admin/presentation/widgets/language_toggle_widget.dart';
import '../../../profile/presentation/widgets/profile_settings_widget.dart';

class ResponsiveProviderDashboard extends StatefulWidget {
  const ResponsiveProviderDashboard({super.key});

  @override
  State<ResponsiveProviderDashboard> createState() => _ResponsiveProviderDashboardState();
}

class _ResponsiveProviderDashboardState extends State<ResponsiveProviderDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'myServices',
      'icon': Icons.work,
      'widget': const MyServicesWidget(),
    },
    {
      'title': 'bookings',
      'icon': Icons.calendar_today,
      'widget': const BookingsWidget(),
    },
    {
      'title': 'earnings',
      'icon': Icons.attach_money,
      'widget': const EarningsWidget(),
    },
    {
      'title': 'reviews',
      'icon': Icons.star,
      'widget': const ReviewsWidget(),
    },
    {
      'title': 'profileSettings',
      'icon': Icons.person,
      'widget': const ProfileSettingsWidget(),
    },
    {
      'title': 'settings',
      'icon': Icons.settings,
      'widget': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth <= 768;
            final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
            
            if (isMobile) {
              return _buildMobileLayout(isMobile, languageService);
            } else {
              return _buildWebLayout(isTablet, languageService);
            }
          },
        );
      },
    );
  }

  Widget _buildMobileLayout(bool isMobile, LanguageService languageService) {
    return WillPopScope(
      onWillPop: () async {
        // If not on the home tab, go to home instead of popping the route
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        // On home tab: confirm stay or logout instead of leaving the dashboard
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text(
                AppStrings.getString('providerDashboard', languageService.currentLanguage),
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              content: Text(
                AppStrings.getString('areYouSure', languageService.currentLanguage)
                    .isNotEmpty
                    ? AppStrings.getString('areYouSure', languageService.currentLanguage)
                    : 'Do you want to logout or stay on the dashboard?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(AppStrings.getString('cancel', languageService.currentLanguage)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(AppStrings.getString('logout', languageService.currentLanguage)),
                ),
              ],
            );
          },
        );
        if (shouldLogout == true && mounted) {
          try {
            final authService = Provider.of<AuthService>(context, listen: false);
            await authService.logout();
          } catch (_) {}
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        }
        // Prevent default pop in both cases (we either stayed or navigated ourselves)
        return false;
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildMobileDrawer(languageService),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.getString(_menuItems[_selectedIndex]['title'], languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            Text(
              AppStrings.getString('providerDashboard', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
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
          
          // Notifications
          IconButton(
            onPressed: () {
              // TODO: Show notifications
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 20, color: AppColors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Provider profile
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.white,
              child: Text(
                'P',
                style: GoogleFonts.cairo(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.all(16),
        child: _buildContent(languageService),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        selectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.cairo(),
        items: _menuItems.asMap().entries.map((entry) {
          final item = entry.value;
          return BottomNavigationBarItem(
            icon: Icon(item['icon']),
            label: AppStrings.getString(item['title'], languageService.currentLanguage),
          );
        }).toList(),
      ),
  ),
  );
  }

  Widget _buildWebLayout(bool isTablet, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        // On home tab: confirm stay or logout instead of leaving the dashboard
        final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text(
                AppStrings.getString('providerDashboard', languageService.currentLanguage),
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              content: Text(
                AppStrings.getString('areYouSure', languageService.currentLanguage)
                    .isNotEmpty
                    ? AppStrings.getString('areYouSure', languageService.currentLanguage)
                    : 'Do you want to logout or stay on the dashboard?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(AppStrings.getString('cancel', languageService.currentLanguage)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(AppStrings.getString('logout', languageService.currentLanguage)),
                ),
              ],
            );
          },
        );
        if (shouldLogout == true && mounted) {
          try {
            final authService = Provider.of<AuthService>(context, listen: false);
            await authService.logout();
          } catch (_) {}
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          }
        }
        return false;
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          Container(
            width: _isSidebarExpanded ? 280 : 70,
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sidebar Header
                _buildSidebarHeader(languageService),
                
                // Menu Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = _selectedIndex == index;
                      
                      return ListTile(
                        leading: Icon(
                          item['icon'],
                          color: isSelected ? AppColors.primary : AppColors.grey,
                        ),
                        title: _isSidebarExpanded ? Text(
                          AppStrings.getString(item['title'], languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            color: isSelected ? AppColors.primary : AppColors.textDark,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ) : null,
                        selected: isSelected,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
                
                // Language Toggle in Sidebar
                _buildSidebarLanguageToggle(languageService),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header - Updated to match Admin Dashboard order
                _buildHeader(languageService),
                
                // Content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(screenWidth > 1400 ? 24 : 16),
                    child: _buildContent(languageService),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth > 1400 ? 80 : 70,
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
          // Title Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth > 1400 ? 32 : 24),
              child: Row(
                children: [
                  // Palestinian flag colors accent
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                          Color(0xFF2E8B57),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: screenWidth > 1400 ? 20 : 16),
                  
                  // Title text
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.getString(_menuItems[_selectedIndex]['title'], languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 24 : 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        AppStrings.getString('providerDashboard', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 14 : 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Header Actions - Updated to match Admin Dashboard order
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth > 1400 ? 32 : 24),
            child: Row(
              children: [
                // Notifications
                IconButton(
                  onPressed: () {
                    // TODO: Show notifications
                  },
                  icon: Stack(
                    children: [
                      Icon(Icons.notifications_outlined, 
                           size: screenWidth > 1400 ? 26 : 24),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: screenWidth > 1400 ? 20 : 16),

                // Provider profile - more compact
                Row(
                  children: [
                    CircleAvatar(
                      radius: screenWidth > 1400 ? 24 : 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        'P', // Provider initial
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
                          AppStrings.getString('providerName', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: screenWidth > 1400 ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          AppStrings.getString('serviceProvider', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: screenWidth > 1400 ? 12 : 10,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  icon: const Icon(
                    Icons.logout,
                    color: AppColors.textSecondary,
                    size: 24.0,
                  ),
                  tooltip: AppStrings.getString('logout', languageService.currentLanguage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Row(
        children: [
          if (_isSidebarExpanded) ...[
            // User avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.getString('providerName', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    AppStrings.getString('serviceProvider', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Collapsed header
            Expanded(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ),
          ],
          // Toggle button
          IconButton(
            onPressed: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
            icon: Icon(
              _isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Note: legacy sidebar menu item builders removed as unused.

  Widget _buildContent(LanguageService languageService) {
    if (_selectedIndex == _menuItems.length - 1) {
      // Settings tab
      return _buildSettingsWidget();
    }
    
    final selectedItem = _menuItems[_selectedIndex];
    return selectedItem['widget'] ?? Container();
  }

  Widget _buildSettingsWidget() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth <= 768;
            
            return Center(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.getString('settings', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 24.0 : 28.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greyDark,
                      ),
                    ),
                    SizedBox(height: isMobile ? 8.0 : 12.0),
                    Text(
                      AppStrings.getString('comingSoon', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14.0 : 16.0,
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSidebarLanguageToggle(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    return LanguageToggleWidget(
      isCollapsed: !_isSidebarExpanded,
      screenWidth: screenWidth,
    );
  }

  Widget _buildMobileDrawer(LanguageService languageService) {
    return Drawer(
      child: Container(
        color: AppColors.white,
        child: Column(
          children: [
            // Drawer header
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
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
                        child: const Icon(
                          Icons.work,
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
                              AppStrings.getString('providerName', languageService.currentLanguage),
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              AppStrings.getString('serviceProvider', languageService.currentLanguage),
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppColors.white.withValues(alpha: 0.8),
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
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = _selectedIndex == index;
                  
                  return ListTile(
                    leading: Icon(
                      item['icon'],
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    title: Text(
                      AppStrings.getString(item['title'], languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            
            // Language toggle and logout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // Language toggle - Updated to match Admin dashboard design
                  LanguageToggleWidget(
                    isCollapsed: false,
                    screenWidth: MediaQuery.of(context).size.width,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
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
                    onTap: () async {
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
