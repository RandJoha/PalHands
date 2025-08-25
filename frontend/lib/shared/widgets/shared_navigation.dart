import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/services/language_service.dart';
import '../../shared/services/responsive_service.dart';
import '../../shared/services/auth_service.dart';
import '../widgets/animated_handshake.dart';

class SharedNavigation extends StatelessWidget {
  final String? currentPage;
  final bool showAuthButtons;
  final VoidCallback? onMenuTap;
  final bool isMobile;

  const SharedNavigation({
    super.key,
    this.currentPage,
    this.showAuthButtons = true,
    this.onMenuTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ResponsiveService>(
      builder: (context, languageService, responsiveService, child) {
        // Get screen width for responsive decision
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Determine responsive layout based on service and screen size
  final shouldUseMobileLayout = responsiveService.shouldUseMobileLayout(screenWidth) || isMobile;
        final shouldUseCompactNavigation = responsiveService.shouldUseCompactNavigation(screenWidth);
        final shouldUseVeryCompactNavigation = responsiveService.shouldUseVeryCompactNavigation(screenWidth);
  // Unified collapsed behavior to avoid switchback flicker around ~770-840px
  final isCollapsed = responsiveService.shouldCollapseNavigation(screenWidth);
  final forceMobileLayout = shouldUseMobileLayout || isCollapsed;
        
  return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: forceMobileLayout ? 16 : (shouldUseCompactNavigation ? 24 : 32),
            vertical: forceMobileLayout ? 16 : 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr, // Keep logo on the visual left and actions on the right regardless of app language
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo Section - Fixed size, never wraps
              _buildLogoSection(forceMobileLayout),
              
              // Desktop/Tablet Navigation - Only show when not mobile
              if (!forceMobileLayout) ...[
                Expanded(
                  child: _buildDesktopNavigation(context, languageService, shouldUseCompactNavigation, shouldUseVeryCompactNavigation),
                ),
                
                // Right side elements - Fixed layout, never wraps
                _buildRightSection(context, languageService, shouldUseCompactNavigation),
              ],
              
              // Mobile menu button - Only show when mobile
              if (forceMobileLayout) ...[
                _buildMobileMenuSection(context, languageService),
              ],
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildLogoSection(bool isMobile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: isMobile ? 28 : 32,
          height: isMobile ? 28 : 32,
          child: const AnimatedHandshake(
            size: 28,
            color: AppColors.primary,
            animationDuration: Duration(milliseconds: 2000),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'PalHands',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNavigation(BuildContext context, LanguageService languageService, bool isCompact, bool isVeryCompact) {
    // Center titles must flip order in Arabic (RTL) while logo stays left and actions stay right
    final baseItems = [
      {'key': 'home', 'route': '/home'},
      {'key': 'aboutUs', 'route': '/about'},
      {'key': 'ourServices', 'route': '/categories'},
      {'key': 'faqs', 'route': '/faqs'},
      {'key': 'contactUs', 'route': '/contact'},
    ];

    final navItems = languageService.currentLanguage == 'ar'
        ? List<Map<String, String>>.from(baseItems.reversed)
        : List<Map<String, String>>.from(baseItems);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: navItems.map((item) => _buildNavItem(
        context,
        item['key']!,
        item['route']!,
        languageService,
        currentPage == item['key'],
        isCompact,
        isVeryCompact,
      )).toList(),
    );
  }

  Widget _buildNavItem(BuildContext context, String key, String route, LanguageService languageService, bool isSelected, bool isCompact, bool isVeryCompact) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isVeryCompact ? 4 : (isCompact ? 6 : 10),
        vertical: 6,
      ),
      child: TextButton(
        onPressed: () {
          if (key == 'home') {
            Navigator.pushReplacementNamed(context, route);
          } else {
            Navigator.pushNamed(context, route);
          }
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: isVeryCompact ? 6 : (isCompact ? 8 : 10),
            vertical: 6,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          AppStrings.getString(key, languageService.currentLanguage),
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
            fontSize: isVeryCompact ? 12 : (isCompact ? 13 : 14),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ),
    );
  }

  Widget _buildRightSection(BuildContext context, LanguageService languageService, bool isCompact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Language toggle
        _buildLanguageToggle(languageService, isCompact),
        
        // Authentication buttons or user actions
        if (showAuthButtons) ...[
          const SizedBox(width: 8),
          _buildAuthOrUserActions(context, languageService, isCompact),
        ],
      ],
    );
  }

  Widget _buildAuthOrUserActions(BuildContext context, LanguageService languageService, bool isCompact) {
    final auth = Provider.of<AuthService>(context, listen: false);
    
    if (auth.isAuthenticated) {
      // User is authenticated - show user actions
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dashboard button
          _buildDashboardQuickAction(context, languageService, isCompact),
          const SizedBox(width: 8),
          // Logout button
          _buildPillButton(
            AppStrings.getString('logout', languageService.currentLanguage),
            () async {
              try {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            isCompact: isCompact,
          ),
        ],
      );
    } else {
      // User is not authenticated - show login/signup buttons
      return _buildAuthButtons(context, languageService, isCompact);
    }
  }

  Widget _buildDashboardQuickAction(BuildContext context, LanguageService languageService, bool isCompact) {
    // Decide label and destination based on auth state and role
    final auth = Provider.of<AuthService>(context, listen: false);
    String label;
    VoidCallback onTap;

    if (auth.isAuthenticated) {
      // Pick dashboard by role
      if (auth.isAdmin) {
        label = AppStrings.getString('adminDashboard', languageService.currentLanguage);
        onTap = () => Navigator.pushNamed(context, '/admin');
      } else if (auth.isProvider) {
        label = AppStrings.getString('goToDashboard', languageService.currentLanguage);
        onTap = () => Navigator.pushNamed(context, '/provider');
      } else {
        // Client
        label = AppStrings.getString('goToDashboard', languageService.currentLanguage);
        onTap = () => Navigator.pushNamed(context, '/user');
      }
    } else {
      // Not authenticated -> Go to profile/login makes less sense; keep existing flow minimal
      label = AppStrings.getString('goToDashboard', languageService.currentLanguage);
      onTap = () => Navigator.pushNamed(context, '/login');
    }

  return _buildPillButton(label, onTap, isCompact: isCompact);
  }

  // Unify button look & feel: language/login/signup share same style
  Widget _buildPillButton(String label, VoidCallback onTap, {bool isCompact = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 14,
          vertical: isCompact ? 6 : 8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(LanguageService languageService, bool isCompact) {
    final label = languageService.currentLanguage == 'ar' ? 'EN' : 'العربية';
    return _buildPillButton(label, languageService.toggleLanguage, isCompact: isCompact);
  }

  Widget _buildAuthButtons(BuildContext context, LanguageService languageService, bool isCompact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPillButton(
          AppStrings.getString('login', languageService.currentLanguage),
          () => Navigator.pushNamed(context, '/login'),
          isCompact: isCompact,
        ),
  const SizedBox(width: 6),
        _buildPillButton(
          AppStrings.getString('signUp', languageService.currentLanguage),
          () => Navigator.pushNamed(context, '/signup'),
          isCompact: isCompact,
        ),
      ],
    );
  }

  Widget _buildMobileMenuSection(BuildContext context, LanguageService languageService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
  _buildLanguageToggle(languageService, true),
        const SizedBox(width: 12),
        // Enhanced mobile menu button with better touch target
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onMenuTap ?? () {
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold != null) {
                // Always open the primary drawer for reliability across layouts
                scaffold.openDrawer();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SharedMobileDrawer extends StatelessWidget {
  final String? currentPage;
  final bool showAuthButtons;

  const SharedMobileDrawer({
    super.key,
    this.currentPage,
    this.showAuthButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ResponsiveService>(
      builder: (context, languageService, responsiveService, child) {
        return Drawer(
          child: Column(
            children: [
              // Drawer header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, // Reduced from 40
                      height: 32, // Reduced from 40
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8), // Reduced from 10
                      ),
                      child: const AnimatedHandshake(
                        size: 16, // Reduced from 20
                        color: AppColors.primary,
                        animationDuration: Duration(milliseconds: 2000),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'PalHands', // Brand stays in English
                        style: TextStyle(
                          fontSize: 16, // Reduced from 18
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Navigation items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Quick dashboard/profile access at top when logged in
                    Builder(
                      builder: (context) {
                        final auth = Provider.of<AuthService>(context, listen: false);
                        if (!auth.isAuthenticated) return const SizedBox.shrink();
                        String title;
                        VoidCallback onTap;
                        if (auth.isAdmin) {
                          title = AppStrings.getString('adminDashboard', languageService.currentLanguage);
                          onTap = () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/admin');
                          };
                        } else if (auth.isProvider) {
                          title = AppStrings.getString('goToDashboard', languageService.currentLanguage);
                          onTap = () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/provider');
                          };
                        } else {
                          title = AppStrings.getString('goToDashboard', languageService.currentLanguage);
                          onTap = () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/user');
                          };
                        }
                        return _buildDrawerItem(
                          context,
                          Icons.dashboard_customize,
                          title,
                          onTap,
                          false,
                          languageService,
                        );
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.home,
                      AppStrings.getString('home', languageService.currentLanguage),
                      () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      currentPage == 'home',
                      languageService,
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.info,
                      AppStrings.getString('aboutUs', languageService.currentLanguage),
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/about');
                      },
                      currentPage == 'aboutUs',
                      languageService,
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.cleaning_services,
                      AppStrings.getString('ourServices', languageService.currentLanguage),
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/categories');
                      },
                      currentPage == 'ourServices',
                      languageService,
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.question_answer,
                      AppStrings.getString('faqs', languageService.currentLanguage),
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/faqs');
                      },
                      currentPage == 'faqs',
                      languageService,
                    ),
                    _buildDrawerItem(
                      context,
                      Icons.contact_support,
                      AppStrings.getString('contactUs', languageService.currentLanguage),
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/contact');
                      },
                      currentPage == 'contactUs',
                      languageService,
                    ),
                    
                    // Divider
                    const Divider(height: 32, thickness: 1),
                  ],
                ),
              ),
              
              // Language toggle at bottom
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _buildDrawerLanguageToggle(languageService)),
                  ],
                ),
              ),
              // Go to Dashboard inside the drawer (small main menu)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      final auth = Provider.of<AuthService>(context, listen: false);
                      Navigator.pop(context);
                      if (auth.isAuthenticated) {
                        if (auth.isAdmin) {
                          Navigator.pushNamed(context, '/admin');
                        } else if (auth.isProvider) {
                          Navigator.pushNamed(context, '/provider');
                        } else {
                          Navigator.pushNamed(context, '/user');
                        }
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(AppStrings.getString('goToDashboard', languageService.currentLanguage),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              // Auth actions in collapsed mode (match drawer language button style)
              if (showAuthButtons) Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    Expanded(child: _buildDrawerOutlinedButton(
                      AppStrings.getString('login', languageService.currentLanguage),
                      () => Navigator.pushNamed(context, '/login'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDrawerOutlinedButton(
                      AppStrings.getString('signUp', languageService.currentLanguage),
                      () => Navigator.pushNamed(context, '/signup'),
                    )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
    bool isSelected,
    LanguageService languageService,
  ) {
    return Directionality(
      textDirection: languageService.textDirection,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : Colors.black87,
        ),
        title: Text(
          title,
          textAlign: languageService.currentLanguage == 'ar' ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        selected: isSelected,
        tileColor: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      ),
    );
  }

  Widget _buildDrawerLanguageToggle(LanguageService languageService) {
    return GestureDetector(
      onTap: () {
        languageService.toggleLanguage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.language,
              color: AppColors.primary,
              size: 18, // Reduced from 20
            ),
            const SizedBox(width: 8),
            Text(
              languageService.currentLanguage == 'ar' ? 'EN' : 'العربية',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14, // Reduced from 16
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerOutlinedButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
