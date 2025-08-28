import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'app_toast.dart';

// Services
import '../services/base_api_service.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Services
import '../services/language_service.dart';
import '../services/auth_service.dart';
import '../services/responsive_service.dart';

// Widget imports
import 'animated_handshake.dart';
import 'signup_screen.dart';
import '../../features/profile/presentation/widgets/security_widget.dart';

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

  // Enhanced error handling with secure messages
  String _getSecureErrorMessage(dynamic error) {
    // Check if this is a deactivation error from ApiException
    if (error is ApiException && error.message.contains('deactivated by an administrator')) {
      return error.message; // Show the specific deactivation message
    }
    
    // Check if this is a deactivation error from string
    if (error is String && error.contains('deactivated by an administrator')) {
      return error; // Show the specific deactivation message
    }
    
    // For other login errors, show generic message to avoid leaking information
    return 'Incorrect email or password';
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final response = await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

  if (response['success'] == true) {
          // Login successful - navigate to root to trigger AuthWrapper routing
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        } else {
          // Debug: Print the response to see what we're getting
          if (kDebugMode) {
            print('🔍 Login response: $response');
            print('🔍 Response message: ${response['message']}');
            print('🔍 Response error: ${response['error']}');
          }
          
          // Rate limit friendly message if backend returned 429
          final status = response['statusCode'] as int?;
          final friendly = (status == 429)
              ? 'Too many attempts. Please try again later.'
              : _getSecureErrorMessage(response['message'] ?? 'Login failed');
          // Login failed - show secure error message
          if (mounted) {
              AppToast.show(context, message: friendly, type: AppToastType.error, actionLabel: 'Dismiss', onAction: () => ScaffoldMessenger.of(context).hideCurrentSnackBar());
          }
        }
      } catch (e) {
        // Debug: Print the exception to see what we're getting
        if (kDebugMode) {
          print('🔍 Login exception: $e');
          print('🔍 Exception type: ${e.runtimeType}');
          if (e is ApiException) {
            print('🔍 ApiException message: ${e.message}');
            print('🔍 ApiException statusCode: ${e.statusCode}');
          }
        }
        
        // Network or other error - show secure error message
        if (mounted) {
            AppToast.show(context, message: _getSecureErrorMessage(e), type: AppToastType.error);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ResponsiveService>(
      builder: (context, languageService, responsiveService, child) {
        // Use the unified ResponsiveService instead of hardcoded breakpoints
        // This eliminates the circular responsive logic that was causing conflicts
        final screenWidth = MediaQuery.of(context).size.width;
        final shouldUseMobileLayout = responsiveService.shouldUseMobileLayout(screenWidth);

        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC),
          body: shouldUseMobileLayout
            ? _buildMobileLayout(languageService)
            : _buildWebLayout(languageService),
        );
      },
    );
  }

  Widget _buildWebLayout(LanguageService languageService) {
    return Consumer<ResponsiveService>(
      builder: (context, responsiveService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
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
                              child: const Stack(
                                children: [
                                  // Main animated icon
                                  Center(
                                    child: AnimatedHandshake(
                                      size: 100.0, // Fixed size
                                      color: AppColors.primary,
                                      animationDuration: Duration(milliseconds: 2500),
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
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppStrings.getString('login', languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary, // Palestinian red
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),
                          Focus(
                            onKey: (node, event) {
                              // Handle Enter key press anywhere in the form
                              if (event.isKeyPressed(LogicalKeyboardKey.enter) && !_isLoading) {
                                _handleLogin();
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: _buildLoginForm(),
                          ),
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
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'العربية',
                            style: TextStyle(
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

  Widget _buildMobileLayout(LanguageService languageService) {
    return Consumer<ResponsiveService>(
      builder: (context, responsiveService, child) {
        // Mobile responsive sizing for login
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
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
                      Focus(
                        onKey: (node, event) {
                          // Handle Enter key press anywhere in the form
                          if (event.isKeyPressed(LogicalKeyboardKey.enter) && !_isLoading) {
                            _handleLogin();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: _buildLoginForm(screenWidth, screenHeight),
                      ),
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
                            const Icon(
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
  // screenWidth is used directly below; no need for an extra flag.
        
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
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (value) {
                  // Focus on password field when Enter is pressed
                  FocusScope.of(context).nextFocus();
                },
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
                    borderSide: const BorderSide(
                      color: AppColors.inputBorder, // Normal red border
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorderFocused, // Focused red border
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: const BorderSide(
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
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                enableSuggestions: false,
                autocorrect: false,
                onFieldSubmitted: (value) {
                  // Trigger login when Enter is pressed in password field
                  if (!_isLoading) {
                    _handleLogin();
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  // Remove password length validation for login - it should only apply during signup
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
                    borderSide: const BorderSide(
                      color: AppColors.inputBorder, // Normal red border
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: const BorderSide(
                      color: AppColors.inputBorderFocused, // Focused red border
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: const BorderSide(
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
            SizedBox(height: spacing * 0.75),
            // Row with Forgot Password and Change Password (same line)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
                    final email = _emailController.text.trim();
                    if (email.isEmpty) {
                      AppToast.show(context, message: 'Enter your email to reset password', type: AppToastType.warning);
                      return;
                    }
                    try {
                      final auth = Provider.of<AuthService>(context, listen: false);
                      final res = await auth.forgotPassword(email);
                      final ok = res['success'] == true;
                      if (ok) {
                        AppToast.show(context, message: 'Reset link sent to your email', type: AppToastType.info);
                      } else {
                        AppToast.show(context, message: res['message'] ?? 'Failed to send reset link', type: AppToastType.error);
                      }
                    } catch (e) {
                      AppToast.show(context, message: 'Error: $e', type: AppToastType.error);
                    }
                  },
                  child: Text(
                    AppStrings.getString('forgotPassword', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: fontSize,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '·',
                  style: GoogleFonts.cairo(
                    fontSize: fontSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Open the same Change Password dialog as in Profile > Security
                    SecurityWidget.showChangePasswordDialog(context);
                  },
                  child: Text(
                    AppStrings.getString('changePassword', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: fontSize,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 0.25),
            // Register link on its own line under the actions
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: Text(
                  AppStrings.getString('dontHaveAccount', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: fontSize,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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
} 