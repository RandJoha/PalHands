import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'base_api_service.dart';

class ImageUploadResult {
  final bool success;
  final String? url;
  final String? error;
  final double progress;

  ImageUploadResult({
    required this.success,
    this.url,
    this.error,
    this.progress = 1.0,
  });
}

class ImageUploadService with BaseApiService {
  static const String _storageDriver = String.fromEnvironment('STORAGE_DRIVER', defaultValue: 'local');
  static const int _maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> _allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

  // Upload image with environment-driven storage
  Future<ImageUploadResult> uploadImage({
    required String serviceId,
    required File imageFile,
    required Function(double) onProgress,
  }) async {
    try {
      // Validate file
      final validationResult = await _validateFile(imageFile);
      if (!validationResult.success) {
        return ImageUploadResult(
          success: false,
          error: validationResult.error,
        );
      }

      if (_storageDriver == 'local') {
        return await _uploadToLocal(serviceId, imageFile, onProgress);
      } else {
        return await _uploadToS3(serviceId, imageFile, onProgress);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error uploading image: $e');
      }
      return ImageUploadResult(
        success: false,
        error: 'Upload failed: $e',
      );
    }
  }

  // Upload multiple images
  Future<List<ImageUploadResult>> uploadImages({
    required String serviceId,
    required List<File> imageFiles,
    required Function(double) onProgress,
  }) async {
    final results = <ImageUploadResult>[];
    final totalFiles = imageFiles.length;

    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileProgress = (i / totalFiles) * 100;
      
      onProgress(fileProgress);
      
      final result = await uploadImage(
        serviceId: serviceId,
        imageFile: file,
        onProgress: (progress) {
          // Calculate overall progress
          final overallProgress = fileProgress + (progress / totalFiles);
          onProgress(overallProgress);
        },
      );
      
      results.add(result);
      
      if (!result.success) {
        // Stop on first failure
        break;
      }
    }

    return results;
  }

  // Local upload (development)
  Future<ImageUploadResult> _uploadToLocal(
    String serviceId,
    File imageFile,
    Function(double) onProgress,
  ) async {
    try {
      onProgress(0.1);

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_getBaseUrl()}/api/services/$serviceId/images'),
      );

      // Add auth headers
      final headers = _getAuthHeaders();
      request.headers.addAll(headers);

      // Add file
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'images',
        stream,
        length,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      onProgress(0.3);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      onProgress(0.8);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = _parseResponse(response.body);
        if (responseData['success'] == true) {
          onProgress(1.0);
          return ImageUploadResult(
            success: true,
            url: responseData['data']?['images']?.last?['url'],
          );
        }
      }

      return ImageUploadResult(
        success: false,
        error: 'Upload failed: ${response.statusCode}',
      );
    } catch (e) {
      return ImageUploadResult(
        success: false,
        error: 'Local upload error: $e',
      );
    }
  }

  // S3 upload (production)
  Future<ImageUploadResult> _uploadToS3(
    String serviceId,
    File imageFile,
    Function(double) onProgress,
  ) async {
    try {
      onProgress(0.1);

      // Step 1: Get presigned URL
      final presignResponse = await post('/api/services/$serviceId/images/presign', 
        body: {
          'files': [{
            'filename': imageFile.path.split('/').last,
            'contentType': await _getContentType(imageFile),
            'size': await imageFile.length(),
          }],
        },
        headers: _getAuthHeaders(),
      );

      if (!presignResponse['success']) {
        return ImageUploadResult(
          success: false,
          error: 'Failed to get presigned URL',
        );
      }

      onProgress(0.3);

      final uploads = presignResponse['data']['uploads'] as List;
      if (uploads.isEmpty) {
        return ImageUploadResult(
          success: false,
          error: 'No presigned URLs received',
        );
      }

      final upload = uploads.first;
      final presignedUrl = upload['url'];
      final key = upload['key'];

      // Step 2: Upload to S3
      final fileBytes = await imageFile.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(presignedUrl),
        headers: {
          'Content-Type': await _getContentType(imageFile),
        },
        body: fileBytes,
      );

      onProgress(0.7);

      if (uploadResponse.statusCode != 200) {
        return ImageUploadResult(
          success: false,
          error: 'S3 upload failed: ${uploadResponse.statusCode}',
        );
      }

      // Step 3: Attach to service
      final attachResponse = await post('/api/services/$serviceId/images/attach',
        body: {
          'images': [{
            'key': key,
            'alt': imageFile.path.split('/').last,
          }],
        },
        headers: _getAuthHeaders(),
      );

      onProgress(1.0);

      if (attachResponse['success'] == true) {
        return ImageUploadResult(
          success: true,
          url: attachResponse['data']?['images']?.last?['url'],
        );
      }

      return ImageUploadResult(
        success: false,
        error: 'Failed to attach image to service',
      );
    } catch (e) {
      return ImageUploadResult(
        success: false,
        error: 'S3 upload error: $e',
      );
    }
  }

  // Validate file before upload
  Future<ImageUploadResult> _validateFile(File imageFile) async {
    try {
      // Check file size
      final size = await imageFile.length();
      if (size > _maxFileSize) {
        final maxSizeMB = _maxFileSize / (1024 * 1024);
        return ImageUploadResult(
          success: false,
          error: 'File too large. Maximum size is ${maxSizeMB.toInt()}MB.',
        );
      }

      // Check file type
      final contentType = await _getContentType(imageFile);
      if (!_allowedTypes.contains(contentType)) {
        return ImageUploadResult(
          success: false,
          error: 'Invalid file type. Only JPEG, PNG, WebP, and GIF files are allowed.',
        );
      }

      return ImageUploadResult(success: true);
    } catch (e) {
      return ImageUploadResult(
        success: false,
        error: 'File validation failed: $e',
      );
    }
  }

  // Get content type from file
  Future<String> _getContentType(File file) async {
    final path = file.path.toLowerCase();
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (path.endsWith('.png')) {
      return 'image/png';
    } else if (path.endsWith('.webp')) {
      return 'image/webp';
    } else if (path.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'application/octet-stream';
  }

  // Parse response
  Map<String, dynamic> _parseResponse(String responseBody) {
    try {
      return json.decode(responseBody);
    } catch (e) {
      return {'success': false, 'error': 'Invalid response format'};
    }
  }

  // Get base URL
  String _getBaseUrl() {
    // TODO: Get from environment or config
    return 'http://localhost:3000';
  }

  // Get auth headers
  Map<String, String> _getAuthHeaders() {
    // TODO: Implement proper auth token retrieval
    return {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer $token',
    };
  }
}
