import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/booking_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/widgets/client_rating_dialog.dart';
import '../../../../shared/widgets/client_reviews_dialog.dart';

class BookingsWidget extends StatefulWidget {
  const BookingsWidget({super.key});

  @override
  State<BookingsWidget> createState() => _BookingsWidgetState();
}

class _BookingsWidgetState extends State<BookingsWidget> {
  // Filters
  int _selectedFilter = 0; // 0=All, 1=Pending, 2=Confirmed, 3=Completed, 4=Cancelled
  final _bookingService = BookingService();
  bool _loading = false;
  List<BookingModel> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    try {
      final items = await _bookingService.getMyBookings(page: 1, limit: 50);
      setState(() {
        _bookings = items;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            
            // Responsive breakpoints
            final isDesktop = screenWidth > 1200;
            final isTablet = screenWidth > 768 && screenWidth <= 1200;
            final isMobile = screenWidth <= 768;
            
            return _buildBookingsWidget(languageService, isMobile, isTablet, isDesktop, screenWidth);
          },
        );
      },
    );
  }

  Widget _buildBookingsWidget(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters
          _buildHeader(languageService, isMobile, isTablet, isDesktop),
          
          SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
          
          // Recent Bookings
          _buildBookingsList(languageService, isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildHeader(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('bookings', languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 20.0 : (isTablet ? 24.0 : 28.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: isMobile ? 6.0 : 8.0,
          runSpacing: 8.0,
          children: [
            _buildFilterChip(languageService, 0, 'all'),
            _buildFilterChip(languageService, 1, 'pending'),
            _buildFilterChip(languageService, 2, 'confirmed'),
            _buildFilterChip(languageService, 3, 'completed'),
            _buildFilterChip(languageService, 4, 'cancelled'),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(LanguageService languageService, int value, String key) {
    final lang = languageService.currentLanguage;
    final selected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(AppStrings.getString(key, lang)),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.cairo(color: selected ? AppColors.primary : AppColors.textPrimary),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
  }

  List<BookingModel> _filtered() {
    switch (_selectedFilter) {
      case 1: // pending
        return _bookings.where((b) => b.status.toLowerCase() == 'pending').toList();
      case 2: // confirmed
        return _bookings.where((b) => b.status.toLowerCase() == 'confirmed').toList();
      case 3: // completed
        return _bookings.where((b) => b.status.toLowerCase() == 'completed').toList();
      case 4: // cancelled
        return _bookings.where((b) => b.status.toLowerCase() == 'cancelled').toList();
      default:
  // Default 'All' hides cancelled to avoid resurrecting closed items
  return _bookings.where((b) => b.status.toLowerCase() != 'cancelled').toList();
    }
  }

  Widget _buildBookingsList(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    final list = _filtered();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.getString('recentBookings', languageService.currentLanguage),
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 18.0 : (isTablet ? 20.0 : 22.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.greyDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${list.length}',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 13.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 12.0 : (isTablet ? 16.0 : 20.0)),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppStrings.getString('noBookingsFound', languageService.currentLanguage),
              style: GoogleFonts.cairo(color: AppColors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return _buildBookingDetailCard(list[index], isMobile, isTablet);
            },
          ),
      ],
    );
  }

  Widget _buildBookingDetailCard(BookingModel b, bool isMobile, bool isTablet) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final statusInfo = BookingService.getStatusInfo(b.status);
    final displayDate = BookingService.formatBookingTime(b.schedule);
    final address = b.location.address;
    final price = '₪${b.pricing.totalAmount.toStringAsFixed(0)}';
    final instructions = b.location.instructions ?? '';
    final notes = b.notes ?? '';

  final hasPendingCancel = b.cancellationRequests.any((r) => r.status.toLowerCase() == 'pending');
  final pendingReq = hasPendingCancel ? b.cancellationRequests.firstWhere((r) => r.status.toLowerCase() == 'pending') : null;

  return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isMobile ? 16.0 : 20.0),
      padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 16.0),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((notes.toLowerCase()).contains('admin set to') || (notes.toLowerCase()).contains('admin cancelled')) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 6),
                  Text('Admin update', style: GoogleFonts.cairo(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  b.serviceDetails.title,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 18.0 : 20.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8.0 : 12.0,
                  vertical: isMobile ? 4.0 : 6.0,
                ),
                decoration: BoxDecoration(
                  color: (statusInfo['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 8.0 : 12.0),
                ),
                child: Text(
                  statusInfo['label'] as String,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : 14.0,
                    fontWeight: FontWeight.w600,
                    color: statusInfo['color'] as Color,
                  ),
                ),
              ),
              if (b.status.toLowerCase() == 'cancelled') ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Remove',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _bookings.removeWhere((x) => x.id == b.id);
                      });
                    },
                    child: Container(
                      width: isMobile ? 24 : 28,
                      height: isMobile ? 24 : 28,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (hasPendingCancel && pendingReq != null) ...[
            SizedBox(height: isMobile ? 8.0 : 10.0),
            Container(
              padding: EdgeInsets.all(isMobile ? 10.0 : 12.0),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.getString('cancellationRequest', languageService.currentLanguage),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: Colors.amber.shade900),
                  ),
                  if ((pendingReq.reason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(pendingReq.reason!, style: GoogleFonts.cairo(color: Colors.amber.shade900)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await BookingService().respondCancellationRequest(b.id, pendingReq.id, 'accept');
                            final list = await BookingService().getMyBookings(page: 1, limit: 50);
                            if (mounted) setState(() { _bookings = list; });
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.check, color: AppColors.success, size: 18),
                        label: Text(AppStrings.getString('accept', languageService.currentLanguage), style: GoogleFonts.cairo(color: AppColors.success)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.success)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await BookingService().respondCancellationRequest(b.id, pendingReq.id, 'decline');
                            final list = await BookingService().getMyBookings(page: 1, limit: 50);
                            if (mounted) setState(() { _bookings = list; });
                          } catch (_) {}
                        },
                        icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                        label: Text(AppStrings.getString('decline', languageService.currentLanguage), style: GoogleFonts.cairo(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: isMobile ? 12.0 : 16.0),
          _buildBookingDetailRow(
            Icons.person,
            AppStrings.getString('client', languageService.currentLanguage),
            b.clientName ?? '-',
            isMobile,
          ),
          // Add client overall rating from database
          const SizedBox(height: 8.0),
          _buildClientOverallRatingRow(b, isMobile),
          // Add specific booking rating if available
          if (b.clientRating != null) ...[
            const SizedBox(height: 8.0),
            _buildClientRatingRow(b.clientRating!, isMobile),
          ],
          const SizedBox(height: 8.0),
          if (instructions.isNotEmpty) ...[
            _buildBookingDetailRow(
              Icons.notes,
              AppStrings.getString('specialInstructions', languageService.currentLanguage),
              instructions,
              isMobile,
            ),
            const SizedBox(height: 8.0),
          ],
          if (notes.isNotEmpty) ...[
            _buildBookingDetailRow(
              Icons.sticky_note_2,
              AppStrings.getString('additionalNotesOptional', languageService.currentLanguage),
              notes,
              isMobile,
            ),
            const SizedBox(height: 8.0),
          ],
          _buildBookingDetailRow(
            Icons.calendar_today,
            AppStrings.getString('dateTime', languageService.currentLanguage),
            displayDate,
            isMobile,
          ),
          const SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.location_on,
            AppStrings.getString('address', languageService.currentLanguage),
            address,
            isMobile,
          ),
          const SizedBox(height: 8.0),
          _buildBookingDetailRow(
            Icons.attach_money,
            AppStrings.getString('estimatedCost', languageService.currentLanguage),
            price,
            isMobile,
          ),
          SizedBox(height: isMobile ? 16.0 : 20.0),
          _buildActionButtons(b, isMobile),
        ],
      ),
    );
  }

  Widget _buildBookingDetailRow(IconData icon, String label, String value, bool isMobile) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: isMobile ? 16.0 : 18.0,
        ),
        const SizedBox(width: 8.0),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 14.0 : 16.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 14.0 : 16.0,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientOverallRatingRow(BookingModel booking, bool isMobile) {
    // Get client rating from the populated client data
    final averageRating = booking.clientOverallRating?.average ?? 0.0;
    final ratingCount = booking.clientOverallRating?.count ?? 0;
    
    return Row(
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: isMobile ? 16.0 : 18.0,
        ),
        const SizedBox(width: 8.0),
        Text(
          'Client Rating: ',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 14.0 : 16.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            // Star rating display
            ...List.generate(5, (index) {
              return Icon(
                index < averageRating.floor() 
                    ? Icons.star 
                    : (index < averageRating ? Icons.star_half : Icons.star_border),
                color: Colors.amber,
                size: isMobile ? 14.0 : 16.0,
              );
            }),
            const SizedBox(width: 6.0),
            Text(
              averageRating > 0 ? '${averageRating.toStringAsFixed(1)}' : 'No rating',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: averageRating > 0 ? Colors.amber.shade700 : AppColors.textSecondary,
              ),
            ),
            if (ratingCount > 0) ...[
              const SizedBox(width: 4.0),
              Text(
                '($ratingCount)',
                style: GoogleFonts.cairo(
                  fontSize: isMobile ? 12.0 : 14.0,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const Spacer(),
        // View Reviews button
        if (ratingCount > 0) ...[
          TextButton.icon(
            onPressed: () => _showClientReviewsDialog(booking),
            icon: Icon(
              Icons.reviews,
              size: isMobile ? 14.0 : 16.0,
              color: AppColors.primary,
            ),
            label: Text(
              'View Reviews',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : 14.0,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8.0 : 12.0,
                vertical: isMobile ? 4.0 : 6.0,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClientRatingRow(ClientRating clientRating, bool isMobile) {
    return Row(
      children: [
        Icon(
          Icons.star,
          color: Colors.amber,
          size: isMobile ? 16.0 : 18.0,
        ),
        const SizedBox(width: 8.0),
        Text(
          'This Service Rating: ',
          style: GoogleFonts.cairo(
            fontSize: isMobile ? 14.0 : 16.0,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            // Star rating display
            ...List.generate(5, (index) {
              return Icon(
                index < clientRating.rating.floor() 
                    ? Icons.star 
                    : (index < clientRating.rating ? Icons.star_half : Icons.star_border),
                color: Colors.amber,
                size: isMobile ? 14.0 : 16.0,
              );
            }),
            const SizedBox(width: 6.0),
            Text(
              '${clientRating.rating.toStringAsFixed(1)}',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 14.0 : 16.0,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ),
        if (clientRating.comment != null && clientRating.comment!.isNotEmpty) ...[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              '"${clientRating.comment!}"',
              style: GoogleFonts.cairo(
                fontSize: isMobile ? 12.0 : 14.0,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BookingModel b, bool isMobile) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final status = b.status.toLowerCase();
    final hasPendingCancel = b.cancellationRequests.any((r) => (r.status ?? '').toLowerCase() == 'pending');

    final List<Map<String, Object>> actions = [];
    if (status == 'pending') {
      actions.add({'key': 'confirm', 'icon': Icons.check_circle, 'label': AppStrings.getString('confirmed', languageService.currentLanguage), 'color': AppColors.success});
      actions.add({'key': 'cancel', 'icon': Icons.cancel, 'label': AppStrings.getString('cancel', languageService.currentLanguage), 'color': AppColors.error});
    } else if (status == 'confirmed' || status == 'in_progress') {
      actions.add({'key': 'complete', 'icon': Icons.done_all, 'label': AppStrings.getString('completed', languageService.currentLanguage), 'color': AppColors.secondary});
      if (!hasPendingCancel) {
        actions.add({'key': 'cancel', 'icon': Icons.cancel, 'label': AppStrings.getString('cancel', languageService.currentLanguage), 'color': AppColors.error});
      }
    } else if (status == 'completed') {
      // Show rating icon for completed services that haven't been rated yet
      if (b.clientRating == null) {
        actions.add({'key': 'rate', 'icon': Icons.star_rate, 'label': 'Rate Client', 'color': Colors.amber});
      }
    }

    return Wrap(
      spacing: isMobile ? 8.0 : 12.0,
      runSpacing: isMobile ? 8.0 : 12.0,
      children: actions.map((action) {
        return OutlinedButton.icon(
          onPressed: () => _onProviderActionPressed(action['key'] as String, b),
          icon: Icon(
            action['icon'] as IconData,
            size: isMobile ? 16.0 : 18.0,
            color: action['color'] as Color,
          ),
          label: Text(
            action['label'] as String,
            style: GoogleFonts.cairo(
              fontSize: isMobile ? 12.0 : 14.0,
              fontWeight: FontWeight.w500,
              color: action['color'] as Color,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: action['color'] as Color, width: 1),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12.0 : 16.0,
              vertical: isMobile ? 8.0 : 10.0,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _onProviderActionPressed(String key, BookingModel target) async {
    final svc = BookingService();
    try {
      if (key == 'confirm' && target.status.toLowerCase() == 'pending') {
        await svc.confirmBooking(target.id);
      } else if (key == 'complete' && ['confirmed','in_progress'].contains(target.status.toLowerCase())) {
        await svc.completeBooking(target.id);
        
        // Show rating dialog after successful completion
        if (mounted) {
          _showClientRatingDialog(target);
        }
      } else if (key == 'rate' && target.status.toLowerCase() == 'completed') {
        // Show rating dialog for completed services that haven't been rated
        if (mounted) {
          _showClientRatingDialog(target);
        }
      } else if (key == 'cancel') {
        await svc.cancelBookingAction(target.id);
      }
      // refresh
      final list = await BookingService().getMyBookings(page: 1, limit: 50);
      if (mounted) setState(() => _bookings = list);
    } catch (_) {
      // ignore for now; UI can show snackbars later
    }
  }

  void _showClientRatingDialog(BookingModel booking) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return ClientRatingDialog(
          bookingId: booking.id,
          clientName: booking.clientName ?? 'Unknown Client',
          serviceName: booking.serviceDetails.title,
          onRatingSubmitted: () {
            // Refresh bookings after rating is submitted
            _loadBookings();
          },
        );
      },
    );
  }

  void _showClientReviewsDialog(BookingModel booking) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = BookingService();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ClientReviewsDialog(
          clientId: booking.clientId ?? '',
          clientName: booking.clientName ?? 'Unknown Client',
          reviewsFuture: bookingService.getClientReviews(
            booking.clientId ?? '',
            authService: authService,
          ),
        );
      },
    );
  }
}
