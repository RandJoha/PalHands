import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/reports_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/shared_navigation.dart';
import '../../../../shared/services/responsive_service.dart';
import '../../../../shared/widgets/shared_hero_section.dart';
import '../../../../shared/widgets/app_toast.dart';
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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _formKey = GlobalKey();

  void _onPurposeSelected(ContactPurpose purpose) {
    setState(() {
      _selectedPurpose = purpose;
    });
    
    // Scroll to form after a short delay to ensure the form is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_formKey.currentContext != null) {
        Scrollable.ensureVisible(
          _formKey.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onConsentChanged(bool? value) {
    setState(() {
      _consentChecked = value ?? false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onFormSubmitted(Map<String, dynamic> formData) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Submitting report...'),
          ],
        ),
      ),
    );

    try {
      // Debug: Check if user is authenticated
      final authService = Provider.of<AuthService>(context, listen: false);
      if (kDebugMode) {
        print('🔐 User authenticated: ${authService.isAuthenticated}');
        print('🔐 User token: ${authService.token?.substring(0, 20)}...');
        print('🔐 Current user: ${authService.currentUser}');
      }
      
      final reportsService = ReportsService();
      
      // Map contact purpose to report category
      String reportCategory;
      switch (_selectedPurpose) {
        case ContactPurpose.reportServiceProvider:
          reportCategory = 'user_issue';
          break;
        case ContactPurpose.suggestFeature:
          reportCategory = 'feature_suggestion';
          break;
        case ContactPurpose.requestServiceCategory:
          reportCategory = 'service_category_request';
          break;
        case ContactPurpose.technicalProblem:
          reportCategory = 'technical_issue';
          break;
        case ContactPurpose.other:
          reportCategory = 'other';
          break;
        default:
          reportCategory = 'other';
      }

      // Create report data
      final reportData = {
        'reportCategory': reportCategory,
        'description': formData['whatWentWrong'] ?? formData['otherDetails'] ?? formData['problemDescription'] ?? formData['ideaDescription'] ?? 'No description provided',
        'contactEmail': formData['contactEmail'] ?? '',
        'contactName': formData['yourName'] ?? '',
      };
      
      // Ensure description meets minimum length requirement
      if ((reportData['description'] as String).length < 3) {
        reportData['description'] = 'A detailed description of the issue or request.';
      }

      // Add specific fields based on category
      if (reportCategory == 'user_issue') {
        reportData['issueType'] = formData['issueType'] ?? 'other';
        reportData['reportedName'] = formData['serviceName'] ?? '';
        // Add partyInfo for user_issue reports (required by validator)
        reportData['partyInfo'] = {
          'reporterName': formData['yourName'] ?? '',
          'reporterEmail': formData['contactEmail'] ?? '',
          'reportedEmail': '', // Optional field
        };
      } else if (reportCategory == 'feature_suggestion') {
        reportData['ideaTitle'] = formData['ideaTitle'] ?? '';
        reportData['communityBenefit'] = formData['howItHelpsCommunity'] ?? '';
        // For feature suggestions, the description should come from ideaDescription
        reportData['description'] = formData['ideaDescription'] ?? 'No description provided';
        
        // Ensure minimum length requirements are met
        if ((reportData['ideaTitle'] as String).length < 3) {
          reportData['ideaTitle'] = 'Feature Suggestion'; // Default title if too short
        }
        if ((reportData['communityBenefit'] as String).length < 5) {
          reportData['communityBenefit'] = 'This feature will help improve the platform for all users.'; // Default benefit if too short
        }
        if ((reportData['description'] as String).length < 10) {
          reportData['description'] = 'A new feature suggestion for the platform.'; // Default description if too short
        }
      } else if (reportCategory == 'service_category_request') {
        reportData['serviceName'] = formData['newServiceName'] ?? '';
        reportData['importanceReason'] = formData['whyImportant'] ?? '';
        reportData['categoryFit'] = formData['whichCategory'] ?? '';
        
        // Ensure minimum length requirements are met
        if ((reportData['serviceName'] as String).length < 2) {
          reportData['serviceName'] = 'New Service'; // Default name if too short
        }
        if ((reportData['importanceReason'] as String).length < 5) {
          reportData['importanceReason'] = 'This service category is important for the community.'; // Default reason if too short
        }
        if ((reportData['categoryFit'] as String).length < 2) {
          reportData['categoryFit'] = 'General'; // Default category if too short
        }
      }

      // Debug: Print the form data being sent
      if (kDebugMode) {
        print('📝 Form data: $formData');
        print('📝 Report data: $reportData');
      }

      // Create the report with only the fields that are present
      final response = await reportsService.createReport(
        reportCategory: reportCategory,
        description: reportData['description'],
        contactEmail: reportData['contactEmail'],
        contactName: reportData['contactName'],
        issueType: reportData['issueType'],
        reportedName: reportData['reportedName'],
        ideaTitle: reportData['ideaTitle'],
        communityBenefit: reportData['communityBenefit'],
        serviceName: reportData['serviceName'],
        importanceReason: reportData['importanceReason'],
        categoryFit: reportData['categoryFit'],
        partyInfo: reportData['partyInfo'],
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response['success'] == true) {
        // Show success dialog
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
      } else {
        // Show error message
        AppToast.show(
          context, 
          message: response['message'] ?? 'Failed to submit report', 
          type: AppToastType.error
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      AppToast.show(
        context, 
        message: 'Network error: $e', 
        type: AppToastType.error
      );
    }
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
            controller: _scrollController,
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
            key: _formKey,
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