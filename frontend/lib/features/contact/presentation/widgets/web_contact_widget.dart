import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/widgets/shared_navigation.dart';
import '../../../../shared/services/responsive_service.dart';
import '../../../../shared/widgets/shared_hero_section.dart';
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
        final screenWidth = MediaQuery.of(context).size.width;
        final isCollapsed = context.read<ResponsiveService>().shouldCollapseNavigation(screenWidth);
        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC),
          drawer: isCollapsed ? const SharedMobileDrawer(currentPage: 'contactUs') : null,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Shared Navigation
                SharedNavigation(
                  currentPage: 'contactUs',
                  showAuthButtons: true,
                  isMobile: isCollapsed,
                ),
                // Shared Hero Section
                SharedHeroSections.contactHero(
                  languageService: languageService,
                  isMobile: false,
                ),
                _buildContentSection(languageService),
                _buildFooter(languageService),
              ],
            ),
          ),
        );
      },
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
            color: AppColors.primary.withValues(alpha: 0.05),
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
              const QuickAccessWidgets(),
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
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
  child: const SizedBox.shrink(),
    );
  }
} 