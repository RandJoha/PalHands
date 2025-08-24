import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/responsive_service.dart';
import '../../../../shared/widgets/shared_navigation.dart';
import '../../../../shared/widgets/shared_hero_section.dart';

class MobileAboutWidget extends StatefulWidget {
  const MobileAboutWidget({super.key});

  @override
  State<MobileAboutWidget> createState() => _MobileAboutWidgetState();
}

class _MobileAboutWidgetState extends State<MobileAboutWidget> with TickerProviderStateMixin {
  late AnimationController _bannerController;
  late AnimationController _cardController;
  late Animation<double> _bannerAnimation;
  late Animation<double> _cardAnimation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _bannerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeInOut,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));
    
    _bannerController.forward();
    _cardController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ResponsiveService>(
      builder: (context, languageService, responsiveService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
  final shouldUseMobileLayout = responsiveService.shouldUseMobileLayout(screenWidth);
  final isCollapsed = responsiveService.shouldCollapseNavigation(screenWidth);
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFFDF5EC),
          drawer: (shouldUseMobileLayout || isCollapsed) ? const SharedMobileDrawer(currentPage: 'aboutUs') : null,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Shared Navigation
                SharedNavigation(
                  currentPage: 'aboutUs',
                  showAuthButtons: false,
                  onMenuTap: (shouldUseMobileLayout || isCollapsed) ? () {
                    _scaffoldKey.currentState?.openDrawer();
                  } : null,
                  isMobile: shouldUseMobileLayout || isCollapsed,
                ),
                // Shared Hero Section
                SharedHeroSections.aboutHero(
                  languageService: languageService,
                  isMobile: shouldUseMobileLayout || isCollapsed,
                ),
                _buildMissionSection(languageService),
                _buildValuesSection(languageService),
                _buildWhoWeServeSection(languageService),
                _buildHowItWorksSection(languageService),
                _buildOurStorySection(languageService),
                _buildContactSection(languageService),
                _buildFooter(languageService),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionSection(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Text(
            '🎯 ${AppStrings.getString('missionStatement', languageService.currentLanguage).split('.')[0]}',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValuesSection(LanguageService languageService) {
    final values = [
      {'icon': Icons.people, 'title': 'communityEmpowerment'},
      {'icon': Icons.star, 'title': 'localTalentFirst'},
      {'icon': Icons.verified, 'title': 'trustAndTransparency'},
      {'icon': Icons.favorite, 'title': 'culturalRespect'},
      {'icon': Icons.security, 'title': 'simplicityAndSafety'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          Text(
            AppStrings.getString('ourValues', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: values.length,
            itemBuilder: (context, index) {
              return _buildValueCard(
                values[index]['icon'] as IconData,
                AppStrings.getString(values[index]['title'] as String, languageService.currentLanguage),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWhoWeServeSection(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('whoWeServe', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.getString('whoWeServeDescription', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.people_outline,
                size: 80,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildHowItWorksSection(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.getString('howItWorks', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.getString('howItWorksDescription', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOurStorySection(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Text(
            AppStrings.getString('ourStory', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.getString('ourStoryDescription', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        children: [
          Text(
            AppStrings.getString('wantToLearnMore', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildContactButton(
                Icons.email,
                AppStrings.getString('emailUs', languageService.currentLanguage),
                () {
                  // TODO: Open email
                },
              ),
              const SizedBox(height: 12),
              _buildContactButton(
                Icons.phone,
                AppStrings.getString('callUs', languageService.currentLanguage),
                () {
                  // TODO: Open phone
                },
              ),
              const SizedBox(height: 12),
              _buildContactButton(
                Icons.share,
                AppStrings.getString('followUs', languageService.currentLanguage),
                () {
                  // TODO: Open social media
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}