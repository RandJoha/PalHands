import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/services/language_service.dart';
import 'tatreez_pattern.dart';

class SharedHeroSection extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget>? actionButtons;
  final Widget? leadingWidget;
  final String? backgroundPattern;
  final bool isMobile;
  final EdgeInsets? padding;
  final VoidCallback? onBookNowPressed;
  final VoidCallback? onRegisterPressed;

  const SharedHeroSection({
    super.key,
    required this.title,
    required this.description,
    this.actionButtons,
    this.leadingWidget,
    this.backgroundPattern,
    this.isMobile = false,
    this.padding,
    this.onBookNowPressed,
    this.onRegisterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 40,
            vertical: isMobile ? 24 : 40,
          ),
          padding: padding ?? EdgeInsets.all(isMobile ? 20 : 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: isMobile ? 1 : 2,
            ),
          ),
          child: Stack(
            children: [
              // Background patterns
              if (backgroundPattern != null) ...[
                Positioned(
                  top: isMobile ? 20 : 40,
                  right: isMobile ? 20 : 40,
                  child: Opacity(
                    opacity: 0.1,
                    child: TatreezPattern(
                      size: isMobile ? 60 : 80,
                      opacity: 0.3,
                    ),
                  ),
                ),
                Positioned(
                  bottom: isMobile ? 20 : 40,
                  left: isMobile ? 20 : 40,
                  child: Opacity(
                    opacity: 0.1,
                    child: TatreezPattern(
                      size: isMobile ? 40 : 60,
                      opacity: 0.3,
                    ),
                  ),
                ),
              ],
              
              // Content
              _buildContent(context, languageService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, LanguageService languageService) {
    if (isMobile) {
      return _buildMobileContent(context, languageService);
    } else {
      return _buildDesktopContent(context, languageService);
    }
  }

  Widget _buildMobileContent(BuildContext context, LanguageService languageService) {
    return Column(
      children: [
        // Leading widget (if provided)
        if (leadingWidget != null) ...[
          leadingWidget!,
          const SizedBox(height: 24),
        ],
        
        // Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        // Description
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Action buttons
        if (actionButtons != null && actionButtons!.isNotEmpty) ...[
          const SizedBox(height: 24),
          ...actionButtons!.map((button) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: button,
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildDesktopContent(BuildContext context, LanguageService languageService) {
    return Row(
      children: [
        // Leading widget (if provided)
        if (leadingWidget != null) ...[
          leadingWidget!,
          const SizedBox(width: 40),
        ],
        
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                description,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              
              // Action buttons
              if (actionButtons != null && actionButtons!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: actionButtons!.map((button) => button).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Predefined hero sections for common use cases
class SharedHeroSections {
  static Widget homeHero({
    required LanguageService languageService,
    bool isMobile = false,
    VoidCallback? onBookNowPressed,
  }) {
    return SharedHeroSection(
      title: AppStrings.getString('heroTitle', languageService.currentLanguage),
      description: AppStrings.getString('professionalCleaningDescription', languageService.currentLanguage),
      leadingWidget: Container(
        width: isMobile ? 200 : 280,
        height: isMobile ? 200 : 280,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isMobile ? 100 : 140),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: isMobile ? 2 : 3,
          ),
        ),
        child: Icon(
          Icons.person,
          size: isMobile ? 80 : 120,
          color: AppColors.primary,
        ),
      ),
      actionButtons: [
        ElevatedButton(
          onPressed: onBookNowPressed ?? () {
            // Default action - can be overridden by parent
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 32,
              vertical: isMobile ? 12 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
            ),
          ),
          child: Text(
            AppStrings.getString('bookNow', languageService.currentLanguage),
            style: TextStyle(
              fontSize: isMobile ? 14 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      isMobile: isMobile,
      onBookNowPressed: onBookNowPressed,
    );
  }

  static Widget aboutHero({
    required LanguageService languageService,
    bool isMobile = false,
  }) {
    return SharedHeroSection(
      title: AppStrings.getString('aboutUs', languageService.currentLanguage),
      description: AppStrings.getString('appTagline', languageService.currentLanguage),
      leadingWidget: Container(
        width: isMobile ? 150 : 200,
        height: isMobile ? 150 : 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 15 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.handshake,
            size: 60,
            color: AppColors.primary,
          ),
        ),
      ),
      isMobile: isMobile,
    );
  }

  static Widget servicesHero({
    required LanguageService languageService,
    bool isMobile = false,
    VoidCallback? onBookNowPressed,
    VoidCallback? onRegisterPressed,
  }) {
    return SharedHeroSection(
      title: AppStrings.getString('allServices', languageService.currentLanguage),
      description: AppStrings.getString('connectWithTrustedServiceProvider', languageService.currentLanguage),
      leadingWidget: Container(
        width: isMobile ? 80 : 120,
        height: isMobile ? 80 : 120,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isMobile ? 15 : 20),
        ),
        child: Icon(
          Icons.category,
          size: isMobile ? 40 : 60,
          color: AppColors.primary,
        ),
      ),
      actionButtons: [
        if (!isMobile)
          OutlinedButton(
            onPressed: onRegisterPressed ?? () {
              // Default action - can be overridden by parent
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppStrings.getString('registerAsServiceProvider', languageService.currentLanguage),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
      isMobile: isMobile,
      onBookNowPressed: onBookNowPressed,
      onRegisterPressed: onRegisterPressed,
    );
  }

  static Widget faqsHero({
    required LanguageService languageService,
    bool isMobile = false,
  }) {
    return SharedHeroSection(
      title: AppStrings.getString('faqPageTitle', languageService.currentLanguage),
      description: AppStrings.getString('faqPageDescription', languageService.currentLanguage),
      backgroundPattern: 'default',
      isMobile: isMobile,
    );
  }

  static Widget contactHero({
    required LanguageService languageService,
    bool isMobile = false,
  }) {
    return SharedHeroSection(
      title: AppStrings.getString('contactUs', languageService.currentLanguage),
      description: AppStrings.getString('contactPageDescription', languageService.currentLanguage),
      backgroundPattern: 'default',
      isMobile: isMobile,
    );
  }
}


