import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Services
import '../services/language_service.dart';

// Widget imports
import 'tatreez_pattern.dart';
import 'mobile_signup_widget.dart';
import 'web_signup_widget.dart';

// Services

// Sign-up screen with separate mobile and web widgets
class SignupScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  
  const SignupScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWeb = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: AppColors.loginBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return Text(
              AppStrings.getString('signUp', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          _buildLanguageButton(),
        ],
      ),
      body: Stack(
        children: [
          // Background tatreez patterns - random placement (away from form)
          if (isWeb) ...[
            // Web layout - more patterns, darker, positioned away from center
            Positioned(
              top: screenHeight * 0.05,
              left: screenWidth * 0.02,
              child: const TatreezPattern(
                size: 80,
                opacity: 0.15,
              ),
            ),
            Positioned(
              top: screenHeight * 0.12,
              right: screenWidth * 0.03,
              child: const TatreezPattern(
                size: 65,
                opacity: 0.12,
              ),
            ),
            Positioned(
              top: screenHeight * 0.25,
              left: screenWidth * 0.08,
              child: const TatreezPattern(
                size: 95,
                opacity: 0.18,
              ),
            ),
            Positioned(
              top: screenHeight * 0.35,
              right: screenWidth * 0.06,
              child: const TatreezPattern(
                size: 70,
                opacity: 0.14,
              ),
            ),
            Positioned(
              top: screenHeight * 0.55,
              left: screenWidth * 0.15,
              child: const TatreezPattern(
                size: 85,
                opacity: 0.16,
              ),
            ),
            Positioned(
              top: screenHeight * 0.65,
              right: screenWidth * 0.12,
              child: const TatreezPattern(
                size: 75,
                opacity: 0.13,
              ),
            ),
            Positioned(
              top: screenHeight * 0.75,
              left: screenWidth * 0.05,
              child: const TatreezPattern(
                size: 90,
                opacity: 0.17,
              ),
            ),
            Positioned(
              top: screenHeight * 0.85,
              right: screenWidth * 0.08,
              child: const TatreezPattern(
                size: 60,
                opacity: 0.11,
              ),
            ),
            Positioned(
              top: screenHeight * 0.18,
              left: screenWidth * 0.85,
              child: const TatreezPattern(
                size: 70,
                opacity: 0.15,
              ),
            ),
            Positioned(
              top: screenHeight * 0.45,
              right: screenWidth * 0.85,
              child: const TatreezPattern(
                size: 80,
                opacity: 0.14,
              ),
            ),
            Positioned(
              top: screenHeight * 0.72,
              left: screenWidth * 0.9,
              child: const TatreezPattern(
                size: 65,
                opacity: 0.12,
              ),
            ),
          ] else ...[
            // Mobile layout - fewer patterns, positioned away from form
            Positioned(
              top: screenHeight * 0.08,
              left: screenWidth * 0.05,
              child: const TatreezPattern(
                size: 70,
                opacity: 0.12,
              ),
            ),
            Positioned(
              top: screenHeight * 0.25,
              right: screenWidth * 0.08,
              child: const TatreezPattern(
                size: 85,
                opacity: 0.15,
              ),
            ),
            Positioned(
              top: screenHeight * 0.45,
              left: screenWidth * 0.12,
              child: const TatreezPattern(
                size: 60,
                opacity: 0.13,
              ),
            ),
            Positioned(
              top: screenHeight * 0.65,
              right: screenWidth * 0.15,
              child: const TatreezPattern(
                size: 75,
                opacity: 0.14,
              ),
            ),
            Positioned(
              top: screenHeight * 0.8,
              left: screenWidth * 0.03,
              child: const TatreezPattern(
                size: 80,
                opacity: 0.11,
              ),
            ),
          ],
          
          // Main content - use separate widgets for mobile and web
          isWeb 
            ? WebSignupWidget(screenWidth: screenWidth, screenHeight: screenHeight, arguments: arguments)
            : MobileSignupWidget(screenWidth: screenWidth, screenHeight: screenHeight, arguments: arguments),
        ],
      ),
    );
  }

  Widget _buildLanguageButton() {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(25),
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
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                languageService.toggleLanguage();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      languageService.currentLanguage == 'ar' ? 'EN' : 'عربي',
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
        );
      },
    );
  }
} 