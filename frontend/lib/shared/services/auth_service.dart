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
  String? get userId {
    final id = _currentUser?['_id'] ?? _currentUser?['id'];
    return id?.toString();
  }

  // Initialize auth service and load persisted data
  Future<void> initialize() async {
    try {
      // if (kDebugMode) {
      //   print('🚀 Auth service - Starting initialization...');
      // }
      
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      final savedUser = prefs.getString(_userKey);
      
      // if (kDebugMode) {
      //   print('🔍 Auth service - Checking persisted data:');
      //   print('  - Saved token present: ${savedToken != null}');
      //   print('  - Saved user present: ${savedUser != null}');
      //   if (savedToken != null) {
      //     print('  - Saved token length: ${savedToken.length}');
      //     print('  - Saved token preview: ${savedToken.substring(0, savedToken.length > 30 ? 30 : savedToken.length)}...');
      //   }
      // }
      
      if (savedToken != null && savedUser != null) {
        _token = savedToken;
        _currentUser = Map<String, dynamic>.from(json.decode(savedUser));
        _isAuthenticated = true;
        notifyListeners();
        
        // if (kDebugMode) {
        //   print('✅ Auth service initialized with persisted data');
        //   print('  - Token loaded: ${_token != null}');
        //   print('  - User loaded: ${_currentUser != null}');
        //   print('  - Is authenticated: $_isAuthenticated');
        //   print('  - Current user email: ${_currentUser?['email'] ?? 'None'}');
        // }
        // Always refresh profile in the background to sync latest fields (e.g., email changed)
        try { await getProfile(); } catch (_) {}
      } else if (savedToken != null && savedUser == null) {
        // Recover session if we have a token but no user data persisted
        // if (kDebugMode) {
        //   print('🔄 Auth service - Token found but no user data, attempting recovery...');
        // }
        _token = savedToken;
        final valid = await validateToken();
        _isAuthenticated = valid;
        if (valid) {
          // if (kDebugMode) {
          //   print('✅ Auth service restored session via token validation');
          // }
          // Fetch full profile after validating token
          try { await getProfile(); } catch (_) {}
        } else {
          // if (kDebugMode) {
          //   print('❌ Auth service - Token validation failed, clearing token');
          // }
          await _clearPersistedData();
        }
      } else {
        // if (kDebugMode) {
        //   print('ℹ️ Auth service - No persisted data found, starting fresh');
        //   print('  - Token: null');
        //   print('  - User: null');
        //   print('  - Is authenticated: false');
        // }
      }
      
      // if (kDebugMode) {
      //   print('🏁 Auth service - Initialization complete');
      //   print('  - Final token state: ${_token != null}');
      //   print('  - Final user state: ${_currentUser != null}');
      //   print('  - Final auth state: $_isAuthenticated');
      // }
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Failed to initialize auth service: $e');
      //   print('  - Error type: ${e.runtimeType}');
      //   print('  - Stack trace: ${StackTrace.current}');
      // }
      // Clear any corrupted data
      await _clearPersistedData();
    }
  }

  // Save token and user data to persistent storage
  Future<void> _savePersistedData() async {
    try {
      // if (kDebugMode) {
      //   print('💾 Auth service - _savePersistedData called');
      //   print('  - Token to save: ${_token != null}');
      //   print('  - User to save: ${_currentUser != null}');
      // }
      
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString(_tokenKey, _token!);
        // if (kDebugMode) {
        //   print('✅ Token saved to persistent storage');
        // }
      } else {
        // if (kDebugMode) {
        //   print('⚠️ No token to save');
        // }
      }
      
      if (_currentUser != null) {
        await prefs.setString(_userKey, json.encode(_currentUser));
        // if (kDebugMode) {
        //   print('✅ User data saved to persistent storage');
        // }
      } else {
        // if (kDebugMode) {
        //   print('⚠️ No user data to save');
        // }
      }
      
      // if (kDebugMode) {
      //   print('✅ _savePersistedData completed successfully');
      // }
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Failed to save persisted data: $e');
      //   print('  - Error type: ${e.runtimeType}');
      //   print('  - Stack trace: ${StackTrace.current}');
      // }
    }
  }

  // Clear persisted data
  Future<void> _clearPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Failed to clear persisted data: $e');
      // }
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
        // if (kDebugMode) {
        //   print('💾 Auth service - Saving login data to persistent storage...');
        //   print('  - Token to save: ${_token != null}');
        //   print('  - User to save: ${_currentUser != null}');
        // }
        
        await _savePersistedData();
        notifyListeners();
        
        // if (kDebugMode) {
        //   print('✅ User logged in successfully: ${_currentUser?['email']}');
        //   print('  - Final token state: ${_token != null}');
        //   print('  - Final user state: ${_currentUser != null}');
        //   print('  - Final auth state: $_isAuthenticated');
        // }
      }

      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Login failed: $e');
      // }
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
    int? age,
    String? city,
    String? street,
    String? area,
    Map<String, dynamic>? providerSelections,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      };
      if (age != null) body['age'] = age;
      if (city != null || street != null || area != null) {
        body['address'] = {
          if (city != null) 'city': city,
          if (street != null) 'street': street,
          if (area != null) 'area': area,
        };
      }
     if (providerSelections != null && providerSelections.isNotEmpty) {
       body['providerSelections'] = providerSelections;
     }
      final response = await post(
        '${ApiConfig.authEndpoint}/register',
        body: body,
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
        
        // if (kDebugMode) {
        //   print('✅ User registered successfully: ${_currentUser?['email']}');
        // }
      }

      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Registration failed: $e');
      // }
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
      // if (kDebugMode) {
      //   print('❌ Logout request failed: $e');
      // }
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
    
    // if (kDebugMode) {
    //   print('✅ User logged out - all data cleared');
    // }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await get(
  // Backend exposes GET /api/auth/profile for current user
  '${ApiConfig.authEndpoint}/profile',
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
      // if (kDebugMode) {
      //   print('❌ Get profile failed: $e');
      // }
      rethrow;
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await put(
        '${ApiConfig.usersEndpoint}/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        headers: {'Authorization': 'Bearer $_token'},
      );

      // On success, backend returns ok({}) with a message; no user change expected
      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Change password failed: $e');
      // }
      rethrow;
    }
  }

  // Change password directly (no login) by verifying email + currentPassword
  Future<Map<String, dynamic>> changePasswordDirect({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await post(
        '${ApiConfig.authEndpoint}/change-password-direct',
        body: {
          'email': email,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        headers: { 'Content-Type': 'application/json' },
      );
      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Change password direct failed: $e');
      // }
      rethrow;
    }
  }

  // Forgot password - request reset link
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await post(
        '${ApiConfig.authEndpoint}/forgot-password',
        body: { 'email': email },
        headers: { 'Content-Type': 'application/json' },
      );
      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Forgot password failed: $e');
      // }
      rethrow;
    }
  }

  // Reset password with token (from email)
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await post(
        '${ApiConfig.authEndpoint}/reset-password',
        body: { 'token': token, 'newPassword': newPassword },
        headers: { 'Content-Type': 'application/json' },
      );
      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Reset password failed: $e');
      // }
      rethrow;
    }
  }

  // Request email verification (if not verified)
  Future<Map<String, dynamic>> requestVerification() async {
    try {
      final response = await post(
        '${ApiConfig.authEndpoint}/request-verification',
        headers: {'Authorization': 'Bearer $_token'},
      );
      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Request verification failed: $e');
      // }
      rethrow;
    }
  }

  // Confirm email change using token from email
  Future<Map<String, dynamic>> confirmEmailChange(String token) async {
    try {
      final response = await post(
        '${ApiConfig.authEndpoint}/confirm-email-change',
        body: { 'token': token },
        headers: { 'Content-Type': 'application/json' },
      );
      // Refresh profile if logged in
      if (_isAuthenticated) {
        try { await getProfile(); } catch (_) {}
      }
      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Confirm email change failed: $e');
      // }
      rethrow;
    }
  }

  // Verify email with token (deep link)
  Future<Map<String, dynamic>> verifyEmail(String token) async {
    try {
      final response = await post(
        '${ApiConfig.authEndpoint}/verify',
        body: { 'token': token },
        headers: { 'Content-Type': 'application/json' },
      );
      // If logged in, refresh profile to update isVerified flag
      if (_isAuthenticated) {
        try { await getProfile(); } catch (_) {}
      }
      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Verify email failed: $e');
      // }
      rethrow;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    int? age,
    String? profileImage,
    Map<String, dynamic>? address,
    List<Map<String, dynamic>>? addresses,
    bool? useGpsLocation,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
  if (phone != null) body['phone'] = phone;
  if (email != null) body['email'] = email;
  if (age != null) body['age'] = age;
      if (profileImage != null) body['profileImage'] = profileImage;
      if (address != null) body['address'] = address;
      if (addresses != null) body['addresses'] = addresses;
      if (useGpsLocation != null) body['useGpsLocation'] = useGpsLocation;

      final response = await put(
        '${ApiConfig.usersEndpoint}/profile',
        body: body,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response['success'] == true) {
        // Prefer data.user, else top-level user
        final data = (response['data'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(response['data'])
            : <String, dynamic>{};
        final userPayload = (data['user'] is Map<String, dynamic>)
            ? Map<String, dynamic>.from(data['user'])
            : (response['user'] is Map<String, dynamic>)
                ? Map<String, dynamic>.from(response['user'])
                : <String, dynamic>{};
        if (userPayload.isNotEmpty) {
          _currentUser = userPayload;
        }
        await _savePersistedData();
        notifyListeners();
      }

      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Update profile failed: $e');
      // }
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
      // if (kDebugMode) {
      //   print('❌ Token validation failed: $e');
      // }
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

  // Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    if (_token == null) {
      throw Exception('No authentication token available');
    }

    try {
      final response = await delete(
        '${ApiConfig.authEndpoint}/account',
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response['success'] == true) {
        // Clear all data after successful deletion
        await _clearAllData();
      }

      return response;
    } catch (e) {
      // if (kDebugMode) {
      //   print('❌ Delete account failed: $e');
      // }
      rethrow;
    }
  }
}