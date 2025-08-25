# API Services Architecture

This directory contains the API services for the PalHands Flutter app, designed with a centralized configuration approach for better maintainability and consistency.

## Architecture Overview

### 1. Centralized Configuration (`api_config.dart`)
All API URLs, endpoints, and configurations are centralized in `lib/core/constants/api_config.dart`.

**Benefits:**
- Single source of truth for all API endpoints
- Easy to switch between development and production environments
- Consistent timeout and header configurations
- No hardcoded URLs scattered throughout the codebase

### 2. Base API Service (`base_api_service.dart`)
Provides common HTTP functionality that all services can extend.

**Features:**
- Standardized HTTP methods (GET, POST, PUT, DELETE)
- Automatic error handling and timeout management
- Consistent response parsing
- Custom exception handling
- **Automatic retry mechanism** (configurable)
- **Request/response logging** (development only)
- **Environment-aware configuration**

### 3. Specific Services
Each service extends the base API service and uses the centralized configuration.

## Usage Examples

### Creating a New Service

```dart
import 'package:flutter/foundation.dart';
import '../../core/constants/api_config.dart';
import 'base_api_service.dart';

class MyService extends ChangeNotifier with BaseApiService {
  
  // GET request example
  Future<Map<String, dynamic>> getData() async {
    try {
      final response = await get(ApiConfig.usersEndpoint);
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get data failed: $e');
      }
      rethrow;
    }
  }
  
  // POST request example
  Future<Map<String, dynamic>> createData(Map<String, dynamic> data) async {
    try {
      final response = await post(
        ApiConfig.usersEndpoint,
        body: data,
      );
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Create data failed: $e');
      }
      rethrow;
    }
  }
}
```

### Using Services in Widgets

```dart
import 'package:provider/provider.dart';
import '../services/health_service.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<HealthService>(
      builder: (context, healthService, child) {
        return ElevatedButton(
          onPressed: () => healthService.checkHealth(),
          child: Text('Check Health'),
        );
      },
    );
  }
}
```

## Configuration

### Environment Switching
The system automatically detects the environment using build-time constants:

```bash
# Development (default)
flutter run

# Production
flutter run --dart-define=ENVIRONMENT=prod
```

Or update the `_environment` constant in `api_config.dart`:

```dart
static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
```

### Adding New Endpoints
To add new endpoints, simply add them to `api_config.dart`:

```dart
// API Endpoints
static const String healthEndpoint = '/health';
static const String authEndpoint = '/auth';
static const String newFeatureEndpoint = '/new-feature'; // Add here

// Full API URLs
static String get healthUrl => '$currentApiBaseUrl$healthEndpoint';
static String get newFeatureUrl => '$currentApiBaseUrl$newFeatureEndpoint'; // Add here
```

## Error Handling

The base API service provides standardized error handling:

- **Network errors**: Automatic detection and user-friendly messages
- **HTTP errors**: Status code and response body included in exceptions
- **Timeout errors**: Configurable timeout with clear error messages
- **Automatic retries**: Failed requests are retried up to 3 times by default
- **Detailed logging**: All requests and responses are logged in development mode

## Best Practices

1. **Always use the centralized configuration** - Never hardcode URLs in services
2. **Extend BaseApiService** - Use the provided HTTP methods for consistency
3. **Handle errors gracefully** - Use try-catch blocks and provide user feedback
4. **Use debug logging** - Include debug prints for development troubleshooting
5. **Notify listeners** - Call `notifyListeners()` when state changes in services

## File Structure

```
lib/
├── core/
│   └── constants/
│       └── api_config.dart          # Centralized API configuration
└── shared/
    └── services/
        ├── base_api_service.dart    # Base HTTP functionality
        ├── health_service.dart      # Health check service
        ├── auth_service.dart        # Authentication service
        └── README.md               # This documentation
```

## Testing

When testing services, you can mock the base API service or use the actual configuration:

```dart
// Test with actual configuration
final healthService = HealthService();
final isConnected = await healthService.checkHealth();

// Test with mocked configuration
// (Implement your preferred mocking strategy)
``` 