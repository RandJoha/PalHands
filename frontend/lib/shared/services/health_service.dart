import 'package:flutter/foundation.dart';

// Core imports
import '../../core/constants/api_config.dart';
import 'base_api_service.dart';

class HealthService extends ChangeNotifier with BaseApiService {
  
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
      final data = await get(ApiConfig.healthEndpoint);
      
      _lastCheckTime = DateTime.now();

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
    if (error is ApiException) {
      return error.message;
    }
    return 'Connection error: ${error.toString()}';
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