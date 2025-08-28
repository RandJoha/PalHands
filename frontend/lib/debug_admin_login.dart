import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/reports_service.dart';
import 'shared/widgets/app_toast.dart';
import 'core/constants/app_colors.dart';

class DebugAdminLoginPage extends StatefulWidget {
  const DebugAdminLoginPage({super.key});

  @override
  State<DebugAdminLoginPage> createState() => _DebugAdminLoginPageState();
}

class _DebugAdminLoginPageState extends State<DebugAdminLoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Admin Login', style: GoogleFonts.cairo()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Login Debug',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Use this page to quickly log in as an admin for testing the reports feature.',
              style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            
            // Current Auth Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Auth Status:',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('• Authenticated: ${_authService.isAuthenticated}'),
                  Text('• Is Admin: ${_authService.isAdmin}'),
                  Text('• User Role: ${_authService.userRole ?? 'None'}'),
                  Text('• Has Token: ${_authService.token != null}'),
                  if (_authService.token != null)
                    Text('• Token Preview: ${_authService.token!.substring(0, 20)}...'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Login Buttons
            Text(
              'Quick Login Options:',
              style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Roro User
            _buildLoginButton(
              'Login as Roro (Admin)',
              'roro@palhands.com',
              'admin123',
              Colors.blue,
            ),
            const SizedBox(height: 12),
            
            // Admin User
            _buildLoginButton(
              'Login as Admin User',
              'admin@example.com',
              'admin123',
              Colors.green,
            ),
            const SizedBox(height: 12),
            
            // Qamar User
            _buildLoginButton(
              'Login as Qamar (Admin)',
              'qamarp@palhands.com',
              'admin123',
              Colors.orange,
            ),
            const SizedBox(height: 24),
            
            // Logout Button
            if (_authService.isAuthenticated)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Logout'),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Test Reports Button
            if (_authService.isAuthenticated && _authService.isAdmin)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testReports,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Test Reports API'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(String title, String email, String password, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _login(email, password),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(title),
      ),
    );
  }

  Future<void> _login(String email, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('🔄 Attempting login with: $email');
      }

      final response = await _authService.login(email: email, password: password);

      if (response['success'] == true) {
        if (kDebugMode) {
          print('✅ Login successful');
          print('🔐 Token: ${_authService.token?.substring(0, 20)}...');
          print('👤 Role: ${_authService.userRole}');
          print('👑 Is Admin: ${_authService.isAdmin}');
        }
        
        AppToast.show(
          context,
          message: 'Login successful! Role: ${_authService.userRole}',
          type: AppToastType.success,
        );
        
        // Refresh the UI
        setState(() {});
      } else {
        if (kDebugMode) {
          print('❌ Login failed: ${response['message']}');
        }
        AppToast.show(
          context,
          message: 'Login failed: ${response['message']}',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login error: $e');
      }
      AppToast.show(
        context,
        message: 'Login error: $e',
        type: AppToastType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.logout();
      if (kDebugMode) {
        print('✅ Logout successful');
      }
      AppToast.show(
        context,
        message: 'Logout successful',
        type: AppToastType.success,
      );
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('❌ Logout error: $e');
      }
      AppToast.show(
        context,
        message: 'Logout error: $e',
        type: AppToastType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('🔧 Testing reports API...');
      }
      
      // Test the reports service directly
      final reportsService = ReportsService();
      final response = await reportsService.listAllReports(page: 1, limit: 3);
      
      if (kDebugMode) {
        print('📊 Reports API Response: $response');
      }
      
      if (response['success'] == true) {
        final reports = response['data']['reports'] as List;
        AppToast.show(
          context,
          message: 'Reports API working! Found ${reports.length} reports',
          type: AppToastType.success,
        );
      } else {
        AppToast.show(
          context,
          message: 'Reports API failed: ${response['message']}',
          type: AppToastType.error,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Reports API test error: $e');
      }
      AppToast.show(
        context,
        message: 'Reports API test error: $e',
        type: AppToastType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
