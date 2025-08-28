import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_config.dart';
import 'auth_service.dart';

class ReportModel {
  final String id;
  final String? reporterId;
  final String? reporterRole;
  final String reportCategory;
  final String? reportedType;
  final String? reportedId;
  final String? reportedUserRole;
  final String? reportedName;
  final String? issueType;
  final String description;
  final String? contactEmail;
  final String? contactName;
  final String? subject;
  final String? requestedCategory;
  final String? serviceName;
  final String? categoryFit;
  final String? importanceReason;
  final String? ideaTitle;
  final String? communityBenefit;
  final String? device;
  final String? os;
  final String? appVersion;
  final Map<String, dynamic>? partyInfo;
  final String? relatedBookingId;
  final String? reportedServiceId;
  final List<String> evidence;
  final String status;
  final String? assignedAdminId;
  final String? adminNote;
  final String? resolution;
  final String? resolutionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? reporter;
  final Map<String, dynamic>? assignedAdmin;

  ReportModel({
    required this.id,
    this.reporterId,
    this.reporterRole,
    required this.reportCategory,
    this.reportedType,
    this.reportedId,
    this.reportedUserRole,
    this.reportedName,
    this.issueType,
    required this.description,
    this.contactEmail,
    this.contactName,
    this.subject,
    this.requestedCategory,
    this.serviceName,
    this.categoryFit,
    this.importanceReason,
    this.ideaTitle,
    this.communityBenefit,
    this.device,
    this.os,
    this.appVersion,
    this.partyInfo,
    this.relatedBookingId,
    this.reportedServiceId,
    required this.evidence,
    required this.status,
    this.assignedAdminId,
    this.adminNote,
    this.resolution,
    this.resolutionReason,
    required this.createdAt,
    required this.updatedAt,
    this.reporter,
    this.assignedAdmin,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      reporterId: json['reporter']?.toString(),
      reporterRole: json['reporterRole']?.toString(),
      reportCategory: json['reportCategory']?.toString() ?? '',
      reportedType: json['reportedType']?.toString(),
      reportedId: json['reportedId']?.toString(),
      reportedUserRole: json['reportedUserRole']?.toString(),
      reportedName: json['reportedName']?.toString(),
      issueType: json['issueType']?.toString(),
      description: json['description']?.toString() ?? '',
      contactEmail: json['contactEmail']?.toString(),
      contactName: json['contactName']?.toString(),
      subject: json['subject']?.toString(),
      requestedCategory: json['requestedCategory']?.toString(),
      serviceName: json['serviceName']?.toString(),
      categoryFit: json['categoryFit']?.toString(),
      importanceReason: json['importanceReason']?.toString(),
      ideaTitle: json['ideaTitle']?.toString(),
      communityBenefit: json['communityBenefit']?.toString(),
      device: json['device']?.toString(),
      os: json['os']?.toString(),
      appVersion: json['appVersion']?.toString(),
      partyInfo: json['partyInfo'] is Map ? Map<String, dynamic>.from(json['partyInfo']) : null,
      relatedBookingId: json['relatedBookingId']?.toString(),
      reportedServiceId: json['reportedServiceId']?.toString(),
      evidence: (json['evidence'] as List?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status']?.toString() ?? 'pending',
      assignedAdminId: json['assignedAdmin']?.toString(),
      adminNote: json['adminNote']?.toString(),
      resolution: json['resolution']?.toString(),
      resolutionReason: json['resolutionReason']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      reporter: json['reporter'] is Map ? Map<String, dynamic>.from(json['reporter']) : null,
      assignedAdmin: json['assignedAdmin'] is Map ? Map<String, dynamic>.from(json['assignedAdmin']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterRole': reporterRole,
      'reportCategory': reportCategory,
      'reportedType': reportedType,
      'reportedId': reportedId,
      'reportedUserRole': reportedUserRole,
      'reportedName': reportedName,
      'issueType': issueType,
      'description': description,
      'contactEmail': contactEmail,
      'contactName': contactName,
      'subject': subject,
      'requestedCategory': requestedCategory,
      'serviceName': serviceName,
      'categoryFit': categoryFit,
      'importanceReason': importanceReason,
      'ideaTitle': ideaTitle,
      'communityBenefit': communityBenefit,
      'device': device,
      'os': os,
      'appVersion': appVersion,
      'partyInfo': partyInfo,
      'relatedBookingId': relatedBookingId,
      'reportedServiceId': reportedServiceId,
      'evidence': evidence,
      'status': status,
      'assignedAdminId': assignedAdminId,
      'adminNote': adminNote,
      'resolution': resolution,
      'resolutionReason': resolutionReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reporter': reporter,
      'assignedAdmin': assignedAdmin,
    };
  }
}

class ReportsService {
  static final ReportsService _instance = ReportsService._internal();
  factory ReportsService() => _instance;
  ReportsService._internal();

  // Get authentication headers
  Map<String, String> get _authHeaders {
    final authService = AuthService();
    final token = authService.token;
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      if (kDebugMode) {
        print('🔐 Using auth token: ${token.substring(0, 20)}...');
      }
    } else {
      if (kDebugMode) {
        print('⚠️ No auth token available - proceeding with anonymous submission');
      }
    }
    
    return headers;
  }

  // Create a new report
  Future<Map<String, dynamic>> createReport({
    required String reportCategory,
    String? reportedType,
    String? reportedId,
    String? reportedUserRole,
    String? reportedName,
    String? issueType,
    required String description,
    String? contactEmail,
    String? contactName,
    String? subject,
    String? requestedCategory,
    String? serviceName,
    String? categoryFit,
    String? importanceReason,
    String? ideaTitle,
    String? communityBenefit,
    String? device,
    String? os,
    String? appVersion,
    Map<String, dynamic>? partyInfo,
    String? relatedBookingId,
    String? reportedServiceId,
    List<String> evidence = const [],
    String? idempotencyKey,
  }) async {
    try {
      final body = <String, dynamic>{
        'reportCategory': reportCategory,
        'description': description,
        'evidence': evidence,
      };

      if (reportedType != null) body['reportedType'] = reportedType;
      if (reportedId != null) body['reportedId'] = reportedId;
      if (reportedUserRole != null) body['reportedUserRole'] = reportedUserRole;
      if (reportedName != null) body['reportedName'] = reportedName;
      if (issueType != null) body['issueType'] = issueType;
      if (contactEmail != null) body['contactEmail'] = contactEmail;
      if (contactName != null) body['contactName'] = contactName;
      if (subject != null) body['subject'] = subject;
      if (requestedCategory != null) body['requestedCategory'] = requestedCategory;
      if (serviceName != null) body['serviceName'] = serviceName;
      if (categoryFit != null) body['categoryFit'] = categoryFit;
      if (importanceReason != null) body['importanceReason'] = importanceReason;
      if (ideaTitle != null) body['ideaTitle'] = ideaTitle;
      if (communityBenefit != null) body['communityBenefit'] = communityBenefit;
      if (device != null) body['device'] = device;
      if (os != null) body['os'] = os;
      if (appVersion != null) body['appVersion'] = appVersion;
      if (partyInfo != null) body['partyInfo'] = partyInfo;
      if (relatedBookingId != null) body['relatedBookingId'] = relatedBookingId;
      if (reportedServiceId != null) body['reportedServiceId'] = reportedServiceId;
      if (idempotencyKey != null) body['idempotencyKey'] = idempotencyKey;

      final headers = <String, String>{..._authHeaders};
      if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;

      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/reports');
      
      if (kDebugMode) {
        print('📤 Sending report to: $uri');
        print('📤 Headers: $headers');
        print('📤 Body: ${json.encode(body)}');
      }
      
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': ReportModel.fromJson(data['data']),
          };
        }
        return data;
      }

