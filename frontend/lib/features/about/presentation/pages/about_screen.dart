import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/responsive_service.dart';
import '../widgets/web_about_widget.dart';
import '../widgets/mobile_about_widget.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ResponsiveService>(
      builder: (context, languageService, responsiveService, child) {
        // Use the unified ResponsiveService instead of hardcoded breakpoints
        // This eliminates the circular responsive logic that was causing conflicts
        final screenWidth = MediaQuery.of(context).size.width;
        final shouldUseMobileLayout = responsiveService.shouldUseMobileLayout(screenWidth);

        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC), // Warm beige background
          body: shouldUseMobileLayout 
            ? const MobileAboutWidget()
            : const WebAboutWidget(),
        );
      },
    );
  }
} 