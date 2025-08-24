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

class PaymentMethodsWidget extends StatefulWidget {
  final Function(PaymentMethod)? onMethodSelected;
  final PaymentMethod? selectedMethod;
  final bool showTitle;

  const PaymentMethodsWidget({
    super.key,
    this.onMethodSelected,
    this.selectedMethod,
    this.showTitle = true,
  });

  @override
  State<PaymentMethodsWidget> createState() => _PaymentMethodsWidgetState();
}

class _PaymentMethodsWidgetState extends State<PaymentMethodsWidget> {
  final PaymentService _paymentService = PaymentService();
  
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final methods = await _paymentService.getPaymentMethods();
      setState(() {
        _paymentMethods = methods.where((method) => method.isEnabled).toList();
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
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildPaymentMethods(languageService);
      },
    );
  }

  Widget _buildPaymentMethods(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text(
            AppStrings.getString('paymentMethod', languageService.currentLanguage),
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
        ],
        
        // Loading state
        if (_isLoading)
          _buildLoadingState()
        // Error state
        else if (_error != null)
          _buildErrorState(languageService)
        // Payment methods list
        else
          _buildMethodsList(languageService),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 20.h),
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Loading payment methods...',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LanguageService languageService) {
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
              'Failed to load payment methods',
              style: GoogleFonts.cairo(
                fontSize: 14.sp,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _loadPaymentMethods,
            child: Text(
              'Retry',
              style: GoogleFonts.cairo(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodsList(LanguageService languageService) {
    if (_paymentMethods.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.textLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.payment_outlined,
              color: AppColors.textLight,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'No payment methods available',
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _paymentMethods.map((method) {
        final isSelected = widget.selectedMethod?.method == method.method;
        
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: _buildMethodItem(method, isSelected, languageService),
        );
      }).toList(),
    );
  }

  Widget _buildMethodItem(PaymentMethod method, bool isSelected, LanguageService languageService) {
    return InkWell(
      onTap: () {
        widget.onMethodSelected?.call(method);
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Method icon
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.textLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                _getMethodIcon(method.method),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            
            // Method details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (method.description != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      method.description!,
                      style: GoogleFonts.cairo(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    _getMethodDescription(method, languageService),
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
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

  String _getMethodDescription(PaymentMethod method, LanguageService languageService) {
    final currencies = method.capabilities.supportedCurrencies.join(', ');
    final methods = method.capabilities.supportedMethods.join(', ');
    
    if (currencies.isNotEmpty && methods.isNotEmpty) {
      return 'Supports: $currencies • $methods';
    } else if (currencies.isNotEmpty) {
      return 'Supports: $currencies';
    } else if (methods.isNotEmpty) {
      return 'Supports: $methods';
    } else {
      return 'Payment method available';
    }
  }
}
