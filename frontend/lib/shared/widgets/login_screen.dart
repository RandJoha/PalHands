import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Services
import '../services/language_service.dart';
import '../services/auth_service.dart';

// Widget imports
import 'tatreez_pattern.dart';
import 'animated_handshake.dart';
import 'signup_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';

// Responsive login screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final response = await authService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response['success'] == true) {
          // Login successful - navigate to home page
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Login failed - show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Login failed. Please try again.',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Network or other error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection error. Please check your internet connection and try again.',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWeb = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: AppColors.loginBackground, // Warm beige background
      body: Stack(
        children: [
          // Background tatreez patterns - random placement (away from form)
          if (isWeb) ...[
            // Web layout - more patterns, darker, positioned away from center
            Positioned(
              top: screenHeight * 0.05,
              left: screenWidth * 0.02,
              child: TatreezPattern(
                size: 80,
                opacity: 0.15,
              ),
            ),
            Positioned(
              top: screenHeight * 0.12,
              right: screenWidth * 0.03,
              child: TatreezPattern(
                size: 65,
                opacity: 0.12,
              ),
            ),
            Positioned(
              top: screenHeight * 0.25,
              left: screenWidth * 0.08,
              child: TatreezPattern(
                size: 95,
                opacity: 0.18,
              ),
            ),
            Positioned(
              top: screenHeight * 0.35,
              right: screenWidth * 0.06,
              child: TatreezPattern(
                size: 70,
                opacity: 0.14,
              ),
            ),
            Positioned(
              top: screenHeight * 0.55,
              left: screenWidth * 0.15,
              child: TatreezPattern(
                size: 85,
                opacity: 0.16,
              ),
            ),
            Positioned(
              top: screenHeight * 0.65,
              right: screenWidth * 0.12,
              child: TatreezPattern(
                size: 75,
                opacity: 0.13,
              ),
            ),
            Positioned(
              top: screenHeight * 0.75,
              left: screenWidth * 0.05,
              child: TatreezPattern(
                size: 90,
                opacity: 0.17,
              ),
            ),
            Positioned(
              top: screenHeight * 0.85,
              right: screenWidth * 0.08,
              child: TatreezPattern(
                size: 60,
                opacity: 0.11,
              ),
            ),
            Positioned(
              top: screenHeight * 0.18,
              left: screenWidth * 0.85,
              child: TatreezPattern(
                size: 70,
                opacity: 0.15,
              ),
            ),
            Positioned(
              top: screenHeight * 0.45,
              right: screenWidth * 0.85,
              child: TatreezPattern(
                size: 80,
                opacity: 0.14,
              ),
            ),
            Positioned(
              top: screenHeight * 0.72,
              left: screenWidth * 0.9,
              child: TatreezPattern(
                size: 65,
                opacity: 0.12,
              ),
            ),
          ] else ...[
            // Mobile layout - fewer patterns, positioned away from form
            Positioned(
              top: screenHeight * 0.08,
              left: screenWidth * 0.05,
              child: TatreezPattern(
                size: 70,
                opacity: 0.12,
              ),
            ),
            Positioned(
              top: screenHeight * 0.25,
              right: screenWidth * 0.08,
              child: TatreezPattern(
                size: 85,
                opacity: 0.15,
              ),
            ),
            Positioned(
              top: screenHeight * 0.45,
              left: screenWidth * 0.12,
              child: TatreezPattern(
                size: 60,
                opacity: 0.13,
              ),
            ),
            Positioned(
              top: screenHeight * 0.65,
              right: screenWidth * 0.15,
              child: TatreezPattern(
                size: 75,
                opacity: 0.14,
              ),
            ),
            Positioned(
              top: screenHeight * 0.8,
              left: screenWidth * 0.03,
              child: TatreezPattern(
                size: 80,
                opacity: 0.11,
              ),
            ),
          ],
          // Main content
          isWeb ? _buildWebLayout(screenWidth, screenHeight) : _buildMobileLayout(screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildWebLayout(double screenWidth, double screenHeight) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Stack(
          children: [
            Row(
              children: [
                // Left side - Branding (scales down but icon stays same size)
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
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Fixed size logo (doesn't scale down)
                            Container(
                              width: 200.0, // Fixed size
                              height: 200.0, // Fixed size
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(40.0),
                                border: Border.all(
                                  color: AppColors.white.withValues(alpha: 0.3),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [

                                  // Main animated icon
                                  Center(
                                    child: AnimatedHandshake(
                                size: 100.0, // Fixed size
                                color: AppColors.primary,
                                      animationDuration: const Duration(milliseconds: 2500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.05),
                            // App name - scales with screen but with constraints
                            Text(
                              AppStrings.getString('appName', languageService.currentLanguage),
                              style: GoogleFonts.cairo(
                                fontSize: (screenWidth * 0.025).clamp(32.0, 64.0),
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            // Tagline - scales with screen but with constraints
                            Text(
                              AppStrings.getString('appTagline', languageService.currentLanguage),
                              style: GoogleFonts.cairo(
                                fontSize: (screenWidth * 0.012).clamp(16.0, 24.0),
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
                // Right side - Login Form
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 400.w),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.getString('login', languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary, // Palestinian red
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 48.h),
                          _buildLoginForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Language toggle button - top right
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => languageService.toggleLanguage(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            languageService.isEnglish ? 'العربية' : 'English',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout(double screenWidth, double screenHeight) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        // Mobile responsive sizing for login
        final logoSize = screenWidth * 0.25; // 25% of screen width for logo
        final titleSize = screenWidth * 0.065; // 6.5% of screen width
        final subtitleSize = screenWidth * 0.04; // 4% of screen width
        final padding = screenWidth * 0.08; // 8% padding (increased for mobile)
        
        return SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Welcome text
                      Text(
                        AppStrings.getString('welcomeBack', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: titleSize.clamp(20.0, 36.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary, // Palestinian red
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      // PalHands logo/branding
                      Container(
                        width: logoSize.clamp(80.0, 150.0),
                        height: logoSize.clamp(80.0, 150.0),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(logoSize * 0.16),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                                      child: AnimatedHandshake(
                          size: logoSize * 0.5,
                          color: AppColors.primary,
                animationDuration: const Duration(milliseconds: 2500),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      // Tagline
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                        child: Text(
                          AppStrings.getString('loginToContinue', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: subtitleSize.clamp(14.0, 20.0),
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.05),
                      // Login form
                      _buildLoginForm(screenWidth, screenHeight),
                    ],
                  ),
                ),
              ),
              // Language toggle button - top right for mobile
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => languageService.toggleLanguage(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.language,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              languageService.isEnglish ? 'عربي' : 'EN',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginForm([double? screenWidth, double? screenHeight]) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        // Use provided dimensions or fallback to ScreenUtil
        final fieldHeight = screenHeight != null ? (screenHeight * 0.06).clamp(48.0, 64.0) : 56.0;
        final buttonHeight = screenHeight != null ? (screenHeight * 0.055).clamp(44.0, 60.0) : 52.0;
        final fontSize = screenWidth != null ? (screenWidth * 0.025).clamp(14.0, 18.0) : 16.0;
        final buttonFontSize = screenWidth != null ? (screenWidth * 0.03).clamp(16.0, 20.0) : 18.0;
        final spacing = screenHeight != null ? (screenHeight * 0.015).clamp(12.0, 20.0) : 16.0;
        final borderRadius = screenWidth != null ? (screenWidth * 0.015).clamp(8.0, 16.0) : 12.0;
        
        // Check if we're on mobile (green background)
        final isMobile = screenWidth != null && screenWidth < 600;
        
        return Form(
          key: _formKey,
          child: Column(
          children: [
            // Email field
            Container(
              height: fieldHeight,
              decoration: BoxDecoration(
                color: AppColors.inputFieldBackground, // Cream fill
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                style: GoogleFonts.cairo(
                  fontSize: fontSize,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.getString('email', languageService.currentLanguage),
                  hintStyle: GoogleFonts.cairo(
                    fontSize: fontSize * 0.9,
                    color: AppColors.placeholderText, // Medium gray
                  ),
                  prefixIcon: Icon(
                    Icons.email, 
                    color: AppColors.primary,
                    size: fontSize * 1.2,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: AppColors.inputBorder, // Normal red border
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: AppColors.inputBorderFocused, // Focused red border
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: AppColors.inputBorder, // Normal red border
                      width: 1.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth != null ? (screenWidth * 0.015).clamp(8.0, 16.0) : 12.0,
                    vertical: fieldHeight * 0.3,
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing),
            // Password field
            Container(
              height: fieldHeight,
              decoration: BoxDecoration(
                color: AppColors.inputFieldBackground, // Cream fill
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                obscureText: _obscurePassword,
                style: GoogleFonts.cairo(
                  fontSize: fontSize,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.getString('password', languageService.currentLanguage),
                  hintStyle: GoogleFonts.cairo(
                    fontSize: fontSize * 0.9,
                    color: AppColors.placeholderText, // Medium gray
                  ),
                  prefixIcon: Icon(
                    Icons.lock, 
                    color: AppColors.primary,
                    size: fontSize * 1.2,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primary,
                      size: fontSize * 1.2,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: AppColors.inputBorder, // Normal red border
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: AppColors.inputBorderFocused, // Focused red border
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: AppColors.inputBorder, // Normal red border
                      width: 1.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth != null ? (screenWidth * 0.015).clamp(8.0, 16.0) : 12.0,
                    vertical: fieldHeight * 0.3,
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing * 1.5),
            // Login button
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Palestinian red
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: buttonFontSize,
                        height: buttonFontSize,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          strokeWidth: 2.0,
                        ),
                      )
                    : Text(
                  AppStrings.getString('login', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                          color: AppColors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing),
            // Register link
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: Text(
                AppStrings.getString('dontHaveAccount', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: fontSize,
                  color: AppColors.primary, // Palestinian red
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        );
      },
    );
  }
} 