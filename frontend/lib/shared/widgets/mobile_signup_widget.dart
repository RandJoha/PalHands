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
      'name': 'Cleaning Services',
      'icon': '🧼',
      'subCategories': ['House Cleaning', 'Deep Cleaning', 'Window Cleaning', 'Carpet Cleaning']
    },
    'organizing': {
      'name': 'Organizing Services',
      'icon': '🧺',
      'subCategories': ['Home Organization', 'Closet Organization', 'Office Organization', 'Event Planning']
    },
    'cooking': {
      'name': 'Home Cooking Services',
      'icon': '🍲',
      'subCategories': ['Main Dishes', 'Desserts', 'Special Requests', 'Meal Prep']
    },
    'childcare': {
      'name': 'Child Care Services',
      'icon': '🧒',
      'subCategories': ['Babysitting', 'Tutoring', 'Play Activities', 'Special Needs Care']
    },
    'elderly': {
      'name': 'Personal & Elderly Care',
      'icon': '🧕',
      'subCategories': ['Elderly Care', 'Personal Assistance', 'Medical Support', 'Companionship']
    },
    'maintenance': {
      'name': 'Maintenance & Repair',
      'icon': '🔧',
      'subCategories': ['Plumbing', 'Electrical', 'Carpentry', 'General Repairs']
    },
    'newhome': {
      'name': 'New Home Services',
      'icon': '🏠',
      'subCategories': ['Moving Assistance', 'Furniture Assembly', 'Home Setup', 'Decoration']
    },
    'miscellaneous': {
      'name': 'Miscellaneous & Errands',
      'icon': '🚗',
      'subCategories': ['Shopping', 'Delivery', 'Pet Care', 'Garden Maintenance']
    },
  };

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
          _buildFormContent(),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    if (_currentStep == 0 && _selectedUserType == null) {
      return _buildUserTypeSelection();
    }

    if (_currentStep == _getMaxSteps()) {
      return _buildSuccessMessage();
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
            _buildBasicInfoForm(),
          ] else if (_currentStep == 1 && _selectedUserType == 'provider') ...[
            _buildMainCategorySelection(),
          ] else if (_currentStep == 2 && _selectedUserType == 'provider') ...[
            _buildSubCategorySelection(),
          ] else if (_currentStep == 3 && _selectedUserType == 'provider') ...[
            _buildAdditionalDetails(),
          ],
          
          SizedBox(height: widget.screenHeight * 0.04),
          
          // Navigation buttons
          _buildNavigationButtons(),
          
          // Support reminder for service providers
          if (_selectedUserType == 'provider' && _currentStep < _getMaxSteps()) ...[
            SizedBox(height: widget.screenHeight * 0.03),
            _buildSupportReminder(),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTypeSelection() {
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
                  'Sign up as Client',
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
                  'Sign up as Service Provider',
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

  Widget _buildBasicInfoForm() {
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
          label: 'Full Name',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        
        SizedBox(height: widget.screenHeight * 0.02),
        
        // Email
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        
        SizedBox(height: widget.screenHeight * 0.02),
        
        // Password
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock,
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        
        SizedBox(height: widget.screenHeight * 0.02),
        
        // Confirm Password
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
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
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMainCategorySelection() {
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
                      category['name'],
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

  Widget _buildSubCategorySelection() {
    if (_selectedMainCategory == null) return Container();
    
    List<String> subCategories = _serviceCategories[_selectedMainCategory!]!['subCategories'] as List<String>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your sub-service',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.02),
        Text(
          'Select the specific service you want to provide:',
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
                      subCategory,
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

  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details',
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: widget.screenHeight * 0.03),
        
        // Number of service providers
        Text(
          'How many people will be providing this service?',
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
          'Add any additional notes or preferences:',
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
              hintText: 'Tell us about your experience, availability, or any special requirements...',
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

  Widget _buildNavigationButtons() {
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
                    _currentStep == _getMaxSteps() - 1 ? 'Create Account' : 'Next',
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

  Widget _buildSuccessMessage() {
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
            'Back to Login',
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