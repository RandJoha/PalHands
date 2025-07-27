import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/auth_service.dart';

// Admin widgets
import '../widgets/web_admin_dashboard.dart';
import '../widgets/mobile_admin_dashboard.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use constraints.maxWidth instead of MediaQuery for more stable responsive behavior
        final screenWidth = constraints.maxWidth;
        
        // Better responsive breakpoints with more stable transitions
        if (screenWidth > 900) {
          // Desktop and large tablet - use web dashboard
          return const WebAdminDashboard();
        } else {
          // Small tablet and mobile - use mobile dashboard
          return const MobileAdminDashboard();
        }
      },
    );
  }
}