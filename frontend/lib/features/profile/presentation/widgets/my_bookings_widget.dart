import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/booking_service.dart';
import '../../../../shared/widgets/app_toast.dart';

class MyBookingsWidget extends StatefulWidget {
  const MyBookingsWidget({super.key});

  @override
  State<MyBookingsWidget> createState() => _MyBookingsWidgetState();
}

class _MyBookingsWidgetState extends State<MyBookingsWidget> {
  final BookingService _bookingService = BookingService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final bookings = await _bookingService.getMyBookings();
      
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to load bookings: ${e.toString()}',
          type: AppToastType.error,
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_selectedFilter == 'all') return _bookings;
    
    return _bookings.where((booking) {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      
      switch (_selectedFilter) {
        case 'upcoming':
          return ['pending', 'confirmed'].contains(status);
        case 'completed':
          return status == 'completed';
        case 'cancelled':
          return ['cancelled', 'disputed'].contains(status);
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildBookings(context, languageService);
      },
    );
  }

  Widget _buildBookings(BuildContext context, LanguageService languageService) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Bookings',
                style: GoogleFonts.cairo(
                  fontSize: 24.sp,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🇵🇸',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(width: 6.w),
                                            Text(
                          AppStrings.getString('palestine', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: 12.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Filter tabs
          _buildFilterTabs(),
          SizedBox(height: 24.h),
          
          // Bookings list
          _isLoading 
              ? _buildLoadingState()
              : _filteredBookings.isEmpty 
                  ? _buildEmptyState(languageService)
                  : _buildBookingsList(),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
                      Expanded(
            child: _buildFilterTab('All', _selectedFilter == 'all'),
          ),
          Expanded(
            child: _buildFilterTab('Upcoming', _selectedFilter == 'upcoming'),
          ),
          Expanded(
            child: _buildFilterTab('Completed', _selectedFilter == 'completed'),
          ),
          Expanded(
            child: _buildFilterTab('Cancelled', _selectedFilter == 'cancelled'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title.toLowerCase();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            color: isActive ? AppColors.white : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return Column(
      children: _filteredBookings.map((booking) => Padding(
        padding: EdgeInsets.only(bottom: 16.h),
        child: _buildBookingItem(booking),
      )).toList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 40.h),
          const CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16.h),
          Text(
            'Loading bookings...',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageService languageService) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Icon(
            Icons.calendar_today_outlined,
            size: 64.sp,
            color: AppColors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'No bookings found',
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your booking history will appear here',
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingItem(Map<String, dynamic> booking) {
    final serviceName = booking['serviceDetails']?['title'] ?? booking['service']?['title'] ?? 'Service';
    final providerName = '${booking['provider']?['firstName'] ?? ''} ${booking['provider']?['lastName'] ?? ''}'.trim();
    final status = booking['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final price = '${booking['pricing']?['currency'] ?? 'ILS'} ${booking['pricing']?['totalAmount'] ?? 0}';
    final date = _formatBookingDate(booking);
    
    return _buildBookingCard(
      serviceName: serviceName,
      providerName: providerName.isNotEmpty ? providerName : 'Unknown Provider',
      date: date,
      status: status,
      statusColor: statusColor,
      price: price,
      booking: booking,
    );
  }

  Widget _buildBookingCard({
    required String serviceName,
    required String providerName,
    required String date,
    required String status,
    required Color statusColor,
    required String price,
    required Map<String, dynamic> booking,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
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
          Row(
            children: [
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Icon(
                  Icons.cleaning_services,
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
                        fontSize: 18.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      providerName,
                      style: GoogleFonts.cairo(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
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
                    price,
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
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            date,
            style: GoogleFonts.cairo(
              fontSize: 14.sp,
              color: AppColors.textLight,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Handle contact provider
                  },
                  icon: Icon(Icons.message, size: 16.sp),
                  label: Text(
                    'Contact',
                    style: GoogleFonts.cairo(fontSize: 14.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Action buttons based on booking status and user role
              if (status == 'pending' || status == 'confirmed')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelBooking(booking),
                    icon: Icon(Icons.cancel, size: 16.sp, color: AppColors.error),
                    label: Text(
                      'Cancel',
                      style: GoogleFonts.cairo(fontSize: 14.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.info;
      case 'completed':
        return AppColors.primary;
      case 'cancelled':
      case 'disputed':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }

  String _formatBookingDate(Map<String, dynamic> booking) {
    try {
      final dateStr = booking['schedule']?['date'];
      final startTime = booking['schedule']?['startTime'];
      
      if (dateStr != null && startTime != null) {
        final date = DateTime.parse(dateStr);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final bookingDate = DateTime(date.year, date.month, date.day);
        
        String dayText;
        if (bookingDate == today) {
          dayText = 'Today';
        } else if (bookingDate == today.add(const Duration(days: 1))) {
          dayText = 'Tomorrow';
        } else if (bookingDate == today.subtract(const Duration(days: 1))) {
          dayText = 'Yesterday';
        } else {
          dayText = '${date.day}/${date.month}/${date.year}';
        }
        
        return '$dayText, $startTime';
      }
    } catch (e) {
      // Fallback for parsing errors
    }
    
    return 'Date not available';
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final confirmed = await _showCancelConfirmation();
    if (!confirmed) return;

    try {
      await _bookingService.cancelBooking(
        bookingId: booking['_id'] ?? booking['id'],
        reason: 'Cancelled by user',
      );
      
      if (mounted) {
        AppToast.show(context, message: 'Booking cancelled successfully', type: AppToastType.success);
        _loadBookings(); // Reload bookings
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to cancel booking: ${e.toString()}', type: AppToastType.error);
      }
    }
  }

  Future<bool> _showCancelConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Booking',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep Booking',
              style: GoogleFonts.cairo(color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cancel Booking',
              style: GoogleFonts.cairo(color: AppColors.error),
            ),
          ),
        ],
      ),
    ) ?? false;
  }
} 