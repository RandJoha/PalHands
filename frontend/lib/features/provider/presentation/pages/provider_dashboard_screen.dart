import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/language_service.dart';

// Provider widgets
import '../widgets/responsive_provider_dashboard.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: ResponsiveProviderDashboard(),
        );
      },
    );
  }
}
