// ignore_for_file: dead_code
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../../shared/services/auth_service.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

// Widget imports
import '../../../admin/presentation/widgets/language_toggle_widget.dart';

// User models
class UserMenuItem {
  final String title;
  final IconData icon;
  final int index;
  final String? badge;

  UserMenuItem({
    required this.title,
    required this.icon,
    required this.index,
    this.badge,
  });
}

class ResponsiveUserDashboard extends StatefulWidget {
  final int? initialIndex;
  const ResponsiveUserDashboard({super.key, this.initialIndex});

  @override
  State<ResponsiveUserDashboard> createState() => _ResponsiveUserDashboardState();
}

class _ResponsiveUserDashboardState extends State<ResponsiveUserDashboard> 
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  static const String _tabStorageKey = 'user_dashboard_tab_index';
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _sidebarAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _contentAnimation;

  // Menu items - will be localized
  List<UserMenuItem> _getMenuItems() {
    return [
      UserMenuItem(title: _getLocalizedString('my_bookings'), icon: Icons.calendar_today, index: 0, badge: '3'),
      UserMenuItem(title: _getLocalizedString('chat_messages'), icon: Icons.chat, index: 1, badge: '2'),
      UserMenuItem(title: _getLocalizedString('payments'), icon: Icons.payment, index: 2),
      UserMenuItem(title: _getLocalizedString('my_reviews'), icon: Icons.star, index: 3),
      UserMenuItem(title: _getLocalizedString('profile_settings'), icon: Icons.person, index: 4),
      UserMenuItem(title: _getLocalizedString('saved_providers'), icon: Icons.favorite, index: 5),
      UserMenuItem(title: _getLocalizedString('support_help'), icon: Icons.help, index: 6),
      UserMenuItem(title: _getLocalizedString('security'), icon: Icons.security, index: 7),
    ];
  }

  String _getLocalizedString(String key) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final ar = languageService.currentLanguage == 'ar';
    switch (key) {
      case 'pleaseVerifyAccount':
        return ar ? 'يرجى توثيق الحساب' : 'Please verify account';
      case 'verify':
        return ar ? 'توثيق' : 'Verify';
      case 'age':
        return ar ? 'العمر' : 'Age';
      case 'membersSince':
        return ar ? 'عضو منذ' : 'Members since';
      case 'email':
        return ar ? 'البريد الإلكتروني' : 'Email';
      case 'phoneNumber':
        return ar ? 'رقم الهاتف' : 'Phone Number';
      case 'fullName':
        return ar ? 'الاسم الكامل' : 'Full Name';
      case 'personalInformation':
        return ar ? 'المعلومات الشخصية' : 'Personal Information';
      case 'savedAddresses':
        return ar ? 'العناوين المحفوظة' : 'Saved Addresses';
      case 'addNewAddress':
        return ar ? 'إضافة عنوان جديد' : 'Add New Address';
      case 'notificationPreferences':
        return ar ? 'تفضيلات الإشعارات' : 'Notification Preferences';
      case 'emailNotifications':
        return ar ? 'إشعارات البريد الإلكتروني' : 'Email Notifications';
      case 'pushNotifications':
        return ar ? 'الإشعارات الفورية' : 'Push Notifications';
      case 'defaultText':
        return ar ? 'افتراضي' : 'Default';
      case 'home':
        return ar ? 'المنزل' : 'Home';
      case 'profileSettings':
        return ar ? 'إعدادات الملف الشخصي' : 'Profile Settings';
      case 'saveChanges':
        return ar ? 'حفظ التغييرات' : 'Save Changes';
      case 'cancel':
        return ar ? 'إلغاء' : 'Cancel';
      default:
        return AppStrings.getString(key, languageService.currentLanguage);
    }
  }

  @override
  void initState() {
    super.initState();
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  // Sidebar animation controller in place for future transitions

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    ));

  _contentAnimationController.forward();
  _restoreSelectedTab();
  if (widget.initialIndex != null) {
    final max = _getMenuItems().length - 1;
    final idx = widget.initialIndex!.clamp(0, max);
    setState(() => _selectedIndex = idx);
  }
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
  final screenWidth = constraints.maxWidth;
        
        // Responsive breakpoints
        final isDesktop = screenWidth > 1200;
        final isTablet = screenWidth > 768 && screenWidth <= 1200;
        final isMobile = screenWidth <= 768;

        return Scaffold(
          key: _scaffoldKey,
          drawer: isMobile ? _buildMobileDrawer() : null,
          body: Row(
            children: [
              // Responsive Sidebar
              if (isDesktop || isTablet) _buildResponsiveSidebar(isDesktop, isTablet),
              
              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Responsive App Bar
                    _buildResponsiveAppBar(isMobile, isTablet),
                    
                    // Main Content
                    Expanded(
                      child: _buildResponsiveContent(isMobile, isTablet, isDesktop),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Mobile Bottom Navigation
          bottomNavigationBar: isMobile ? _buildMobileBottomNavigation() : null,
        );
      },
    );
  }

  Widget _buildResponsiveSidebar(bool isDesktop, bool isTablet) {
    final sidebarWidth = isDesktop ? 280.0 : 240.0;
    const collapsedWidth = 70.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarCollapsed ? collapsedWidth : sidebarWidth,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            right: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Sidebar Header
            _buildSidebarHeader(isDesktop, isTablet),
            
            // Menu Items
            Expanded(
              child: _buildSidebarMenu(isDesktop, isTablet),
            ),
            
            // Language Toggle
            _buildLanguageToggle(isDesktop, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(bool isDesktop, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: const Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!_isSidebarCollapsed) ...[
            Icon(
              Icons.handshake,
              color: AppColors.primary,
              size: isDesktop ? 32.0 : 28.0,
            ),
            SizedBox(width: isDesktop ? 16.0 : 12.0),
            Expanded(
              child: Text(
                'PalHands',
                style: GoogleFonts.cairo(
                  fontSize: isDesktop ? 20.0 : 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ] else ...[
            const Icon(
              Icons.handshake,
              color: AppColors.primary,
              size: 28.0,
            ),
          ],
          if (isDesktop) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
              icon: Icon(
                _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarMenu(bool isDesktop, bool isTablet) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final menuItems = _getMenuItems();
        return ListView.builder(
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 16.0 : 12.0,
            horizontal: isDesktop ? 12.0 : 8.0,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            final isSelected = _selectedIndex == index;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: isDesktop ? 8.0 : 6.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(isDesktop ? 12.0 : 10.0),
                border: isSelected ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ) : null,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16.0 : 12.0,
                  vertical: isDesktop ? 8.0 : 6.0,
                ),
                leading: Icon(
                  item.icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: isDesktop ? 24.0 : 22.0,
                ),
                title: _isSidebarCollapsed ? null : Text(
                  item.title,
                  style: GoogleFonts.cairo(
                    fontSize: isDesktop ? 16.0 : 14.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _selectedIndex = index;
                    });
                    _persistSelectedTab();
                    _contentAnimationController.reset();
                    _contentAnimationController.forward();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResponsiveAppBar(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 24.0,
        vertical: isMobile ? 12.0 : 16.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(
                Icons.menu,
                color: AppColors.textPrimary,
                size: 24.0,
              ),
            ),
            const SizedBox(width: 12.0),
          ],
          Expanded(
            child: Consumer<LanguageService>(
              builder: (context, languageService, child) {
                final menuItems = _getMenuItems();
                return Text(
                  menuItems[_selectedIndex].title,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 20.0 : 24.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                );
              },
            ),
          ),
          // Header Actions - Updated to match Admin Dashboard order
          _buildHeaderActions(isMobile, isTablet),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(bool isMobile, bool isTablet) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
    return Row(
      children: [
            // Notifications
            IconButton(
              onPressed: () {
                // TODO: Show notifications
              },
              icon: Stack(
                children: [
          Icon(
            Icons.notifications_outlined,
            color: AppColors.textSecondary,
            size: isTablet ? 22.0 : 24.0,
          ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
          SizedBox(width: isTablet ? 16.0 : 20.0),

            // User profile
            Consumer<AuthService>(
              builder: (context, authService, child) {
                return Row(
                  children: [
                    CircleAvatar(
                      radius: isTablet ? 20.0 : 24.0,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        authService.currentUser?['firstName']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 16.0 : 18.0,
                        ),
                      ),
                    ),
                    if (!isMobile) ...[
                      SizedBox(width: isTablet ? 10.0 : 12.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${authService.currentUser?['firstName'] ?? 'User'} ${authService.currentUser?['lastName'] ?? ''}',
                            style: GoogleFonts.cairo(
                              fontSize: isTablet ? 14.0 : 16.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            AppStrings.getString('client', languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: isTablet ? 10.0 : 12.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
            ],
                      ),
          ],
                  ],
                );
              },
            ),

            SizedBox(width: isTablet ? 16.0 : 20.0),

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
              icon: Icon(
                Icons.logout,
                color: AppColors.textSecondary,
                size: isTablet ? 22.0 : 24.0,
              ),
              tooltip: AppStrings.getString('logout', languageService.currentLanguage),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveContent(bool isMobile, bool isTablet, bool isDesktop) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return AnimatedBuilder(
          animation: _contentAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.95 + (_contentAnimation.value * 0.05),
              child: Opacity(
                opacity: _contentAnimation.value,
                child: _buildContent(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildMyBookings();
      case 1:
        return _buildChatMessages();
      case 2:
        return _buildPayments();
      case 3:
        return _buildMyReviews();
      case 4:
        return _buildProfileSettings();
      case 5:
        return _buildSavedProviders();
      case 6:
        return _buildSupportHelp();
      case 7:
        return _buildSecurity();
      default:
        return _buildMyBookings();
    }
  }

  Widget _buildLanguageToggle(bool isDesktop, bool isTablet) {
    return LanguageToggleWidget(
      isCollapsed: _isSidebarCollapsed,
      screenWidth: MediaQuery.of(context).size.width,
    );
  }

  Widget _buildMobileBottomNavigation() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        // Only show bottom navigation for main sections (0-4)
        // For other sections (5-8), hide the bottom navigation
        if (_selectedIndex > 4) {
          return const SizedBox.shrink();
        }
        
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex.clamp(0, 4),
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
          onTap: (index) {
            if (mounted) {
              setState(() {
                _selectedIndex = index;
                _persistSelectedTab();
              });
              _contentAnimationController.reset();
              _contentAnimationController.forward();
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  if (_selectedIndex != 0)
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
              label: _getLocalizedString('my_bookings'),
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.chat, size: 20),
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
              label: _getLocalizedString('chat_messages'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payment, size: 20),
              label: _getLocalizedString('payments'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star, size: 20),
              label: _getLocalizedString('my_reviews'),
            ),
          ],
        );
      },
    );
  }





  // Content sections with responsive layouts
  Widget _buildMyBookings() => _buildMyBookingsContent();
  Widget _buildChatMessages() => _buildChatMessagesContent();
  Widget _buildPayments() => _buildPaymentsContent();
  Widget _buildMyReviews() => _buildMyReviewsContent();
  Widget _buildProfileSettings() => _buildProfileSettingsContent();
  Widget _buildSavedProviders() => _buildSavedProvidersContent();
  Widget _buildSupportHelp() => _buildSupportHelpContent();
  Widget _buildSecurity() => _buildSecurityContent();

  // My Bookings Section
  Widget _buildMyBookingsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Palestine element
              Row(
                children: [
                  Text(
                    _getLocalizedString('my_bookings'),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0), 
                      vertical: isMobile ? 4.0 : (isTablet ? 5.0 : 6.0)
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
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
                          style: TextStyle(fontSize: isMobile ? 14.0 : (isTablet ? 15.0 : 16.0)),
                        ),
                        SizedBox(width: isMobile ? 4.0 : (isTablet ? 5.0 : 6.0)),
                        Text(
                          _getLocalizedString('palestine'),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 16.0 : 20.0),
              
              // Filter Tabs
              _buildBookingFilters(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Bookings List
              _buildBookingsList(isMobile, isTablet, constraints.maxWidth),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingFilters(bool isMobile, bool isTablet) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final filters = [
      AppStrings.getString('all', languageService.currentLanguage),
      AppStrings.getString('upcoming', languageService.currentLanguage),
      AppStrings.getString('completed', languageService.currentLanguage),
      AppStrings.getString('cancelled', languageService.currentLanguage),
    ];
    int selectedFilter = 0; // This would be state in a real app
    
    return Wrap(
      spacing: isMobile ? 8.0 : 12.0,
      children: filters.asMap().entries.map((entry) {
        final index = entry.key;
        final filter = entry.value;
        final isSelected = selectedFilter == index;
        
        return FilterChip(
          label: Text(
            filter,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            // Handle filter selection
          },
          backgroundColor: AppColors.white,
          selectedColor: AppColors.primary,
          checkmarkColor: AppColors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingsList(bool isMobile, bool isTablet, double screenWidth) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final bookings = [
      {
        'service': AppStrings.getString('homeCleaning', languageService.currentLanguage),
        'provider': 'Fatima Al-Zahra',
        'date': AppStrings.getString('tomorrow10AM', languageService.currentLanguage),
        'status': AppStrings.getString('confirmed', languageService.currentLanguage),
        'statusColor': AppColors.success,
        'price': '₪150',
        'address': '${AppStrings.getString('mainStreet', languageService.currentLanguage)}, ${AppStrings.getString('jerusalem', languageService.currentLanguage)}',
      },
      {
        'service': AppStrings.getString('elderlyCare', languageService.currentLanguage),
        'provider': 'Mariam Hassan',
        'date': AppStrings.getString('friday2PM', languageService.currentLanguage),
        'status': AppStrings.getString('pending', languageService.currentLanguage),
        'statusColor': AppColors.warning,
        'price': '₪200',
        'address': '${AppStrings.getString('oakAvenue', languageService.currentLanguage)}, ${AppStrings.getString('telAviv', languageService.currentLanguage)}',
      },
      {
        'service': AppStrings.getString('babysitting', languageService.currentLanguage),
        'provider': 'Aisha Mohammed',
        'date': AppStrings.getString('yesterday3PM', languageService.currentLanguage),
        'status': AppStrings.getString('completed', languageService.currentLanguage),
        'statusColor': AppColors.info,
        'price': '₪120',
        'address': '${AppStrings.getString('pineRoad', languageService.currentLanguage)}, ${AppStrings.getString('haifa', languageService.currentLanguage)}',
      },
    ];

    return Column(
      children: bookings.map((booking) {
        return Container(
          margin: EdgeInsets.only(bottom: isMobile ? 16.0 : 20.0),
          child: _buildDetailedBookingCard(booking, isMobile, isTablet, screenWidth),
        );
      }).toList(),
    );
  }

  Widget _buildDetailedBookingCard(Map<String, dynamic> booking, bool isMobile, bool isTablet, double screenWidth) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with service and status
          Row(
            children: [
              Expanded(
                child: Text(
                  booking['service'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 18.0 : 20.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8.0 : 12.0,
                  vertical: isMobile ? 4.0 : 6.0,
                ),
                decoration: BoxDecoration(
                  color: booking['statusColor'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
                ),
                child: Text(
                  booking['status'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: booking['statusColor'],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          // Booking details
          _buildBookingDetailRow(
            Icons.person,
            AppStrings.getString('provider', languageService.currentLanguage),
            booking['provider'],
            isMobile,
          ),
          const SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.calendar_today,
            AppStrings.getString('dateTime', languageService.currentLanguage),
            booking['date'],
            isMobile,
          ),
          const SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.location_on,
            AppStrings.getString('address', languageService.currentLanguage),
            booking['address'],
            isMobile,
          ),
          const SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.attach_money,
            AppStrings.getString('price', languageService.currentLanguage),
            booking['price'],
            isMobile,
          ),
          SizedBox(height: isMobile ? 16.0 : 20.0),
          
          // Action buttons
          _buildBookingActions(isMobile, isTablet, screenWidth),
        ],
      ),
    );
  }

  Widget _buildBookingDetailRow(IconData icon, String label, String value, bool isMobile) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: isMobile ? 16.0 : 18.0,
        ),
        const SizedBox(width: 8.0),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 14.0 : 16.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingActions(bool isMobile, bool isTablet, double screenWidth) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final actions = [
      {'icon': Icons.cancel, 'label': AppStrings.getString('cancel', languageService.currentLanguage), 'color': AppColors.error},
      {'icon': Icons.schedule, 'label': AppStrings.getString('reschedule', languageService.currentLanguage), 'color': AppColors.warning},
      {'icon': Icons.chat, 'label': AppStrings.getString('contact', languageService.currentLanguage), 'color': AppColors.primary},
      // Removed Tracking action per requirements
    ];

    return Wrap(
      spacing: isMobile ? 8.0 : 12.0,
      runSpacing: isMobile ? 8.0 : 12.0,
      children: actions.map((action) {
        return OutlinedButton.icon(
          onPressed: () {
            // Handle action
          },
          icon: Icon(
            action['icon'] as IconData,
            size: isMobile ? 16.0 : 18.0,
            color: action['color'] as Color,
          ),
          label: Text(
            action['label'] as String,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.w500,
              color: action['color'] as Color,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: action['color'] as Color, width: 1),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12.0 : 16.0,
              vertical: isMobile ? 8.0 : 10.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Chat Messages Section
  Widget _buildChatMessagesContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return Row(
          children: [
            // Chat List (hidden on mobile)
            if (!isMobile) ...[
              Container(
                width: isTablet ? 300.0 : 350.0,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    right: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: _buildChatList(isMobile, isTablet),
              ),
            ],
            
            // Chat Messages Area
            Expanded(
              child: _buildChatMessagesArea(isMobile, isTablet),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatList(bool isMobile, bool isTablet) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final chats = [
      {
        'name': 'Fatima Al-Zahra',
        'service': AppStrings.getString('homeCleaning', languageService.currentLanguage),
        'lastMessage': 'I will arrive in 10 minutes',
        'time': '2 ${AppStrings.getString('minutesAgo', languageService.currentLanguage)}',
        'unread': 2,
        'isOnline': true,
      },
      {
        'name': 'Mariam Hassan',
        'service': AppStrings.getString('elderlyCare', languageService.currentLanguage),
        'lastMessage': 'Thank you for the booking',
        'time': '1 ${AppStrings.getString('hoursAgo', languageService.currentLanguage)}',
        'unread': 0,
        'isOnline': false,
      },
      {
        'name': 'Aisha Mohammed',
        'service': AppStrings.getString('babysitting', languageService.currentLanguage),
        'lastMessage': 'The children are doing great',
        'time': '3 ${AppStrings.getString('hoursAgo', languageService.currentLanguage)}',
        'unread': 1,
        'isOnline': true,
      },
    ];

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(isTablet ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.chat,
                color: AppColors.primary,
                size: isTablet ? 24.0 : 28.0,
              ),
              const SizedBox(width: 12.0),
              Text(
                _getLocalizedString('messages'),
                style: GoogleFonts.cairo(
                  fontSize: isTablet ? 18.0 : 20.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        
        // Chat list
        Expanded(
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return _buildChatListItem(chat, isMobile, isTablet);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatListItem(Map<String, dynamic> chat, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12.0 : 16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: isTablet ? 48.0 : 56.0,
                height: isTablet ? 48.0 : 56.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isTablet ? 24.0 : 28.0),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: isTablet ? 24.0 : 28.0,
                ),
              ),
              if (chat['isOnline'])
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: isTablet ? 12.0 : 14.0,
                    height: isTablet ? 12.0 : 14.0,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(isTablet ? 6.0 : 7.0),
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12.0),
          
          // Chat info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat['name'],
                        style: GoogleFonts.cairo(
                          fontSize: isTablet ? 16.0 : 18.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      chat['time'],
                      style: GoogleFonts.cairo(
                        fontSize: isTablet ? 12.0 : 14.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  chat['service'],
                  style: GoogleFonts.cairo(
                    fontSize: isTablet ? 12.0 : 14.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat['lastMessage'],
                        style: GoogleFonts.cairo(
                          fontSize: isTablet ? 14.0 : 16.0,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (chat['unread'] > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          chat['unread'].toString(),
                          style: GoogleFonts.cairo(
                            fontSize: isTablet ? 10.0 : 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessagesArea(bool isMobile, bool isTablet) {
    return Column(
      children: [
        // Chat header
        Container(
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  onPressed: () {
                    // Show chat list on mobile
                  },
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 12.0),
              ],
              Container(
                width: isMobile ? 40.0 : 48.0,
                height: isMobile ? 40.0 : 48.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 20.0 : 24.0),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: isMobile ? 20.0 : 24.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fatima Al-Zahra',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16.0 : 18.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _getLocalizedString('homeCleaning'),
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 12.0 : 14.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.circle,
                color: AppColors.success,
                size: isMobile ? 12.0 : 14.0,
              ),
            ],
          ),
        ),
        
        // Messages area
        Expanded(
          child: Container(
            color: AppColors.background,
            child: _buildMessagesList(isMobile, isTablet),
          ),
        ),
        
        // Message input
        _buildMessageInput(isMobile, isTablet),
      ],
    );
  }

  Widget _buildMessagesList(bool isMobile, bool isTablet) {
    final messages = [
      {
        'text': 'Hello! I will arrive in 10 minutes',
        'isMe': false,
        'time': '10:30 AM',
      },
      {
        'text': 'Perfect, thank you!',
        'isMe': true,
        'time': '10:31 AM',
      },
      {
        'text': 'I\'m here now',
        'isMe': false,
        'time': '10:40 AM',
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message, isMobile, isTablet);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMobile, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message['isMe'] ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message['isMe']) ...[
            Container(
              width: isMobile ? 32.0 : 36.0,
              height: isMobile ? 32.0 : 36.0,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isMobile ? 16.0 : 18.0),
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
                size: isMobile ? 16.0 : 18.0,
              ),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
              decoration: BoxDecoration(
                color: message['isMe'] ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
                border: message['isMe'] ? null : Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['text'],
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14.0 : 16.0,
                      fontWeight: FontWeight.w400,
                      color: message['isMe'] ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    message['time'],
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 10.0 : 12.0,
                      fontWeight: FontWeight.w400,
                      color: message['isMe'] ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // Attach file
            },
            icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: _getLocalizedString('type_message'),
                hintStyle: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isMobile ? 20.0 : 24.0),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16.0 : 20.0,
                  vertical: isMobile ? 12.0 : 16.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            onPressed: () {
              // Send message
            },
            icon: const Icon(Icons.send, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // Payments Section
  Widget _buildPaymentsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Summary
              _buildPaymentSummary(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Payment Methods
              _buildPaymentMethods(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Payment History
              _buildPaymentHistory(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentSummary(bool isMobile, bool isTablet, double screenWidth) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final summaryCards = [
      {'title': AppStrings.getString('totalSpent', languageService.currentLanguage), 'amount': '₪2,450', 'icon': Icons.account_balance_wallet, 'color': AppColors.primary},
      {'title': AppStrings.getString('thisMonth', languageService.currentLanguage), 'amount': '₪580', 'icon': Icons.calendar_today, 'color': AppColors.success},
      {'title': AppStrings.getString('pending', languageService.currentLanguage), 'amount': '₪150', 'icon': Icons.pending, 'color': AppColors.warning},
    ];

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      children: summaryCards.map((card) {
        final cardWidth = isMobile 
            ? (screenWidth - 48) / 2 
            : (screenWidth - 96) / 3;
        
        return Container(
          width: cardWidth,
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                card['icon'] as IconData,
                color: card['color'] as Color,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                card['amount'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 24.0 : 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                card['title'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethods(bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getLocalizedString('paymentMethods'),
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add, size: isMobile ? 16.0 : 18.0),
              label: Text(
                _getLocalizedString('addNew'),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12.0 : 16.0,
                  vertical: isMobile ? 8.0 : 10.0,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        // Payment methods list
        _buildPaymentMethodCard(
          _getLocalizedString('visaEndingIn'),
          _getLocalizedString('defaultText'),
          Icons.credit_card,
          AppColors.primary,
          true,
          isMobile,
        ),
        const SizedBox(height: 12.0),
        _buildPaymentMethodCard(
          _getLocalizedString('paypal'),
          _getLocalizedString('connected'),
          Icons.payment,
          AppColors.info,
          false,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String title, String status, IconData icon, Color color, bool isDefault, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: isMobile ? 24.0 : 28.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  status,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getLocalizedString('defaultText'),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(bool isMobile, bool isTablet) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final payments = [
      {
        'service': AppStrings.getString('homeCleaning', languageService.currentLanguage),
        'provider': 'Fatima Al-Zahra',
        'amount': '₪150',
        'date': '${AppStrings.getString('today', languageService.currentLanguage)}, 10:00 AM',
        'status': AppStrings.getString('completed', languageService.currentLanguage),
        'statusColor': AppColors.success,
      },
      {
        'service': AppStrings.getString('elderlyCare', languageService.currentLanguage),
        'provider': 'Mariam Hassan',
        'amount': '₪200',
        'date': '${AppStrings.getString('yesterday', languageService.currentLanguage)}, 2:00 PM',
        'status': AppStrings.getString('pending', languageService.currentLanguage),
        'statusColor': AppColors.warning,
      },
      {
        'service': AppStrings.getString('babysitting', languageService.currentLanguage),
        'provider': 'Aisha Mohammed',
        'amount': '₪120',
        'date': '2 ${AppStrings.getString('daysAgo', languageService.currentLanguage)}',
        'status': AppStrings.getString('completed', languageService.currentLanguage),
        'statusColor': AppColors.success,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('paymentHistory'),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        ...payments.map((payment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: _buildPaymentHistoryCard(payment, isMobile, isTablet),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentHistoryCard(Map<String, dynamic> payment, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment['service'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  payment['provider'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  payment['date'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment['amount'],
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: payment['statusColor'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment['status'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: payment['statusColor'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // My Reviews Section
  Widget _buildMyReviewsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reviews Summary
              _buildReviewsSummary(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // My Reviews List
              _buildMyReviewsList(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewsSummary(bool isMobile, bool isTablet, double screenWidth) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final summaryCards = [
      {'title': AppStrings.getString('totalReviews', languageService.currentLanguage), 'count': '8', 'icon': Icons.rate_review, 'color': AppColors.primary},
      {'title': AppStrings.getString('averageRating', languageService.currentLanguage), 'count': '4.8', 'icon': Icons.star, 'color': AppColors.warning},
      {'title': AppStrings.getString('thisMonth', languageService.currentLanguage), 'count': '3', 'icon': Icons.calendar_today, 'color': AppColors.success},
    ];

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      children: summaryCards.map((card) {
        final cardWidth = isMobile 
            ? (screenWidth - 48) / 2 
            : (screenWidth - 96) / 3;
        
        return Container(
          width: cardWidth,
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                card['icon'] as IconData,
                color: card['color'] as Color,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                card['count'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 24.0 : 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                card['title'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMyReviewsList(bool isMobile, bool isTablet) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final reviews = [
      {
        'provider': 'Fatima Al-Zahra',
        'service': AppStrings.getString('homeCleaning', languageService.currentLanguage),
        'rating': 5.0,
        'comment': 'Excellent service! Very professional and thorough cleaning.',
        'date': '2 ${AppStrings.getString('daysAgo', languageService.currentLanguage)}',
        'canEdit': true,
      },
      {
        'provider': 'Mariam Hassan',
        'service': AppStrings.getString('elderlyCare', languageService.currentLanguage),
        'rating': 4.5,
        'comment': 'Very caring and attentive. Highly recommended.',
        'date': '1 ${AppStrings.getString('weekAgo', languageService.currentLanguage)}',
        'canEdit': false,
      },
      {
        'provider': 'Aisha Mohammed',
        'service': AppStrings.getString('babysitting', languageService.currentLanguage),
        'rating': 5.0,
        'comment': 'Great with kids! Very reliable and trustworthy.',
        'date': '2 ${AppStrings.getString('weeksAgo', languageService.currentLanguage)}',
        'canEdit': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('myReviews'),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        ...reviews.map((review) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: _buildReviewCard(review, isMobile, isTablet),
          );
        }),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['provider'],
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 16.0 : 18.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      review['service'],
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14.0 : 16.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (review['canEdit'])
                TextButton(
                  onPressed: () {},
                  child: Text(
                    _getLocalizedString('edit'),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 14.0 : 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          
          // Rating stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < review['rating'] ? Icons.star : Icons.star_border,
                color: AppColors.ratingFilled,
                size: isMobile ? 20.0 : 24.0,
              );
            }),
          ),
          const SizedBox(height: 8.0),
          
          Text(
            review['comment'],
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8.0),
          
          Text(
            review['date'],
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Profile Settings Section
  Widget _buildProfileSettingsContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Profile Form
              _buildProfileForm(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Addresses
              _buildAddressesSection(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Notifications
              _buildNotificationsSection(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(bool isMobile, bool isTablet) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser ?? const {};
    final first = (user['firstName'] ?? '').toString();
    final last = (user['lastName'] ?? '').toString();
    final fullName = [first, last].where((e) => e.isNotEmpty).join(' ').trim();
    final createdAt = (user['createdAt'] ?? user['created_at'] ?? '').toString();
    String joinedText = _getLocalizedString('membersSince');
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.tryParse(createdAt);
        if (dt != null) {
          final monthNames = {
            'en': [
              'January','February','March','April','May','June','July','August','September','October','November','December'
            ],
            'ar': [
              'يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'
            ],
          };
          final lang = Provider.of<LanguageService>(context, listen: false).currentLanguage;
          final month = monthNames[lang]?[dt.month - 1] ?? dt.month.toString();
          joinedText = '${_getLocalizedString('membersSince')} $month ${dt.year}';
        }
      } catch (_) {}
    }
    return Container(
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 80.0 : 100.0,
            height: isMobile ? 80.0 : 100.0,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(isMobile ? 40.0 : 50.0),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.white,
              size: isMobile ? 40.0 : 50.0,
            ),
          ),
          SizedBox(width: isMobile ? 16.0 : 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isNotEmpty ? fullName : _getLocalizedString('fullName'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24.0 : 28.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  joinedText,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          // Header edit button hidden until profile image feature is implemented
        ],
      ),
    );
  }

  Widget _buildProfileForm(bool isMobile, bool isTablet) {
    // Listen to AuthService so the card updates when profile changes (e.g., email)
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser ?? const {};
    final currentFullName = [
      (user['firstName'] ?? '').toString(),
      (user['lastName'] ?? '').toString(),
    ].where((e) => e.isNotEmpty).join(' ').trim();
    final currentEmail = (user['email'] ?? '').toString();
    final currentPhone = (user['phone'] ?? '').toString();
    final currentAge = user['age'];
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedString('personalInformation'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 16.0 : 20.0),
          
          _buildFormField(
            _getLocalizedString('fullName'),
            currentFullName,
            Icons.person,
            isMobile,
            onEdit: _onEditName,
          ),
          const SizedBox(height: 12.0),
          _buildFormField(
            _getLocalizedString('email'),
            currentEmail,
            Icons.email,
            isMobile,
            onEdit: _onEditEmail,
          ),
          const SizedBox(height: 12.0),
          _buildFormField(
            _getLocalizedString('phoneNumber'),
            currentPhone,
            Icons.phone,
            isMobile,
            onEdit: _onEditPhone,
          ),
          const SizedBox(height: 12.0),
          _buildFormField(
            _getLocalizedString('age'),
            (currentAge is int && currentAge > 0) ? currentAge.toString() : '-',
            Icons.cake,
            isMobile,
            onEdit: _onEditAge,
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String value, IconData icon, bool isMobile, {VoidCallback? onEdit}) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: isMobile ? 20.0 : 24.0,
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 16.0 : 18.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: Icon(
            Icons.edit,
            color: AppColors.primary,
            size: isMobile ? 20.0 : 24.0,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressesSection(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getLocalizedString('savedAddresses'),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _onAddOrEditAddress,
                icon: Icon(Icons.add, size: isMobile ? 16.0 : 18.0),
                label: Text(
                  _getLocalizedString('addNewAddress'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 8.0 : 10.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          ..._buildAddressCards(isMobile),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
    String label,
    String address,
    bool isDefault,
    bool isMobile, {
    VoidCallback? onMakeDefault,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
        border: Border.all(
          color: isDefault ? AppColors.primary : AppColors.border,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 16.0 : 18.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (onEdit != null)
                      TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit, size: 18), label: const Text('Edit')),
                    if (onEdit != null) const SizedBox(width: 8),
                    if (onDelete != null)
                      TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('Delete')),
                    const Spacer(),
                    if (!isDefault && onMakeDefault != null)
                      TextButton(onPressed: onMakeDefault, child: const Text('Make Default')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(bool isMobile, bool isTablet) {
    // Local stateful toggles; backend integration TBD
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedString('notificationPreferences'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          _buildNotificationToggle(_getLocalizedString('emailNotifications'), _emailNotifs, isMobile, (v) => setState(() { _emailNotifs = v; })),
          const SizedBox(height: 8.0),
          _buildNotificationToggle(_getLocalizedString('pushNotifications'), _pushNotifs, isMobile, (v) => setState(() { _pushNotifs = v; })),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(String label, bool isEnabled, bool isMobile, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 16.0 : 18.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Switch(
          value: isEnabled,
          onChanged: (value) {
            onChanged(value);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${_getLocalizedString('saveChanges')} · $label: ${value ? 'ON' : 'OFF'}')),
            );
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  // Local notification prefs state
  bool _emailNotifs = true;
  bool _pushNotifs = true;

  // Helpers: edit actions
  Future<void> _onEditName() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firstName = TextEditingController(text: (auth.currentUser?['firstName'] ?? '').toString());
    final lastName = TextEditingController(text: (auth.currentUser?['lastName'] ?? '').toString());
    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_getLocalizedString('fullName')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: firstName, decoration: const InputDecoration(labelText: 'First name')),
            TextField(controller: lastName, decoration: const InputDecoration(labelText: 'Last name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_getLocalizedString('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_getLocalizedString('saveChanges'))),
        ],
      ),
    );
    if (okPressed == true) {
      try {
        await auth.updateProfile(firstName: firstName.text.trim(), lastName: lastName.text.trim());
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
        }
      } catch (_) {}
    }
  }

  Future<void> _onEditEmail() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final email = TextEditingController(text: (auth.currentUser?['email'] ?? '').toString());
    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_getLocalizedString('email')),
        content: TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ), 
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_getLocalizedString('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_getLocalizedString('saveChanges'))),
        ],
      ),
    );
    if (okPressed == true) {
      try {
        final next = email.text.trim();
        final valid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(next);
        if (!valid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email address')));
          }
          return;
        }
        await auth.updateProfile(email: next);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email updated. Check your inbox to verify.')));
          // Prompt to send verification link immediately
          final proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(_getLocalizedString('profileSettings')),
              content: Text(_getLocalizedString('pleaseVerifyAccount')),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_getLocalizedString('cancel'))),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_getLocalizedString('verify'))),
              ],
            ),
          );
          if (proceed == true) {
            try {
              await Provider.of<AuthService>(context, listen: false).requestVerification();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email sent. Please use the link in your inbox.')));
              }
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _restoreSelectedTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getInt(_tabStorageKey);
      if (idx != null && mounted) {
        setState(() => _selectedIndex = idx);
      }
    } catch (_) {}
  }

  Future<void> _persistSelectedTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_tabStorageKey, _selectedIndex);
    } catch (_) {}
  }

  Future<void> _onEditPhone() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final phone = TextEditingController(text: (auth.currentUser?['phone'] ?? '').toString());
    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_getLocalizedString('phoneNumber')),
        content: TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')), 
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_getLocalizedString('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_getLocalizedString('saveChanges'))),
        ],
      ),
    );
    if (okPressed == true) {
      try {
        await auth.updateProfile(phone: phone.text.trim());
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone updated')));
        }
      } catch (e) {
        final msg = e.toString();
        final friendly = msg.contains('Phone number already registered')
            ? 'Phone number already registered'
            : 'Failed to update phone';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
        }
      }
    }
  }

  Future<void> _onEditAge() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final ageCtl = TextEditingController(text: (auth.currentUser?['age']?.toString() ?? ''));
    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_getLocalizedString('age')),
        content: TextField(controller: ageCtl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')), 
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_getLocalizedString('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(_getLocalizedString('saveChanges'))),
        ],
      ),
    );
    if (okPressed == true) {
      final parsed = int.tryParse(ageCtl.text.trim());
      if (parsed != null) {
        try {
          await auth.updateProfile(age: parsed);
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Age updated')));
          }
        } catch (_) {}
      }
    }
  }

  // Available cities with their real streets - Palestinian cities
  final Map<String, List<String>> _cityStreets = {
    'jerusalem': [
      'salahuddin_street', 'damascus_gate_road', 'jaffa_road', 'king_george_street', 
      'ben_yehuda_street', 'agron_street', 'mamilla_street', 'yafo_street',
      'sultan_suleiman_street', 'nablus_road', 'ramallah_road', 'bethlehem_road'
    ],
    'ramallah': [
      'al_manara_square', 'rukab_street', 'main_street', 'al_balad', 'al_masyoun',
      'al_irsal_street', 'hospital_street', 'al_nahda_street', 'radio_street',
      'al_masayef_road', 'al_bireh_ramallah_road'
    ],
    'nablus': [
      'rafidia_street', 'al_najah_street', 'faisal_street', 'al_quds_street',
      'al_maidan_street', 'al_anbat_street', 'martyrs_street', 'al_nasr_street',
      'university_street', 'old_city_street'
    ],
    'hebron': [
      'al_shuhada_street', 'king_talal_street', 'al_salam_street', 'al_haramain_street',
      'al_manshiyya_street', 'polytechnic_university_road', 'al_thahiriyya_road',
      'al_fawwar_road', 'halhul_road', 'dura_road'
    ],
    'bethlehem': [
      'manger_street', 'pope_paul_vi_street', 'star_street', 'milk_grotto_street',
      'nativity_square', 'hebron_road', 'jerusalem_road', 'beit_sahour_road',
      'solomon_pools_street', 'rachel_tomb_road'
    ],
    'gaza': [
      'omar_mukhtar_street', 'al_rasheed_street', 'al_wahda_street', 'al_azhar_street',
      'al_nasr_street', 'beach_road', 'salah_al_din_street', 'al_thalateen_street',
      'industrial_road', 'al_shati_camp_road'
    ],
    'jenin': [
      'al_maidan_street', 'al_quds_street', 'hospital_street', 'al_salam_street',
      'freedom_fighters_street', 'al_yarmouk_street', 'arab_american_university_road',
      'al_jalama_road', 'ya_bad_road', 'tubas_road'
    ],
    'tulkarm': [
      'al_alimi_street', 'nablus_street', 'al_quds_street', 'al_shuhada_street',
      'al_sikka_street', 'industrial_street', 'khadouri_university_road',
      'qalqilya_road', 'jenin_road', 'netanya_road'
    ],
    'qalqilya': [
      'al_quds_street', 'al_andalus_street', 'al_nasr_street', 'al_wahda_street',
      'al_istiqlal_street', 'nablus_road', 'tulkarm_road', 'al_taybeh_road',
      'azzoun_road', 'jaljulia_road'
    ],
    'salfit': [
      'al_quds_street', 'al_nahda_street', 'al_salam_street', 'hospital_street',
      'al_bireh_road', 'ramallah_road', 'nablus_road', 'ariel_road',
      'deir_istiya_road', 'bruqin_road'
    ],
    'tubas': [
      'al_quds_street', 'al_yarmouk_street', 'al_wahda_street', 'hospital_street',
      'al_far_aa_road', 'jenin_road', 'nablus_road', 'tammun_road',
      'aqaba_road', 'al_malih_road'
    ],
    'jericho': [
      'al_quds_street', 'al_sultan_street', 'al_andalus_street', 'hospital_street',
      'dead_sea_road', 'jerusalem_road', 'ramallah_road', 'al_auja_road',
      'allenby_bridge_road', 'aqabat_jaber_road'
    ],
    'rafah': [
      'al_rasheed_street', 'al_salah_street', 'al_nasr_street', 'al_wahda_street',
      'al_quds_street', 'beach_road', 'al_shati_road', 'al_thalateen_road'
    ],
    'khan yunis': [
      'al_quds_street', 'al_nasr_street', 'al_wahda_street', 'al_salam_street',
      'hospital_street', 'beach_road', 'al_shati_road', 'al_thalateen_road'
    ],
    'deir al-balah': [
      'al_quds_street', 'al_nasr_street', 'al_wahda_street', 'al_salam_street',
      'hospital_street', 'beach_road', 'al_shati_road', 'al_thalateen_road'
    ],
    'north gaza': [
      'al_quds_street', 'al_nasr_street', 'al_wahda_street', 'al_salam_street',
      'hospital_street', 'beach_road', 'al_shati_road', 'al_thalateen_road'
    ],
  };

  // Get streets for selected city
  List<String> _getStreetsForCity(String? city) {
    if (city == null) return [];
    return _cityStreets[city] ?? [];
  }

  Future<void> _onAddOrEditAddress({int? editIndex}) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final List<dynamic> existing = (auth.currentUser?['addresses'] as List<dynamic>?) ?? [];
    // Pre-fill fields if editing
    Map<String, dynamic>? current = (editIndex != null && editIndex >= 0 && editIndex < existing.length)
        ? Map<String, dynamic>.from(existing[editIndex] as Map)
        : null;
    String type = (current?['type'] ?? 'home').toString();
    // Cities whitelist aligned with backend
    final cities = const [
      'jerusalem','ramallah','nablus','hebron','bethlehem','jericho','tulkarm','qalqilya','jenin','salfit','tubas',
      'gaza','rafah','khan yunis','deir al-balah','north gaza'
    ];
    String? city = (current?['city'] as String?);
    String? selectedStreet = (current?['street'] as String?);
    final area = TextEditingController(text: (current?['area'] ?? '').toString());
    bool makeDefault = current?['isDefault'] == true || existing.isEmpty; // first one becomes default
    
    // Validate that the existing street is valid for the current city
    if (city != null && selectedStreet != null) {
      final availableStreets = _getStreetsForCity(city);
      if (!availableStreets.contains(selectedStreet)) {
        selectedStreet = null; // Reset if street is not valid for current city
      }
    }

    final okPressed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final languageService = Provider.of<LanguageService>(context, listen: false);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(editIndex == null ? _getLocalizedString('addNewAddress') : _getLocalizedString('edit')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Address type dropdown
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(value: 'home', child: Text('Home')),
                        DropdownMenuItem(value: 'work', child: Text('Work')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) { 
                        setState(() {
                          type = v ?? 'home'; 
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // City dropdown with localized labels
                    DropdownButtonFormField<String>(
                      value: city,
                      decoration: const InputDecoration(labelText: 'City'),
                      items: [
                        for (final c in cities)
                          DropdownMenuItem(
                            value: c,
                            child: Text(AppStrings.getString(c, languageService.currentLanguage)),
                          )
                      ],
                      onChanged: (v) { 
                        setState(() {
                          city = v;
                          selectedStreet = null; // Reset street when city changes
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Street dropdown (only show if city is selected)
                    if (city != null) ...[
                                             DropdownButtonFormField<String>(
                         value: selectedStreet,
                         decoration: const InputDecoration(
                           labelText: 'Street *',
                           helperText: 'Please select a street',
                         ),
                         items: _getStreetsForCity(city).map((street) {
                           return DropdownMenuItem(
                             value: street,
                             child: Text(AppStrings.getString(street, languageService.currentLanguage)),
                           );
                         }).toList(),
                         onChanged: (v) { 
                           setState(() {
                             selectedStreet = v; 
                           });
                         },
                         validator: (value) {
                           if (value == null || value.isEmpty) {
                             return 'Street is required';
                           }
                           return null;
                         },
                       ),
                      const SizedBox(height: 16),
                    ],
                    // Area field (optional)
                    TextField(
                      controller: area, 
                      decoration: const InputDecoration(
                        labelText: 'Area (Optional)',
                        hintText: 'Enter area or neighborhood if needed',
                      )
                    ),
                    if (existing.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: makeDefault,
                        onChanged: (v) { 
                          setState(() {
                            makeDefault = v ?? false; 
                          });
                        },
                        title: Text(_getLocalizedString('defaultText')),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false), 
                  child: Text(_getLocalizedString('cancel'))
                ),
                TextButton(
                  onPressed: (city != null && selectedStreet != null) 
                    ? () => Navigator.of(ctx).pop(true) 
                    : null, // Disable if validation fails
                  child: Text(_getLocalizedString('saveChanges'))
                ),
              ],
            );
          },
        );
      },
    );
    if (okPressed == true) {
      // Build updated addresses list
      final updated = [...existing.map((e) => Map<String, dynamic>.from(e as Map))];
      final payload = {
        'type': type,
        'street': selectedStreet ?? '',
        'city': (city ?? '').trim(),
        'area': area.text.trim(),
        'isDefault': makeDefault,
      };
      if (editIndex != null && editIndex >= 0 && editIndex < updated.length) {
        updated[editIndex] = {
          ...updated[editIndex],
          ...payload,
        };
      } else {
        updated.add(payload);
      }
      // Ensure only one default
      bool foundDefault = false;
      for (final m in updated) {
        if ((m['isDefault'] ?? false) && !foundDefault) {
          foundDefault = true;
        } else {
          m['isDefault'] = false;
        }
      }
      if (!foundDefault && updated.isNotEmpty) updated[0]['isDefault'] = true;
      try {
        await auth.updateProfile(addresses: updated.cast<Map<String, dynamic>>());
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(editIndex == null ? 'Address added' : 'Address updated')));
        }
      } catch (_) {}
    }
  }

  List<Widget> _buildAddressCards(bool isMobile) {
    // Listen to AuthService to update addresses when profile changes
    final auth = Provider.of<AuthService>(context);
    final List<dynamic> list = (auth.currentUser?['addresses'] as List<dynamic>?) ?? [];
    if (list.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Text(
            'No address saved',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        )
      ];
    }
    final languageService = Provider.of<LanguageService>(context, listen: false);
    // Compute totals per type for numbering
    final totals = <String, int>{};
    for (final e in list) {
      final t = ((e as Map)['type'] ?? 'home').toString();
      totals[t] = (totals[t] ?? 0) + 1;
    }
    // Running counters for numbering duplicates
    final counters = <String, int>{};
    final widgets = <Widget>[];
    for (int i = 0; i < list.length; i++) {
      final m = Map<String, dynamic>.from(list[i] as Map);
      final type = (m['type'] ?? 'home').toString();
      final baseLabel = _localizedTypeLabel(type, languageService.currentLanguage);
      final countForType = totals[type] ?? 0;
      final nextIndex = (counters[type] ?? 0) + 1;
      counters[type] = nextIndex;
      final numberedLabel = countForType > 1 ? '$baseLabel $nextIndex' : baseLabel;
      final line = [m['street'], m['city'], m['area']]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: isMobile ? 8.0 : 12.0),
        child: _buildAddressCard(
          numberedLabel,
          line.isEmpty ? '-' : line,
          m['isDefault'] == true,
          isMobile,
          onMakeDefault: () => _setDefaultAddress(i),
          onEdit: () => _onAddOrEditAddress(editIndex: i),
          onDelete: () => _deleteAddress(i),
        ),
      ));
    }
    return widgets;
  }

  String _localizedTypeLabel(String type, String lang) {
    switch (type) {
      case 'work':
  return AppStrings.getString('work', lang);
      case 'other':
  return AppStrings.getString('other', lang);
      case 'home':
      default:
  return AppStrings.getString('home', lang);
    }
  }

  Future<void> _setDefaultAddress(int index) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final List<dynamic> existing = (auth.currentUser?['addresses'] as List<dynamic>?) ?? [];
    if (index < 0 || index >= existing.length) return;
    final updated = [
      for (int i = 0; i < existing.length; i++)
        {
          ...Map<String, dynamic>.from(existing[i] as Map),
          'isDefault': i == index,
        }
    ];
    try {
      await auth.updateProfile(addresses: updated.cast<Map<String, dynamic>>());
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default address updated')));
      }
    } catch (_) {}
  }

  Future<void> _deleteAddress(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(_getLocalizedString('cancel'))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    final auth = Provider.of<AuthService>(context, listen: false);
    final List<dynamic> existing = (auth.currentUser?['addresses'] as List<dynamic>?) ?? [];
    if (index < 0 || index >= existing.length) return;
    final updated = [
      for (int i = 0; i < existing.length; i++)
        if (i != index) Map<String, dynamic>.from(existing[i] as Map)
    ];
    // Ensure one default remains if list not empty
    bool hasDefault = updated.any((e) => (e['isDefault'] ?? false) == true);
    if (updated.isNotEmpty && !hasDefault) {
      updated[0]['isDefault'] = true;
    }
    try {
      await auth.updateProfile(addresses: updated.cast<Map<String, dynamic>>());
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address deleted')));
      }
    } catch (_) {}
  }

  // Saved Providers Section
  Widget _buildSavedProvidersContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Providers Summary
              _buildProvidersSummary(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Saved Providers List
              _buildSavedProvidersList(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProvidersSummary(bool isMobile, bool isTablet, double screenWidth) {
    final summaryCards = [
      {'title': _getLocalizedString('totalProviders'), 'count': '5', 'icon': Icons.favorite, 'color': AppColors.error},
      {'title': _getLocalizedString('available'), 'count': '3', 'icon': Icons.check_circle, 'color': AppColors.success},
      // Removed 'Recently Booked' card per requirements
    ];

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      children: summaryCards.map((card) {
        final cardWidth = isMobile 
            ? (screenWidth - 48) / 2 
            : (screenWidth - 96) / 3;
        
        return Container(
          width: cardWidth,
          padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                card['icon'] as IconData,
                color: card['color'] as Color,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                card['count'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 24.0 : 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                card['title'] as String,
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSavedProvidersList(bool isMobile, bool isTablet) {
  final providers = [
      {
        'name': 'Fatima Al-Zahra',
        'service': _getLocalizedString('homeCleaning'),
        'rating': 4.8,
        'price': '₪150',
        'isAvailable': true,
      },
      {
        'name': 'Mariam Hassan',
        'service': _getLocalizedString('elderlyCare'),
        'rating': 4.9,
        'price': '₪200',
        'isAvailable': true,
      },
      {
        'name': 'Aisha Mohammed',
        'service': _getLocalizedString('babysitting'),
        'rating': 4.7,
        'price': '₪120',
        'isAvailable': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('savedProviders'),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        ...providers.map((provider) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: _buildSavedProviderCard(provider, isMobile, isTablet),
          );
        }),
      ],
    );
  }

  Widget _buildSavedProviderCard(Map<String, dynamic> provider, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 60.0 : 70.0,
            height: isMobile ? 60.0 : 70.0,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isMobile ? 30.0 : 35.0),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: isMobile ? 30.0 : 35.0,
            ),
          ),
          SizedBox(width: isMobile ? 12.0 : 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider['name'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  provider['service'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: AppColors.ratingFilled,
                      size: isMobile ? 16.0 : 18.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      provider['rating'].toString(),
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14.0 : 16.0,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: provider['isAvailable'] ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        provider['isAvailable'] ? _getLocalizedString('available') : _getLocalizedString('unavailable'),
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 12.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: provider['isAvailable'] ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                // Removed Recent Bookings info per requirements
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                provider['price'],
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18.0 : 20.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: provider['isAvailable'] ? () {
                  // Handle book again
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12.0 : 16.0,
                    vertical: isMobile ? 8.0 : 10.0,
                  ),
                ),
                child: Text(
                  _getLocalizedString('bookNow'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Support Help Section
  Widget _buildSupportHelpContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Support Header
              _buildSupportHeader(isMobile, isTablet),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Quick Help
              _buildQuickHelp(isMobile, isTablet, constraints.maxWidth),
              SizedBox(height: isMobile ? 20.0 : 32.0),
              
              // Recent Tickets
              _buildRecentTickets(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportHeader(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16.0 : 20.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.support_agent,
            color: AppColors.white,
            size: isMobile ? 48.0 : 64.0,
          ),
          SizedBox(width: isMobile ? 16.0 : 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedString('needHelp'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 24.0 : 28.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _getLocalizedString('weAreHereToHelp'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelp(bool isMobile, bool isTablet, double screenWidth) {
    final helpItems = [
      {'title': _getLocalizedString('faq'), 'icon': Icons.help_outline, 'color': AppColors.primary},
      {'title': _getLocalizedString('viewPreviousRequests'), 'icon': Icons.chat, 'color': AppColors.success},
      {'title': _getLocalizedString('reportIssue'), 'icon': Icons.support_agent, 'color': AppColors.warning},
      {'title': _getLocalizedString('contactSupport'), 'icon': Icons.phone, 'color': AppColors.info},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('quickHelp'),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        Wrap(
          spacing: isMobile ? 12.0 : 16.0,
          runSpacing: isMobile ? 12.0 : 16.0,
          children: helpItems.map((item) {
            final cardWidth = isMobile 
                ? (screenWidth - 48) / 2 
                : (screenWidth - 96) / 4;
            
            return Container(
              width: cardWidth,
              padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: isMobile ? 32.0 : 40.0,
                  ),
                  SizedBox(height: isMobile ? 8.0 : 12.0),
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 16.0 : 18.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  

  

  Widget _buildRecentTickets(bool isMobile, bool isTablet) {
    final tickets = [
      {
        'title': _getLocalizedString('paymentIssueResolved'),
        'status': _getLocalizedString('resolved'),
        'date': _getLocalizedString('twoDaysAgo'),
        'statusColor': AppColors.success,
      },
      {
        'title': _getLocalizedString('bookingCancellations'),
        'status': _getLocalizedString('inProgress'),
        'date': _getLocalizedString('oneWeekAgo'),
        'statusColor': AppColors.warning,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedString('recentTickets'),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: isMobile ? 12.0 : 16.0),
        
        ...tickets.map((ticket) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: _buildTicketCard(ticket, isMobile, isTablet),
          );
        }),
      ],
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['title'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  ticket['date'],
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ticket['statusColor'].withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ticket['status'],
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : 14.0,
                fontWeight: FontWeight.w600,
                color: ticket['statusColor'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Security Section
  Widget _buildSecurityContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Options
              _buildSecurityOptions(isMobile, isTablet),
            ],
          ),
        );
      },
    );
  }

  

  

  Widget _buildSecurityOptions(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getLocalizedString('security'),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 18.0 : 20.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          _buildSecurityOption(
            _getLocalizedString('changePassword'),
            _getLocalizedString('updatePassword'),
            Icons.lock,
            isMobile,
          ),
          const SizedBox(height: 12.0),
          _buildSecurityOption(
            _getLocalizedString('twoFactorAuth'),
            _getLocalizedString('addExtraSecurity'),
            Icons.verified_user,
            isMobile,
          ),
          const SizedBox(height: 12.0),
          _buildSecurityOption(
            _getLocalizedString('loginAlerts'),
            _getLocalizedString('getLoginNotifications'),
            Icons.notifications,
            isMobile,
          ),
          const SizedBox(height: 12.0),
          _buildSecurityOption(
            _getLocalizedString('trustedDevices'),
            _getLocalizedString('manageTrustedDevices'),
            Icons.devices,
            isMobile,
          ),
          const SizedBox(height: 12.0),
          GestureDetector(
            onTap: () => _showDeleteAccountDialog(context),
            child: _buildSecurityOption(
              _getLocalizedString('deleteAccount'),
              _getLocalizedString('permanentlyDeleteAccount'),
              Icons.delete_forever,
              isMobile,
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption(String title, String subtitle, IconData icon, bool isMobile, {bool isDestructive = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
            size: isMobile ? 24.0 : 28.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 14.0 : 16.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textSecondary,
            size: isMobile ? 16.0 : 18.0,
          ),
        ],
      ),
    );
  }

  

  

  



  Widget _buildMobileDrawer() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final menuItems = _getMenuItems();
        
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
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      return _buildDrawerMenuItem(item);
                    },
                  ),
                ),
                
                // Language toggle in drawer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: const Icon(
                      Icons.language,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    title: Text(
                      languageService.isEnglish ? 'العربية' : 'English',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      languageService.toggleLanguage();
                      Navigator.pop(context);
                    },
                  ),
                ),
                
                // Drawer footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ListTile(
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
                    onTap: () {
                      // Handle logout
                      Navigator.pop(context); // Close drawer
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: () {
        if (mounted) {
          setState(() {
            _selectedIndex = item.index;
          });
          _persistSelectedTab();
        }
        Navigator.pop(context); // Close drawer
      },
    );
  }

  // Show delete account confirmation dialog
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _getLocalizedString('deleteAccount'),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: AppColors.error,
            ),
          ),
          content: Text(
            _getLocalizedString('deleteAccountWarning') ?? 'Are you sure you want to delete your account? This action cannot be undone.',
            style: GoogleFonts.cairo(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                _getLocalizedString('cancel') ?? 'Cancel',
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              child: Text(
                _getLocalizedString('delete') ?? 'Delete',
                style: GoogleFonts.cairo(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Delete account
  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.deleteAccount();
      
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _getLocalizedString('accountDeleted') ?? 'Account deleted successfully',
                style: GoogleFonts.cairo(color: AppColors.white),
              ),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Navigate to home screen and clear all routes
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? _getLocalizedString('deleteAccountFailed') ?? 'Failed to delete account',
                style: GoogleFonts.cairo(color: AppColors.white),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getLocalizedString('deleteAccountFailed') ?? 'Failed to delete account: ${e.toString()}',
              style: GoogleFonts.cairo(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
} 