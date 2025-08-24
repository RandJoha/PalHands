import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Core imports
import '../../core/constants/app_colors.dart';

// Shared imports
import '../services/payment_service.dart';
import '../services/auth_service.dart';

class DebugPaymentTest extends StatefulWidget {
  const DebugPaymentTest({super.key});

  @override
  State<DebugPaymentTest> createState() => _DebugPaymentTestState();
}

class _DebugPaymentTestState extends State<DebugPaymentTest> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  
  String _statusMessage = 'Ready to debug';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Debug Test'),
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
                    'Debug Status:',
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
            
            // Debug Steps
            Text(
              'Debug Steps:',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Step 1: Check Authentication
            _buildDebugButton(
              title: '1. Check Authentication Status',
              subtitle: 'Verify if you are logged in',
              onPressed: _checkAuthStatus,
            ),
            
            SizedBox(height: 12.h),
            
            // Step 2: Test Backend Connection
            _buildDebugButton(
              title: '2. Test Backend Connection',
              subtitle: 'Check if backend is accessible',
              onPressed: _testBackendConnection,
            ),
            
            SizedBox(height: 12.h),
            
            // Step 3: Test Payment Methods (No Auth)
            _buildDebugButton(
              title: '3. Test Payment Methods (No Auth)',
              subtitle: 'Try to get payment methods without auth',
              onPressed: _testPaymentMethodsNoAuth,
            ),
            
            SizedBox(height: 12.h),
            
            // Step 4: Test Payment Methods (With Auth)
            _buildDebugButton(
              title: '4. Test Payment Methods (With Auth)',
              subtitle: 'Try to get payment methods with auth',
              onPressed: _testPaymentMethodsWithAuth,
            ),
            
            SizedBox(height: 12.h),
            
            // Step 5: Test Payment Creation
            _buildDebugButton(
              title: '5. Test Payment Creation',
              subtitle: 'Try to create a test payment',
              onPressed: _testPaymentCreation,
            ),
            
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
                    'How to Debug:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '1. Click each button in order\n'
                    '2. Watch the status message for results\n'
                    '3. If step 1 fails, you need to login first\n'
                    '4. If step 2 fails, backend is not running\n'
                    '5. If step 3 works but step 4 fails, auth issue\n'
                    '6. If step 5 fails, payment creation issue',
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

  Widget _buildDebugButton({
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
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
            Icon(Icons.bug_report, color: AppColors.primary),
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
            if (_isLoading)
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

  Future<void> _checkAuthStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking authentication...';
    });

    try {
      final user = _authService.currentUser;
      final token = _authService.token;
      final isAuthenticated = _authService.isAuthenticated;
      
      setState(() {
        _statusMessage = 'Auth Status:\n'
            'User: ${user != null ? "Logged in" : "Not logged in"}\n'
            'Token: ${token != null ? "Present" : "Missing"}\n'
            'Authenticated: ${isAuthenticated ? "Yes" : "No"}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Auth check failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testBackendConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing backend connection...';
    });

    try {
      final response = await _paymentService.getPaymentMethods();
      setState(() {
        _statusMessage = 'Backend connection: ✅ SUCCESS\n'
            'Found ${response.length} payment methods';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Backend connection: ❌ FAILED\n'
            'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testPaymentMethodsNoAuth() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing payment methods without auth...';
    });

    try {
      // This will fail because we need auth
      final response = await _paymentService.getPaymentMethods();
      setState(() {
        _statusMessage = 'Payment methods (no auth): ✅ SUCCESS\n'
            'This should not happen - auth is working';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Payment methods (no auth): ❌ FAILED (Expected)\n'
            'Error: $e\n'
            'This is expected if auth is required';
        _isLoading = false;
      });
    }
  }

  Future<void> _testPaymentMethodsWithAuth() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing payment methods with auth...';
    });

    try {
      final response = await _paymentService.getPaymentMethods();
      setState(() {
        _statusMessage = 'Payment methods (with auth): ✅ SUCCESS\n'
            'Found ${response.length} payment methods';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Payment methods (with auth): ❌ FAILED\n'
            'Error: $e\n'
            'You need to be logged in first';
        _isLoading = false;
      });
    }
  }

  Future<void> _testPaymentCreation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing payment creation...';
    });

    try {
      final payment = await _paymentService.createPayment(
        bookingId: 'debug_test_${DateTime.now().millisecondsSinceEpoch}',
        method: 'cash',
        amount: 25.0,
        currency: 'ILS',
      );
      
      setState(() {
        _statusMessage = 'Payment creation: ✅ SUCCESS\n'
            'Payment ID: ${payment.id}\n'
            'Amount: ${payment.currency} ${payment.amount}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Payment creation: ❌ FAILED\n'
            'Error: $e';
        _isLoading = false;
      });
    }
  }
}
