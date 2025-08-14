import 'package:flutter/foundation.dart';
import 'dart:convert'; // Added for json.decode
import 'package:shared_preferences/shared_preferences.dart';

// Core imports
import '../../core/constants/api_config.dart';
import 'base_api_service.dart';

class AuthService extends ChangeNotifier with BaseApiService {
  String? _token;
  Map<String, dynamic>? _currentUser;
  bool _isAuthenticated = false;
  
  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize auth service and load persisted data
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      final savedUser = prefs.getString(_userKey);
      
      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        _currentUser = Map<String, dynamic>.from(json.decode(savedUser));
        _isAuthenticated = true;
        notifyListeners();
        
        if (kDebugMode) {
          print('✅ Auth service initialized with persisted data');
        }
      } else if (savedToken != null && savedUser == null) {
        // Recover session if we have a token but no user data persisted
        _token = savedToken;
        final valid = await validateToken();
        _isAuthenticated = valid;
        if (valid) {
          if (kDebugMode) {
            print('✅ Auth service restored session via token validation');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize auth service: $e');
      }
      // Clear any corrupted data
      await _clearPersistedData();
    }
  }

  // Save token and user data to persistent storage
  Future<void> _savePersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString(_tokenKey, _token!);
      }
      if (_currentUser != null) {
        await prefs.setString(_userKey, json.encode(_currentUser));
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save persisted data: $e');
      }
    }
  }

  // Clear persisted data
  Future<void> _clearPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear persisted data: $e');
      }
    }
  }

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
    // Support both flat and { data: { token, user } } API shapes
    final data = (response['data'] is Map<String, dynamic>)
      ? Map<String, dynamic>.from(response['data'])
      : <String, dynamic>{};
    _token = (data['token'] ?? response['token']) as String?;
    final user = data['user'] ?? response['user'] ?? data;
    _currentUser = user is Map<String, dynamic>
      ? Map<String, dynamic>.from(user)
      : null;
        _isAuthenticated = true;
        
        // Save to persistent storage
        await _savePersistedData();
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
    // Support both flat and { data: { token, user } } API shapes
    final data = (response['data'] is Map<String, dynamic>)
      ? Map<String, dynamic>.from(response['data'])
      : <String, dynamic>{};
    _token = (data['token'] ?? response['token']) as String?;
    final user = data['user'] ?? response['user'] ?? data;
    _currentUser = user is Map<String, dynamic>
      ? Map<String, dynamic>.from(user)
      : null;
        _isAuthenticated = true;
        
        // Save to persistent storage
        await _savePersistedData();
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
      // Attempt to notify backend about logout
      if (_token != null) {
        try {
          await post(
            '${ApiConfig.authEndpoint}/logout',
            headers: {'Authorization': 'Bearer $_token'},
          );
        } catch (e) {
          // Don't fail logout if backend request fails
          if (kDebugMode) {
            print('⚠️ Backend logout request failed: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Logout request failed: $e');
      }
    } finally {
      // Always clear local data regardless of backend response
      await _clearAllData();
    }
  }

  // Clear all data (local and persisted)
  Future<void> _clearAllData() async {
    // Clear in-memory data
    _token = null;
    _currentUser = null;
    _isAuthenticated = false;
    
    // Clear persisted data
    await _clearPersistedData();
    
    // Notify listeners
    notifyListeners();
    
    if (kDebugMode) {
      print('✅ User logged out - all data cleared');
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
        // Backend returns ok({ ...userFields }) so user lives under data
        final data = (response['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(response['data'])
            : (response['user'] is Map<String, dynamic>)
                ? Map<String, dynamic>.from(response['user'])
                : <String, dynamic>{};
        _currentUser = data.isNotEmpty ? data : _currentUser;
        await _savePersistedData();
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
        // Unified shape handling: data contains updated user
        final data = (response['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(response['data'])
            : (response['user'] is Map<String, dynamic>)
                ? Map<String, dynamic>.from(response['user'])
                : <String, dynamic>{};
        _currentUser = data.isNotEmpty ? data : _currentUser;
        await _savePersistedData();
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

      // Backend shape: ok({ valid: true, user: {...} })
      final data = (response['data'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(response['data'])
          : <String, dynamic>{};
      final isValid = (data['valid'] ?? response['valid']) == true;
      if (isValid && data['user'] is Map<String, dynamic>) {
        _currentUser = Map<String, dynamic>.from(data['user']);
        await _savePersistedData();
        notifyListeners();
      }
      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Token validation failed: $e');
      }
      // If token validation fails, clear the data
      await _clearAllData();
      return false;
    }
  }

  // Set token (for persistence)
  void setToken(String token) {
    _token = token;
    _isAuthenticated = true;
    _savePersistedData();
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _clearAllData();
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