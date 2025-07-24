import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Service imports
import '../services/health_service.dart';

// Widget imports
import 'login_screen.dart';

// Splash screen with navigation logic
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    final healthService = Provider.of<HealthService>(context, listen: false);
    
    // Check backend health
    final isConnected = await healthService.checkHealth();
    
    if (mounted) {
      if (isConnected) {
        // Backend is healthy, navigate to login after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        });
      } else {
        // Backend is down, stay on splash screen with error message
        // The UI will automatically update to show the error state
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthService>(
      builder: (context, healthService, child) {
        // Get screen dimensions
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Check if we're on web or mobile
        final isWeb = screenWidth > 600;
        final isMobile = screenWidth < 600;
        
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: SafeArea(
            child: isWeb ? _buildWebLayout(screenWidth, screenHeight, healthService) : 
                   _buildMobileLayout(screenWidth, screenHeight, isMobile, healthService),
          ),
        );
      },
    );
  }

  Widget _buildWebLayout(double screenWidth, double screenHeight, HealthService healthService) {
    // Responsive sizing for web
    final logoSize = screenWidth * 0.1; // 10% of screen width
    final titleSize = screenWidth * 0.025; // 2.5% of screen width
    final taglineSize = screenWidth * 0.012; // 1.2% of screen width
    final loadingSize = screenWidth * 0.03; // 3% of screen width
    
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
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Large logo
                    Container(
                      width: logoSize.clamp(150.0, 300.0),
                      height: logoSize.clamp(150.0, 300.0),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(logoSize * 0.2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.handshake,
                        size: logoSize * 0.5,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                                      Text(
                    AppStrings.getString('appName', 'en'), // Default to English for splash
                    style: GoogleFonts.cairo(
                      fontSize: titleSize.clamp(32.0, 64.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      AppStrings.getString('appTagline', 'en'), // Default to English for splash
                      style: GoogleFonts.cairo(
                        fontSize: taglineSize.clamp(16.0, 24.0),
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
        // Right side - Loading/Error
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.background,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (healthService.isLoading) ...[
                    SizedBox(
                      width: loadingSize.clamp(40.0, 80.0),
                      height: loadingSize.clamp(40.0, 80.0),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        strokeWidth: 4.0,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Checking server...',
                      style: GoogleFonts.cairo(
                        fontSize: taglineSize.clamp(16.0, 22.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else if (healthService.isConnected) ...[
                    Icon(
                      Icons.check_circle,
                      size: loadingSize.clamp(40.0, 80.0),
                      color: Colors.green,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Server connected!',
                      style: GoogleFonts.cairo(
                        fontSize: taglineSize.clamp(16.0, 22.0),
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.error_outline,
                      size: loadingSize.clamp(40.0, 80.0),
                      color: Colors.red,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Server Error',
                      style: GoogleFonts.cairo(
                        fontSize: taglineSize.clamp(16.0, 22.0),
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Text(
                        healthService.errorMessage,
                        style: GoogleFonts.cairo(
                          fontSize: (taglineSize * 0.8).clamp(12.0, 16.0),
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    ElevatedButton(
                      onPressed: () => healthService.retry(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(double screenWidth, double screenHeight, bool isMobile, HealthService healthService) {
    // Mobile-specific responsive sizing
    final logoSize = isMobile ? screenWidth * 0.35 : screenWidth * 0.25; // Much larger for mobile
    final titleSize = isMobile ? screenWidth * 0.08 : screenWidth * 0.06; // Larger mobile title
    final taglineSize = isMobile ? screenWidth * 0.045 : screenWidth * 0.035; // Larger tagline
    final loadingSize = isMobile ? screenWidth * 0.12 : screenWidth * 0.08; // Larger loading indicator
    final horizontalPadding = screenWidth * 0.08; // 8% padding
    
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: screenHeight * 0.05,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo - much larger on mobile
            Container(
              width: logoSize.clamp(100.0, 200.0),
              height: logoSize.clamp(100.0, 200.0),
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
            SizedBox(height: screenHeight * 0.04),
            // App name - larger and more prominent
                              Text(
                    AppStrings.getString('appName', 'en'), // Default to English for splash
                    style: GoogleFonts.cairo(
                      fontSize: titleSize.clamp(24.0, 48.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
            SizedBox(height: screenHeight * 0.015),
            // Tagline - better sized for mobile
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child:                   Text(
                    AppStrings.getString('appTagline', 'en'), // Default to English for splash
                    style: GoogleFonts.cairo(
                      fontSize: taglineSize.clamp(14.0, 20.0),
                      color: AppColors.white.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
            ),
            SizedBox(height: screenHeight * 0.06),
            // Loading/Error indicator
            if (healthService.isLoading) ...[
              SizedBox(
                width: loadingSize.clamp(32.0, 60.0),
                height: loadingSize.clamp(32.0, 60.0),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  strokeWidth: 4.0,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Checking server...',
                style: GoogleFonts.cairo(
                  fontSize: (taglineSize * 0.8).clamp(12.0, 16.0),
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
            ] else if (healthService.isConnected) ...[
              Icon(
                Icons.check_circle,
                size: loadingSize.clamp(32.0, 60.0),
                color: Colors.green,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Server connected!',
                style: GoogleFonts.cairo(
                  fontSize: (taglineSize * 0.8).clamp(12.0, 16.0),
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Icon(
                Icons.error_outline,
                size: loadingSize.clamp(32.0, 60.0),
                color: Colors.red,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Server Error',
                style: GoogleFonts.cairo(
                  fontSize: (taglineSize * 0.8).clamp(12.0, 16.0),
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Text(
                  healthService.errorMessage,
                  style: GoogleFonts.cairo(
                    fontSize: (taglineSize * 0.7).clamp(10.0, 14.0),
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: () => healthService.retry(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 