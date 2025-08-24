import 'dart:convert';
import 'package:flutter/foundation.dart';

// Core imports
import '../../core/constants/api_config.dart';

// Shared imports
import 'base_api_service.dart';
import 'auth_service.dart';

class PaymentService with BaseApiService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Get authentication headers
  Map<String, String> _getAuthHeaders() {
    final authService = AuthService();
    final token = authService.token;
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  // Get available payment methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await get('/payments/methods', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> methodsData = response['data'];
        return methodsData.map((method) => PaymentMethod.fromJson(method)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching payment methods: $e');
      }
      rethrow;
    }
  }

  // Create a new payment
  Future<Payment> createPayment({
    required String bookingId,
    required String method,
    required double amount,
    String? currency = 'ILS',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await post('/payments', 
        body: {
          'bookingId': bookingId,
          'method': method,
          'amount': amount,
          'currency': currency,
          if (metadata != null) 'metadata': metadata,
        },
        headers: _getAuthHeaders(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return Payment.fromJson(response['data']);
      }
      
      throw ApiException('Failed to create payment', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating payment: $e');
      }
      rethrow;
    }
  }

  // Confirm a payment
  Future<Payment> confirmPayment(String paymentId) async {
    try {
      final response = await post('/payments/$paymentId/confirm', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        return Payment.fromJson(response['data']);
      }
      
      throw ApiException('Failed to confirm payment', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error confirming payment: $e');
      }
      rethrow;
    }
  }

  // Process a refund
  Future<RefundResult> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final response = await post('/payments/$paymentId/refund', 
        body: {
          'amount': amount,
          if (reason != null) 'reason': reason,
        },
        headers: _getAuthHeaders(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return RefundResult.fromJson(response['data']);
      }
      
      throw ApiException('Failed to process refund', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing refund: $e');
      }
      rethrow;
    }
  }

  // Get payment audit trail
  Future<List<PaymentAuditEntry>> getPaymentAudit(String paymentId) async {
    try {
      final response = await get('/payments/$paymentId/audit', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        final auditTrail = response['data']['auditTrail'];
        if (auditTrail != null) {
          final List<dynamic> auditData = auditTrail;
          return auditData.map((entry) => PaymentAuditEntry.fromJson(entry)).toList();
        }
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching payment audit: $e');
      }
      rethrow;
    }
  }

  // Get payment system health
  Future<PaymentHealthStatus> getPaymentHealth() async {
    try {
      final response = await get('/payments/health', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        return PaymentHealthStatus.fromJson(response['data']);
      }
      
      throw ApiException('Failed to get payment health status', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching payment health: $e');
      }
      rethrow;
    }
  }

  // Create minimal cash payment (admin only)
  Future<Payment> createMinimalCashPayment({
    required String bookingId,
    required double amount,
    String? currency = 'ILS',
    String? notes,
  }) async {
    try {
      final response = await post('/payments/minimal-cash', 
        body: {
          'bookingId': bookingId,
          'amount': amount,
          'currency': currency,
          if (notes != null) 'notes': notes,
        },
        headers: _getAuthHeaders(),
      );
      
      if (response['success'] == true && response['data'] != null) {
        return Payment.fromJson(response['data']);
      }
      
      throw ApiException('Failed to create cash payment', 0, '');
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating cash payment: $e');
      }
      rethrow;
    }
  }

  // Get user's payment history
  Future<List<Payment>> getUserPayments({int? limit, int? offset}) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      
      final queryString = queryParams.isNotEmpty 
          ? '?${Uri(queryParameters: queryParams).query}' 
          : '';
      
      final response = await get('/payments/mine$queryString', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> paymentsData = response['data'];
        return paymentsData.map((payment) => Payment.fromJson(payment)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching user payments: $e');
      }
      rethrow;
    }
  }

  // Get provider's received payments
  Future<List<Payment>> getProviderPayments({int? limit, int? offset}) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      
      final queryString = queryParams.isNotEmpty 
          ? '?${Uri(queryParameters: queryParams).query}' 
          : '';
      
      final response = await get('/payments/received$queryString', headers: _getAuthHeaders());
      
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> paymentsData = response['data'];
        return paymentsData.map((payment) => Payment.fromJson(payment)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching provider payments: $e');
      }
      rethrow;
    }
  }
}

