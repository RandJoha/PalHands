import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Services
import '../services/language_service.dart';

// Widget imports
import 'tatreez_pattern.dart';
import 'animated_handshake.dart';

// Mobile-specific signup widget
class MobileSignupWidget extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;

  const MobileSignupWidget({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  State<MobileSignupWidget> createState() => _MobileSignupWidgetState();
}

class _MobileSignupWidgetState extends State<MobileSignupWidget> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Step management
  int _currentStep = 0;
  String? _selectedUserType;
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  int _serviceProvidersCount = 1;
  
  // Service categories
  final Map<String, Map<String, dynamic>> _serviceCategories = {
    'cleaning': {
      'icon': '🧼',
      'subCategories': ['houseCleaning', 'deepCleaning', 'windowCleaning', 'carpetCleaning']
    },
    'organizing': {
      'icon': '🧺',
      'subCategories': ['homeOrganization', 'closetOrganization', 'officeOrganization', 'eventPlanning']
    },
    'cooking': {
      'icon': '🍲',
      'subCategories': ['mainDishes', 'desserts', 'specialRequests', 'mealPrep']
    },
    'childcare': {
      'icon': '🧒',
      'subCategories': ['babysitting', 'tutoring', 'playActivities', 'specialNeedsCare']
    },
    'elderly': {
      'icon': '🧕',
      'subCategories': ['elderlyCare', 'personalAssistance', 'medicalSupport', 'companionship']
    },
    'maintenance': {
      'icon': '🔧',
      'subCategories': ['plumbing', 'electrical', 'carpentry', 'generalRepairs']
    },
    'newhome': {
      'icon': '🏠',
      'subCategories': ['movingAssistance', 'furnitureAssembly', 'homeSetup', 'decoration']
    },
    'miscellaneous': {
      'icon': '🚗',
      'subCategories': ['shopping', 'delivery', 'petCare', 'gardenMaintenance']
    },
  };

  String _getCategoryName(String categoryKey, LanguageService languageService) {
    switch (categoryKey) {
      case 'cleaning':
        return AppStrings.getString('cleaningServices', languageService.currentLanguage);
      case 'organizing':
        return AppStrings.getString('organizingServices', languageService.currentLanguage);
      case 'cooking':
        return AppStrings.getString('homeCookingServices', languageService.currentLanguage);
      case 'childcare':
        return AppStrings.getString('childCareServices', languageService.currentLanguage);
      case 'elderly':
        return AppStrings.getString('personalElderlyCare', languageService.currentLanguage);
      case 'maintenance':
        return AppStrings.getString('maintenanceRepair', languageService.currentLanguage);
      case 'newhome':
        return AppStrings.getString('newHomeServices', languageService.currentLanguage);
      case 'miscellaneous':
        return AppStrings.getString('miscellaneousErrands', languageService.currentLanguage);
      default:
        return categoryKey;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
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

  void _selectMainCategory(String category) {
    setState(() {
      _selectedMainCategory = category;
      _selectedSubCategory = null;
    });
  }

  void _selectSubCategory(String subCategory) {
    setState(() {
      _selectedSubCategory = subCategory;
    });
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _currentStep = _getMaxSteps();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Thank you! We\'re excited to welcome you onboard.',
            style: GoogleFonts.cairo(color: AppColors.white),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return SingleChildScrollView(
      padding: EdgeInsets.all(widget.screenWidth * 0.05),
      child: Column(
        children: [
          // Logo and title
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AnimatedHandshake(
              size: 60,
              color: AppColors.white,
              animationDuration: const Duration(milliseconds: 2500),
            ),
          ),
          SizedBox(height: widget.screenHeight * 0.03),
          Text(
            'Join PalHands',
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: widget.screenHeight * 0.02),
          Text(
            'Connect with trusted service providers in Palestine',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: widget.screenHeight * 0.04),
          
          // Form content
          _buildFormContent(languageService),
        ],
      ),
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
            _buildSupportReminder(),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTypeSelection(LanguageService languageService) {
    return Column(
      children: [
        Text(
          'Do you want to sign up as a client or as a service provider?',
          style: GoogleFonts.cairo(
            fontSize: 20,
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
                side: BorderSide(color: AppColors.primary, width: 2),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('👤', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
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
                Text('🛠', style: TextStyle(fontSize: 24)),
                SizedBox(width: 12),
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
          'Basic Information',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.03),
        
        // Full Name
        _buildTextField(
          controller: _fullNameController,
                      label: AppStrings.getString('fullName', languageService.currentLanguage),
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.getString('pleaseEnterFullName', languageService.currentLanguage);
            }
            return null;
          },
        ),
        
        SizedBox(height: widget.screenHeight * 0.02),
        
        // Email
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
        
        // Password
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
        
        // Confirm Password
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
        
        SizedBox(height: widget.screenHeight * 0.03),
        
        // OR divider
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.gray)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: GoogleFonts.cairo(
                  color: AppColors.gray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.gray)),
          ],
        ),
        
        SizedBox(height: widget.screenHeight * 0.03),
        
        // Google Sign Up
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implement Google sign up
            },
            icon: Text('🔍', style: TextStyle(fontSize: 20)),
            label: Text(
              'Sign up with Google',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        
        SizedBox(height: widget.screenHeight * 0.02),
        
        // Phone Number
        _buildTextField(
          controller: _phoneController,
                      label: AppStrings.getString('phoneNumber', languageService.currentLanguage),
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.getString('pleaseEnterPhoneNumber', languageService.currentLanguage);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMainCategorySelection(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your main service category',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.02),
        Text(
          'Select the category that best describes your primary service:',
          style: GoogleFonts.cairo(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.03),
        
        // Service category grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _serviceCategories.length,
          itemBuilder: (context, index) {
            String categoryKey = _serviceCategories.keys.elementAt(index);
            Map<String, dynamic> category = _serviceCategories[categoryKey]!;
            bool isSelected = _selectedMainCategory == categoryKey;
            
            return GestureDetector(
              onTap: () => _selectMainCategory(categoryKey),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.gray.withValues(alpha: 0.3),
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
                    Text(
                      category['icon'],
                      style: TextStyle(fontSize: 32),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _getCategoryName(categoryKey, languageService),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.white : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubCategorySelection(LanguageService languageService) {
    if (_selectedMainCategory == null) return Container();
    
    List<String> subCategories = _serviceCategories[_selectedMainCategory!]!['subCategories'] as List<String>;
    
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
        
        // Sub-category list
        ...subCategories.map((subCategory) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _selectSubCategory(subCategory),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedSubCategory == subCategory ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedSubCategory == subCategory ? AppColors.primary : AppColors.gray.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedSubCategory == subCategory ? Icons.check_circle : Icons.circle_outlined,
                    color: _selectedSubCategory == subCategory ? AppColors.white : AppColors.primary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.getString(subCategory, languageService.currentLanguage),
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _selectedSubCategory == subCategory ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )).toList(),
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
        
        // Number of service providers
        Text(
          AppStrings.getString('howManyPeople', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.01),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.inputFieldBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonFormField<int>(
            value: _serviceProvidersCount,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.people, color: AppColors.primary),
            ),
            items: List.generate(10, (index) => index + 1).map((number) {
              return DropdownMenuItem(
                value: number,
                child: Text(
                  number == 1 ? '1 person' : '$number people',
                  style: GoogleFonts.cairo(fontSize: 16),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _serviceProvidersCount = value!;
              });
            },
          ),
        ),
        
        SizedBox(height: widget.screenHeight * 0.03),
        
        // Additional notes
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
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.getString('addAdditionalNotes', languageService.currentLanguage),
              hintStyle: GoogleFonts.cairo(
                fontSize: 14,
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
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Previous',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
        
        Expanded(
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
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.3),
            ),
            child: _isLoading
                ? SizedBox(
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

  Widget _buildSupportReminder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.contact_support, color: AppColors.primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Want to offer a new service that\'s not listed? Contact us at: +970 59 123 4567',
              style: GoogleFonts.cairo(
                fontSize: 14,
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
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            size: 60,
            color: AppColors.white,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.04),
        
        Text(
          'Thank you! We\'re excited to welcome you onboard.',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: widget.screenHeight * 0.02),
        
        Text(
          'Your request has been successfully sent to our admin team. We\'ll review and contact you shortly.',
          style: GoogleFonts.cairo(
            fontSize: 16,
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(
            AppStrings.getString('login', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 16,
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
        ),
        validator: validator,
      ),
    );
  }
} 