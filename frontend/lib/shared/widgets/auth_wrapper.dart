import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/profile/presentation/pages/user_dashboard_screen.dart';
import '../../features/admin/presentation/pages/admin_dashboard_screen.dart';
import '../../features/provider/presentation/pages/provider_dashboard_screen.dart';
import 'reset_password_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/web_event_bridge.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _bridge = WebEventBridge();
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Listen for cross-tab signals and refresh profile when needed
      _bridge.init(() {
        final auth = Provider.of<AuthService>(context, listen: false);
        // Best effort refresh (ignore errors)
  auth.getProfile().catchError((_) => <String, dynamic>{});
      });
    }
  }

  @override
  void dispose() {
    _bridge.dispose();
    super.dispose();
  }

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
          // Handle deep link for reset password on web even if initial route was swallowed
          if (kIsWeb) {
            final uri = Uri.base;
            if (uri.path == '/reset-password') {
              // Defer navigation to next microtask to avoid setState during build
              Future.microtask(() {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => ResetPasswordScreen(token: uri.queryParameters['token']),
                  ),
                );
              });
              return const SizedBox.shrink();
            }
          }
          // User is not authenticated, show home page with login/register
          return const HomeScreen();
        }
      },
    );
  }
} 