import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';

class BookingManagementWidget extends StatefulWidget {
  const BookingManagementWidget({super.key});

  @override
  State<BookingManagementWidget> createState() => _BookingManagementWidgetState();
}

class _BookingManagementWidgetState extends State<BookingManagementWidget> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock data
    setState(() {
      _bookings = [
        {
          'id': 'BK001',
          'client': {'firstName': 'Ahmed', 'lastName': 'Hassan', 'email': 'ahmed@email.com'},
          'provider': {'firstName': 'Fatima', 'lastName': 'Ali', 'email': 'fatima@email.com'},
          'service': {'title': 'Home Cleaning', 'category': 'cleaning'},
          'status': 'confirmed',
          'schedule': {'date': '2024-02-15', 'startTime': '09:00', 'endTime': '12:00'},
          'pricing': {'totalAmount': 150, 'currency': 'ILS'},
          'payment': {'status': 'paid', 'method': 'cash'},
          'createdAt': '2024-02-10T10:30:00Z',
        },
        {
          'id': 'BK002',
          'client': {'firstName': 'Omar', 'lastName': 'Khalil', 'email': 'omar@email.com'},
          'provider': {'firstName': 'Layla', 'lastName': 'Hassan', 'email': 'layla@email.com'},
          'service': {'title': 'Elderly Care', 'category': 'elderly_support'},
          'status': 'pending',
          'schedule': {'date': '2024-02-16', 'startTime': '08:00', 'endTime': '16:00'},
          'pricing': {'totalAmount': 200, 'currency': 'ILS'},
          'payment': {'status': 'pending', 'method': 'credit_card'},
          'createdAt': '2024-02-11T14:15:00Z',
        },
        {
          'id': 'BK003',
          'client': {'firstName': 'Sara', 'lastName': 'Mohammed', 'email': 'sara@email.com'},
          'provider': {'firstName': 'Youssef', 'lastName': 'Ibrahim', 'email': 'youssef@email.com'},
          'service': {'title': 'Home Maintenance', 'category': 'maintenance'},
          'status': 'completed',
          'schedule': {'date': '2024-02-14', 'startTime': '10:00', 'endTime': '14:00'},
          'pricing': {'totalAmount': 120, 'currency': 'ILS'},
          'payment': {'status': 'paid', 'method': 'bank_transfer'},
          'createdAt': '2024-02-09T09:45:00Z',
        },
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return _buildBookingManagement(context, languageService);
      },
    );
  }

  Widget _buildBookingManagement(BuildContext context, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isArabic = languageService.isArabic;
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.all(screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - More compact
            _buildHeader(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
            
            // Statistics cards - More compact
            _buildStatisticsCards(languageService),
            
            SizedBox(height: screenWidth > 1400 ? 20 : screenWidth > 1024 ? 16 : 12),
            
            // Bookings table
            Expanded(
              child: _buildBookingsTable(languageService),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.getString('bookingManagement', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 22 : screenWidth > 1024 ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                AppStrings.getString('monitorBookings', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate statistics
    final totalBookings = _bookings.length;
    final pendingBookings = _bookings.where((b) => b['status'] == 'pending').length;
    final completedBookings = _bookings.where((b) => b['status'] == 'completed').length;
    final totalRevenue = _bookings
        .where((b) => b['payment']['status'] == 'paid')
        .fold(0.0, (sum, b) => sum + b['pricing']['totalAmount']);

    final stats = [
      {
        'title': AppStrings.getString('totalBookings', languageService.currentLanguage),
        'value': totalBookings.toString(),
        'icon': Icons.calendar_today,
        'color': AppColors.primary,
      },
      {
        'title': AppStrings.getString('pending', languageService.currentLanguage),
        'value': pendingBookings.toString(),
        'icon': Icons.schedule,
        'color': Colors.orange,
      },
      {
        'title': AppStrings.getString('completed', languageService.currentLanguage),
        'value': completedBookings.toString(),
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'title': AppStrings.getString('revenue', languageService.currentLanguage),
        'value': '₪${totalRevenue.toStringAsFixed(0)}',
        'icon': Icons.attach_money,
        'color': Colors.purple,
      },
    ];

    // Responsive grid layout
    if (screenWidth <= 768) {
      // Mobile: Use 2-column grid layout instead of horizontal scrolling
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2, // Slightly taller for mobile
        children: stats.map((stat) => _buildStatCard(stat, screenWidth)).toList(),
      );
    } else {
      // Desktop/Tablet: Grid layout
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 1400 ? 4 : screenWidth > 1024 ? 3 : 2,
          crossAxisSpacing: screenWidth > 1400 ? 16 : 12,
          mainAxisSpacing: screenWidth > 1400 ? 16 : 12,
          childAspectRatio: screenWidth > 1400 ? 3.5 : 3.0,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildStatCard(stat, screenWidth);
        },
      );
    }
  }

  Widget _buildStatCard(Map<String, dynamic> stat, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth > 1400 ? 10 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth > 1400 ? 40 : 36,
            height: screenWidth > 1400 ? 40 : 36,
            decoration: BoxDecoration(
              color: stat['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              stat['icon'],
              color: stat['color'],
              size: screenWidth > 1400 ? 20 : 18,
            ),
          ),
          SizedBox(width: screenWidth > 1400 ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat['value'],
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  stat['title'],
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 12 : 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTable(LanguageService languageService) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.getString('noBookingsFound', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth > 1400 ? 10 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header - More compact
          Container(
            padding: EdgeInsets.all(screenWidth > 1400 ? 14 : 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth > 1400 ? 10 : 8),
                topRight: Radius.circular(screenWidth > 1400 ? 10 : 8),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('bookingId', languageService.currentLanguage))),
                Expanded(flex: 2, child: _buildHeaderCell(AppStrings.getString('service', languageService.currentLanguage))),
                if (screenWidth > 768) ...[
                  Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('client', languageService.currentLanguage))),
                  Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('provider', languageService.currentLanguage))),
                ],
                if (screenWidth > 1024) ...[
                  Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('dateTime', languageService.currentLanguage))),
                ],
                if (screenWidth > 768) ...[
                  Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('amount', languageService.currentLanguage))),
                ],
                Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('status', languageService.currentLanguage))),
                Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('actions', languageService.currentLanguage))),
              ],
            ),
          ),
          
          // Table body
          Expanded(
            child: ListView.builder(
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return _buildBookingRow(booking, languageService);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: screenWidth > 1400 ? 14 : 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildBookingRow(Map<String, dynamic> booking, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 16 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Booking ID - Balanced sizing
          Expanded(
            flex: 1,
            child: Text(
              booking['id'],
              style: GoogleFonts.cairo(
                fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          
          // Service info - Balanced sizing
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: screenWidth > 1400 ? 36 : screenWidth > 1024 ? 32 : 28,
                  height: screenWidth > 1400 ? 36 : screenWidth > 1024 ? 32 : 28,
                  decoration: BoxDecoration(
                    color: _getServiceColor(booking['service']['category']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getServiceIcon(booking['service']['category']),
                    color: _getServiceColor(booking['service']['category']),
                    size: screenWidth > 1400 ? 18 : screenWidth > 1024 ? 16 : 14,
                  ),
                ),
                SizedBox(width: screenWidth > 1400 ? 10 : screenWidth > 1024 ? 8 : 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['service']['title'],
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        _getLocalizedCategoryLabel(booking['service']['category'], languageService),
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 11 : 10,
                          color: AppColors.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Client (hidden on mobile) - Balanced sizing
          if (screenWidth > 768) ...[
            Expanded(
              flex: 1,
              child: Text(
                '${booking['client']['firstName']} ${booking['client']['lastName']}',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // Provider (hidden on mobile) - Balanced sizing
          if (screenWidth > 768) ...[
            Expanded(
              flex: 1,
              child: Text(
                '${booking['provider']['firstName']} ${booking['provider']['lastName']}',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // Date & Time (hidden on tablet) - Balanced sizing
          if (screenWidth > 1024) ...[
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['schedule']['date'],
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 13 : screenWidth > 1024 ? 12 : 11,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '${booking['schedule']['startTime']} - ${booking['schedule']['endTime']}',
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 11 : 10,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Amount (hidden on mobile) - Balanced sizing
          if (screenWidth > 768) ...[
            Expanded(
              flex: 1,
              child: Text(
                '₪${booking['pricing']['totalAmount']}',
                style: GoogleFonts.cairo(
                  fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 1400 ? 8 : 6,
                vertical: screenWidth > 1400 ? 4 : 3,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor(booking['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking['status']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    _getLocalizedStatusLabel(booking['status'], languageService).toUpperCase(),
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 10 : 9,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(booking['status']),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Actions
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: View booking details
                  },
                  icon: Icon(
                    Icons.visibility,
                    size: screenWidth > 1400 ? 18 : 16,
                    color: AppColors.textLight,
                  ),
                  tooltip: AppStrings.getString('view', languageService.currentLanguage),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Edit booking
                  },
                  icon: Icon(
                    Icons.edit,
                    size: screenWidth > 1400 ? 18 : 16,
                    color: AppColors.primary,
                  ),
                  tooltip: AppStrings.getString('edit', languageService.currentLanguage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedCategoryLabel(String category, LanguageService languageService) {
    switch (category) {
      case 'cleaning':
        return AppStrings.getString('cleaning', languageService.currentLanguage);
      case 'elderly_support':
        return AppStrings.getString('elderlySupport', languageService.currentLanguage);
      case 'maintenance':
        return AppStrings.getString('maintenance', languageService.currentLanguage);
      default:
        return category;
    }
  }

  String _getLocalizedStatusLabel(String status, LanguageService languageService) {
    switch (status) {
      case 'confirmed':
        return AppStrings.getString('confirmed', languageService.currentLanguage);
      case 'pending':
        return AppStrings.getString('pending', languageService.currentLanguage);
      case 'completed':
        return AppStrings.getString('completed', languageService.currentLanguage);
      case 'cancelled':
        return AppStrings.getString('cancelled', languageService.currentLanguage);
      default:
        return status;
    }
  }

  Color _getServiceColor(String category) {
    switch (category) {
      case 'cleaning':
        return Colors.blue;
      case 'elderly_support':
        return Colors.orange;
      case 'maintenance':
        return Colors.green;
      default:
        return AppColors.textLight;
    }
  }

  IconData _getServiceIcon(String category) {
    switch (category) {
      case 'cleaning':
        return Icons.cleaning_services;
      case 'elderly_support':
        return Icons.elderly;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.business_center;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.textLight;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
} 