import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/booking_service.dart';
import '../../../../shared/models/booking.dart';

class BookingManagementWidget extends StatefulWidget {
  const BookingManagementWidget({super.key});

  @override
  State<BookingManagementWidget> createState() => _BookingManagementWidgetState();
}

class _BookingManagementWidgetState extends State<BookingManagementWidget> {
  bool _isLoading = false;
  List<BookingModel> _bookings = [];
  final _bookingService = BookingService();
  int _selectedFilter = 0; // 0=All,1=Pending,2=Confirmed,3=Completed,4=Cancelled

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final status = _statusFromFilter(_selectedFilter);
      var results = await _bookingService.getAllBookingsAdmin(page: 1, limit: 50, status: status);
      // Hide stale entries with missing provider/client info
      results = results.where((b) {
        final provOk = ((b.providerId ?? '').isNotEmpty) || ((b.providerName ?? '').isNotEmpty);
        final clientOk = ((b.clientId ?? '').isNotEmpty) || ((b.clientName ?? '').isNotEmpty);
        return provOk && clientOk;
      }).toList();
      setState(() {
        _bookings = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
            
            // Filters + Bookings table
            _buildFilters(languageService),
            const SizedBox(height: 8),
            Expanded(child: _buildBookingsTable(languageService)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(LanguageService languageService) {
    final labels = ['all','pending','confirmed','completed','cancelled'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (i){
        final selected = _selectedFilter == i;
        return ChoiceChip(
          label: Text(AppStrings.getString(labels[i], languageService.currentLanguage)),
          selected: selected,
          onSelected: (_) async { setState(()=>_selectedFilter=i); await _loadBookings(); },
          selectedColor: AppColors.primary.withValues(alpha: 0.12),
          labelStyle: GoogleFonts.cairo(color: selected? AppColors.primary: AppColors.textPrimary),
          side: BorderSide(color: selected? AppColors.primary: AppColors.border),
        );
      }),
    );
  }

  String? _statusFromFilter(int f){
    switch (f){
      case 1: return 'pending';
      case 2: return 'confirmed';
      case 3: return 'completed';
      case 4: return 'cancelled';
      default: return null;
    }
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
  final pendingBookings = _bookings.where((b) => b.status == 'pending').length;
  final completedBookings = _bookings.where((b) => b.status == 'completed').length;

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
            color: Colors.black.withValues(alpha: 0.04),
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
              color: stat['color'].withValues(alpha: 0.1),
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
            const Icon(
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
            color: Colors.black.withValues(alpha: 0.04),
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
                Expanded(flex: 1, child: _buildHeaderCell(AppStrings.getString('createdAt', languageService.currentLanguage))),
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
                SizedBox(width: screenWidth > 768 ? 12 : 8),
                if (screenWidth > 480) _buildHeaderCell(AppStrings.getString('actions', languageService.currentLanguage)),
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

  Widget _buildBookingRow(BookingModel booking, LanguageService languageService) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.all(screenWidth > 1400 ? 16 : 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Created At - Balanced sizing
      Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.createdAt != null
                      ? _formatDateTime(booking.createdAt!)
                      : '-',
                  style: GoogleFonts.cairo(
                    fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if ((booking.bookingId ?? booking.id).isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: booking.bookingId ?? booking.id,
                          waitDuration: const Duration(milliseconds: 300),
                          child: InkWell(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: booking.bookingId ?? booking.id));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Booking ID copied')),
                                );
                              }
                            },
                            child: Text(
                              booking.bookingId ?? booking.id,
                              style: GoogleFonts.cairo(
                                fontSize: screenWidth > 1400 ? 11 : screenWidth > 1024 ? 10 : 9,
                                color: AppColors.textLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      if (screenWidth > 480)
                        IconButton(
                          icon: const Icon(Icons.copy, size: 14, color: AppColors.textLight),
                          tooltip: 'Copy ID',
                          padding: const EdgeInsets.all(0),
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: booking.bookingId ?? booking.id));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking ID copied')),
                              );
                            }
                          },
                        ),
                    ],
                  ),
              ],
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
                    color: _getServiceColor(booking.serviceDetails.category ?? '').withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getServiceIcon(booking.serviceDetails.category ?? ''),
                    color: _getServiceColor(booking.serviceDetails.category ?? ''),
                    size: screenWidth > 1400 ? 18 : screenWidth > 1024 ? 16 : 14,
                  ),
                ),
                SizedBox(width: screenWidth > 1400 ? 10 : screenWidth > 1024 ? 8 : 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceDetails.title,
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 14 : screenWidth > 1024 ? 13 : 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        _getLocalizedCategoryLabel(booking.serviceDetails.category ?? '', languageService),
                        style: GoogleFonts.cairo(
                          fontSize: screenWidth > 1400 ? 12 : screenWidth > 1024 ? 11 : 10,
                          color: AppColors.textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if ((booking.location.address).isNotEmpty) ...[
                        Text(
                          booking.location.address,
                          style: GoogleFonts.cairo(
                            fontSize: screenWidth > 1400 ? 11 : screenWidth > 1024 ? 10 : 9,
                            color: AppColors.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                      if (((booking.location.instructions ?? booking.notes) ?? '').isNotEmpty) ...[
                        Text(
                          booking.location.instructions?.isNotEmpty == true
                              ? booking.location.instructions!
                              : (booking.notes ?? ''),
                          style: GoogleFonts.cairo(
                            fontSize: screenWidth > 1400 ? 11 : screenWidth > 1024 ? 10 : 9,
                            color: AppColors.textLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
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
                booking.clientName ?? '-',
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
                booking.providerName ?? '-',
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
                    _formatDateDisplay(booking.schedule.date),
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 13 : screenWidth > 1024 ? 12 : 11,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    _formatTimeRange(booking.schedule.startTime, booking.schedule.endTime),
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
                '₪${booking.pricing.totalAmount.toStringAsFixed(0)}',
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
                color: _getStatusColor(booking.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getLocalizedStatusLabel(booking.status, languageService).toUpperCase(),
                    style: GoogleFonts.cairo(
                      fontSize: screenWidth > 1400 ? 10 : 9,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(booking.status),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Admin actions: quick cancel + status set menu; plus an indicator if admin changed it
          if (screenWidth > 480)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((booking.notes ?? '').isNotEmpty || (booking.bookingId?.startsWith('BK') ?? false))
                  Tooltip(
                    message: 'Admin action possible',
                    child: Icon(Icons.shield, size: 16, color: Colors.blueGrey.withValues(alpha: 0.8)),
                  ),
                const SizedBox(width: 6),
                PopupMenuButton<String>(
                  tooltip: AppStrings.getString('actions', languageService.currentLanguage),
                  onSelected: (value) async {
                    try {
                      await _bookingService.updateBookingStatus(booking.id, value);
                      await _loadBookings();
                    } catch (_) {}
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'pending', child: Text('Set Pending')),
                    PopupMenuItem(value: 'confirmed', child: Text('Set Confirmed')),
                    PopupMenuItem(value: 'completed', child: Text('Set Completed')),
                    PopupMenuItem(value: 'cancelled', child: Text('Set Cancelled')),
                  ],
                  icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textLight),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // Local short format: yyyy-MM-dd HH:mm
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _formatDateDisplay(String raw) {
    // Accepts either 'yyyy-MM-dd' or ISO-like strings; returns 'yyyy-MM-dd'
    try {
      if (raw.contains('T')) {
        final dt = DateTime.parse(raw).toLocal();
        final two = (int n) => n.toString().padLeft(2, '0');
        return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
      }
    } catch (_) {}
    return raw.split('T').first; // fallback to remove trailing time/Z if present
  }

  String _formatTimeRange(String start, String end) {
    // If times are in 'HH:mm' keep; if ISO or malformed, try to parse and extract HH:mm
    String toHm(String v) {
      if (RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) return v;
      try {
        final dt = DateTime.parse(v).toLocal();
        final two = (int n) => n.toString().padLeft(2, '0');
        return '${two(dt.hour)}:${two(dt.minute)}';
      } catch (_) {
        return v; // as-is fallback
      }
    }
    return '${toHm(start)} - ${toHm(end)}';
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

  // Removed unused _getStatusLabel helper (view-only simplifies usage)
} 