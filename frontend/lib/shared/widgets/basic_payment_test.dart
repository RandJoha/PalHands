import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core imports
import '../../core/constants/app_colors.dart';

// Shared imports
import '../services/payment_service.dart';
import '../services/auth_service.dart';

class BasicPaymentTest extends StatefulWidget {
  const BasicPaymentTest({super.key});

  @override
  State<BasicPaymentTest> createState() => _BasicPaymentTestState();
}

class _BasicPaymentTestState extends State<BasicPaymentTest> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  
  List<dynamic> _paymentMethods = [];
  List<dynamic> _userPayments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedMethod = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _statusMessage = 'Loading...';
    });

    try {
      // Load payment methods
      final methods = await _paymentService.getPaymentMethods();
      setState(() {
        _paymentMethods = methods;
        if (methods.isNotEmpty) {
          _selectedMethod = methods[0].method;
        }
        _statusMessage = 'Loaded ${methods.length} payment methods';
      });

      // Load user payments
      final user = _authService.currentUser;
      if (user != null) {
        List<dynamic> payments;
        if (user['role'] == 'provider') {
          payments = await _paymentService.getProviderPayments(limit: 5);
        } else {
          payments = await _paymentService.getUserPayments(limit: 5);
        }
        setState(() {
          _userPayments = payments;
          _statusMessage += ', ${payments.length} payments';
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _createTestPayment() async {
    if (_selectedMethod.isEmpty) {
      setState(() {
        _statusMessage = 'Please select a payment method first';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Creating test payment...';
    });

    try {
      final payment = await _paymentService.createPayment(
        bookingId: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        method: _selectedMethod,
        amount: 100.0,
        currency: 'ILS',
      );
      
      setState(() {
        _statusMessage = 'Payment created successfully! ID: ${payment.id}';
      });
      
      // Refresh data
      await _loadData();
    } catch (e) {
      setState(() {
        _statusMessage = 'Payment failed: $e';
      });
    }
  }

  Future<void> _checkHealth() async {
    setState(() {
      _statusMessage = 'Checking system health...';
    });

    try {
      final health = await _paymentService.getPaymentHealth();
      setState(() {
        _statusMessage = 'System Health: ${health.isHealthy ? "Healthy" : "Unhealthy"}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Health check failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Basic Payment Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Message
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _error != null ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: _error != null ? AppColors.error : AppColors.success,
                ),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _error != null ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Loading State
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    SizedBox(height: 16.h),
                    Text('Loading payment data...'),
                  ],
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment Methods
                      _buildSection(
                        title: 'Payment Methods (${_paymentMethods.length})',
                        child: Column(
                          children: [
                            if (_paymentMethods.isEmpty)
                              Text('No payment methods available')
                            else
                              ..._paymentMethods.map((method) => _buildMethodItem(method)),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Payment Method Selection
                      if (_paymentMethods.isNotEmpty)
                        _buildSection(
                          title: 'Select Payment Method',
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedMethod.isNotEmpty ? _selectedMethod : null,
                                decoration: InputDecoration(
                                  labelText: 'Choose a method',
                                  border: OutlineInputBorder(),
                                ),
                                items: _paymentMethods.map<DropdownMenuItem<String>>((method) {
                                  return DropdownMenuItem<String>(
                                    value: method.method,
                                    child: Text(method.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMethod = value ?? '';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      
                      SizedBox(height: 20.h),
                      
                      // Test Actions
                      _buildSection(
                        title: 'Test Actions',
                        child: Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _createTestPayment,
                              icon: Icon(Icons.payment),
                              label: Text('Create Test Payment (₪100)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                minimumSize: Size(double.infinity, 48.h),
                              ),
                            ),
                            
                            SizedBox(height: 12.h),
                            
                            ElevatedButton.icon(
                              onPressed: _checkHealth,
                              icon: Icon(Icons.health_and_safety),
                              label: Text('Check System Health'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.white,
                                minimumSize: Size(double.infinity, 48.h),
                              ),
                            ),
                            
                            SizedBox(height: 12.h),
                            
                            ElevatedButton.icon(
                              onPressed: _loadData,
                              icon: Icon(Icons.refresh),
                              label: Text('Refresh Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.grey,
                                foregroundColor: AppColors.white,
                                minimumSize: Size(double.infinity, 48.h),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Payment History
                      _buildSection(
                        title: 'Payment History (${_userPayments.length})',
                        child: Column(
                          children: [
                            if (_userPayments.isEmpty)
                              Text('No payment history found')
                            else
                              ..._userPayments.map((payment) => _buildPaymentItem(payment)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _buildMethodItem(dynamic method) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            method.name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Method: ${method.method}',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          if (method.capabilities != null) ...[
            SizedBox(height: 4.h),
            Text(
              'Currencies: ${method.capabilities.supportedCurrencies?.join(', ') ?? 'N/A'}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentItem(dynamic payment) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment #${payment.id.substring(0, 8)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(payment.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  payment.status,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _getStatusColor(payment.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Amount: ${payment.currency} ${payment.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Method: ${payment.method}',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
