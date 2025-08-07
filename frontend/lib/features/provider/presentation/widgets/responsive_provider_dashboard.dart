import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

// Provider widgets
import 'dashboard_overview.dart';
import 'my_services_widget.dart';
import 'bookings_widget.dart';
import 'earnings_widget.dart';
import 'reviews_widget.dart';

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
      'title': 'dashboard',
      'icon': Icons.dashboard,
      'widget': DashboardOverviewWidget(),
    },
    {
      'title': 'myServices',
      'icon': Icons.work,
      'widget': MyServicesWidget(),
    },
    {
      'title': 'bookings',
      'icon': Icons.calendar_today,
      'widget': BookingsWidget(),
    },
    {
      'title': 'earnings',
      'icon': Icons.attach_money,
      'widget': EarningsWidget(),
    },
    {
      'title': 'reviews',
      'icon': Icons.star,
      'widget': ReviewsWidget(),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          AppStrings.getString(_menuItems[_selectedIndex]['title'], languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        actions: [
          // Language toggle button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => languageService.toggleLanguage(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language,
                        size: 16,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        languageService.isEnglish ? 'عربي' : 'EN',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Logout button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout,
                        size: 16,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.getString('logout', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildContent(languageService),
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
          final index = entry.key;
          final item = entry.value;
          return BottomNavigationBarItem(
            icon: Icon(item['icon']),
            label: AppStrings.getString(item['title'], languageService.currentLanguage),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWebLayout(bool isTablet, LanguageService languageService) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: _isSidebarExpanded ? 280 : 80,
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
                // Sidebar header
                _buildSidebarHeader(languageService),
                // Menu items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      return _buildMenuItem(index, languageService);
                    },
                  ),
                ),
                // Language toggle at bottom
                if (_isSidebarExpanded)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => languageService.toggleLanguage(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.language,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    languageService.isEnglish ? 'العربية' : 'English',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _buildContent(languageService),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
              child: Icon(
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
                    'Provider Name',
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
                child: Icon(
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

  Widget _buildMenuItem(int index, LanguageService languageService) {
    final item = _menuItems[index];
    final isSelected = _selectedIndex == index;

    if (_isSidebarExpanded) {
      return _buildExpandedMenuItem(index, item, isSelected, languageService);
    } else {
      return _buildCollapsedMenuItem(index, item, isSelected, languageService);
    }
  }

  Widget _buildExpandedMenuItem(int index, Map<String, dynamic> item, bool isSelected, LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedIndex = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  item['icon'],
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.getString(item['title'], languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.greyDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedMenuItem(int index, Map<String, dynamic> item, bool isSelected, LanguageService languageService) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedIndex = index),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              item['icon'],
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.grey,
            ),
          ),
        ),
      ),
    );
  }

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
            
            return SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.getString('settings', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 24.0 : 32.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.greyDark,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8.0 : 12.0),
                  Text(
                    AppStrings.getString('manageAccountSettings', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14.0 : 16.0,
                      color: AppColors.grey,
                    ),
                  ),
                  SizedBox(height: isMobile ? 20.0 : 32.0),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.getString('manageAccountSettings', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 18.0 : 20.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.greyDark,
                          ),
                        ),
                        SizedBox(height: isMobile ? 16.0 : 20.0),
                        Text(
                          AppStrings.getString('comingSoon', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 14.0 : 16.0,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
