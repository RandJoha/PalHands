import 'package:flutter/foundation.dart';

// Core imports
import '../../core/constants/api_config.dart';
import 'base_api_service.dart';

class AuthService extends ChangeNotifier with BaseApiService {
  String? _token;
  Map<String, dynamic>? _currentUser;
  bool _isAuthenticated = false;

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await post(
        '${ApiConfig.authEndpoint}/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response['success'] == true) {
        _token = response['token'];
        _currentUser = response['user'];
        _isAuthenticated = true;
        notifyListeners();
        
        if (kDebugMode) {
          print('✅ User logged in successfully: ${_currentUser?['email']}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Login failed: $e');
      }
      rethrow;
    }
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await post(
        '${ApiConfig.authEndpoint}/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        },
      );

      if (response['success'] == true) {
        _token = response['token'];
        _currentUser = response['user'];
        _isAuthenticated = true;
        notifyListeners();
        
        if (kDebugMode) {
          print('✅ User registered successfully: ${_currentUser?['email']}');
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Registration failed: $e');
      }
      rethrow;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      if (_token != null) {
        await post(
          '${ApiConfig.authEndpoint}/logout',
          headers: {'Authorization': 'Bearer $_token'},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Logout request failed: $e');
      }
    } finally {
      _token = null;
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ User logged out');
      }
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await get(
        '${ApiConfig.usersEndpoint}/profile',
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response['success'] == true) {
        _currentUser = response['user'];
        notifyListeners();
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get profile failed: $e');
      }
      rethrow;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (avatar != null) body['avatar'] = avatar;

      final response = await put(
        '${ApiConfig.usersEndpoint}/profile',
        body: body,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response['success'] == true) {
        _currentUser = response['user'];
        notifyListeners();
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Update profile failed: $e');
      }
      rethrow;
    }
  }

  // Check if token is valid
  Future<bool> validateToken() async {
    if (_token == null) return false;

    try {
      final response = await get(
        '${ApiConfig.authEndpoint}/validate',
        headers: {'Authorization': 'Bearer $_token'},
      );

      return response['valid'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token validation failed: $e');
      }
      return false;
    }
  }

  // Set token (for persistence)
  void setToken(String token) {
    _token = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
} 