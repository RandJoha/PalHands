import 'package:flutter/material.dart';

// Core imports

// Shared imports

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