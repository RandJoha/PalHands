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
import 'user_sidebar.dart';
import 'my_bookings_widget.dart';
import 'chat_messages_widget.dart';
import 'profile_settings_widget.dart';
import 'saved_providers_widget.dart';
import 'support_help_widget.dart';
import 'security_widget.dart';

// User models
import '../../domain/models/user_menu_item.dart';

class WebUserDashboard extends StatefulWidget {
  const WebUserDashboard({super.key});

  @override
  State<WebUserDashboard> createState() => _WebUserDashboardState();
}

class _WebUserDashboardState extends State<WebUserDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  final GlobalKey<ChatMessagesWidgetState> _chatMessagesKey = GlobalKey<ChatMessagesWidgetState>();

  List<UserMenuItem> _getMenuItems(String languageCode) {
    return [
      UserMenuItem(
        title: AppStrings.getString('myBookings', languageCode),
        icon: Icons.calendar_today,
        index: 0,
        badge: '3', // Example badge for upcoming bookings
      ),
      UserMenuItem(
        title: AppStrings.getString('chatMessages', languageCode),
        icon: Icons.chat,
        index: 1,
        badge: '2', // Example badge for unread messages
      ),
      UserMenuItem(
        title: AppStrings.getString('profileSettings', languageCode),
        icon: Icons.person,
        index: 2,
      ),
      UserMenuItem(
        title: AppStrings.getString('savedProviders', languageCode),
        icon: Icons.favorite,
        index: 3,
      ),
      UserMenuItem(
        title: AppStrings.getString('supportHelp', languageCode),
        icon: Icons.help,
        index: 4,
      ),
      UserMenuItem(
        title: AppStrings.getString('security', languageCode),
        icon: Icons.security,
        index: 5,
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
    // Use a more stable approach to prevent widget lifecycle issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && screenWidth <= 1200 && !_isSidebarCollapsed) {
        setState(() {
          _isSidebarCollapsed = true;
        });
      }
    });
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar
          UserSidebar(
            selectedIndex: _selectedIndex,
            menuItems: menuItems,
            isCollapsed: _isSidebarCollapsed,
            onItemSelected: (index) {
              if (mounted) {
                _onTabChanged(index);
              }
            },
            onToggleCollapse: () {
              if (mounted) {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              }
            },
          ),
          
          // Main content area
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                children: [
                  // Top bar
                  _buildTopBar(languageService),
                  
                  // Content area
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildContent(),
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

  Widget _buildTopBar(LanguageService languageService) {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Welcome message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.getString('welcomeBack', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  (Provider.of<AuthService>(context, listen: false).currentUser != null)
                      ? (
                          [
                            (Provider.of<AuthService>(context, listen: false).currentUser!['firstName'] ?? '').toString(),
                            (Provider.of<AuthService>(context, listen: false).currentUser!['lastName'] ?? '').toString(),
                          ].where((e) => e.isNotEmpty).join(' ').trim()
                        )
                      : '—',
                  style: GoogleFonts.cairo(
                    fontSize: 20.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Language toggle and user menu
          Row(
            children: [
              // Back to Main Menu Button
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/home');
                  },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home,
                        size: 16.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        AppStrings.getString('backToMainMenu', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: 12.sp,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // Language toggle
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language,
                      size: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      languageService.currentLanguage == 'ar' ? 'العربية' : 'English',
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // User avatar and menu
              PopupMenuButton<String>(
                offset: Offset(0, 50.h),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 20.sp,
                    color: AppColors.primary,
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16.sp, color: AppColors.textSecondary),
                        SizedBox(width: 8.w),
                        Text(
                          AppStrings.getString('profile', languageService.currentLanguage),
                          style: GoogleFonts.cairo(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 16.sp, color: AppColors.textSecondary),
                        SizedBox(width: 8.w),
                        Text(
                          AppStrings.getString('settings', languageService.currentLanguage),
                          style: GoogleFonts.cairo(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16.sp, color: AppColors.error),
                        SizedBox(width: 8.w),
                        Text(
                          AppStrings.getString('logout', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  // Handle menu selection
                  if (value == 'logout') {
                    try {
                      // Handle logout
                      final authService = Provider.of<AuthService>(context, listen: false);
                      await authService.logout();
                      
                      // Navigate to home screen and clear all routes
                      if (mounted) {
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
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const MyBookingsWidget();
              case 1:
          return ChatMessagesWidget(key: _chatMessagesKey);
      case 2:
        return const ProfileSettingsWidget();
      case 3:
        return const SavedProvidersWidget();
      default:
        return const MyBookingsWidget();
    }
  }

  // Method to refresh chat messages
  void _refreshChatMessages() {
    if (_selectedIndex == 1 && _chatMessagesKey.currentState != null) {
      _chatMessagesKey.currentState!.refreshChats();
    }
  }

  // Method to handle tab changes
  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Refresh chat messages when navigating to chat tab
    if (index == 1) {
      // Use a small delay to ensure the widget is built
      Future.delayed(const Duration(milliseconds: 100), () {
        _refreshChatMessages();
      });
    }
  }
} 