      // Log the error response for debugging
      if (kDebugMode) {
        print('❌ Report creation failed with status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }

      final errorData = json.decode(response.body);
      return {
        'success': false,
        'message': errorData['message'] ?? 'Failed to create report (Status: ${response.statusCode})',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Create report failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Admin: List all reports
  Future<Map<String, dynamic>> listAllReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? reportCategory,
    String? issueType,
    bool? hasEvidence,
    String? assignedAdmin,
    bool? awaitingUser,
    String sort = 'createdAt:desc',
    Map<String, String>? headersOverride,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };

      if (status != null) queryParams['status'] = status;
      if (reportCategory != null) queryParams['reportCategory'] = reportCategory;
      if (issueType != null) queryParams['issueType'] = issueType;
      if (hasEvidence != null) queryParams['hasEvidence'] = hasEvidence.toString();
      if (assignedAdmin != null) queryParams['assignedAdmin'] = assignedAdmin;
      if (awaitingUser != null) queryParams['awaiting_user'] = awaitingUser.toString();

      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/admin/reports')
          .replace(queryParameters: queryParams);

      final headers = headersOverride ?? _authHeaders;
      if (kDebugMode) {
        print('📤 Fetching admin reports from: $uri');
        print('📤 Headers: $headers');
      }

      final response = await http.get(uri, headers: headers);

      if (kDebugMode) {
        print('📊 Response status: ${response.statusCode}');
        print('📊 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final reports = (data['data']['reports'] as List)
              .map((item) => ReportModel.fromJson(item))
              .toList();

          if (kDebugMode) {
            print('✅ Successfully fetched ${reports.length} reports');
          }

          return {
            'success': true,
            'data': {
              'reports': reports,
              'pagination': data['data']['pagination'],
            },
          };
        }
        return data;
      }

      if (kDebugMode) {
        print('❌ Failed to fetch reports - Status: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }

      return {
        'success': false,
        'message': 'Failed to fetch reports (Status: ${response.statusCode})',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ List all reports failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Admin: Update report
  Future<Map<String, dynamic>> updateReport(
    String reportId, {
    String? status,
    String? assignedAdminId,
    String? adminNote,
    Map<String, String>? headersOverride,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (assignedAdminId != null) body['assignedAdmin'] = assignedAdminId;
      if (adminNote != null) body['adminNote'] = adminNote;

      if (kDebugMode) {
        print('📤 Updating report $reportId with body: $body');
      }

      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/admin/reports/$reportId');
      final response = await http.put(
        uri,
        headers: headersOverride ?? _authHeaders,
        body: json.encode(body),
      );

      if (kDebugMode) {
        print('📊 Update response status: ${response.statusCode}');
        print('📊 Update response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': ReportModel.fromJson(data['data']),
          };
        }
        return data;
      }

      // Try to parse error response
      try {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update report (Status: ${response.statusCode})',
        };
      } catch (parseError) {
        return {
          'success': false,
          'message': 'Failed to update report (Status: ${response.statusCode})',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Update report failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Admin: Resolve report
  Future<Map<String, dynamic>> resolveReport(
    String reportId, {
    required String action,
    required String reason,
    String? details,
  }) async {
    try {
      final body = {
        'action': action,
        'reason': reason,
        if (details != null) 'details': details,
      };

      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/admin/reports/$reportId/resolve');
      final response = await http.put(
        uri,
        headers: _authHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': ReportModel.fromJson(data['data']),
          };
        }
        return data;
      }

      return {
        'success': false,
        'message': 'Failed to resolve report',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Resolve report failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Admin: Dismiss report
  Future<Map<String, dynamic>> dismissReport(
    String reportId, {
    required String reason,
  }) async {
    try {
      final body = {
        'reason': reason,
      };

      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/admin/reports/$reportId/dismiss');
      final response = await http.put(
        uri,
        headers: _authHeaders,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'data': ReportModel.fromJson(data['data']),
          };
        }
        return data;
      }

      return {
        'success': false,
        'message': 'Failed to dismiss report',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Dismiss report failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Admin: Get reports statistics
  Future<Map<String, dynamic>> getReportsStats({
    String? since, 
    Map<String, String>? headersOverride,
    Map<String, String>? queryParams,
  }) async {
    try {
      final params = <String, String>{};
      if (since != null) params['since'] = since;
      if (queryParams != null) params.addAll(queryParams);

      final uri = Uri.parse('${ApiConfig.currentApiBaseUrl}/admin/reports/stats')
          .replace(queryParameters: params);

      final response = await http.get(uri, headers: headersOverride ?? _authHeaders);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      return {
        'success': false,
        'message': 'Failed to get reports stats',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get reports stats failed: $e');
      }
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
