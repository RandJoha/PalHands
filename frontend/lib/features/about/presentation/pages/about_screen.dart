import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../widgets/web_about_widget.dart';
import '../widgets/mobile_about_widget.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        // Determine if we're on web or mobile based on screen width
        final screenWidth = MediaQuery.of(context).size.width;
        final isWeb = screenWidth > 600;

        return Scaffold(
          backgroundColor: const Color(0xFFFDF5EC), // Warm beige background
          body: isWeb 
            ? const WebAboutWidget()
            : const MobileAboutWidget(),
        );
      },
    );
  }
} 