import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Shared imports
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import 'payment_methods_widget.dart';
import 'payment_confirmation_widget.dart';

class PaymentTestPage extends StatefulWidget {
  const PaymentTestPage({super.key});

  @override
  State<PaymentTestPage> createState() => _PaymentTestPageState();
}

class _PaymentTestPageState extends State<PaymentTestPage> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  
  List<dynamic> _paymentMethods = [];
  List<dynamic> _userPayments = [];
  bool _isLoading = true;
  String? _error;
  PaymentMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load payment methods
      final methods = await _paymentService.getPaymentMethods();
      setState(() {
        _paymentMethods = methods;
      });

      // Load user payments
      final user = _authService.currentUser;
      if (user != null) {
        List<Payment> payments;
        if (user['role'] == 'provider') {
          payments = await _paymentService.getProviderPayments(limit: 10);
        } else {
          payments = await _paymentService.getUserPayments(limit: 10);
        }
        setState(() {
          _userPayments = payments;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment System Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildTestContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading payment data...',
            style: GoogleFonts.cairo(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: AppColors.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'Error loading payment data',
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _error!,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Methods Section
          _buildSection(
            title: '1. Available Payment Methods',
            child: Column(
              children: [
                if (_paymentMethods.isEmpty)
                  Text('No payment methods available')
                else
                  ..._paymentMethods.map((method) => _buildMethodCard(method)),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Payment Method Selection Widget
          _buildSection(
            title: '2. Payment Method Selection Widget',
            child: PaymentMethodsWidget(
              onMethodSelected: (method) {
                setState(() {
                  _selectedMethod = method;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected: ${method.name}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              selectedMethod: _selectedMethod,
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Payment Confirmation Widget
          if (_selectedMethod != null)
            _buildSection(
              title: '3. Payment Confirmation Widget',
              child: PaymentConfirmationWidget(
                bookingId: 'test_booking_123',
                amount: 150.0,
                currency: 'ILS',
                selectedMethod: _selectedMethod!,
                onPaymentConfirmed: (payment) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment confirmed: ${payment.id}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadData(); // Refresh data
                },
                onPaymentFailed: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment failed: $error'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                },
              ),
            ),
          
          SizedBox(height: 24.h),
          
          // User Payments Section
          _buildSection(
            title: '4. User Payment History',
            child: Column(
              children: [
                if (_userPayments.isEmpty)
                  Text('No payment history found')
                else
                  ..._userPayments.map((payment) => _buildPaymentCard(payment)),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Test Actions
          _buildSection(
            title: '5. Test Actions',
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final health = await _paymentService.getPaymentHealth();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('System Health: ${health.isHealthy ? "Healthy" : "Unhealthy"}'),
                          backgroundColor: health.isHealthy ? AppColors.success : AppColors.error,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Health check failed: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.health_and_safety),
                  label: Text('Check System Health'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildMethodCard(dynamic method) {
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
            style: GoogleFonts.cairo(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Method: ${method.method}',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          if (method.capabilities != null) ...[
            SizedBox(height: 4.h),
            Text(
              'Currencies: ${method.capabilities.supportedCurrencies?.join(', ') ?? 'N/A'}',
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppColors.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
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
                style: GoogleFonts.cairo(
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
                  style: GoogleFonts.cairo(
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
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Method: ${payment.method}',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Date: ${payment.createdAt.toString().substring(0, 19)}',
            style: GoogleFonts.cairo(
              fontSize: 12.sp,
              color: AppColors.textLight,
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
