import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/payment_service.dart';
import '../../../../shared/services/auth_service.dart';

class PaymentsWidget extends StatefulWidget {
  const PaymentsWidget({super.key});

  @override
  State<PaymentsWidget> createState() => _PaymentsWidgetState();
}

class _PaymentsWidgetState extends State<PaymentsWidget> {
  final PaymentService _paymentService = PaymentService();
  final AuthService _authService = AuthService();
  
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
          final user = _authService.currentUser;
    if (user != null) {
        List<Payment> payments;
        
        // Load payments based on user role
        if (user['role'] == 'provider') {
          payments = await _paymentService.getProviderPayments(limit: 20);
        } else {
          payments = await _paymentService.getUserPayments(limit: 20);
        }
        
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPayments() async {
    setState(() {
      _isRefreshing = true;
    });
    
    await _loadPayments();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _requestRefund(Payment payment) async {
    try {
      final result = await _paymentService.refundPayment(
        paymentId: payment.id,
        amount: payment.amount,
        reason: 'User requested refund',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refund request submitted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _refreshPayments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request refund: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildPayments(context, languageService);
      },
    );
  }

  Widget _buildPayments(BuildContext context, LanguageService languageService) {
    return RefreshIndicator(
      onRefresh: _refreshPayments,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.getString('payments', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 24.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    if (_isRefreshing)
                      SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    SizedBox(width: 12.w),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/basic-payment-test');
                      },
                      icon: Icon(Icons.science, size: 16.sp),
                      label: Text('Test Payment System'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24.h),
            
            // Loading state
            if (_isLoading)
              _buildLoadingState()
            // Error state
            else if (_error != null)
              _buildErrorState(languageService)
            // Payment history
            else
              _buildPaymentHistory(languageService),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 50.h),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading payments...',
            style: GoogleFonts.cairo(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LanguageService languageService) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 50.h),
          Icon(
            Icons.error_outline,
            size: 48.sp,
            color: AppColors.error,
          ),
          SizedBox(height: 16.h),
          Text(
            'Failed to load payments',
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _error ?? 'Unknown error',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _loadPayments,
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

  Widget _buildPaymentHistory(LanguageService languageService) {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 50.h),
            Icon(
              Icons.payment_outlined,
              size: 48.sp,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16.h),
            Text(
              'No payments found',
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your payment history will appear here',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _payments.map((payment) {
        return Column(
          children: [
            _buildPaymentItem(payment, languageService),
            SizedBox(height: 12.h),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPaymentItem(Payment payment, LanguageService languageService) {
    final serviceName = 'Booking #${payment.bookingId.substring(0, 8)}';
    final amount = '${payment.currency} ${payment.amount.toStringAsFixed(2)}';
    final date = _formatDate(payment.createdAt, languageService);
    final status = _getStatusText(payment.status, languageService);
    final method = payment.method;
    
    Color statusColor;
    switch (payment.status.toLowerCase()) {
      case 'paid':
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        break;
      case 'failed':
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25.r),
            ),
            child: Icon(
              Icons.payment,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  method,
                  style: GoogleFonts.cairo(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  date,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.cairo(
                    fontSize: 12.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          // Refund button for completed payments
          if (payment.status.toLowerCase() == 'paid' || payment.status.toLowerCase() == 'completed')
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _requestRefund(payment),
                    icon: Icon(Icons.refresh, size: 16.sp),
                    label: Text('Request Refund'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date, LanguageService languageService) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return AppStrings.getString('today', languageService.currentLanguage);
    } else if (difference.inDays == 1) {
      return AppStrings.getString('yesterday', languageService.currentLanguage);
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getStatusText(String status, LanguageService languageService) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return AppStrings.getString('completed', languageService.currentLanguage);
      case 'pending':
        return AppStrings.getString('pending', languageService.currentLanguage);
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
} 