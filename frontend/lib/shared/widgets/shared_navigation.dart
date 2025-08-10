import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/services/language_service.dart';
import '../../shared/services/responsive_service.dart';
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
        final shouldStackButtons = responsiveService.shouldStackButtons(screenWidth);
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: shouldUseMobileLayout ? 16 : (shouldUseCompactNavigation ? 20 : 32),
            vertical: shouldUseMobileLayout ? 12 : 16,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo - Made smaller
              Row(
                children: [
                  SizedBox(
                    width: shouldUseMobileLayout ? 24 : 32,
                    height: shouldUseMobileLayout ? 24 : 32,
                    child: const AnimatedHandshake(
                      size: 24,
                      color: AppColors.primary,
                      animationDuration: Duration(milliseconds: 2000),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PalHands',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: shouldUseMobileLayout ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Desktop/Tablet Navigation
              if (!shouldUseMobileLayout) ...[
                Expanded(
                  child: _buildDesktopNavigation(context, languageService, shouldUseCompactNavigation),
                ),
                
                // Language toggle - Made smaller
                _buildLanguageToggle(languageService, shouldUseCompactNavigation),
                
                // Authentication buttons
                if (showAuthButtons && !shouldUseMobileLayout) ...[
                  const SizedBox(width: 16),
                  _buildAuthButtons(context, languageService, shouldStackButtons, shouldUseCompactNavigation),
                ],
              ],
              
              // Mobile menu button
              if (shouldUseMobileLayout) ...[
                Row(
                  children: [
                    _buildLanguageToggle(languageService, true),
                    const SizedBox(width: 12),
                    // Enhanced mobile menu button - More reliable and clickable
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onMenuTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopNavigation(BuildContext context, LanguageService languageService, bool isCompact) {
    final navItems = [
      {'key': 'home', 'route': '/home'},
      {'key': 'aboutUs', 'route': '/about'},
      {'key': 'ourServices', 'route': '/categories'},
      {'key': 'faqs', 'route': '/faqs'},
      {'key': 'contactUs', 'route': '/contact'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: navItems.map((item) => _buildNavItem(
        context,
        item['key']!,
        item['route']!,
        languageService,
        currentPage == item['key'],
        isCompact,
      )).toList(),
    );
  }

  Widget _buildNavItem(BuildContext context, String key, String route, LanguageService languageService, bool isSelected, bool isCompact) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: 4,
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
            horizontal: isCompact ? 8 : 16,
            vertical: 6,
          ),
        ),
        child: Text(
          AppStrings.getString(key, languageService.currentLanguage),
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.black87,
            fontSize: isCompact ? 14 : 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(LanguageService languageService, bool isCompact) {
    return GestureDetector(
      onTap: () {
        languageService.toggleLanguage();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 12,
          vertical: isCompact ? 3 : 6,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
        ),
        child: Text(
          languageService.currentLanguage == 'ar' ? 'EN' : 'العربية',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: isCompact ? 9 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButtons(BuildContext context, LanguageService languageService, bool shouldStack, bool isCompact) {
    // If buttons should be stacked, use Column layout to prevent overlap
    if (shouldStack) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoginButton(context, languageService, isCompact),
          const SizedBox(height: 8),
          _buildSignupButton(context, languageService, isCompact),
        ],
      );
    }
    
    // Otherwise, use Row layout for side-by-side buttons
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoginButton(context, languageService, isCompact),
        const SizedBox(width: 8),
        _buildSignupButton(context, languageService, isCompact),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, LanguageService languageService, bool isCompact) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/login');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 6 : 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        AppStrings.getString('login', languageService.currentLanguage),
        style: TextStyle(
          color: Colors.white,
          fontSize: isCompact ? 12 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSignupButton(BuildContext context, LanguageService languageService, bool isCompact) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, '/signup');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 6 : 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        AppStrings.getString('signUp', languageService.currentLanguage),
        style: TextStyle(
          fontSize: isCompact ? 12 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class SharedMobileDrawer extends StatelessWidget {
  final String? currentPage;

  const SharedMobileDrawer({
    super.key,
    this.currentPage,
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
                    Expanded(
                      child: Text(
                        AppStrings.getString('appName', languageService.currentLanguage),
                        style: const TextStyle(
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
                    Expanded(
                      child: _buildDrawerLanguageToggle(languageService),
                    ),
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
}
