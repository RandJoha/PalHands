import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/language_service.dart';
import '../widgets/mobile_contact_widget.dart';
import '../widgets/web_contact_widget.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

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
            ? const WebContactWidget()
            : const MobileContactWidget(),
        );
      },
    );
  }
} 