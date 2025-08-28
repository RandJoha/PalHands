import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/reports_service.dart';

class DebugReportsLoader extends StatefulWidget {
  const DebugReportsLoader({super.key});

  @override
  State<DebugReportsLoader> createState() => _DebugReportsLoaderState();
}

class _DebugReportsLoaderState extends State<DebugReportsLoader> {
  final ReportsService _reportsService = ReportsService();
  String _status = 'Ready to test';
  List<dynamic> _reports = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Debug Reports Loader')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reports Debug Tool', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Auth Status
            _buildAuthStatus(),
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _checkAuthStatus,
                  child: const Text('Check Auth'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadReports,
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Load Reports'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _loginAsAdmin,
                  child: const Text('Login as Admin'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Status: $_status'),
            ),
            const SizedBox(height: 20),
            
            // Reports List
            Expanded(
              child: _reports.isEmpty
                ? const Center(child: Text('No reports loaded'))
                : ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return Card(
                        child: ListTile(
                          title: Text(report['description'] ?? 'No description'),
                          subtitle: Text('Category: ${report['reportCategory']} | Status: ${report['status']}'),
                          trailing: Text(report['status'] ?? 'pending'),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthStatus() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: authService.isAdmin ? Colors.green.shade100 : Colors.red.shade100,
            border: Border.all(color: authService.isAdmin ? Colors.green : Colors.red),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Authentication Status:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('• Authenticated: ${authService.isAuthenticated}'),
              Text('• Is Admin: ${authService.isAdmin}'),
              Text('• User Role: ${authService.userRole ?? 'None'}'),
              Text('• User Email: ${authService.currentUser?['email'] ?? 'None'}'),
              Text('• Has Token: ${authService.token != null}'),
              if (authService.token != null)
                Text('• Token: ${authService.token!.substring(0, 20)}...'),
            ],
          ),
        );
      },
    );
  }

  void _checkAuthStatus() {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _status = 'Auth checked - Admin: ${authService.isAdmin}, Token: ${authService.token != null}';
    });
    print('=== AUTH STATUS ===');
    print('Authenticated: ${authService.isAuthenticated}');
    print('Is Admin: ${authService.isAdmin}');
    print('User Role: ${authService.userRole}');
    print('Current User: ${authService.currentUser}');
    print('Has Token: ${authService.token != null}');
    print('==================');
  }

  void _loginAsAdmin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _status = 'Logging in as admin...';
    });

    try {
      final response = await authService.login(
        email: 'roro@palhands.com',
        password: 'admin123',
      );

      if (response['success'] == true) {
        setState(() {
          _status = 'Admin login successful!';
        });
        print('✅ Admin login successful');
      } else {
        setState(() {
          _status = 'Login failed: ${response['message']}';
        });
        print('❌ Login failed: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _status = 'Login error: $e';
      });
      print('❌ Login error: $e');
    }
  }

  void _loadReports() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading reports...';
    });

    try {
      final response = await _reportsService.listAllReports(
        page: 1,
        limit: 10,
      );

      print('📋 Raw response: $response');

      if (response['success'] == true) {
        final reports = response['data']['reports'] as List;
        setState(() {
          _reports = reports.map((r) => r.toJson()).toList();
          _status = 'Successfully loaded ${reports.length} reports';
          _isLoading = false;
        });
        print('✅ Loaded ${reports.length} reports');
      } else {
        setState(() {
          _status = 'Failed to load reports: ${response['message']}';
          _isLoading = false;
        });
        print('❌ Failed to load reports: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _status = 'Error loading reports: $e';
        _isLoading = false;
      });
      print('❌ Error loading reports: $e');
    }
  }
}
