import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Shared imports
import '../services/payment_service.dart';
import '../services/language_service.dart';

class PaymentConfirmationWidget extends StatefulWidget {
  final String bookingId;
  final double amount;
  final String currency;
  final PaymentMethod selectedMethod;
  final Function(Payment)? onPaymentConfirmed;
  final Function(String)? onPaymentFailed;

  const PaymentConfirmationWidget({
    super.key,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.selectedMethod,
    this.onPaymentConfirmed,
    this.onPaymentFailed,
  });

  @override
  State<PaymentConfirmationWidget> createState() => _PaymentConfirmationWidgetState();
}

class _PaymentConfirmationWidgetState extends State<PaymentConfirmationWidget> {
  final PaymentService _paymentService = PaymentService();
  
  bool _isProcessing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildPaymentConfirmation(languageService);
      },
    );
  }

  Widget _buildPaymentConfirmation(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment summary
        _buildPaymentSummary(languageService),
        SizedBox(height: 24.h),
        
        // Payment method display
        _buildPaymentMethodDisplay(languageService),
        SizedBox(height: 24.h),
        
        // Error display
        if (_error != null)
          _buildErrorDisplay(languageService),
        
        // Confirm button
        _buildConfirmButton(languageService),
      ],
    );
  }

  Widget _buildPaymentSummary(LanguageService languageService) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.getString('paymentSummary', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.getString('bookingId', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '#${widget.bookingId.substring(0, 8)}',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.getString('amount', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                style: GoogleFonts.cairo(
                  fontSize: 18.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDisplay(LanguageService languageService) {
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
          // Method icon
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Icon(
              _getMethodIcon(widget.selectedMethod.method),
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          
          // Method details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedMethod.name,
                  style: GoogleFonts.cairo(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.selectedMethod.description != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    widget.selectedMethod.description!,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Change method button
          TextButton(
            onPressed: _isProcessing ? null : () {
              // Navigate back to method selection
              Navigator.of(context).pop();
            },
            child: Text(
              AppStrings.getString('change', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(LanguageService languageService) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(LanguageService languageService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: _isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    AppStrings.getString('processing', languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                '${AppStrings.getString('confirm', languageService.currentLanguage)} ${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                style: GoogleFonts.cairo(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Create payment
      final payment = await _paymentService.createPayment(
        bookingId: widget.bookingId,
        method: widget.selectedMethod.method,
        amount: widget.amount,
        currency: widget.currency,
      );

      // Confirm payment
      final confirmedPayment = await _paymentService.confirmPayment(payment.id);

      if (mounted) {
        widget.onPaymentConfirmed?.call(confirmedPayment);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment confirmed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
      
      if (mounted) {
        widget.onPaymentFailed?.call(e.toString());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'stripe':
      case 'card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }
}
