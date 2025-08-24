import 'package:flutter/foundation.dart';

// Core imports
import '../../core/constants/api_config.dart';

// Shared imports
import 'base_api_service.dart';
import 'auth_service.dart';

class CustomServiceRequestService with BaseApiService {
  static final CustomServiceRequestService _instance = CustomServiceRequestService._internal();
  factory CustomServiceRequestService() => _instance;
  CustomServiceRequestService._internal();

  // Get authentication headers
  Map<String, String> _getAuthHeaders() {
    final authService = AuthService();
    final token = authService.token;
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  // Submit a custom service request
  Future<CustomServiceRequest> submitCustomServiceRequest({
    required String title,
    required String description,
    required String category,
    required double proposedPrice,
    required String currency,
    String? location,
    String? additionalDetails,
    List<String>? requirements,
    List<String>? equipment,
  }) async {
    try {
      final response = await post('/services/custom-requests', 
        body: {
          'title': title,
          'description': description,
          'category': category,
          'proposedPrice': proposedPrice,
          'currency': currency,
          if (location != null) 'location': location,
          if (additionalDetails != null) 'additionalDetails': additionalDetails,
          if (requirements != null) 'requirements': requirements,
          if (equipment != null) 'equipment': equipment,
          'status': 'pending',
        },
        headers: _getAuthHeaders(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return CustomServiceRequest.fromJson(response['data']);
      }
      
      throw ApiException('Failed to submit custom service request', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting custom service request: $e');
      }
      rethrow;
    }
  }

  // Get provider's custom service requests
  Future<List<CustomServiceRequest>> getMyCustomServiceRequests() async {
    try {
      final response = await get('/services/custom-requests/my-requests', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> requestsData = response['data'];
        return requestsData.map((request) => CustomServiceRequest.fromJson(request)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching custom service requests: $e');
      }
      rethrow;
    }
  }

  // Get all custom service requests (admin only)
  Future<List<CustomServiceRequest>> getAllCustomServiceRequests({
    String? status,
    int? page = 1,
    int? limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final queryString = queryParams.isNotEmpty 
          ? '?${Uri(queryParameters: queryParams).query}' 
          : '';

      final response = await get('/services/custom-requests$queryString', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> requestsData = response['data'];
        return requestsData.map((request) => CustomServiceRequest.fromJson(request)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching all custom service requests: $e');
      }
      rethrow;
    }
  }

  // Approve a custom service request (admin only)
  Future<bool> approveCustomServiceRequest(String requestId, {
    String? approvedTitle,
    String? approvedDescription,
    double? approvedPrice,
    String? approvedCategory,
    String? approvedSubcategory,
    String? notes,
  }) async {
    try {
      final response = await put('/services/custom-requests/$requestId/approve', 
        body: {
          'status': 'approved',
          if (approvedTitle != null) 'approvedTitle': approvedTitle,
          if (approvedDescription != null) 'approvedDescription': approvedDescription,
          if (approvedPrice != null) 'approvedPrice': approvedPrice,
          if (approvedCategory != null) 'approvedCategory': approvedCategory,
          if (approvedSubcategory != null) 'approvedSubcategory': approvedSubcategory,
          if (notes != null) 'notes': notes,
        },
        headers: _getAuthHeaders(),
      );
      
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error approving custom service request: $e');
      }
      rethrow;
    }
  }

  // Reject a custom service request (admin only)
  Future<bool> rejectCustomServiceRequest(String requestId, {String? reason}) async {
    try {
      final response = await put('/services/custom-requests/$requestId/reject', 
        body: {
          'status': 'rejected',
          if (reason != null) 'reason': reason,
        },
        headers: _getAuthHeaders(),
      );
      
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error rejecting custom service request: $e');
      }
      rethrow;
    }
  }

  // Update a custom service request
  Future<CustomServiceRequest> updateCustomServiceRequest(String requestId, {
    String? title,
    String? description,
    String? category,
    double? proposedPrice,
    String? currency,
    String? location,
    String? additionalDetails,
    List<String>? requirements,
    List<String>? equipment,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (category != null) updateData['category'] = category;
      if (proposedPrice != null) updateData['proposedPrice'] = proposedPrice;
      if (currency != null) updateData['currency'] = currency;
      if (location != null) updateData['location'] = location;
      if (additionalDetails != null) updateData['additionalDetails'] = additionalDetails;
      if (requirements != null) updateData['requirements'] = requirements;
      if (equipment != null) updateData['equipment'] = equipment;

      final response = await put('/services/custom-requests/$requestId', 
        body: updateData,
        headers: _getAuthHeaders(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return CustomServiceRequest.fromJson(response['data']);
      }
      
      throw ApiException('Failed to update custom service request', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating custom service request: $e');
      }
      rethrow;
    }
  }

  // Delete a custom service request
  Future<bool> deleteCustomServiceRequest(String requestId) async {
    try {
      final response = await delete('/services/custom-requests/$requestId', headers: _getAuthHeaders());
      
      return response['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting custom service request: $e');
      }
      rethrow;
    }
  }
}

class CustomServiceRequest {
  final String id;
  final String title;
  final String description;
  final String category;
  final double proposedPrice;
  final String currency;
  final String providerId;
  final String providerName;
  final String? location;
  final String? additionalDetails;
  final List<String> requirements;
  final List<String> equipment;
  final String status; // pending, approved, rejected
  final String? approvedTitle;
  final String? approvedDescription;
  final double? approvedPrice;
  final String? approvedCategory;
  final String? approvedSubcategory;
  final String? notes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomServiceRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.proposedPrice,
    required this.currency,
    required this.providerId,
    required this.providerName,
    this.location,
    this.additionalDetails,
    required this.requirements,
    required this.equipment,
    required this.status,
    this.approvedTitle,
    this.approvedDescription,
    this.approvedPrice,
    this.approvedCategory,
    this.approvedSubcategory,
    this.notes,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomServiceRequest.fromJson(Map<String, dynamic> json) {
    return CustomServiceRequest(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      proposedPrice: (json['proposedPrice'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'ILS',
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      location: json['location'],
      additionalDetails: json['additionalDetails'],
      requirements: List<String>.from(json['requirements'] ?? []),
      equipment: List<String>.from(json['equipment'] ?? []),
      status: json['status'] ?? 'pending',
      approvedTitle: json['approvedTitle'],
      approvedDescription: json['approvedDescription'],
      approvedPrice: json['approvedPrice'] != null ? (json['approvedPrice'] as num).toDouble() : null,
      approvedCategory: json['approvedCategory'],
      approvedSubcategory: json['approvedSubcategory'],
      notes: json['notes'],
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'proposedPrice': proposedPrice,
      'currency': currency,
      'providerId': providerId,
      'providerName': providerName,
      'location': location,
      'additionalDetails': additionalDetails,
      'requirements': requirements,
      'equipment': equipment,
      'status': status,
      'approvedTitle': approvedTitle,
      'approvedDescription': approvedDescription,
      'approvedPrice': approvedPrice,
      'approvedCategory': approvedCategory,
      'approvedSubcategory': approvedSubcategory,
      'notes': notes,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }
}
