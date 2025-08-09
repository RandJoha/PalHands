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

class MobileContactWidget extends StatefulWidget {
  const MobileContactWidget({super.key});

  @override
  State<MobileContactWidget> createState() => _MobileContactWidgetState();
}

class _MobileContactWidgetState extends State<MobileContactWidget> {
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
          drawer: _buildDrawer(languageService),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(languageService),
                _buildHeroSection(languageService),
                _buildPurposeSelector(languageService),
                if (_selectedPurpose != null) ...[
                  _buildFormSection(languageService),
                  const SizedBox(height: 24),
                ],
                _buildQuickAccessSection(languageService),
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
          // Hamburger menu
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.menu,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Logo and app name
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
          ),
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
              Navigator.pushNamed(context, '/about');
            },
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
            },
            isSelected: true,
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
      child: Stack(
        children: [
          // Background Tatreez pattern
          Positioned(
            top: 20,
            right: 20,
            child: Opacity(
              opacity: 0.1,
              child: const TatreezPattern(
                size: 80,
                opacity: 0.3,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Opacity(
              opacity: 0.1,
              child: const TatreezPattern(
                size: 60,
                opacity: 0.3,
              ),
            ),
          ),
          // Content
          Column(
            children: [
              const SizedBox(height: 24),
              Text(
                AppStrings.getString('contactPageTitle', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.getString('contactPageDescription', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  AppStrings.getString('communityQuote', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
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

  Widget _buildPurposeSelector(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('contactPurposeTitle', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ContactPurposeSelector(
            selectedPurpose: _selectedPurpose,
            onPurposeSelected: _onPurposeSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildQuickAccessSection(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 16),
          QuickAccessWidgets(),
        ],
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