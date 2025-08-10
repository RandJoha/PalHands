import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/time_translation_utils.dart';
import '../../../../shared/services/language_service.dart';

class TimeTranslationExampleWidget extends StatelessWidget {
  const TimeTranslationExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Time Translation Examples'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Efficient Time Translation System',
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Example 1: Using the efficient system
                _buildExampleCard(
                  'Dynamic Time Translation',
                  [
                    '1 second ago: ${AppStrings.getTimeAgo(1, "second", languageService.currentLanguage)}',
                    '2 minutes ago: ${AppStrings.getTimeAgo(2, "minute", languageService.currentLanguage)}',
                    '3 hours ago: ${AppStrings.getTimeAgo(3, "hour", languageService.currentLanguage)}',
                    '1 day ago: ${AppStrings.getTimeAgo(1, "day", languageService.currentLanguage)}',
                    '2 weeks ago: ${AppStrings.getTimeAgo(2, "week", languageService.currentLanguage)}',
                    '1 month ago: ${AppStrings.getTimeAgo(1, "month", languageService.currentLanguage)}',
                    '1 year ago: ${AppStrings.getTimeAgo(1, "year", languageService.currentLanguage)}',
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Example 2: Month translations
                _buildExampleCard(
                  'Month Translations',
                  [
                    'January: ${AppStrings.getMonthName(1, languageService.currentLanguage)}',
                    'March: ${AppStrings.getMonthName(3, languageService.currentLanguage)}',
                    'December: ${AppStrings.getMonthName(12, languageService.currentLanguage)}',
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Example 3: Date formatting
                _buildExampleCard(
                  'Date Formatting',
                  [
                    'March 15, 1998: ${TimeTranslationUtils.formatDate(15, 3, 1998, languageService.currentLanguage)}',
                    'January 1, 2024: ${TimeTranslationUtils.formatDate(1, 1, 2024, languageService.currentLanguage)}',
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Example 4: Relative time from DateTime
                _buildExampleCard(
                  'Relative Time from DateTime',
                  [
                    'Now: ${TimeTranslationUtils.getRelativeTime(DateTime.now(), languageService.currentLanguage)}',
                    '1 hour ago: ${TimeTranslationUtils.getRelativeTime(DateTime.now().subtract(const Duration(hours: 1)), languageService.currentLanguage)}',
                    '2 days ago: ${TimeTranslationUtils.getRelativeTime(DateTime.now().subtract(const Duration(days: 2)), languageService.currentLanguage)}',
                    '1 week ago: ${TimeTranslationUtils.getRelativeTime(DateTime.now().subtract(const Duration(days: 7)), languageService.currentLanguage)}',
                    '1 month ago: ${TimeTranslationUtils.getRelativeTime(DateTime.now().subtract(const Duration(days: 30)), languageService.currentLanguage)}',
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Benefits explanation
                _buildExampleCard(
                  'Benefits of This System',
                  [
                    '✅ No need for individual strings for each time period',
                    '✅ Handles any number dynamically',
                    '✅ Proper pluralization for both languages',
                    '✅ Consistent formatting across the app',
                    '✅ Easy to maintain and extend',
                    '✅ Supports both English and Arabic formats',
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExampleCard(String title, List<String> examples) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...examples.map((example) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                example,
                style: GoogleFonts.cairo(fontSize: 14),
              ),
            )),
          ],
        ),
      ),
    );
  }
} 