import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Responsive login screen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWeb = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: isWeb ? AppColors.background : AppColors.primary,
      body: isWeb ? _buildWebLayout(screenWidth, screenHeight) : _buildMobileLayout(screenWidth, screenHeight),
    );
  }

  Widget _buildWebLayout(double screenWidth, double screenHeight) {
    return Row(
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
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.handshake,
                        size: 100.0, // Fixed size
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    // App name - scales with screen but with constraints
                    Text(
                      AppStrings.appName,
                      style: GoogleFonts.cairo(
                        fontSize: (screenWidth * 0.025).clamp(32.0, 64.0),
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    // Tagline - scales with screen but with constraints
                    Text(
                      AppStrings.appTagline,
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
                    AppStrings.login,
                    style: GoogleFonts.cairo(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
    );
  }

  Widget _buildMobileLayout(double screenWidth, double screenHeight) {
    // Mobile responsive sizing for login
    final logoSize = screenWidth * 0.25; // 25% of screen width for logo
    final titleSize = screenWidth * 0.065; // 6.5% of screen width
    final subtitleSize = screenWidth * 0.04; // 4% of screen width
    final padding = screenWidth * 0.08; // 8% padding (increased for mobile)
    
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome text
              Text(
                AppStrings.welcomeBack,
                style: GoogleFonts.cairo(
                  fontSize: titleSize.clamp(20.0, 36.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
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
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.handshake,
                  size: logoSize * 0.5,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Tagline
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Text(
                  AppStrings.loginToContinue,
                  style: GoogleFonts.cairo(
                    fontSize: subtitleSize.clamp(14.0, 20.0),
                    color: AppColors.white.withValues(alpha: 0.9),
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
    );
  }

  Widget _buildLoginForm([double? screenWidth, double? screenHeight]) {
    // Use provided dimensions or fallback to ScreenUtil
    final fieldHeight = screenHeight != null ? (screenHeight * 0.06).clamp(48.0, 64.0) : 56.0;
    final buttonHeight = screenHeight != null ? (screenHeight * 0.055).clamp(44.0, 60.0) : 52.0;
    final fontSize = screenWidth != null ? (screenWidth * 0.025).clamp(14.0, 18.0) : 16.0;
    final buttonFontSize = screenWidth != null ? (screenWidth * 0.03).clamp(16.0, 20.0) : 18.0;
    final spacing = screenHeight != null ? (screenHeight * 0.015).clamp(12.0, 20.0) : 16.0;
    final borderRadius = screenWidth != null ? (screenWidth * 0.015).clamp(8.0, 16.0) : 12.0;
    
    // Check if we're on mobile (green background)
    final isMobile = screenWidth != null && screenWidth < 600;
    
    return Column(
      children: [
        // Email field
        Container(
          height: fieldHeight,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: isMobile ? AppColors.white.withValues(alpha: 0.3) : AppColors.border),
            boxShadow: [
              BoxShadow(
                color: isMobile ? AppColors.black.withValues(alpha: 0.1) : AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            style: GoogleFonts.cairo(fontSize: fontSize),
            decoration: InputDecoration(
              hintText: AppStrings.email,
              hintStyle: GoogleFonts.cairo(
                fontSize: fontSize * 0.9,
                color: isMobile ? AppColors.textSecondary.withValues(alpha: 0.7) : AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.email, 
                color: isMobile ? AppColors.primary : AppColors.textSecondary,
                size: fontSize * 1.2,
              ),
              border: InputBorder.none,
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
            color: AppColors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: isMobile ? AppColors.white.withValues(alpha: 0.3) : AppColors.border),
            boxShadow: [
              BoxShadow(
                color: isMobile ? AppColors.black.withValues(alpha: 0.1) : AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            obscureText: true,
            style: GoogleFonts.cairo(fontSize: fontSize),
            decoration: InputDecoration(
              hintText: AppStrings.password,
              hintStyle: GoogleFonts.cairo(
                fontSize: fontSize * 0.9,
                color: isMobile ? AppColors.textSecondary.withValues(alpha: 0.7) : AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.lock, 
                color: isMobile ? AppColors.primary : AppColors.textSecondary,
                size: fontSize * 1.2,
              ),
              border: InputBorder.none,
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
            onPressed: () {
              // TODO: Implement login logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isMobile ? AppColors.white : AppColors.primary,
              foregroundColor: isMobile ? AppColors.primary : AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              elevation: isMobile ? 4 : 2,
            ),
            child: Text(
              AppStrings.login,
              style: GoogleFonts.cairo(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.bold,
                color: isMobile ? AppColors.primary : AppColors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: spacing),
        // Register link
        TextButton(
          onPressed: () {
            // TODO: Navigate to register screen
          },
          child: Text(
            AppStrings.dontHaveAccount,
            style: GoogleFonts.cairo(
              fontSize: fontSize,
              color: isMobile ? AppColors.white : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
} 