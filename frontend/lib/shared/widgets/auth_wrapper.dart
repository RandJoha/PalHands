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
  bool _hasCheckedDeactivation = false;
  
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
    
    // Check for account deactivation on startup
    _checkAccountDeactivation();
  }
  
  Future<void> _checkAccountDeactivation() async {
    if (_hasCheckedDeactivation) return;
    _hasCheckedDeactivation = true;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final deactivationInfo = await authService.checkAccountDeactivation();
      
      if (deactivationInfo != null && mounted) {
        _showAccountDeactivationDialog(deactivationInfo);
      }
    } catch (e) {
      // Silently handle errors
    }
  }
  
  void _showAccountDeactivationDialog(Map<String, dynamic> deactivationInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Account Deactivated',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your account has been deactivated by an administrator.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(deactivationInfo['reason'] ?? 'No reason provided'),
                    if (deactivationInfo['deactivatedAt'] != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Deactivated on: ${_formatDate(deactivationInfo['deactivatedAt'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to home screen
                Navigator.of(context).pushReplacementNamed('/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
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