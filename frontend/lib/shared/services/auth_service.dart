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
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    String role = 'client',
  }) async {
    try {
      final response = await post(
        '${ApiConfig.authEndpoint}/register',
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
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
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImage,
    Map<String, dynamic>? address,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (phone != null) body['phone'] = phone;
      if (profileImage != null) body['profileImage'] = profileImage;
      if (address != null) body['address'] = address;

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

  // Get user role
  String? get userRole => _currentUser?['role'];

  // Check if user is admin
  bool get isAdmin => _currentUser?['role'] == 'admin';

  // Check if user is provider
  bool get isProvider => _currentUser?['role'] == 'provider';

  // Check if user is client
  bool get isClient => _currentUser?['role'] == 'client';

  // Get user full name
  String get userFullName {
    if (_currentUser == null) return '';
    final firstName = _currentUser!['firstName'] ?? '';
    final lastName = _currentUser!['lastName'] ?? '';
    return '$firstName $lastName'.trim();
  }

  // Check if user is verified
  bool get isVerified => _currentUser?['isVerified'] ?? false;

  // Check if user is active
  bool get isActive => _currentUser?['isActive'] ?? false;
} 