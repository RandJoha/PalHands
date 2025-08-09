import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/widgets/animated_handshake.dart';
import '../../../../shared/widgets/tatreez_pattern.dart';

class WebAboutWidget extends StatelessWidget {
  const WebAboutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(languageService),
              _buildHeroSection(languageService),
              _buildMissionSection(languageService),
              _buildValuesSection(languageService),
              _buildWhoWeServeSection(languageService),

              _buildHowItWorksSection(languageService),
              _buildOurStorySection(languageService),
              _buildContactSection(languageService),
              _buildFooter(languageService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo and app name
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const AnimatedHandshake(
                  size: 25,
                  color: Colors.white,
                  animationDuration: Duration(milliseconds: 2000),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                AppStrings.getString('appName', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          // Navigation - centered for Arabic
          if (languageService.currentLanguage == 'ar')
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildNavLink('home', languageService),
                  _buildNavLink('aboutUs', languageService, isSelected: true),
                  _buildNavLink('ourServices', languageService),
                  _buildNavLink('contactUs', languageService),
                ],
              ),
            )
          else ...[
            const Spacer(),
            Row(
              children: [
                _buildNavLink('home', languageService),
                _buildNavLink('aboutUs', languageService, isSelected: true),
                _buildNavLink('ourServices', languageService),
                _buildNavLink('contactUs', languageService),
              ],
            ),
          ],
          const SizedBox(width: 24),
          // Language toggle
          _buildLanguageToggle(languageService),
        ],
      ),
    );
  }

  Widget _buildNavLink(String key, LanguageService languageService, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Builder(
        builder: (context) => Directionality(
          textDirection: languageService.textDirection,
          child: TextButton(
            onPressed: () {
              if (key == 'home') {
                Navigator.pushReplacementNamed(context, '/home');
              } else if (key == 'ourServices') {
                Navigator.pushNamed(context, '/categories');
              } else if (key == 'contactUs') {
                Navigator.pushNamed(context, '/contact');
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              AppStrings.getString(key, languageService.currentLanguage),
              style: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(LanguageService languageService) {
    return GestureDetector(
      onTap: () {
        languageService.toggleLanguage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          languageService.currentLanguage == 'ar' ? 'EN' : 'العربية',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.getString('aboutUs', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.getString('appTagline', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const AnimatedHandshake(
                  size: 150,
                  color: AppColors.primary,
                  animationDuration: Duration(milliseconds: 3000),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Text(
            '🎯 ${AppStrings.getString('missionStatement', languageService.currentLanguage).split('.')[0]}',
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            AppStrings.getString('missionStatement', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: Colors.black87,
              height: 1.6,
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          Text(
            AppStrings.getString('ourValues', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive grid based on available width
              int crossAxisCount;
              if (constraints.maxWidth > 1200) {
                crossAxisCount = 5;
              } else if (constraints.maxWidth > 900) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 2;
              }
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.2,
                ),
                itemCount: values.length,
                itemBuilder: (context, index) {
                  return _buildValueCard(
                    values[index]['icon'] as IconData,
                    AppStrings.getString(values[index]['title'] as String, languageService.currentLanguage),
                  );
                },
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
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 36,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWhoWeServeSection(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.getString('whoWeServe', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.getString('whoWeServeDescription', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 60),
          Expanded(
            flex: 1,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.people_outline,
                  size: 120,
                  color: AppColors.primary,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.getString('howItWorks', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            AppStrings.getString('howItWorksDescription', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Text(
            AppStrings.getString('ourStory', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            AppStrings.getString('ourStoryDescription', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        children: [
          Text(
            AppStrings.getString('wantToLearnMore', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildContactButton(
                Icons.email,
                AppStrings.getString('emailUs', languageService.currentLanguage),
                () {
                  // TODO: Open email
                },
              ),
              const SizedBox(width: 24),
              _buildContactButton(
                Icons.phone,
                AppStrings.getString('callUs', languageService.currentLanguage),
                () {
                  // TODO: Open phone
                },
              ),
              const SizedBox(width: 24),
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
    return ElevatedButton.icon(
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
    );
  }

  Widget _buildFooter(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.getString('copyright', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
} 