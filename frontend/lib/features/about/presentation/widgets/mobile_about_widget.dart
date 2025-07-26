import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/widgets/animated_handshake.dart';
import '../../../../shared/widgets/tatreez_pattern.dart';

class MobileAboutWidget extends StatefulWidget {
  const MobileAboutWidget({super.key});

  @override
  State<MobileAboutWidget> createState() => _MobileAboutWidgetState();
}

class _MobileAboutWidgetState extends State<MobileAboutWidget> {

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC),
          drawer: _buildDrawer(languageService),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(languageService),
                _buildHeroSection(languageService),
                _buildMissionSection(languageService),
                _buildValuesSection(languageService),
                _buildWhoWeServeSection(languageService),
                _buildCulturalIdentitySection(languageService),
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

  Widget _buildHeader(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AnimatedHandshake(
                  size: 20,
                  color: Colors.white,
                  animationDuration: Duration(milliseconds: 2000),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.getString('appName', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Language toggle
          _buildLanguageToggle(languageService),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(LanguageService languageService) {
    return GestureDetector(
      onTap: () {
        languageService.toggleLanguage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          languageService.currentLanguage == 'ar' ? 'EN' : 'العربية',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(LanguageService languageService) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const AnimatedHandshake(
                    size: 30,
                    color: AppColors.primary,
                    animationDuration: Duration(milliseconds: 2000),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.getString('appName', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.home,
            title: AppStrings.getString('home', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            languageService: languageService,
          ),
          _buildDrawerItem(
            icon: Icons.info,
            title: AppStrings.getString('aboutUs', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
            },
            isSelected: true,
            languageService: languageService,
          ),
          _buildDrawerItem(
            icon: Icons.cleaning_services,
            title: AppStrings.getString('ourServices', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/categories');
            },
            languageService: languageService,
          ),
          _buildDrawerItem(
            icon: Icons.question_answer,
            title: AppStrings.getString('faqs', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/faqs');
            },
            languageService: languageService,
          ),
          _buildDrawerItem(
            icon: Icons.contact_support,
            title: AppStrings.getString('contactUs', languageService.currentLanguage),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to contact
            },
            languageService: languageService,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    required LanguageService languageService,
  }) {
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
      ),
    );
  }

  Widget _buildHeroSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
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
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
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
              size: 100,
              color: AppColors.primary,
              animationDuration: Duration(milliseconds: 3000),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.getString('aboutUs', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.getString('appTagline', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
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
          const SizedBox(height: 24),
          Text(
            AppStrings.getString('missionStatement', languageService.currentLanguage),
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

  Widget _buildValuesSection(LanguageService languageService) {
    final values = [
      {'icon': Icons.people, 'title': 'communityEmpowerment'},
      {'icon': Icons.star, 'title': 'localTalentFirst'},
      {'icon': Icons.verified, 'title': 'trustAndTransparency'},
      {'icon': Icons.favorite, 'title': 'culturalRespect'},
      {'icon': Icons.security, 'title': 'simplicityAndSafety'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
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
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
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
              color: AppColors.primary.withOpacity(0.1),
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

  Widget _buildCulturalIdentitySection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.getString('culturalIdentity', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: TatreezPattern(
                size: 80,
                opacity: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.getString('culturalIdentityDescription', languageService.currentLanguage),
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

  Widget _buildHowItWorksSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            AppStrings.getString('copyright', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}