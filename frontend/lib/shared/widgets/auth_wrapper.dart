import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/profile/presentation/pages/user_dashboard_screen.dart';
import '../../features/admin/presentation/pages/admin_dashboard_screen.dart';
import '../../features/provider/presentation/pages/provider_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Check if user is authenticated
        if (authService.isAuthenticated) {
          // Route based on user role
          if (authService.isAdmin) {
            return const AdminDashboardScreen();
          } else if (authService.isProvider) {
            return const ProviderDashboardScreen();
          } else {
            return const UserDashboardScreen();
          }
        } else {
          // User is not authenticated, show home page with login/register
          return const HomeScreen();
        }
      },
    );
  }
} 