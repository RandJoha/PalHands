import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/responsive_service.dart';
import '../../../../shared/widgets/shared_navigation.dart';
import '../../../../shared/widgets/shared_hero_section.dart';
import '../../data/contact_data.dart';
import '../widgets/contact_form.dart';
import '../widgets/quick_access_widgets.dart';
import 'contact_purpose_selector.dart';

class MobileContactWidget extends StatefulWidget {
  const MobileContactWidget({super.key});

  @override
  State<MobileContactWidget> createState() => _MobileContactWidgetState();
}

class _MobileContactWidgetState extends State<MobileContactWidget> {
  ContactPurpose? _selectedPurpose;
  bool _consentChecked = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    return Consumer2<LanguageService, ResponsiveService>(
      builder: (context, languageService, responsiveService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
  final shouldUseMobileLayout = responsiveService.shouldUseMobileLayout(screenWidth);
  final isCollapsed = responsiveService.shouldCollapseNavigation(screenWidth);
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFFDF5EC),
          drawer: (shouldUseMobileLayout || isCollapsed) ? const SharedMobileDrawer(currentPage: 'contactUs') : null,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Shared Navigation
                SharedNavigation(
                  currentPage: 'contactUs',
                  showAuthButtons: false,
                  onMenuTap: (shouldUseMobileLayout || isCollapsed) ? () {
                    _scaffoldKey.currentState?.openDrawer();
                  } : null,
                  isMobile: shouldUseMobileLayout || isCollapsed,
                ),
                // Shared Hero Section
                SharedHeroSections.contactHero(
                  languageService: languageService,
                  isMobile: shouldUseMobileLayout,
                ),
                // Purpose selector visible on mobile, above quick access
                Container(
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ContactPurposeSelector(
                        selectedPurpose: _selectedPurpose,
                        onPurposeSelected: _onPurposeSelected,
                      ),
                    ],
                  ),
                ),
                _buildContactFormSection(languageService),
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

  Widget _buildContactFormSection(LanguageService languageService) {
    if (_selectedPurpose == null) {
      return const SizedBox.shrink();
    }
    
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
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
    );
  }

  Widget _buildQuickAccessSection(LanguageService languageService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
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
          const QuickAccessWidgets(),
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
          // Removed copyright
          const SizedBox.shrink(),
        ],
      ),
    );
  }
} 