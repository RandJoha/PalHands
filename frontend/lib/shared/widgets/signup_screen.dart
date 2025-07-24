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
import 'mobile_signup_widget.dart';
import 'web_signup_widget.dart';

// Sign-up screen with separate mobile and web widgets
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Join Us',
          style: GoogleFonts.cairo(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
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
          
          // Main content - use separate widgets for mobile and web
          isWeb 
            ? WebSignupWidget(screenWidth: screenWidth, screenHeight: screenHeight)
            : MobileSignupWidget(screenWidth: screenWidth, screenHeight: screenHeight),
        ],
      ),
    );
  }
} 