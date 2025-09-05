import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Services
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/base_api_service.dart';
import '../services/service_categories_service.dart';

// Widget imports
import 'animated_handshake.dart';

// Web-specific signup widget
class WebSignupWidget extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;

  const WebSignupWidget({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<WebSignupWidget> createState() => _WebSignupWidgetState();
}

class _WebSignupWidgetState extends State<WebSignupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _ageController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  // Preserve scroll position during selections
  final ScrollController _scrollController = ScrollController();
  
  // Step management
  int _currentStep = 0;
  String? _selectedUserType;
  // Multi-select of categories and services (from DB)
  final ValueNotifier<Set<String>> _selectedCategoriesVN = ValueNotifier<Set<String>>(<String>{});
  final ValueNotifier<Set<String>> _selectedServicesVN = ValueNotifier<Set<String>>(<String>{});
  final Map<String, List<String>> _categoryServices = <String, List<String>>{};
  // Cache categories future to avoid re-fetch flicker
  late final Future<List<ServiceCategoryModel>> _categoriesFuture;
  // Track pending service loads to show a lightweight loader
  final ValueNotifier<int> _pendingServiceLoadsVN = ValueNotifier<int>(0);
  // Shared API service instance
  final ServiceCategoriesService _svc = ServiceCategoriesService();
  int _serviceProvidersCount = 1;
  String? _selectedLocation;
  String? _selectedStreet;
  
  // Available cities with their real streets - Palestinian cities
  final Map<String, List<String>> _cityStreets = {
    'jerusalem': [
      'salahuddin_street', 'damascus_gate_road', 'jaffa_road', 'king_george_street', 
      'ben_yehuda_street', 'agron_street', 'mamilla_street', 'yafo_street',
      'sultan_suleiman_street', 'nablus_road', 'ramallah_road', 'bethlehem_road'
    ],
    'ramallah': [
      'al_manara_square', 'rukab_street', 'main_street', 'al_balad', 'al_masyoun',
      'al_irsal_street', 'hospital_street', 'al_nahda_street', 'radio_street',
      'al_masayef_road', 'al_bireh_ramallah_road'
    ],
    'nablus': [
      'rafidia_street', 'al_najah_street', 'faisal_street', 'al_quds_street',
      'al_maidan_street', 'al_anbat_street', 'martyrs_street', 'al_nasr_street',
      'university_street', 'old_city_street'
    ],
    'hebron': [
      'al_shuhada_street', 'king_talal_street', 'al_salam_street', 'al_haramain_street',
      'al_manshiyya_street', 'polytechnic_university_road', 'al_thahiriyya_road',
      'al_fawwar_road', 'halhul_road', 'dura_road'
    ],
    'bethlehem': [
      'manger_street', 'pope_paul_vi_street', 'star_street', 'milk_grotto_street',
      'nativity_square', 'hebron_road', 'jerusalem_road', 'beit_sahour_road',
      'solomon_pools_street', 'rachel_tomb_road'
    ],
    'gaza': [
      'omar_mukhtar_street', 'al_rasheed_street', 'al_wahda_street', 'al_azhar_street',
      'al_nasr_street', 'beach_road', 'salah_al_din_street', 'al_thalateen_street',
      'industrial_road', 'al_shati_camp_road'
    ],
    'jenin': [
      'al_maidan_street', 'al_quds_street', 'hospital_street', 'al_salam_street',
      'freedom_fighters_street', 'al_yarmouk_street', 'arab_american_university_road',
      'al_jalama_road', 'ya_bad_road', 'tubas_road'
    ],
    'tulkarm': [
      'al_alimi_street', 'nablus_street', 'al_quds_street', 'al_shuhada_street',
      'al_sikka_street', 'industrial_street', 'khadouri_university_road',
      'qalqilya_road', 'jenin_road', 'netanya_road'
    ],
    'qalqilya': [
      'al_quds_street', 'al_andalus_street', 'al_nasr_street', 'al_wahda_street',
      'al_istiqlal_street', 'nablus_road', 'tulkarm_road', 'al_taybeh_road',
      'azzoun_road', 'jaljulia_road'
    ],
    'salfit': [
      'al_quds_street', 'al_nahda_street', 'al_salam_street', 'hospital_street',
      'al_bireh_road', 'ramallah_road', 'nablus_road', 'ariel_road',
      'deir_istiya_road', 'bruqin_road'
    ],
    'tubas': [
      'al_quds_street', 'al_yarmouk_street', 'al_wahda_street', 'hospital_street',
      'al_far_aa_road', 'jenin_road', 'nablus_road', 'tammun_road',
      'aqaba_road', 'al_malih_road'
    ],
    'jericho': [
      'al_quds_street', 'al_sultan_street', 'al_andalus_street', 'hospital_street',
      'dead_sea_road', 'jerusalem_road', 'ramallah_road', 'al_auja_road',
      'allenby_bridge_road', 'aqabat_jaber_road'
    ],
  };

  // Get available cities list
  List<String> get _availableCities => _cityStreets.keys.toList();

  // Get streets for selected city
  List<String> get _availableStreets {
    if (_selectedLocation == null) return [];
    return _cityStreets[_selectedLocation!] ?? [];
  }

  // Map icon string/id to a Material IconData
  IconData _resolveCategoryIcon(String icon, {String? fallback}) {
    final key = (icon.isNotEmpty ? icon : (fallback ?? '')).toLowerCase();
    switch (key) {
      case 'cleaning_services':
      case 'cleaning':
        return Icons.cleaning_services;
      case 'folder_open':
      case 'organizing':
        return Icons.folder_open;
      case 'restaurant':
      case 'cooking':
        return Icons.restaurant;
      case 'child_care':
      case 'childcare':
        return Icons.child_care;
      case 'elderly':
      case 'elderly_care':
        return Icons.elderly;
      case 'handyman':
      case 'maintenance':
        return Icons.handyman;
      case 'home':
      case 'newhome':
        return Icons.home;
      case 'miscellaneous_services':
      case 'miscellaneous':
        return Icons.miscellaneous_services;
      default:
        return Icons.build;
    }
  }

  // Prefer colorful asset icons when available
  String? _categoryAssetFor(String idOrKey) {
    final k = idOrKey.toLowerCase();
    switch (k) {
      case 'cleaning':
      case 'cleaningservices':
      case 'cleaning_services':
        return 'assets/images/cleaning_icon.png';
      case 'cooking':
      case 'homecookingservices':
      case 'home_cooking_services':
        return 'assets/images/home_cooking_icon.png';
      case 'elderly':
      case 'personalelderlycare':
      case 'personal_elderly_care':
        return 'assets/images/elderly_care_icon.png';
      case 'childcare':
      case 'childcareservices':
      case 'child_care_services':
        return 'assets/images/babysitting_icon.png';
      default:
        return null; // fall back to Material icon
    }
  }
  
  // Old-version colorful emoji icons (preferred when available)
  String? _categoryEmojiFor(String idOrKey) {
    final k = idOrKey.toLowerCase();
    switch (k) {
      case 'cleaning':
      case 'cleaningservices':
      case 'cleaning_services':
        return '🧼';
      case 'organizing':
      case 'organizingservices':
      case 'organizing_services':
        return '🧺';
      case 'cooking':
      case 'homecookingservices':
      case 'home_cooking_services':
        return '🍲';
      case 'childcare':
      case 'childcareservices':
      case 'child_care_services':
        return '🧒';
      case 'personalelderlycare':
      case 'personal_elderly_care':
      case 'elderly':
        return '🧕';
      case 'maintenance':
      case 'maintenance_repair':
      case 'maintenance_&_repair':
      case 'maintenance & repair':
        return '🔧';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Cache categories once; prevents FutureBuilder from resetting on every setState
  _categoriesFuture = _svc.getCategories();
  }

  void _toggleCategory(String categoryId) async {
    final offset = _scrollController.hasClients ? _scrollController.offset : null;
    // Update selection without rebuilding the whole page
    final current = _selectedCategoriesVN.value;
    if (current.contains(categoryId)) {
      current.remove(categoryId);
    } else {
      current.add(categoryId);
    }
    _selectedCategoriesVN.value = {...current};

    if (_selectedCategoriesVN.value.contains(categoryId) && !_categoryServices.containsKey(categoryId)) {
      _pendingServiceLoadsVN.value = _pendingServiceLoadsVN.value + 1;
      final services = await _svc.getServicesForCategory(categoryId);
      _categoryServices[categoryId] = services;
      _pendingServiceLoadsVN.value = _pendingServiceLoadsVN.value - 1;
      // Nudge listeners to rebuild service chips
      _selectedCategoriesVN.value = {..._selectedCategoriesVN.value};
    }
    if (offset != null && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(offset);
        }
      });
    }
  }

  void _toggleService(String key) {
    final offset = _scrollController.hasClients ? _scrollController.offset : null;
    final current = _selectedServicesVN.value;
    if (current.contains(key)) {
      current.remove(key);
    } else {
      current.add(key);
    }
    _selectedServicesVN.value = {...current};
    if (offset != null && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(offset);
        }
      });
    }
  }

  // Enhanced error handling for signup with specific messages
  String _getSignupErrorMessage(dynamic error, Map<String, dynamic>? response) {
    if (error is ApiException) {
      // Handle specific API errors with user-friendly messages
      if (error.statusCode == 400) {
        // Check for specific validation errors
        if (error.responseBody.contains('Email already registered')) {
          return 'This email address is already registered. Please use a different email or try logging in.';
        } else if (error.responseBody.contains('Phone number already registered')) {
          return 'This phone number is already registered. Please use a different phone number.';
        } else if (error.responseBody.contains('Missing required fields')) {
          return 'Please fill in all required fields.';
        } else if (error.responseBody.contains('Invalid role')) {
          return 'Invalid user type selected. Please try again.';
        } else if (error.responseBody.contains('password')) {
          return 'Password must be at least 6 characters long.';
        } else if (error.responseBody.contains('email')) {
          return 'Please enter a valid email address.';
        } else if (error.responseBody.contains('phone')) {
          return 'Please enter a valid phone number.';
        } else {
          return 'Please check your information and try again.';
        }
      } else if (error.statusCode == 422) {
        return 'Please check your information and try again.';
      } else if (error.statusCode >= 500) {
        return 'Server error. Please try again later.';
      } else {
        return 'Registration failed. Please try again.';
      }
    } else if (error.toString().contains('SocketException') || 
               error.toString().contains('Connection refused')) {
      return 'Unable to connect to server. Please check your internet connection and try again.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Connection timeout. Please check your internet connection and try again.';
    } else if (response != null && response['message'] != null) {
      // Handle backend-specific error messages
      String message = response['message'];
      if (message.contains('Email already registered')) {
        return 'This email address is already registered. Please use a different email or try logging in.';
      } else if (message.contains('Phone number already registered')) {
        return 'This phone number is already registered. Please use a different phone number.';
      } else if (message.contains('password')) {
        return 'Password must be at least 6 characters long.';
      } else if (message.contains('email')) {
        return 'Please enter a valid email address.';
      } else if (message.contains('phone')) {
        return 'Please enter a valid phone number.';
      } else {
        return message;
      }
    } else {
      return 'Registration failed. Please try again.';
    }
  }

  @override
  void dispose() {
  _scrollController.dispose();
  _selectedCategoriesVN.dispose();
  _selectedServicesVN.dispose();
  _pendingServiceLoadsVN.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // For step 0 (basic information), only validate the form fields
    if (_currentStep == 0) {
      if (_formKey.currentState?.validate() != true) {
        return;
      }

      // Move to next step without checking category selection
      setState(() {
        _currentStep++;
      });
      return;
    }
    
    // For step 1 (category selection), check if category is selected
    if (_currentStep == 1 && _selectedUserType == 'provider') {
      if (_selectedCategoriesVN.value.isEmpty) {
        // Show a more prominent error message
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: Row(
                    children: [
                      const Icon(Icons.warning, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        languageService.currentLanguage == 'ar' ? 'الفئة مطلوبة' : 'Category Required',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    languageService.currentLanguage == 'ar' 
                      ? 'يرجى اختيار فئة الخدمة الرئيسية للمتابعة.'
                      : 'Please select at least one main service category to continue.',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        languageService.currentLanguage == 'ar' ? 'موافق' : 'OK',
                        style: GoogleFonts.cairo(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
        return;
      }
      setState(() {
        _currentStep++;
      });
      return;
    }
    
    // For step 2 (sub-category selection), check if sub-category is selected
    if (_currentStep == 2 && _selectedUserType == 'provider') {
      if (_selectedServicesVN.value.isEmpty) {
        // Show a more prominent error message
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Consumer<LanguageService>(
              builder: (context, languageService, child) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: Row(
                    children: [
                      const Icon(Icons.warning, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        languageService.currentLanguage == 'ar' ? 'الخدمات مطلوبة' : 'Services Required',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    languageService.currentLanguage == 'ar' 
                      ? 'يرجى اختيار فئة الخدمة الفرعية للمتابعة.'
                      : 'Please select at least one service to continue.',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        languageService.currentLanguage == 'ar' ? 'موافق' : 'OK',
                        style: GoogleFonts.cairo(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
        return;
      }
      setState(() {
        _currentStep++;
      });
      return;
    }
    
    // For other steps, just move forward
    if (_currentStep < _getMaxSteps()) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  int _getMaxSteps() {
    if (_selectedUserType == 'client') return 1;
    if (_selectedUserType == 'provider') return 3;
    return 0;
  }

  void _selectUserType(String type) {
    setState(() {
      _selectedUserType = type;
      _currentStep = 0;
    });
  }


  void _submitForm() async {
    // Use the original form validation that shows field-level errors
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Additional validation: Ensure city and street are selected
    if (_selectedLocation == null || _selectedLocation!.trim().isEmpty || 
        _selectedStreet == null || _selectedStreet!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select both city and street before proceeding.',
            style: GoogleFonts.cairo(color: AppColors.white),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // For service providers, ensure subcategory is selected before submission
  if (_selectedUserType == 'provider' && _selectedServicesVN.value.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      languageService.currentLanguage == 'ar' ? 'الخدمات مطلوبة' : 'Services Required',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  languageService.currentLanguage == 'ar' 
                    ? 'يرجى اختيار فئة الخدمة الفرعية قبل إرسال طلبك.'
                    : 'Please select a sub-service category before submitting your application.',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      languageService.currentLanguage == 'ar' ? 'موافق' : 'OK',
                      style: GoogleFonts.cairo(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Get first and last name from separate fields
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      // Debug: Print the values being sent
      print('🔍 Debug - Registration values:');
      print('firstName: "$firstName"');
      print('lastName: "$lastName"');
      print('email: "${_emailController.text.trim()}"');
      print('password: "${_passwordController.text}"');
      print('phone: "${_phoneController.text.trim()}"');
      print('role: "${_selectedUserType ?? 'client'}"');
      print('city: $_selectedLocation');
      print('street: $_selectedStreet');

      final response = await authService.register(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        role: _selectedUserType ?? 'client',
        age: int.tryParse(_ageController.text.trim()),
        city: _selectedLocation,
        street: _selectedStreet,
        providerSelections: _selectedUserType == 'provider' ? {
          'categories': _selectedCategoriesVN.value.toList(),
          'services': _selectedServicesVN.value.toList(),
        } : null,
       );

      if (response['success'] == true) {
        setState(() {
          _isLoading = false;
          _currentStep = _getMaxSteps();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registration successful! Welcome to PalHands.',
                style: GoogleFonts.cairo(color: AppColors.white),
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 4),
            ),
          );
          
                  // Navigate to root to trigger AuthWrapper routing after successful registration
        Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _getSignupErrorMessage(null, response),
                style: GoogleFonts.cairo(color: AppColors.white),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: AppColors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getSignupErrorMessage(e, null),
              style: GoogleFonts.cairo(color: AppColors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: AppColors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Row(
          children: [
            // Left side - Branding
            Expanded(
              flex: 1,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: widget.screenWidth * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large logo
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const AnimatedHandshake(
                            size: 100,
                            color: AppColors.primary,
                            animationDuration: Duration(milliseconds: 2500),
                          ),
                        ),
                        SizedBox(height: widget.screenHeight * 0.05),
                        Text(
                          AppStrings.getString('appName', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: widget.screenHeight * 0.02),
                        Text(
                          AppStrings.getString('appTagline', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Right side - Form
            Expanded(
              flex: 1,
              child: Container(
                color: AppColors.background,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(widget.screenWidth * 0.04),
                  child: _buildFormContent(languageService),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormContent(LanguageService languageService) {
    if (_currentStep == 0 && _selectedUserType == null) {
      return _buildUserTypeSelection(languageService);
    }

    if (_currentStep == _getMaxSteps()) {
      return _buildSuccessMessage(languageService);
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step indicator
          if (_selectedUserType == 'provider') ...[
            _buildStepIndicator(),
            SizedBox(height: widget.screenHeight * 0.03),
          ],
          
          // Step content
          if (_currentStep == 0) ...[
            _buildBasicInfoForm(languageService),
          ] else if (_currentStep == 1 && _selectedUserType == 'provider') ...[
            _buildMainCategorySelection(languageService),
          ] else if (_currentStep == 2 && _selectedUserType == 'provider') ...[
            _buildSubCategorySelection(languageService),
          ] else if (_currentStep == 3 && _selectedUserType == 'provider') ...[
            _buildAdditionalDetails(languageService),
          ],
          
          SizedBox(height: widget.screenHeight * 0.04),
          
          // Navigation buttons
          _buildNavigationButtons(languageService),
          
          // Support reminder for service providers
          if (_selectedUserType == 'provider' && _currentStep < _getMaxSteps()) ...[
            SizedBox(height: widget.screenHeight * 0.03),
            _buildSupportReminder(languageService),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTypeSelection(LanguageService languageService) {
    return Column(
      children: [
        Text(
          '${AppStrings.getString('signUpAsClient', languageService.currentLanguage)} / ${AppStrings.getString('signUpAsServiceProvider', languageService.currentLanguage)}',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: widget.screenHeight * 0.04),
        
        // Client button
        SizedBox(
          width: double.infinity,
          height: 80,
          child: ElevatedButton(
            onPressed: () => _selectUserType('client'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: AppColors.primary, width: 2),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👤', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  AppStrings.getString('signUpAsClient', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: widget.screenHeight * 0.02),
        
        // Service Provider button
        SizedBox(
          width: double.infinity,
          height: 80,
          child: ElevatedButton(
            onPressed: () => _selectUserType('provider'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🛠', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(
                  AppStrings.getString('signUpAsServiceProvider', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        bool isActive = index <= _currentStep;
        bool isCompleted = index < _currentStep;
        
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : 
                         isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.gray,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  color: isCompleted ? AppColors.white : AppColors.primary,
                  size: 20,
                ),
              ),
              if (index < 2)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? AppColors.primary : AppColors.gray,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBasicInfoForm(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('personalInformation', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.03),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                label: AppStrings.getString('firstName', languageService.currentLanguage),
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.getString('pleaseEnterFirstName', languageService.currentLanguage);
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _lastNameController,
                label: AppStrings.getString('lastName', languageService.currentLanguage),
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.getString('pleaseEnterLastName', languageService.currentLanguage);
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: widget.screenHeight * 0.02),
        _buildTextField(
          controller: _ageController,
          label: AppStrings.getString('age', languageService.currentLanguage),
          icon: Icons.cake,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.getString('pleaseEnterAge', languageService.currentLanguage);
            }
            final age = int.tryParse(value);
            if (age == null || age < 1 || age > 120) {
              return AppStrings.getString('pleaseEnterValidAge', languageService.currentLanguage);
            }
            return null;
          },
        ),
        SizedBox(height: widget.screenHeight * 0.02),
        _buildTextField(
          controller: _emailController,
          label: AppStrings.getString('email', languageService.currentLanguage),
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.getString('pleaseEnterEmail', languageService.currentLanguage);
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return AppStrings.getString('pleaseEnterValidEmail', languageService.currentLanguage);
            }
            return null;
          },
        ),
        SizedBox(height: widget.screenHeight * 0.02),
  _buildPasswordField(
          controller: _passwordController,
          label: AppStrings.getString('password', languageService.currentLanguage),
          icon: Icons.lock,
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.getString('pleaseEnterPassword', languageService.currentLanguage);
            }
            if (value.length < 6) {
              return AppStrings.getString('passwordTooShort', languageService.currentLanguage);
            }
            return null;
          },
  ),
        SizedBox(height: widget.screenHeight * 0.02),
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: AppStrings.getString('confirmPassword', languageService.currentLanguage),
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.getString('pleaseConfirmPassword', languageService.currentLanguage);
            }
            if (value != _passwordController.text) {
              return AppStrings.getString('passwordsDoNotMatch', languageService.currentLanguage);
            }
            return null;
          },
        ),
        SizedBox(height: widget.screenHeight * 0.02),
        _buildTextField(
          controller: _phoneController,
          label: AppStrings.getString('phoneNumber', languageService.currentLanguage),
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.getString('pleaseEnterPhoneNumber', languageService.currentLanguage);
            }
            // More flexible phone number validation
            const pattern = r'^[\+]?[0-9\s\-\(\)]{8,15}$';
            final regExp = RegExp(pattern);
            if (!regExp.hasMatch(value)) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
        SizedBox(height: widget.screenHeight * 0.02),
        _buildLocationDropdown(languageService),
        SizedBox(height: widget.screenHeight * 0.02),
        // Street field removed - now handled by dropdown in location section
      ],
    );
  }

  Widget _buildMainCategorySelection(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('selectMainCategory', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.03),
  FutureBuilder<List<ServiceCategoryModel>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final cats = snapshot.data ?? const <ServiceCategoryModel>[];
            return ValueListenableBuilder<Set<String>>(
              valueListenable: _selectedCategoriesVN,
              builder: (context, selected, _) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  primary: false,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: cats.length,
                  itemBuilder: (context, index) {
                    final cat = cats[index];
                    final isSelected = selected.contains(cat.id);
                    return GestureDetector(
                      onTap: () => _toggleCategory(cat.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.grey.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Builder(
                              builder: (_) {
                                // Prefer emoji for colorful look (old design)
                                final emoji = _categoryEmojiFor(cat.id);
                                if (emoji != null) {
                                  return Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 32),
                                  );
                                }
                                // Then asset icon if available
                                final asset = _categoryAssetFor(cat.id);
                                if (asset != null) {
                                  return Image.asset(
                                    asset,
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.contain,
                                  );
                                }
                                // Fallback to Material icon
                                return Icon(
                                  _resolveCategoryIcon(cat.icon, fallback: cat.id),
                                  size: 36,
                                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppStrings.getString((cat.nameKey.isNotEmpty ? cat.nameKey : cat.id), languageService.currentLanguage),
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.white : AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubCategorySelection(LanguageService languageService) {
    if (_selectedCategoriesVN.value.isEmpty) return Container();
     
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('chooseSubServices', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.02),
        Text(
          AppStrings.getString('selectSpecificServices', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.03),
        ValueListenableBuilder<Set<String>>(
          valueListenable: _selectedCategoriesVN,
          builder: (context, selectedCats, _) {
            // Build combined subcategory list from cached services
            final set = <String>{};
            for (final catId in selectedCats) {
              final list = _categoryServices[catId];
              if (list != null) set.addAll(list);
            }
            final subCategories = set.toList()..sort();
            return ValueListenableBuilder<int>(
              valueListenable: _pendingServiceLoadsVN,
              builder: (context, pending, __) {
                if (pending > 0 && subCategories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ValueListenableBuilder<Set<String>>(
                  valueListenable: _selectedServicesVN,
                  builder: (context, selectedServices, ___) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: subCategories.map((subCategory) {
                        final isSelected = selectedServices.contains(subCategory);
                        return GestureDetector(
                          onTap: () => _toggleService(subCategory),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.grey.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              AppStrings.getString(subCategory, languageService.currentLanguage),
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalDetails(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('additionalDetails', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.03),
        
        Text(
          AppStrings.getString('howManyPeople', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.01),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _serviceProvidersCount.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() {
                    _serviceProvidersCount = value.toInt();
                  });
                },
              ),
            ),
            SizedBox(width: widget.screenWidth * 0.04),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_serviceProvidersCount',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: widget.screenHeight * 0.01),
        Text(
          AppStrings.getString('additionalNotes', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.01),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFieldBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: TextFormField(
            controller: _notesController,
            maxLines: 4,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.getString('addAdditionalNotes', languageService.currentLanguage),
              hintStyle: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.placeholderText,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(LanguageService languageService) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: _previousStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.grey.withValues(alpha: 0.2),
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                AppStrings.getString('back', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () {
              if (_currentStep == _getMaxSteps() - 1) {
                _submitForm();
              } else {
                _nextStep();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : Text(
                  _currentStep == _getMaxSteps() - 1 ? AppStrings.getString('submitApplication', languageService.currentLanguage) : AppStrings.getString('next', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportReminder(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.contact_support, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              AppStrings.getString('wantToOfferNewService', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(LanguageService languageService) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 80,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.04),
        
        Text(
          AppStrings.getString('thankYouForSigningUp', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: widget.screenHeight * 0.02),
        
        Text(
          AppStrings.getString('weWillReviewYourApplication', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 18,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: widget.screenHeight * 0.04),
        
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          ),
          child: Text(
            AppStrings.getString('login', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.cairo(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.cairo(
            fontSize: 16,
            color: AppColors.placeholderText,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFieldBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        autofillHints: const [AutofillHints.newPassword],
        enableSuggestions: false,
        autocorrect: false,
        style: GoogleFonts.cairo(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.cairo(
            fontSize: 16,
            color: AppColors.placeholderText,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
              color: AppColors.primary,
            ),
            onPressed: onToggleVisibility,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          // Web hint to prevent password manager from suggesting similar passwords
          // ignore: deprecated_member_use
          semanticCounterText: '',
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildLocationDropdown(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedUserType == 'provider' 
            ? AppStrings.getString('whereDoYouWantToProvideService', languageService.currentLanguage)
            : AppStrings.getString('whereDoYouPreferToGetService', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.02),
        
        // City Selection
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputFieldBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedLocation,
            decoration: InputDecoration(
              hintText: AppStrings.getString('selectYourCity', languageService.currentLanguage),
              hintStyle: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.placeholderText,
              ),
              prefixIcon: const Icon(Icons.location_city, color: AppColors.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: _availableCities.map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(
                  AppStrings.getString(city, languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLocation = value;
                _selectedStreet = null; // Reset street when city changes
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.getString('pleaseSelectCity', languageService.currentLanguage);
              }
              return null;
            },
          ),
  ),
        // Street Selection (only show if city is selected)
        if (_selectedLocation != null) ...[
          SizedBox(height: widget.screenHeight * 0.02),
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputFieldBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedStreet,
              decoration: InputDecoration(
                hintText: AppStrings.getString('selectYourStreet', languageService.currentLanguage),
                hintStyle: GoogleFonts.cairo(
                  fontSize: 16,
                  color: AppColors.placeholderText,
                ),
                prefixIcon: const Icon(Icons.streetview, color: AppColors.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: _availableStreets.map((street) {
                return DropdownMenuItem(
                  value: street,
                  child: Text(
                    AppStrings.getString(street, languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStreet = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.getString('pleaseSelectStreet', languageService.currentLanguage);
                }
                return null;
              },
            ),
          ),
        ],
      ],
    );
  }
}