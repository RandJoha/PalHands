import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shared/services/auth_service.dart';
import 'core/constants/api_config.dart';

class DebugApiTest extends StatefulWidget {
  const DebugApiTest({super.key});

  @override
  State<DebugApiTest> createState() => _DebugApiTestState();
}

class _DebugApiTestState extends State<DebugApiTest> {
  String _output = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug mode only')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug API Test'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Info
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('API Configuration:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Base URL: ${ApiConfig.currentBaseUrl}'),
                        Text('API URL: ${ApiConfig.currentApiBaseUrl}'),
                        Text('Is Web: ${kIsWeb}'),
                        Text('Environment: dev'),
                        SizedBox(height: 12),
                        Text('Auth Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Authenticated: ${authService.isAuthenticated}'),
                        Text('Is Admin: ${authService.isAdmin}'),
                        Text('Has Token: ${authService.token != null}'),
                        if (authService.token != null)
                          Text('Token: ${authService.token!.substring(0, 50)}...'),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Test Buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _testApiConfig(),
                      child: Text('1. Test API Config'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _testBackendHealth(),
                      child: Text('2. Test Backend Health'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _testLogin(),
                      child: Text('3. Test Login'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _testReportsAPI(),
                      child: Text('4. Test Reports API'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => _output = ''),
                      child: Text('Clear Output'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                // Output
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _output.isEmpty ? 'Click buttons above to run tests...' : _output,
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
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

  void _addOutput(String message) {
    setState(() {
      _output += '${DateTime.now().toString().substring(11, 19)} $message\n';
    });
    print(message);
  }

  Future<void> _testApiConfig() async {
    setState(() => _isLoading = true);
    _addOutput('=== TESTING API CONFIGURATION ===');
    _addOutput('Current Base URL: ${ApiConfig.currentBaseUrl}');
    _addOutput('Current API Base URL: ${ApiConfig.currentApiBaseUrl}');
    _addOutput('Is Web: ${kIsWeb}');
    _addOutput('Environment: dev');
    _addOutput('Expected URL for reports: ${ApiConfig.currentApiBaseUrl}/admin/reports');
    setState(() => _isLoading = false);
  }

  Future<void> _testBackendHealth() async {
    setState(() => _isLoading = true);
    _addOutput('=== TESTING BACKEND HEALTH ===');
    
    try {
      final healthUrl = '${ApiConfig.currentApiBaseUrl}/health';
      _addOutput('Testing: $healthUrl');
      
      final response = await http.get(Uri.parse(healthUrl));
      _addOutput('Status: ${response.statusCode}');
      _addOutput('Response: ${response.body}');
      
      if (response.statusCode == 200) {
        _addOutput('✅ Backend is reachable!');
      } else {
        _addOutput('❌ Backend returned error status');
      }
    } catch (e) {
      _addOutput('❌ Backend health check failed: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testLogin() async {
    setState(() => _isLoading = true);
    _addOutput('=== TESTING LOGIN ===');
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      _addOutput('Attempting login with roro@palhands.com...');
      
      final response = await authService.login(
        email: 'roro@palhands.com',
        password: 'admin123',
      );
      
      _addOutput('Login response: ${response.toString()}');
      _addOutput('Auth service authenticated: ${authService.isAuthenticated}');
      _addOutput('Auth service is admin: ${authService.isAdmin}');
      _addOutput('Auth service has token: ${authService.token != null}');
      
      if (authService.isAuthenticated && authService.isAdmin) {
        _addOutput('✅ Login successful! Ready to test reports API.');
      } else {
        _addOutput('❌ Login failed or user is not admin');
      }
    } catch (e) {
      _addOutput('❌ Login test failed: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _testReportsAPI() async {
    setState(() => _isLoading = true);
    _addOutput('=== TESTING REPORTS API ===');
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (!authService.isAuthenticated || !authService.isAdmin) {
        _addOutput('❌ Not authenticated as admin. Run login test first.');
        setState(() => _isLoading = false);
        return;
      }
      
      final reportsUrl = '${ApiConfig.currentApiBaseUrl}/admin/reports?page=1&limit=3';
      _addOutput('Testing: $reportsUrl');
      
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${authService.token}',
      };
      
      _addOutput('Headers: ${headers.toString()}');
      
      final response = await http.get(Uri.parse(reportsUrl), headers: headers);
      
      _addOutput('Status: ${response.statusCode}');
      _addOutput('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final reports = data['data']['reports'] as List;
          _addOutput('✅ Reports API test successful!');
          _addOutput('Found ${reports.length} reports');
          _addOutput('Total records: ${data['data']['pagination']['totalRecords']}');
        } else {
          _addOutput('❌ API returned success=false');
        }
      } else {
        _addOutput('❌ Reports API returned error status');
      }
    } catch (e) {
      _addOutput('❌ Reports API test failed: $e');
    }
    
    setState(() => _isLoading = false);
  }
}
