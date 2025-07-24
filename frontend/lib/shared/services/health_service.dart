import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class HealthService extends ChangeNotifier {
  static const String _baseUrl = 'http://localhost:3000'; // Backend URL
  static const String _healthEndpoint = '/api/health';
  
  bool _isConnected = false;
  bool _isLoading = true;
  String _errorMessage = '';
  DateTime? _lastCheckTime;

  // Getters
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  DateTime? get lastCheckTime => _lastCheckTime;

  // Check backend health
  Future<bool> checkHealth() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$_healthEndpoint'))
          .timeout(const Duration(seconds: 10));

      _lastCheckTime = DateTime.now();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          _isConnected = true;
          _errorMessage = '';
          if (kDebugMode) {
            print('✅ Backend health check successful: ${data['message']}');
          }
        } else {
          _isConnected = false;
          _errorMessage = 'Backend returned error status';
        }
      } else {
        _isConnected = false;
        _errorMessage = 'Backend responded with status: ${response.statusCode}';
      }
    } catch (e) {
      _isConnected = false;
      _errorMessage = _getErrorMessage(e);
      if (kDebugMode) {
        print('❌ Backend health check failed: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return _isConnected;
  }

  // Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'Unable to connect to server. Please check your internet connection.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Connection timeout. Server might be down or slow to respond.';
    } else if (error.toString().contains('Connection refused')) {
      return 'Server is not running. Please try again later.';
    } else {
      return 'Connection error: ${error.toString()}';
    }
  }

  // Reset connection status
  void reset() {
    _isConnected = false;
    _isLoading = true;
    _errorMessage = '';
    _lastCheckTime = null;
    notifyListeners();
  }

  // Retry connection
  Future<bool> retry() async {
    return await checkHealth();
  }
} 