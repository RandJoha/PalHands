import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/reports_service.dart';

class DebugAuthPage extends StatefulWidget {
  const DebugAuthPage({super.key});

  @override
  State<DebugAuthPage> createState() => _DebugAuthPageState();
}

class _DebugAuthPageState extends State<DebugAuthPage> {
  final ReportsService _reportsService = ReportsService();
  String _status = 'Ready';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug page only available in development mode')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Authentication'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auth Status Card
                Card(
                  color: authService.isAdmin ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Authentication Status',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow('Authenticated', '${authService.isAuthenticated}', authService.isAuthenticated),
                        _buildStatusRow('Is Admin', '${authService.isAdmin}', authService.isAdmin),
                        _buildStatusRow('User Role', authService.userRole ?? 'None', authService.userRole == 'admin'),
                        _buildStatusRow('Has Token', '${authService.token != null}', authService.token != null),
                        _buildStatusRow('User Email', authService.currentUser?['email'] ?? 'None', authService.currentUser != null),
                        if (authService.token != null)
                          _buildStatusRow('Token Preview', '${authService.token!.substring(0, 30)}...', true),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _loginAsAdmin(authService),
                      icon: _isLoading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login),
                      label: const Text('Login as Admin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _logout(authService),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testReportsEndpoint,
                      icon: const Icon(Icons.api),
                      label: const Text('Test Reports API'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Status'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Status Messages
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status Messages',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(_status),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Instructions
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Click "Login as Admin" to authenticate\n'
                          '2. Verify all status indicators are green\n'
                          '3. Test the Reports API to confirm access\n'
                          '4. Go back to Reports & Disputes page\n'
                          '5. Reports should now load successfully',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.cancel,
            color: isGood ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$label: $value'),
          ),
        ],
      ),
    );
  }

  Future<void> _loginAsAdmin(AuthService authService) async {
    setState(() {
      _isLoading = true;
      _status = 'Logging in as admin...';
    });

    try {
      print('🔄 Attempting admin login...');
      final response = await authService.login(
        email: 'roro@palhands.com',
        password: 'admin123',
      );

      if (response['success'] == true) {
        setState(() {
          _status = '✅ Admin login successful! Token received and user role is admin.';
          _isLoading = false;
        });
        print('✅ Admin login successful');
        print('Token: ${authService.token?.substring(0, 50)}...');
        print('User: ${authService.currentUser}');
      } else {
        setState(() {
          _status = '❌ Login failed: ${response['message']}';
          _isLoading = false;
        });
        print('❌ Login failed: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _status = '❌ Login error: $e';
        _isLoading = false;
      });
      print('❌ Login error: $e');
    }
  }

  Future<void> _logout(AuthService authService) async {
    try {
      await authService.logout();
      setState(() {
        _status = 'Logged out successfully';
      });
      print('✅ Logged out');
    } catch (e) {
      setState(() {
        _status = 'Logout error: $e';
      });
      print('❌ Logout error: $e');
    }
  }

  Future<void> _testReportsEndpoint() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing reports API endpoint...';
    });

    try {
      final response = await _reportsService.listAllReports(page: 1, limit: 5);
      
      if (response['success'] == true) {
        final reports = response['data']['reports'] as List;
        setState(() {
          _status = '✅ Reports API test successful! Retrieved ${reports.length} reports.';
          _isLoading = false;
        });
        print('✅ Reports API test successful - got ${reports.length} reports');
      } else {
        setState(() {
          _status = '❌ Reports API test failed: ${response['message']}';
          _isLoading = false;
        });
        print('❌ Reports API test failed: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _status = '❌ Reports API test error: $e';
        _isLoading = false;
      });
      print('❌ Reports API test error: $e');
    }
  }
}
