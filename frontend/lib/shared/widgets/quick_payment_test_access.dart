import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core imports
import '../../core/constants/app_colors.dart';

// Shared imports
import '../services/payment_service.dart';
import '../services/auth_service.dart';

class QuickPaymentTestAccess extends StatefulWidget {
  const QuickPaymentTestAccess({super.key});

  @override
  State<QuickPaymentTestAccess> createState() => _QuickPaymentTestAccessState();
}

class _QuickPaymentTestAccessState extends State<QuickPaymentTestAccess> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  
  List<dynamic> _paymentMethods = [];
  bool _isLoading = false;
  String _statusMessage = 'Ready to test';

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading payment methods...';
    });

    try {
      final methods = await _paymentService.getPaymentMethods();
      setState(() {
        _paymentMethods = methods;
        _statusMessage = 'Found ${methods.length} payment methods';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestPayment() async {
    if (_paymentMethods.isEmpty) {
      setState(() {
        _statusMessage = 'No payment methods available';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Creating test payment...';
    });

    try {
      final payment = await _paymentService.createPayment(
        bookingId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        method: _paymentMethods[0].method,
        amount: 50.0,
        currency: 'ILS',
      );
      
      setState(() {
        _statusMessage = 'Payment created! ID: ${payment.id.substring(0, 8)}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Payment failed: $e';
      });
    }
  }

  Future<void> _checkHealth() async {
    setState(() {
      _statusMessage = 'Checking health...';
    });

    try {
      final health = await _paymentService.getPaymentHealth();
      setState(() {
        _statusMessage = 'Health: ${health.isHealthy ? "✅ Healthy" : "❌ Unhealthy"}';
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
        title: Text('Quick Payment Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Quick Test Buttons
            Text(
              'Quick Tests:',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Test 1: Payment Methods Loading
            _buildTestButton(
              title: '1. Test Payment Methods Loading',
              subtitle: 'Load available payment methods',
              icon: Icons.payment,
              onPressed: _loadPaymentMethods,
              isLoading: _isLoading,
            ),
            
            SizedBox(height: 12.h),
            
            // Test 2: Payment Creation
            _buildTestButton(
              title: '2. Test Payment Creation',
              subtitle: 'Create a test payment (₪50)',
              icon: Icons.add_shopping_cart,
              onPressed: _createTestPayment,
              isLoading: false,
            ),
            
            SizedBox(height: 12.h),
            
            // Test 3: System Health
            _buildTestButton(
              title: '3. Test System Health',
              subtitle: 'Check payment system health',
              icon: Icons.health_and_safety,
              onPressed: _checkHealth,
              isLoading: false,
            ),
            
            SizedBox(height: 24.h),
            
            // Payment Methods Display
            if (_paymentMethods.isNotEmpty) ...[
              Text(
                'Available Payment Methods:',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              
              SizedBox(height: 12.h),
              
              ..._paymentMethods.map((method) => _buildMethodCard(method)),
            ],
            
            SizedBox(height: 24.h),
            
            // Instructions
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to Test:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '1. Click "Test Payment Methods Loading" to load available methods\n'
                    '2. Click "Test Payment Creation" to create a test payment\n'
                    '3. Click "Test System Health" to check system status\n'
                    '4. Watch the status message for results',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          padding: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(dynamic method) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.border),
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
            'Type: ${method.method}',
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
}
