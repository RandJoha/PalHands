import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/widgets/animated_handshake.dart';
import '../../../../shared/widgets/tatreez_pattern.dart';
import '../../data/contact_data.dart';
import 'contact_purpose_selector.dart';
import 'contact_form.dart';
import 'quick_access_widgets.dart';

class WebContactWidget extends StatefulWidget {
  const WebContactWidget({super.key});

  @override
  State<WebContactWidget> createState() => _WebContactWidgetState();
}

class _WebContactWidgetState extends State<WebContactWidget> {
  ContactPurpose? _selectedPurpose;
  bool _consentChecked = false;

  void _onPurposeSelected(ContactPurpose purpose) {
    setState(() {
      _selectedPurpose = purpose;
    });
  }

  void _onConsentChanged(bool? value) {
    setState(() {
      _consentChecked = value ?? false;
    });
  }

  void _onFormSubmitted(Map<String, dynamic> formData) {
    // TODO: Implement form submission logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppStrings.getString('formSubmitted', context.read<LanguageService>().currentLanguage),
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppStrings.getString('thankYouMessage', context.read<LanguageService>().currentLanguage),
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedPurpose = null;
                _consentChecked = false;
              });
            },
            child: Text(
              'OK',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC),
          body: Row(
            children: [
              // Sidebar Navigation
              _buildSidebar(languageService),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(languageService),
                      _buildHeroSection(languageService),
                      _buildContentSection(languageService),
                      _buildFooter(languageService),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(LanguageService languageService) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo and app name
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const AnimatedHandshake(
                    size: 16,
                    color: Colors.white,
                    animationDuration: Duration(milliseconds: 2000),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.getString('appName', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  title: AppStrings.getString('home', languageService.currentLanguage),
                  onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                  languageService: languageService,
                ),
                _buildNavItem(
                  icon: Icons.info,
                  title: AppStrings.getString('aboutUs', languageService.currentLanguage),
                  onTap: () => Navigator.pushNamed(context, '/about'),
                  languageService: languageService,
                ),
                _buildNavItem(
                  icon: Icons.cleaning_services,
                  title: AppStrings.getString('ourServices', languageService.currentLanguage),
                  onTap: () => Navigator.pushNamed(context, '/categories'),
                  languageService: languageService,
                ),
                _buildNavItem(
                  icon: Icons.question_answer,
                  title: AppStrings.getString('faqs', languageService.currentLanguage),
                  onTap: () => Navigator.pushNamed(context, '/faqs'),
                  languageService: languageService,
                ),
                _buildNavItem(
                  icon: Icons.contact_support,
                  title: AppStrings.getString('contactUs', languageService.currentLanguage),
                  onTap: () {},
                  isSelected: true,
                  languageService: languageService,
                ),
              ],
            ),
          ),
          
          // Language toggle
          Container(
            padding: const EdgeInsets.all(8),
            child: _buildLanguageToggle(languageService),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    required LanguageService languageService,
  }) {
    return Directionality(
      textDirection: languageService.textDirection,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.black87,
            size: 18,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
          onTap: onTap,
          selected: isSelected,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          selectedTileColor: AppColors.primary.withOpacity(0.1),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          languageService.currentLanguage == 'ar' ? 'EN' : 'العربية',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.getString('contactPageTitle', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
      child: Stack(
        children: [
          // Background Tatreez pattern
          Positioned(
            top: 40,
            right: 40,
            child: Opacity(
              opacity: 0.1,
              child: const TatreezPattern(
                size: 120,
                opacity: 0.3,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            child: Opacity(
              opacity: 0.1,
              child: const TatreezPattern(
                size: 100,
                opacity: 0.3,
              ),
            ),
          ),
          // Content
          Column(
            children: [
              Text(
                AppStrings.getString('contactPageDescription', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  AppStrings.getString('communityQuote', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(LanguageService languageService) {
    return Column(
      children: [
        // Contact Purpose Selector Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.getString('contactPurposeTitle', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              ContactPurposeSelector(
                selectedPurpose: _selectedPurpose,
                onPurposeSelected: _onPurposeSelected,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Quick Access Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.getString('quickAccessTitle', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              QuickAccessWidgets(),
            ],
          ),
        ),
        
        // Contact Form Section (when purpose is selected)
        if (_selectedPurpose != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContactForm(
                  purpose: _selectedPurpose!,
                  consentChecked: _consentChecked,
                  onConsentChanged: _onConsentChanged,
                  onSubmit: _onFormSubmitted,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.getString('responseTimeEstimate', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Text(
        AppStrings.getString('copyright', languageService.currentLanguage),
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: Colors.black54,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
} 