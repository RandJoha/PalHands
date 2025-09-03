import 'package:flutter/foundation.dart';

class ApiConfig {
  // Environment detection
  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
  
  // Development vs Production URLs
  static const String devBaseUrl = 'http://localhost:3001';
  static const String prodBaseUrl = 'https://api.palhands.com'; // Change this to your production URL
  
  // Force backend URL for web development
  static const String webDevBackendUrl = 'http://localhost:3001';
  
  // Get the appropriate base URL based on environment
  static String get currentBaseUrl {
    // For web development, always use the backend URL
    if (kIsWeb && _environment == 'dev') {
      return webDevBackendUrl;
    }
    
    switch (_environment) {
      case 'prod':
        return prodBaseUrl;
      case 'dev':
      default:
        return devBaseUrl;
    }
  }
  
  static String get currentApiBaseUrl => '$currentBaseUrl/api';
  
  // Environment info
  static bool get isDevelopment => _environment == 'dev';
  static bool get isProduction => _environment == 'prod';
  
  // API Endpoints
  static const String healthEndpoint = '/health';
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String servicesEndpoint = '/services';
  static const String bookingsEndpoint = '/bookings';
  static const String paymentsEndpoint = '/payments';
  static const String reviewsEndpoint = '/reviews';
  static const String adminEndpoint = '/admin';
  
  // Full API URLs
  static String get healthUrl => '$currentApiBaseUrl$healthEndpoint';
  static String get authUrl => '$currentApiBaseUrl$authEndpoint';
  static String get usersUrl => '$currentApiBaseUrl$usersEndpoint';
  static String get servicesUrl => '$currentApiBaseUrl$servicesEndpoint';
  static String get bookingsUrl => '$currentApiBaseUrl$bookingsEndpoint';
  static String get paymentsUrl => '$currentApiBaseUrl$paymentsEndpoint';
  static String get reviewsUrl => '$currentApiBaseUrl$reviewsEndpoint';
  static String get adminUrl => '$currentApiBaseUrl$adminEndpoint';
  
  // Timeout configurations
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Logging configuration
  static bool get enableLogging => isDevelopment;
  
  // File upload configurations
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  
  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  ];
} 