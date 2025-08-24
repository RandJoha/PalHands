import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/payment_service.dart';
import '../../../../shared/services/auth_service.dart';

class MobilePaymentsWidget extends StatefulWidget {
  const MobilePaymentsWidget({super.key});

  @override
  State<MobilePaymentsWidget> createState() => _MobilePaymentsWidgetState();
}

class _MobilePaymentsWidgetState extends State<MobilePaymentsWidget> {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.getString('payments', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    if (_isRefreshing)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/basic-payment-test');
                      },
                      icon: const Icon(Icons.science, size: 16),
                      label: const Text('Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
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
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 50),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Loading payments...',
            style: TextStyle(
              fontSize: 16,
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
          const SizedBox(height: 50),
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load payments',
            style: GoogleFonts.cairo(
              fontSize: 18,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPayments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Retry'),
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
            const SizedBox(height: 50),
            const Icon(
              Icons.payment_outlined,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No payments found',
              style: GoogleFonts.cairo(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment history will appear here',
              style: GoogleFonts.cairo(
                fontSize: 14,
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
            const SizedBox(height: 12),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.payment,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  method,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
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
                  fontSize: 18,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
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
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _requestRefund(payment),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Request Refund'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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