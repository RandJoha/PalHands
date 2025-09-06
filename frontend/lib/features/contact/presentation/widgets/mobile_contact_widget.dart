import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/responsive_service.dart';
import '../../../../shared/services/reports_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/shared_navigation.dart';
import '../../../../shared/widgets/shared_hero_section.dart';
import '../../../../shared/widgets/app_toast.dart';
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
  void initState() {
    super.initState();
    // Check for stored purpose after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForStoredPurpose();
    });
  }

  // Check for stored purpose and restore it
  void _checkForStoredPurpose() async {
    final storedPurpose = await ContactPurposeSelector.getAndClearStoredPurpose();
    if (kDebugMode) {
      print('🔍 Checking for stored purpose: ${storedPurpose != null ? storedPurpose.toString() : 'None'}');
    }
    if (storedPurpose != null && mounted) {
      if (kDebugMode) {
        print('✅ Restoring stored purpose: ${storedPurpose.toString()}');
      }
      setState(() {
        _selectedPurpose = storedPurpose;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onFormSubmitted(Map<String, dynamic> formData) async {
    // Submit the form data directly (user is already authenticated since they selected a purpose)
    await _submitFormData(formData);
  }

  // Separate method to submit form data (used for both immediate and pending submissions)
  Future<void> _submitFormData(Map<String, dynamic> formData) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
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
      final reportData = <String, dynamic>{
        'reportCategory': reportCategory,
        'description': (formData['whatWentWrong'] ?? formData['otherDetails'] ?? formData['problemDescription'] ?? formData['ideaDescription'] ?? 'No description provided').toString(),
        'contactEmail': (formData['contactEmail'] ?? 'anonymous@example.com').toString(),
        'contactName': (formData['yourName'] ?? 'Anonymous User').toString(),
      };
      
      // Debug: Print the actual description value
      if (kDebugMode) {
        print('🔍 Original description: "${reportData['description']}"');
        print('🔍 Description length: ${(reportData['description'] as String).length}');
        print('🔍 Form data keys: ${formData.keys.toList()}');
        print('🔍 otherDetails value: "${formData['otherDetails']}"');
      }
      
      // Ensure description meets minimum length requirement (backend requires 10+ chars)
      final currentDescription = reportData['description'] as String;
      if (currentDescription.isEmpty || currentDescription == 'No description provided' || currentDescription.length < 10) {
        reportData['description'] = '';
        if (kDebugMode) {
          print('⚠️ Replaced short/empty description with minimal text');
        }
      } else {
        if (kDebugMode) {
          print('✅ Keeping original description: "${currentDescription}"');
        }
      }

      // Add specific fields based on category
      if (reportCategory == 'user_issue') {
        // Set default issueType since field was removed from form
        reportData['issueType'] = 'other';
        reportData['reportedName'] = (formData['serviceName'] ?? 'Unknown Service').toString();
        reportData['reportedType'] = 'user'; // Required for user_issue reports
        reportData['reportedUserRole'] = 'client'; // User is reporting a service provider (client)
        // Add partyInfo for user_issue reports (required by validator)
        reportData['partyInfo'] = {
          'reporterName': (formData['yourName'] ?? 'Anonymous').toString(),
          'reporterEmail': (formData['contactEmail'] ?? 'anonymous@example.com').toString(),
          'reportedEmail': (formData['reportedEmail'] ?? 'unknown@example.com').toString(),
        };
      } else if (reportCategory == 'feature_suggestion') {
        // Only add ideaTitle if it has a meaningful value
        final ideaTitle = formData['ideaTitle'];
        if (ideaTitle != null && ideaTitle.toString().trim().isNotEmpty) {
          reportData['ideaTitle'] = ideaTitle.toString().trim();
        }
        
        // Only add communityBenefit if it has a meaningful value
        final communityBenefit = formData['howItHelpsCommunity'];
        if (communityBenefit != null && communityBenefit.toString().trim().isNotEmpty) {
          reportData['communityBenefit'] = communityBenefit.toString().trim();
        }
      } else if (reportCategory == 'service_category_request') {
        reportData['serviceName'] = (formData['newServiceName'] ?? 'New Service Category').toString();
        reportData['categoryFit'] = (formData['whichCategory'] ?? 'This service fits well in the requested category.').toString();
        reportData['importanceReason'] = (formData['whyImportant'] ?? 'This service category is important for users.').toString();
        
        // Set description to only the importance reason if provided
        final importanceReason = formData['whyImportant'];
        if (importanceReason != null && importanceReason.toString().trim().isNotEmpty) {
          reportData['description'] = importanceReason.toString().trim();
        }
      } else if (reportCategory == 'technical_issue') {
        reportData['device'] = (formData['device'] ?? 'Unknown Device').toString();
        reportData['os'] = (formData['os'] ?? 'Unknown OS').toString();
        reportData['appVersion'] = (formData['appVersion'] ?? 'Unknown Version').toString();
      }

      // Add evidence if any files were uploaded
      final attachScreenshot = formData['attachScreenshot'];
      if (attachScreenshot != null && attachScreenshot.toString().isNotEmpty) {
        reportData['evidence'] = [attachScreenshot.toString()];
      } else {
        reportData['evidence'] = [];
      }

      // Add idempotency key for authenticated users only
      if (authService.isAuthenticated) {
        final userId = authService.currentUser?['_id'] ?? 'unknown';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        reportData['idempotencyKey'] = 'cf_${timestamp}_${reportCategory}_${userId}';
      }

      // Submit the report
      final response = await reportsService.createReport(
        reportCategory: reportData['reportCategory'] as String,
        reportedType: reportData['reportedType'] as String?,
        reportedId: reportData['reportedId'] as String?,
        reportedUserRole: reportData['reportedUserRole'] as String?,
        reportedName: reportData['reportedName'] as String?,
        issueType: reportData['issueType'] as String?,
        description: reportData['description'] as String,
        contactEmail: reportData['contactEmail'] as String?,
        contactName: reportData['contactName'] as String?,
        subject: reportData['subject'] as String?,
        requestedCategory: reportData['requestedCategory'] as String?,
        serviceName: reportData['serviceName'] as String?,
        categoryFit: reportData['categoryFit'] as String?,
        importanceReason: reportData['importanceReason'] as String?,
        partyInfo: reportData['partyInfo'] as Map<String, dynamic>?,
        ideaTitle: reportData['ideaTitle'] as String?,
        communityBenefit: reportData['communityBenefit'] as String?,
        device: reportData['device'] as String?,
        os: reportData['os'] as String?,
        appVersion: reportData['appVersion'] as String?,
        relatedBookingId: reportData['relatedBookingId'] as String?,
        reportedServiceId: reportData['reportedServiceId'] as String?,
        evidence: (reportData['evidence'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        idempotencyKey: reportData['idempotencyKey'] as String?,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response['success'] == true) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Report Submitted',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Your report has been submitted and saved to the database.',
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
            controller: _scrollController,
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
      key: _formKey,
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
          
          // Debug button (only in debug mode)
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Debug: Auth Status'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Authenticated: ${authService.isAuthenticated}'),
                          Text('Token: ${authService.token?.substring(0, 50)}...'),
                          Text('User: ${authService.currentUser?['email'] ?? 'None'}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Debug: Check Auth Status'),
              ),
            ),
          ],
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
      child: const Column(
        children: [
          // Removed copyright
          SizedBox.shrink(),
        ],
      ),
    );
  }
} 