// Data Models
class PaymentMethod {
  final String method;
  final String name;
  final String? description;
  final PaymentCapabilities capabilities;
  final bool isEnabled;

  PaymentMethod({
    required this.method,
    required this.name,
    this.description,
    required this.capabilities,
    required this.isEnabled,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      method: json['method'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      capabilities: PaymentCapabilities.fromJson(json['capabilities'] ?? {}),
      isEnabled: json['isEnabled'] ?? false,
    );
  }
}

class PaymentCapabilities {
  final List<String> supportedCurrencies;
  final List<String> supportedMethods;
  final double? minAmount;
  final double? maxAmount;

  PaymentCapabilities({
    required this.supportedCurrencies,
    required this.supportedMethods,
    this.minAmount,
    this.maxAmount,
  });

  factory PaymentCapabilities.fromJson(Map<String, dynamic> json) {
    return PaymentCapabilities(
      supportedCurrencies: List<String>.from(json['supportedCurrencies'] ?? []),
      supportedMethods: List<String>.from(json['supportedMethods'] ?? []),
      minAmount: json['minAmount']?.toDouble(),
      maxAmount: json['maxAmount']?.toDouble(),
    );
  }
}

class Payment {
  final String id;
  final String bookingId;
  final String method;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final String? transactionId;
  final String? failureReason;

  Payment({
    required this.id,
    required this.bookingId,
    required this.method,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.transactionId,
    this.failureReason,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      method: json['method'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'ILS',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      metadata: json['metadata'],
      transactionId: json['transactionId'],
      failureReason: json['failureReason'],
    );
  }
}

class RefundResult {
  final String id;
  final String paymentId;
  final double amount;
  final String status;
  final String? reason;
  final DateTime createdAt;

  RefundResult({
    required this.id,
    required this.paymentId,
    required this.amount,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  factory RefundResult.fromJson(Map<String, dynamic> json) {
    return RefundResult(
      id: json['_id'] ?? json['id'] ?? '',
      paymentId: json['paymentId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      reason: json['reason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class PaymentAuditEntry {
  final String action;
  final String actorType;
  final String? actorId;
  final String oldStatus;
  final String newStatus;
  final double amount;
  final String currency;
  final String method;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PaymentAuditEntry({
    required this.action,
    required this.actorType,
    this.actorId,
    required this.oldStatus,
    required this.newStatus,
    required this.amount,
    required this.currency,
    required this.method,
    required this.timestamp,
    this.metadata,
  });

  factory PaymentAuditEntry.fromJson(Map<String, dynamic> json) {
    return PaymentAuditEntry(
      action: json['action'] ?? '',
      actorType: json['actorType'] ?? '',
      actorId: json['actorId'],
      oldStatus: json['oldStatus'] ?? '',
      newStatus: json['newStatus'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'ILS',
      method: json['method'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'],
    );
  }
}

class PaymentHealthStatus {
  final bool isHealthy;
  final Map<String, dynamic> processors;
  final Map<String, dynamic> outbox;
  final Map<String, dynamic> reconciliation;
  final DateTime lastChecked;

  PaymentHealthStatus({
    required this.isHealthy,
    required this.processors,
    required this.outbox,
    required this.reconciliation,
    required this.lastChecked,
  });

  factory PaymentHealthStatus.fromJson(Map<String, dynamic> json) {
    return PaymentHealthStatus(
      isHealthy: json['isHealthy'] ?? false,
      processors: json['processors'] ?? {},
      outbox: json['outbox'] ?? {},
      reconciliation: json['reconciliation'] ?? {},
      lastChecked: DateTime.parse(json['lastChecked'] ?? DateTime.now().toIso8601String()),
    );
  }
}
