// ignore_for_file: dead_code
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/booking_service.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/favorites_service.dart';
import '../../../../shared/services/location_service.dart';
import '../../../../shared/services/map_service.dart';

// Widget imports
import '../../../admin/presentation/widgets/language_toggle_widget.dart';
import '../../../../shared/widgets/provider_rating_dialog.dart';
import '../../../../shared/widgets/provider_reviews_dialog.dart';

// Feature imports
import '../widgets/chat_messages_widget.dart';
import '../widgets/mobile_chat_messages_widget.dart';
import 'saved_providers_widget.dart';

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
  // Bookings state (client dashboard)
  int _selectedFilter = 0; // 0=All, 1=Pending, 2=Upcoming, 3=Completed, 4=Cancelled
  List<BookingModel> _myBookings = const [];
  bool _loadingBookings = false;
  final Set<String> _dismissedBookingIds = <String>{};

  // GPS and address state for profile settings
  bool _useGps = false;
  final TextEditingController _addressCtrl = TextEditingController();
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();

  // Map selected filter index to server status parameter
  String? _statusFromFilter(int index) {
    switch (index) {
      case 1:
        return 'pending';
      case 2:
        return 'confirmed';
      case 3:
        return 'completed';
      case 4:
        return 'cancelled';
      default:
        return null; // All
    }
  }

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
      case 'address':
        return ar ? 'العنوان' : 'Address';
      case 'enterAddress':
        return ar ? 'أدخل العنوان' : 'Enter Address';
      case 'currentLocation':
        return ar ? 'الموقع الحالي' : 'Current Location';
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
  // Preload bookings when opening My Bookings by default
  _loadDismissedBookings().then((_) => _maybeLoadBookings(initial: true));
  
  // Initialize GPS state based on user role
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _initializeGpsState();
    }
  });
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _contentAnimationController.dispose();
    _addressCtrl.dispose();
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
                    // Ensure bookings are loaded when navigating to My Bookings
                    if (index == 0) {
                      _maybeLoadBookings();
                    }
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
            // Main Menu (Home) button – preserves session
            IconButton(
              onPressed: () {
                // Navigate to main menu without clearing session or routes
                Navigator.of(context).pushNamed('/home');
              },
              icon: Icon(
                Icons.home_outlined,
                color: AppColors.textSecondary,
                size: isTablet ? 22.0 : 24.0,
              ),
              tooltip: AppStrings.getString('home', languageService.currentLanguage),
            ),
            SizedBox(width: isTablet ? 12.0 : 16.0),
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
        // Only show bottom navigation for main sections (0-3)
        // For other sections (4-7), hide the bottom navigation
        if (_selectedIndex > 3) {
          return const SizedBox.shrink();
        }
        
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex.clamp(0, 3),
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
                  IconButton(
                    tooltip: _getLocalizedString('refresh'),
                    onPressed: _refreshBookings,
                    icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  ),
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
      AppStrings.getString('pending', languageService.currentLanguage),
      AppStrings.getString('confirmed', languageService.currentLanguage),
      AppStrings.getString('completed', languageService.currentLanguage),
      AppStrings.getString('cancelled', languageService.currentLanguage),
    ];
  final selectedFilter = _selectedFilter;
    
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
            setState(() => _selectedFilter = index);
            _refreshBookings();
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
    if (_loadingBookings) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = _filteredBookingsForCurrentTab();
    // Show filtered count badge similar to provider list
    final header = Row(
      children: [
        Expanded(child: const SizedBox()),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${filtered.length}',
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 12.0 : 13.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
    
    if (filtered.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          Center(
            child: Text(
              AppStrings.getString('noBookingsFound', languageService.currentLanguage),
              style: GoogleFonts.cairo(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }
    // Group bookings by provider+date+service for same-day non-consecutive slots
    final groups = _groupBookings(filtered);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        SizedBox(height: isMobile ? 12.0 : 16.0),
        ...groups.map((g) {
          if (g.length == 1) {
            final vm = _vmFromBooking(g.first);
            return Container(
              margin: EdgeInsets.only(bottom: isMobile ? 16.0 : 20.0),
              child: _buildDetailedBookingCard(vm, isMobile, isTablet, screenWidth),
            );
          }
          return Container(
            margin: EdgeInsets.only(bottom: isMobile ? 16.0 : 20.0),
            child: _buildGroupedBookingCard(g, isMobile, isTablet, screenWidth),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _maybeLoadBookings({bool initial = false}) async {
    // Only auto-load on My Bookings tab
    if (initial && _selectedIndex != 0) return;
    await _refreshBookings();
  }

  Future<void> _refreshBookings() async {
    setState(() => _loadingBookings = true);
    try {
      final svc = BookingService();
      final status = _statusFromFilter(_selectedFilter);
      var list = await svc.getMyBookings(status: status, page: 1, limit: 50);
      // Filter out invalid/stale entries missing provider info and any user-dismissed bookings
      list = list.where((b) {
        final provOk = ((b.providerId ?? '').trim().isNotEmpty) || ((b.providerName ?? '').trim().isNotEmpty);
        return provOk && !_dismissedBookingIds.contains(b.id);
      }).toList();
      _myBookings = list;
    } catch (_) {
      _myBookings = const [];
    } finally {
      if (mounted) setState(() => _loadingBookings = false);
    }
  }

  Future<void> _loadDismissedBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('dismissed_bookings') ?? const <String>[];
      _dismissedBookingIds
        ..clear()
        ..addAll(list);
    } catch (_) {}
  }

  Future<void> _saveDismissedBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dismissed_bookings', _dismissedBookingIds.toList());
    } catch (_) {}
  }

  void _dismissGroup(List<BookingModel> group) {
    setState(() {
      _dismissedBookingIds.addAll(group.map((b) => b.id));
      _myBookings = _myBookings.where((b) => !_dismissedBookingIds.contains(b.id)).toList();
    });
    _saveDismissedBookings();
  }

  void _dismissSingle(String bookingId) {
    setState(() {
      _dismissedBookingIds.add(bookingId);
      _myBookings = _myBookings.where((b) => b.id != bookingId).toList();
    });
    _saveDismissedBookings();
  }

  List<BookingModel> _filteredBookingsForCurrentTab() {
    if (_selectedFilter == 3) {
      return _myBookings.where((b) => b.status.toLowerCase() == 'completed').toList();
    }
    if (_selectedFilter == 4) {
      return _myBookings.where((b) => b.status.toLowerCase() == 'cancelled').toList();
    }
    if (_selectedFilter == 2) {
      return _myBookings.where((b) => b.status.toLowerCase() == 'confirmed').toList();
    }
    if (_selectedFilter == 1) {
      return _myBookings.where((b) => b.status.toLowerCase() == 'pending').toList();
    }
  // Default 'All' excludes cancelled to match UX: cancelled disappear by default
  return _myBookings.where((b) => b.status.toLowerCase() != 'cancelled').toList();
  }

  Map<String, dynamic> _vmFromBooking(BookingModel b) {
    final statusInfo = BookingService.getStatusInfo(b.status);
    final displayDate = BookingService.formatBookingTime(b.schedule);
    final hasPendingCancel = b.cancellationRequests.any((r) => r.status.toLowerCase() == 'pending');
    return {
      'id': b.id,
      'service': b.serviceDetails.title,
      'provider': b.providerName ?? '',
      'providerId': b.providerId,
      'date': displayDate,
      'status': statusInfo['label'],
      'statusRaw': b.status,
      'statusColor': statusInfo['color'],
      'price': '₪${b.pricing.totalAmount.toStringAsFixed(0)}',
      'address': b.location.address,
      'instructions': b.location.instructions ?? '',
      'notes': b.notes ?? '',
      'hasPendingCancel': hasPendingCancel,
      'providerOverallRating': b.providerOverallRating,
      'providerRating': b.providerRating,
    };
  }

  // Group by providerId (relationship view across dates/services)
  List<List<BookingModel>> _groupBookings(List<BookingModel> items) {
    final Map<String, List<BookingModel>> map = {};
    for (final b in items) {
      final provId = (b.providerId ?? '').trim();
      final provName = (b.providerName ?? '').trim();
      final key = provId.isNotEmpty
          ? 'prov:$provId'
          : (provName.isNotEmpty ? 'provName:$provName' : 'booking:${b.id}');
      (map[key] ??= <BookingModel>[]).add(b);
    }
    final groups = map.values.toList();
    // Newest first by latest created in group
    groups.sort((a,b){
      final da = a.map((x)=>x.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).fold<DateTime>(DateTime.fromMillisecondsSinceEpoch(0),(p,n)=> n.isAfter(p)?n:p);
      final db = b.map((x)=>x.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).fold<DateTime>(DateTime.fromMillisecondsSinceEpoch(0),(p,n)=> n.isAfter(p)?n:p);
      return db.compareTo(da);
    });
    // Sort items inside a group by date then start time
    for (final g in groups) {
      g.sort((x,y){
        final dx = x.schedule.date;
        final dy = y.schedule.date;
        final c = dx.compareTo(dy);
        if (c != 0) return c;
        return x.schedule.startTime.compareTo(y.schedule.startTime);
      });
    }
    return groups;
  }

  Widget _buildGroupedBookingCard(List<BookingModel> group, bool isMobile, bool isTablet, double screenWidth) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final b0 = group.first;
    final statusAllSame = group.every((b) => b.status.toLowerCase() == b0.status.toLowerCase());
  final statusInfo = BookingService.getStatusInfo(statusAllSame ? b0.status : 'multiple');

    // Aggregate times by date
    final Map<String, List<BookingModel>> byDate = {};
    for (final b in group) { (byDate[b.schedule.date] ??= <BookingModel>[]).add(b); }
  // dates are handled within each service section below
  // (dateLines no longer directly used here; sectioned by service below)

    final total = group.fold<double>(0.0, (sum, b) => sum + b.pricing.totalAmount);
    final price = '₪${total.toStringAsFixed(0)}';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  group.length == 1 ? b0.serviceDetails.title : 'Multiple Services',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 18.0 : 20.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 12.0, vertical: isMobile ? 4.0 : 6.0),
                decoration: BoxDecoration(color: (statusInfo['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0)),
                child: Text(statusAllSame ? statusInfo['label'] : 'Multiple', style: GoogleFonts.cairo(fontSize: isMobile ? 12.0 : 14.0, fontWeight: FontWeight.w600, color: statusInfo['color'] as Color)),
              ),
              const SizedBox(width: 8),
              if (group.any((b) => b.emergency)) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8.0 : 10.0, vertical: isMobile ? 4.0 : 6.0),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0)),
                  child: Text('Emergency', style: GoogleFonts.cairo(fontSize: isMobile ? 12.0 : 13.0, fontWeight: FontWeight.w700, color: Colors.red)),
                ),
              ],
              if (_selectedFilter == 4)
                IconButton(
                  tooltip: _getLocalizedString('remove'),
                  onPressed: () => _dismissGroup(group),
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildProviderRowWithFavoriteForGroup(
            b0.providerName ?? '',
            b0.providerId,
            isMobile,
          ),
          const SizedBox(height: 8),
          // Address and total shown at top of the group
          _detailRow(Icons.location_on, AppStrings.getString('address', languageService.currentLanguage), b0.location.address, isMobile),
          const SizedBox(height: 8),
          _detailRow(Icons.attach_money, AppStrings.getString('estimatedCost', languageService.currentLanguage), price, isMobile),
          const SizedBox(height: 8),
          // Provider rating display
          _buildProviderRatingRowForGroup(b0, isMobile),
          const SizedBox(height: 12),
          // Service sections within this provider
          ...(() {
            final Map<String, List<BookingModel>> byService = {};
            for (final b in group) { (byService[b.serviceDetails.title] ??= <BookingModel>[]).add(b); }
            final entries = byService.entries.toList()..sort((a,b)=> a.key.compareTo(b.key));
            return entries.map((entry) {
              final serviceTitle = entry.key;
              final items = entry.value..sort((x,y){
                final dc = x.schedule.date.compareTo(y.schedule.date);
                if (dc != 0) return dc;
                return x.schedule.startTime.compareTo(y.schedule.startTime);
              });
              // Build date lines for this service
              final Map<String, List<BookingModel>> byDate = {};
              for (final b in items) { (byDate[b.schedule.date] ??= <BookingModel>[]).add(b); }
              final dateLines = byDate.entries.toList()..sort((a,b)=> a.key.compareTo(b.key));
              final dateTextSvc = dateLines.map((e){
                final times = (e.value..sort((x,y)=> x.schedule.startTime.compareTo(y.schedule.startTime)))
                    .map((b)=>'${b.schedule.startTime} - ${b.schedule.endTime}')
                    .join(', ');
                return '${_formatDate(e.key)} • $times';
              }).join('; ');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(serviceTitle, style: GoogleFonts.cairo(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  _detailRow(Icons.calendar_today, AppStrings.getString('dateTime', languageService.currentLanguage), dateTextSvc, isMobile),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.map((b){
                      final canCancel = ['pending','confirmed'].contains(b.status.toLowerCase());
                      final line = '${b.schedule.startTime} - ${b.schedule.endTime} • ₪${b.pricing.totalAmount.toStringAsFixed(0)}';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children:[
                          // Per-booking status chip
                          (() {
                            final mini = BookingService.getStatusInfo(b.status);
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (mini['color'] as Color).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                mini['label'],
                                style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: mini['color'] as Color),
                              ),
                            );
                          })(),
                          if (b.emergency) ...[
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text('Emergency', style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red)),
                            ),
                          ],
                          Expanded(child: Text(line, style: GoogleFonts.cairo(fontSize: isMobile ? 13 : 14, color: AppColors.textPrimary))),
                          if (canCancel)
                            OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  await BookingService().cancelBookingAction(b.id);
                                  await _refreshBookings();
                                } catch(_){ }
                              },
                              icon: const Icon(Icons.cancel, color: AppColors.error, size: 18),
                              label: Text(AppStrings.getString('cancel', languageService.currentLanguage), style: GoogleFonts.cairo(color: AppColors.error)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                            ),
                          if (b.status.toLowerCase() == 'completed' && 
                              (b.providerRating == null || b.providerRating?.rating == null || b.providerRating?.rating == 0)) ...[
                            // Debug logging
                            Builder(builder: (context) {
                              print('🔍 Grouped booking rate button debug for ${b.id}:');
                              print('  - Status: ${b.status}');
                              print('  - Provider rating: ${b.providerRating}');
                              print('  - Can rate: true');
                              return const SizedBox.shrink();
                            }),
                            SizedBox(
                              width: 80, // Fixed width to make it 50% smaller
                              child: ElevatedButton.icon(
                                onPressed: () => _showProviderRatingDialog(b.id),
                                icon: const Icon(Icons.star, color: Colors.white, size: 16),
                                label: Text('Rate', style: GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            ),
                          ]
                        ]),
                      );
                    }).toList(),
                  )
                ],
              );
            }).toList();
          })(),
        ],
      ),
    );
  }

  // Reuse a local detail row to avoid colliding with existing helper
  Widget _detailRow(IconData icon, String label, String value, bool isMobile) {
    return Row(children:[
      Icon(icon, color: AppColors.textSecondary, size: isMobile ? 16.0 : 18.0),
      const SizedBox(width: 8.0),
      Text('$label: ', style: GoogleFonts.cairo(fontSize: isMobile ? 14.0 : 16.0, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      Expanded(child: Text(value, style: GoogleFonts.cairo(fontSize: isMobile ? 14.0 : 16.0, color: AppColors.textPrimary))),
    ]);
  }

  String _formatDate(String ymd) {
    // Handles both 'yyyy-MM-dd' and ISO strings like 'yyyy-MM-ddTHH:mm:ssZ'
    try {
      if (ymd.contains('T')) {
        final dt = DateTime.parse(ymd).toLocal();
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}
    final parts = ymd.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]) ?? parts[0];
      final m = int.tryParse(parts[1]) ?? parts[1];
      final dRaw = parts[2];
      final d = int.tryParse(dRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? dRaw;
      return '$d/$m/$y';
    }
    return ymd;
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
          if ((booking['notes'] as String? ?? '').toLowerCase().contains('admin set to') || (booking['notes'] as String? ?? '').toLowerCase().contains('admin cancelled')) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text('Admin update', style: GoogleFonts.cairo(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
          ],
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
              if (_selectedFilter == 4 && (booking['id'] as String?) != null)
                IconButton(
                  tooltip: _getLocalizedString('remove'),
                  onPressed: () => _dismissSingle(booking['id'] as String),
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                ),
              if (booking['hasPendingCancel'] == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8.0 : 10.0,
                    vertical: isMobile ? 4.0 : 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
                  ),
                  child: Text(
                    AppStrings.getString('awaitingProviderApproval', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 10.0 : 12.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: isMobile ? 12.0 : 16.0),
          
          // Provider details with favorite icon
          _buildProviderRowWithFavorite(
            booking['provider'],
            booking['providerId'] as String?,
            isMobile,
          ),
          const SizedBox(height: 8.0),
          if ((booking['instructions'] as String? ?? '').isNotEmpty) ...[
            _buildBookingDetailRow(
              Icons.notes,
              AppStrings.getString('specialInstructions', languageService.currentLanguage),
              booking['instructions'],
              isMobile,
            ),
            const SizedBox(height: 8.0),
          ],
          if ((booking['notes'] as String? ?? '').isNotEmpty) ...[
            _buildBookingDetailRow(
              Icons.sticky_note_2,
              AppStrings.getString('additionalNotesOptional', languageService.currentLanguage),
              booking['notes'],
              isMobile,
            ),
            const SizedBox(height: 8.0),
          ],
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
            AppStrings.getString('estimatedCost', languageService.currentLanguage),
            booking['price'],
            isMobile,
          ),
          const SizedBox(height: 8.0),
          // Provider rating display
          _buildProviderRatingRow(booking, isMobile),
          SizedBox(height: isMobile ? 16.0 : 20.0),
          
          // Action buttons
          _buildBookingActions(isMobile, isTablet, screenWidth, bookingId: booking['id'] as String?, statusRaw: booking['statusRaw'] as String?, booking: booking),
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

  Widget _buildBookingActions(bool isMobile, bool isTablet, double screenWidth, { String? bookingId, String? statusRaw, Map<String, dynamic>? booking }) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final canCancel = (statusRaw != null) && ['pending','confirmed'].contains(statusRaw.toLowerCase());
    // Debug logging for rate button visibility
    print('🔍 Rate button debug for booking ${booking?['id']}:');
    print('  - Status: $statusRaw');
    print('  - Is completed: ${statusRaw?.toLowerCase() == 'completed'}');
    print('  - Provider rating exists: ${booking?['providerRating'] != null}');
    print('  - Provider rating value: ${booking?['providerRating']}');
    
    final canRate = (statusRaw != null) && statusRaw.toLowerCase() == 'completed' && 
                   (booking?['providerRating'] == null || 
                    (booking?['providerRating'] as ProviderRating?)?.rating == null ||
                    (booking?['providerRating'] as ProviderRating?)?.rating == 0);
    
    print('  - Can rate: $canRate');
    final actions = <Map<String, dynamic>>[];
    if (canCancel) {
      actions.add({'key': 'cancel', 'icon': Icons.cancel, 'label': AppStrings.getString('cancel', languageService.currentLanguage), 'color': AppColors.error});
    }
    if (canRate) {
      actions.add({'key': 'rate', 'icon': Icons.star, 'label': 'Rate', 'color': Colors.amber});
    }

  if (actions.isEmpty) return const SizedBox.shrink();
  return Wrap(
      spacing: isMobile ? 8.0 : 12.0,
      runSpacing: isMobile ? 8.0 : 12.0,
      children: actions.map((action) {
        return OutlinedButton.icon(
          onPressed: () => _onBookingActionPressed(action['key'] as String, bookingId: bookingId),
          icon: Icon(
            action['icon'] as IconData,
            size: isMobile ? 16.0 : 18.0,
            color: action['color'] as Color,
          ),
          label: Text(
            (action['label'] as String? ?? ''),
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.w500,
              color: action['color'] as Color,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: action['color'] as Color, width: 1),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8.0 : 12.0,
              vertical: isMobile ? 6.0 : 8.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _onBookingActionPressed(String key, { String? bookingId }) async {
    if (key == 'rate') {
      await _showProviderRatingDialog(bookingId);
      return;
    }
    if (key != 'cancel') return;
    String? targetId = bookingId;
    if (targetId == null || targetId.isEmpty) {
  final list = _filteredBookingsForCurrentTab();
  if (list.isEmpty) return;
  final idx = list.indexWhere((b) => ['pending','confirmed'].contains(b.status.toLowerCase()));
  final target = idx >= 0 ? list[idx] : list.first;
  targetId = target.id;
    }
    final svc = BookingService();
    final languageService = Provider.of<LanguageService>(context, listen: false);
    // Determine if within allowed cancellation window (cancel immediately) vs outside (needs request)
    // We estimate locally: compare minutes-until-start with thresholds
    // Defaults: 2880 minutes (48h) in production; 1 minute in non-production testing
    int cancelThresholdMins = 2880;
    // If you prefer an explicit dev override, you can wire via flavors or env; here we infer using assert
    assert(() {
      cancelThresholdMins = 1;
      return true;
    }());

    // We need the schedule to compute minutes, fetch the booking briefly
    BookingModel? targetBooking;
    try {
      targetBooking = await svc.getBookingById(targetId);
    } catch (_) {}
    String? reason;
    bool promptReason = true; // default to prompt
    if (targetBooking != null) {
      try {
        final dt = DateTime.tryParse(targetBooking.schedule.date);
        if (dt != null) {
          final parts = (targetBooking.schedule.startTime).split(':');
          final hh = int.tryParse(parts.first) ?? 0;
          final mm = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
          final start = DateTime(dt.year, dt.month, dt.day, hh, mm);
          final mins = start.difference(DateTime.now()).inMinutes;
          if (mins >= cancelThresholdMins) {
            // Within allowed window: cancel immediately, no reason dialog
            promptReason = false;
          }
        }
      } catch (_) {}
    }

    if (promptReason) {
      reason = await showDialog<String?>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text(AppStrings.getString('cancelBooking', languageService.currentLanguage)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.getString('confirmSendCancellationRequest', languageService.currentLanguage)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: AppStrings.getString('reasonOptional', languageService.currentLanguage),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(AppStrings.getString('cancel', languageService.currentLanguage)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text.trim().isEmpty ? null : controller.text.trim()),
                child: Text(AppStrings.getString('sendCancellationRequest', languageService.currentLanguage)),
              ),
            ],
          );
        },
      );
    }

    try {
      final res = await svc.cancelBookingAction(targetId, reason: reason);
      if (res.containsKey('booking')) {
        await _refreshBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.getString('cancelBooking', languageService.currentLanguage) + ' ✓')),
          );
        }
      } else {
        await _refreshBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.getString('sendCancellationRequest', languageService.currentLanguage) + ' ✓')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppStrings.getString('cancellationNotPossible', languageService.currentLanguage)),
          content: Text(AppStrings.getString('cancelWithinWindowMessage', languageService.currentLanguage)),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  // Chat Messages Section
  Widget _buildChatMessagesContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth <= 768;
        final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
        
        if (isMobile) {
          // Use mobile chat messages widget for mobile
          return const MobileChatMessagesWidget();
        }
        
        return Row(
          children: [
            // Chat List (hidden on mobile)
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
    // Use the ChatMessagesWidget for the chat list instead of hardcoded data
    return const ChatMessagesWidget();
  }

  Widget _buildChatMessagesArea(bool isMobile, bool isTablet) {
    // This method is no longer needed since ChatMessagesWidget handles everything
    // Return an empty container as placeholder
    return Container();
  }

  Widget _buildMessagesList(bool isMobile, bool isTablet) {
    // This method is no longer needed since ChatMessagesWidget handles everything
    return Container();
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMobile, bool isTablet) {
    // This method is no longer needed since ChatMessagesWidget handles everything
    return Container();
  }

  Widget _buildMessageInput(bool isMobile, bool isTablet) {
    // This method is no longer needed since ChatMessagesWidget handles everything
    return Container();
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
                card['icon'] as IconData?,
                color: card['color'] as Color?,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                (card['count'] ?? '0').toString(),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 24.0 : 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                (card['title'] ?? '').toString(),
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
                card['icon'] as IconData?,
                color: card['color'] as Color?,
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
                (card['title'] ?? '').toString(),
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
              
              // Addresses (combines GPS toggle and saved addresses in one section)
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

  Widget _buildGpsAddressSection(bool isMobile, bool isTablet) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser ?? {};
    final userRole = (user['role'] ?? '').toString().toLowerCase();
    final isProvider = userRole == 'provider';
    
    // Initialize address controller from user data if empty
    if (_addressCtrl.text.isEmpty) {
      final currentAddress = (user['address'] is String) 
          ? user['address'] 
          : (user['address']?['line1'] ?? '').toString();
      _addressCtrl.text = currentAddress;
    }

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
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.textSecondary,
                size: isMobile ? 20.0 : 24.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  _getLocalizedString('address'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 16.0 : 18.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          
          // Address text field
          TextFormField(
            controller: _addressCtrl,
            readOnly: _useGps,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              hintText: _getLocalizedString('enterAddress'),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // GPS toggle
          Row(
            children: [
              Switch(
                value: _useGps,
                onChanged: isProvider 
                  ? null // Providers must have GPS enabled
                  : (v) async {
                      setState(() { _useGps = v; });
                      if (v) {
                        final userLoc = await _locationService.simulateGpsForAddress();
                        final coupled = await _locationService.coupleAddressFromGps(userLoc.position);
                        final city = (coupled.city ?? '').toString();
                        final street = (coupled.street ?? '').toString();
                        setState(() {
                          _addressCtrl.text = [street, city].where((e) => e.isNotEmpty).join(', ');
                        });
                      }
                    },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use GPS (simulated) for my location and auto-fill address',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14.0 : 16.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isProvider) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        'GPS is mandatory for service providers',
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 12.0 : 14.0,
                          color: AppColors.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // Save button for address changes
          const SizedBox(height: 20.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthService>(context, listen: false);
                try {
                  final res = await auth.updateProfile(
                    useGpsLocation: _useGps,
                    address: _useGps ? {
                      'line1': _addressCtrl.text.trim(),
                      'city': _addressCtrl.text.trim().split(',').last.trim(),
                      'street': _addressCtrl.text.trim().split(',').first.trim(),
                    } : {
                      'line1': _addressCtrl.text.trim(),
                      'city': _addressCtrl.text.trim().split(',').first.trim(),
                      'street': _addressCtrl.text.trim().contains(',') 
                        ? _addressCtrl.text.trim().split(',').last.trim()
                        : _addressCtrl.text.trim(),
                    },
                  );
                  final ok = res['success'] == true;
                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address updated successfully')),
                    );
                  } else {
                    final msg = (res['message'] as String?) ?? 'Failed to update address';
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: AppColors.error, content: Text(msg)),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12.0 : 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                _getLocalizedString('saveChanges'),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesSection(bool isMobile, bool isTablet) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser ?? {};
    final userRole = (user['role'] ?? '').toString().toLowerCase();
    final isProvider = userRole == 'provider';
    
    // Initialize address controller from user data if empty
    if (_addressCtrl.text.isEmpty) {
      final currentAddress = (user['address'] is String) 
          ? user['address'] 
          : (user['address']?['line1'] ?? '').toString();
      _addressCtrl.text = currentAddress;
    }

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
          // GPS Location Section
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                color: _useGps ? AppColors.primary : AppColors.textSecondary,
                size: isMobile ? 20.0 : 24.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  _useGps ? 'Current Location (GPS Active)' : _getLocalizedString('currentLocation'),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 18.0 : 20.0,
                    fontWeight: FontWeight.w600,
                    color: _useGps ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
              if (_useGps) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16.0),
          
          // Address text field
          TextFormField(
            controller: _addressCtrl,
            readOnly: _useGps,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              hintText: _getLocalizedString('enterAddress'),
            ),
          ),
          const SizedBox(height: 16.0),
          
          // GPS toggle
          Row(
            children: [
              Switch(
                value: _useGps,
                 onChanged: isProvider 
                   ? null // Providers must have GPS enabled
                   : (v) async {
                       setState(() { _useGps = v; });
                       
                       // Immediately notify maps about GPS state change
                       LocationService.notifyGpsStateChanged(v);
                       
                       // Update the AuthService to persist the change
                       final auth = Provider.of<AuthService>(context, listen: false);
                       
                       if (v) {
                         // GPS turned ON - fill address and update profile
                         await _simulateGpsAndFillFullAddress();
                         try {
                           await auth.updateProfile(
                             useGpsLocation: true,
                             address: {
                               'line1': _addressCtrl.text.trim(),
                               'city': _addressCtrl.text.trim().split(',').last.trim(),
                               'street': _addressCtrl.text.trim().split(',').first.trim(),
                             },
                           );
                         } catch (e) {
                           // Handle silently, user can still save manually
                         }
                       } else {
                         // GPS turned OFF - clear address and update profile
                         _addressCtrl.text = '';
                         try {
                           await auth.updateProfile(useGpsLocation: false);
                         } catch (e) {
                           // Handle silently, user can still save manually
                         }
                       }
                     },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use GPS (simulated) for my location and auto-fill address',
                      style: GoogleFonts.cairo(
                        fontSize: isMobile ? 14.0 : 16.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isProvider) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        'GPS is mandatory for service providers',
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 12.0 : 14.0,
                          color: AppColors.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          // Save button for address changes
          const SizedBox(height: 20.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthService>(context, listen: false);
                try {
                  final res = await auth.updateProfile(
                    useGpsLocation: _useGps,
                    address: _useGps ? {
                      'line1': _addressCtrl.text.trim(),
                      'city': _addressCtrl.text.trim().split(',').last.trim(),
                      'street': _addressCtrl.text.trim().split(',').first.trim(),
                    } : {
                      'line1': _addressCtrl.text.trim(),
                      'city': _addressCtrl.text.trim().split(',').first.trim(),
                      'street': _addressCtrl.text.trim().contains(',') 
                        ? _addressCtrl.text.trim().split(',').last.trim()
                        : _addressCtrl.text.trim(),
                    },
                  );
                  final ok = res['success'] == true;
                  if (ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address updated successfully')),
                    );
                  } else {
                    final msg = (res['message'] as String?) ?? 'Failed to update address';
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: AppColors.error, content: Text(msg)),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(vertical: isMobile ? 12.0 : 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                _getLocalizedString('saveChanges'),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 14.0 : 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32.0),
          
          // Saved Addresses Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    color: _useGps ? AppColors.textSecondary : AppColors.textPrimary,
                    size: isMobile ? 20.0 : 24.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    _useGps ? 'Saved Addresses (Inactive)' : _getLocalizedString('savedAddresses'),
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 18.0 : 20.0,
                      fontWeight: FontWeight.w600,
                      color: _useGps ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ],
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
    // When GPS is active, saved addresses are inactive (no default highlighting)
    final isActiveDefault = isDefault && !_useGps;
    final isInactive = _useGps;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: isInactive ? AppColors.background.withValues(alpha: 0.5) : AppColors.background,
        borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
        border: Border.all(
          color: isActiveDefault ? AppColors.primary : AppColors.border,
          width: isActiveDefault ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on, 
            color: isInactive ? AppColors.textSecondary : AppColors.primary,
          ),
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
                          color: isInactive ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isActiveDefault)
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
                    if (isInactive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Inactive',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
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
                    color: isInactive ? AppColors.textSecondary.withValues(alpha: 0.6) : AppColors.textSecondary,
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
                    if (!isActiveDefault && onMakeDefault != null)
                      TextButton(
                        onPressed: isInactive ? () => _switchToSavedAddress(onMakeDefault) : onMakeDefault, 
                        child: Text(isInactive ? 'Use This Address' : 'Make Default'),
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
    const cities = [
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFavoriteProvidersData(),
      builder: (context, snapshot) {
        int totalProviders = 0;
        int availableProviders = 0;
        
        if (snapshot.hasData && snapshot.data != null) {
          totalProviders = snapshot.data!.length;
          availableProviders = snapshot.data!.where((provider) {
            final providerData = provider['providerData'] as Map<String, dynamic>? ?? provider;
            return providerData['isAvailable'] ?? true;
          }).length;
        }
        
        final summaryCards = [
          {'title': _getLocalizedString('totalProviders'), 'count': totalProviders.toString(), 'icon': Icons.favorite, 'color': AppColors.error},
          {'title': _getLocalizedString('available'), 'count': availableProviders.toString(), 'icon': Icons.check_circle, 'color': AppColors.success},
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
                card['icon'] as IconData?,
                color: card['color'] as Color?,
                size: isMobile ? 32.0 : 40.0,
              ),
              SizedBox(height: isMobile ? 8.0 : 12.0),
              Text(
                (card['count'] ?? '0').toString(),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 24.0 : 32.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                (card['title'] ?? '').toString(),
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
      },
    );
  }

  /// Get favorite providers data for summary cards
  Future<List<Map<String, dynamic>>> _getFavoriteProvidersData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final favoritesService = FavoritesService();
      
      final favoriteProviders = await favoritesService.getFavoriteProviders(
        authService: authService,
      );
      
      return favoriteProviders;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching favorite providers for summary: $e');
      }
      return [];
    }
  }

  Widget _buildSavedProvidersList(bool isMobile, bool isTablet) {
    // This method should not be used anymore - the SavedProvidersWidget handles this
    // Return a placeholder or redirect to the proper widget
    return const SavedProvidersWidget();
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

                // Main Menu (Home) navigation in drawer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    leading: const Icon(
                      Icons.home_outlined,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    title: Text(
                      AppStrings.getString('home', languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.of(context).pushNamed('/home'); // Preserve session, navigate to main menu
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
      _getLocalizedString('deleteAccountWarning'),
            style: GoogleFonts.cairo(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
        _getLocalizedString('cancel'),
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
        _getLocalizedString('delete'),
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
    // Feature not yet implemented in AuthService; show a friendly message.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _getLocalizedString('deleteAccountFailed'),
          style: GoogleFonts.cairo(color: AppColors.white),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // Provider rating display for single booking cards
  Widget _buildProviderRatingRow(Map<String, dynamic> booking, bool isMobile) {
    final providerOverallRating = booking['providerOverallRating'] as ProviderOverallRating?;
    
    if (providerOverallRating == null) {
      return const SizedBox.shrink();
    }

    final rating = providerOverallRating.average;
    final ratingCount = providerOverallRating.count;
    
    final userProviderRating = booking['providerRating'] as ProviderRating?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider's overall rating row
        Row(
          children: [
            Icon(
              Icons.star,
              color: AppColors.textSecondary,
              size: isMobile ? 16.0 : 18.0,
            ),
            const SizedBox(width: 8.0),
            Text(
              'Provider Rating: ',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14.0 : 16.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            // Star rating display
            Row(
              children: List.generate(5, (index) {
                final starRating = index + 1;
                final isFilled = starRating <= rating;
                return Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  color: isFilled ? Colors.amber : AppColors.textSecondary,
                  size: isMobile ? 16.0 : 18.0,
                );
              }),
            ),
            const SizedBox(width: 8.0),
            Text(
              '${rating.toStringAsFixed(1)} (${ratingCount})',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14.0 : 16.0,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (ratingCount > 0)
              TextButton.icon(
                onPressed: () => _showProviderReviewsDialog(booking),
                icon: Icon(
                  Icons.reviews,
                  color: AppColors.primary,
                  size: isMobile ? 16.0 : 18.0,
                ),
                label: Text(
                  'View Reviews',
                  style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        // User's specific rating and comment row
        if (userProviderRating != null) ...[
          const SizedBox(height: 4.0),
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: isMobile ? 14.0 : 16.0,
              ),
              const SizedBox(width: 6.0),
              Text(
                'My Rating: ',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              // User's star rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < userProviderRating.rating.floor() 
                        ? Icons.star 
                        : (index < userProviderRating.rating ? Icons.star_half : Icons.star_border),
                    color: Colors.amber,
                    size: isMobile ? 12.0 : 14.0,
                  );
                }),
              ),
              const SizedBox(width: 4.0),
              Text(
                '${userProviderRating.rating.toStringAsFixed(1)}',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
              if (userProviderRating.comment != null && userProviderRating.comment!.isNotEmpty) ...[
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    '"${userProviderRating.comment!}"',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 11.0 : 13.0,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // Provider rating display for grouped booking cards
  Widget _buildProviderRatingRowForGroup(BookingModel booking, bool isMobile) {
    final providerOverallRating = booking.providerOverallRating;
    
    if (providerOverallRating == null) {
      return const SizedBox.shrink();
    }

    final rating = providerOverallRating.average;
    final ratingCount = providerOverallRating.count;
    
    final userProviderRating = booking.providerRating;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider's overall rating row
        Row(
          children: [
            Icon(
              Icons.star,
              color: AppColors.textSecondary,
              size: isMobile ? 16.0 : 18.0,
            ),
            const SizedBox(width: 8.0),
            Text(
              'Provider Rating: ',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14.0 : 16.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            // Star rating display
            Row(
              children: List.generate(5, (index) {
                final starRating = index + 1;
                final isFilled = starRating <= rating;
                return Icon(
                  isFilled ? Icons.star : Icons.star_border,
                  color: isFilled ? Colors.amber : AppColors.textSecondary,
                  size: isMobile ? 16.0 : 18.0,
                );
              }),
            ),
            const SizedBox(width: 8.0),
            Text(
              '${rating.toStringAsFixed(1)} (${ratingCount})',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14.0 : 16.0,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (ratingCount > 0)
              TextButton.icon(
                onPressed: () => _showProviderReviewsDialogForGroup(booking),
                icon: Icon(
                  Icons.reviews,
                  color: AppColors.primary,
                  size: isMobile ? 16.0 : 18.0,
                ),
                label: Text(
                  'View Reviews',
                  style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        // User's specific rating and comment row
        if (userProviderRating != null) ...[
          const SizedBox(height: 4.0),
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: isMobile ? 14.0 : 16.0,
              ),
              const SizedBox(width: 6.0),
              Text(
                'My Rating: ',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              // User's star rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < userProviderRating.rating.floor() 
                        ? Icons.star 
                        : (index < userProviderRating.rating ? Icons.star_half : Icons.star_border),
                    color: Colors.amber,
                    size: isMobile ? 12.0 : 14.0,
                  );
                }),
              ),
              const SizedBox(width: 4.0),
              Text(
                '${userProviderRating.rating.toStringAsFixed(1)}',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 14.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
              if (userProviderRating.comment != null && userProviderRating.comment!.isNotEmpty) ...[
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    '"${userProviderRating.comment!}"',
                    style: GoogleFonts.cairo(
                      fontSize: isMobile ? 11.0 : 13.0,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // Show provider reviews dialog for single booking
  void _showProviderReviewsDialog(Map<String, dynamic> booking) {
    final providerId = booking['providerId'] as String?;
    final providerName = booking['provider'] as String?;
    
    if (providerId == null || providerName == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = BookingService();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProviderReviewsDialog(
          providerId: providerId,
          providerName: providerName,
          reviewsFuture: bookingService.getProviderReviews(
            providerId,
            authService: authService,
          ),
        );
      },
    );
  }

  // Show provider reviews dialog for grouped booking
  void _showProviderReviewsDialogForGroup(BookingModel booking) {
    final providerId = booking.providerId;
    final providerName = booking.providerName;
    
    if (providerId == null || providerName == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = BookingService();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProviderReviewsDialog(
          providerId: providerId,
          providerName: providerName,
          reviewsFuture: bookingService.getProviderReviews(
            providerId,
            authService: authService,
          ),
        );
      },
    );
  }


  // Show provider rating dialog for booking ID
  Future<void> _showProviderRatingDialog(String? bookingId) async {
    if (bookingId == null) return;

    // Find the booking to get provider details
    final booking = _myBookings.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => throw Exception('Booking not found'),
    );

    final providerName = booking.providerName ?? 'Unknown Provider';
    final serviceName = booking.serviceDetails.title;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProviderRatingDialog(
          bookingId: bookingId,
          providerName: providerName,
          serviceName: serviceName,
          onRatingSubmitted: () {
            // Refresh bookings to show updated rating
            _refreshBookings();
          },
        );
      },
    );
  }

  // Provider row with favorite icon for single bookings
  Widget _buildProviderRowWithFavorite(String providerName, String? providerId, bool isMobile) {
    return Row(
      children: [
        Icon(
          Icons.person,
          color: AppColors.textSecondary,
          size: isMobile ? 16.0 : 18.0,
        ),
        const SizedBox(width: 8.0),
        Text(
          AppStrings.getString('provider', Provider.of<LanguageService>(context, listen: false).currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 14.0 : 16.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            providerName,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (providerId != null)
          _buildFavoriteIcon(providerId, isMobile),
      ],
    );
  }

  // Provider row with favorite icon for grouped bookings
  Widget _buildProviderRowWithFavoriteForGroup(String providerName, String? providerId, bool isMobile) {
    return Row(
      children: [
        Icon(
          Icons.person,
          color: AppColors.textSecondary,
          size: isMobile ? 16.0 : 18.0,
        ),
        const SizedBox(width: 8.0),
        Text(
          AppStrings.getString('providerName', Provider.of<LanguageService>(context, listen: false).currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 14.0 : 16.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            providerName,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (providerId != null)
          _buildFavoriteIcon(providerId, isMobile),
      ],
    );
  }

  // Favorite icon widget
  Widget _buildFavoriteIcon(String providerId, bool isMobile) {
    return FutureBuilder<bool>(
      future: _isProviderFavorite(providerId),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;
        
        return GestureDetector(
          onTap: () => _toggleProviderFavorite(providerId, isFavorite),
          child: Container(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : AppColors.textSecondary,
              size: isMobile ? 20.0 : 22.0,
            ),
          ),
        );
      },
    );
  }

  // Check if provider is favorite
  Future<bool> _isProviderFavorite(String providerId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final favoritesService = FavoritesService();
      
      return await favoritesService.isProviderFavorite(
        providerId,
        authService: authService,
      );
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Toggle provider favorite status
  Future<void> _toggleProviderFavorite(String providerId, bool currentStatus) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final favoritesService = FavoritesService();
      
      if (currentStatus) {
        // Remove from favorites
        await favoritesService.removeFromFavorites(
          providerId,
          authService: authService,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed from favorites',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Add to favorites
        await favoritesService.addToFavorites(
          providerId,
          authService: authService,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added to favorites',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Refresh the UI
      setState(() {});
    } catch (e) {
      print('Error toggling favorite status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating favorite status',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Initialize GPS state based on user role and preferences
  void _initializeGpsState() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser ?? {};
    final userRole = (user['role'] ?? '').toString().toLowerCase();
    final isProvider = userRole == 'provider';
    
    // For providers, GPS is mandatory - always enabled
    if (isProvider) {
      setState(() {
        _useGps = true;
      });
      
      // Auto-fill full address from GPS for providers
      _simulateGpsAndFillFullAddress();
    } else {
      // For clients and admins, GPS is optional - check user preference or default to false
      final useGpsPreference = user['useGpsLocation'] ?? false;
      setState(() {
        _useGps = useGpsPreference;
      });
      
      if (_useGps) {
        // Auto-fill full address from GPS if enabled
        _simulateGpsAndFillFullAddress();
      }
    }
  }

  // Enhanced GPS simulation that provides full, realistic addresses
  Future<void> _simulateGpsAndFillFullAddress() async {
    final userLoc = await _locationService.simulateGpsForAddress();
    final coupled = await _locationService.coupleAddressFromGps(userLoc.position);
    
    // Generate a full, realistic Palestinian address
    final city = coupled.city ?? 'Ramallah';
    final streetOptions = _getStreetOptionsForCity(city);
    final randomStreet = streetOptions.isNotEmpty 
        ? streetOptions[userLoc.position.latitude.hashCode % streetOptions.length]
        : 'Main Street';
    final buildingNumber = (userLoc.position.longitude.abs() * 1000).round() % 999 + 1;
    
    final fullAddress = '$buildingNumber $randomStreet, $city, Palestine';
    
    if (mounted) {
      setState(() {
        _addressCtrl.text = fullAddress;
      });
    }
  }

  // Get realistic street names for Palestinian cities
  List<String> _getStreetOptionsForCity(String city) {
    final cityLower = city.toLowerCase();
    switch (cityLower) {
      case 'ramallah':
        return ['Al-Manara Street', 'Rukab Street', 'Al-Irsal Street', 'Main Street', 'Al-Nahda Street'];
      case 'jerusalem':
      case 'al-quds':
        return ['Salah Al-Din Street', 'Sultan Suleiman Street', 'Nablus Road', 'Jaffa Road', 'King George Street'];
      case 'bethlehem':
        return ['Manger Street', 'Paul VI Street', 'Hebron Road', 'Star Street', 'Peace Center Street'];
      case 'hebron':
      case 'al-khalil':
        return ['King Talal Street', 'Ein Sarah Street', 'Old City Road', 'University Street', 'Industrial Street'];
      case 'nablus':
        return ['Sufian Street', 'Faisal Street', 'An-Najah Street', 'Old City Street', 'Rafidia Street'];
      case 'gaza':
        return ['Omar Al-Mukhtar Street', 'Al-Wahda Street', 'Al-Nasr Street', 'Beach Road', 'Al-Rimal Street'];
      case 'jenin':
        return ['Haifa Street', 'Al-Yamoun Street', 'Freedom Street', 'Khalil Gibran Street', 'Al-Salam Street'];
      case 'tulkarm':
        return ['Nablus Street', 'Al-Alimi Street', 'Iktaba Street', 'Industrial Street', 'Al-Sikka Street'];
      default:
        return ['Main Street', 'Al-Salam Street', 'Al-Wahda Street', 'Al-Nasr Street', 'Central Street'];
    }
  }

  // Notify any listening map widgets that location preferences have changed
  void _notifyMapsOfLocationChange() {
    // The AuthService.notifyListeners() call in updateProfile() will automatically
    // trigger map widgets to refresh their user location display since they
    // listen to the AuthService through Provider.of<AuthService>
  }

  // Switch from GPS to a saved address
  Future<void> _switchToSavedAddress(VoidCallback? makeDefaultCallback) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser ?? {};
    final userRole = (user['role'] ?? '').toString().toLowerCase();
    final isProvider = userRole == 'provider';
    
    if (isProvider) {
      // Providers cannot disable GPS
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Service providers must use GPS location'),
        ),
      );
      return;
    }
    
    // Turn off GPS and make this saved address the default
    setState(() {
      _useGps = false;
    });
    
    // Update the address field to show we're no longer using GPS
    _addressCtrl.text = '';
    
    // Call the original make default callback
    if (makeDefaultCallback != null) {
      makeDefaultCallback();
    }
    
    // Update user profile to turn off GPS
    try {
      await auth.updateProfile(useGpsLocation: false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error switching address: $e'),
          ),
        );
      }
    }
  }
} 