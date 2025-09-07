import 'package:flutter/foundation.dart';
import 'base_api_service.dart';
import 'auth_service.dart';
import '../../core/constants/api_config.dart';

class FavoritesService with BaseApiService {
  /// Add provider to favorites
  Future<Map<String, dynamic>> addToFavorites(
    String providerId, {
    required AuthService authService,
  }) async {
    final response = await post(
      '${ApiConfig.usersEndpoint}/favorites/$providerId',
      headers: _getAuthHeadersFromService(authService),
    );

    if (kDebugMode) {
      print('✅ Provider added to favorites: $providerId');
    }

    return response;
  }

  /// Remove provider from favorites
  Future<Map<String, dynamic>> removeFromFavorites(
    String providerId, {
    required AuthService authService,
  }) async {
    final response = await delete(
      '${ApiConfig.usersEndpoint}/favorites/$providerId',
      headers: _getAuthHeadersFromService(authService),
    );

    if (kDebugMode) {
      print('✅ Provider removed from favorites: $providerId');
    }

    return response;
  }

  /// Get user's favorite providers
  Future<List<Map<String, dynamic>>> getFavoriteProviders({
    required AuthService authService,
  }) async {
    final response = await get(
      '${ApiConfig.usersEndpoint}/favorites',
      headers: _getAuthHeadersFromService(authService),
    );

    if (kDebugMode) {
      print('✅ Favorite providers fetched successfully');
      print('📊 Response data: ${response['data']}');
      print('📊 Response data type: ${response['data'].runtimeType}');
      if (response['data'] != null) {
        print('📊 Data length: ${(response['data'] as List).length}');
        for (int i = 0; i < (response['data'] as List).length; i++) {
          final provider = (response['data'] as List)[i];
          print('📊 Provider $i: ${provider}');
        }
      }
    }

    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  /// Check if provider is favorite
  Future<bool> isProviderFavorite(
    String providerId, {
    required AuthService authService,
  }) async {
    final response = await get(
      '${ApiConfig.usersEndpoint}/favorites/$providerId/check',
      headers: _getAuthHeadersFromService(authService),
    );

    if (kDebugMode) {
      print('✅ Favorite status checked for provider: $providerId');
    }

    return response['data']?['isFavorite'] ?? false;
  }

  /// Get auth headers from AuthService
  Map<String, String> _getAuthHeadersFromService(AuthService authService) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authService.token != null) {
      headers['Authorization'] = 'Bearer ${authService.token}';
    }

    return headers;
  }
}
