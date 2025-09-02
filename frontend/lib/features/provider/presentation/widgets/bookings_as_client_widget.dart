import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/services/booking_service.dart';
import '../../../../shared/services/language_service.dart';

class BookingsAsClientWidget extends StatefulWidget {
  final String? titleKey; // Optional i18n key to override header title
  const BookingsAsClientWidget({super.key, this.titleKey});

  @override
  State<BookingsAsClientWidget> createState() => _BookingsAsClientWidgetState();
}

class _BookingsAsClientWidgetState extends State<BookingsAsClientWidget> {
  int _selectedFilter = 0;
  bool _loading = false;
  List<BookingModel> _bookings = [];
  final Set<String> _dismissed = <String>{}; // local hide for cancelled

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _loading = true);
    try {
      final items = await BookingService().getMyBookings(page: 1, limit: 50, asClient: true);
      setState(() { _bookings = items; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth <= 768;
            final isTablet = constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
            final isDesktop = constraints.maxWidth > 1200;
            return _build(languageService, isMobile, isTablet, isDesktop);
          },
        );
      },
    );
  }

  Widget _build(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 12 : 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.getString(widget.titleKey ?? 'myClientBookings', languageService.currentLanguage),
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 20 : (isTablet ? 24 : 28),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              )
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: isMobile ? 6.0 : 8.0,
            runSpacing: 8.0,
            children: [
              _filterChip(languageService, 0, 'all'),
              _filterChip(languageService, 1, 'pending'),
              _filterChip(languageService, 2, 'confirmed'),
              _filterChip(languageService, 3, 'completed'),
              _filterChip(languageService, 4, 'cancelled'),
            ],
          ),
          const SizedBox(height: 16),
          _list(languageService, isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _filterChip(LanguageService languageService, int value, String key) {
    final selected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(AppStrings.getString(key, languageService.currentLanguage)),
      selected: selected,
      onSelected: (_) async {
        setState(() => _selectedFilter = value);
        try {
          final status = _statusFromFilter(value);
          final items = await BookingService().getMyBookings(page: 1, limit: 50, asClient: true, status: status);
          if (mounted) setState(() => _bookings = items);
        } catch (_) {}
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.cairo(color: selected ? AppColors.primary : AppColors.textPrimary),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
  }

  List<BookingModel> _filtered() {
    List<BookingModel> src;
    switch (_selectedFilter) {
      case 1: src = _bookings.where((b) => b.status.toLowerCase() == 'pending').toList(); break;
      case 2: src = _bookings.where((b) => b.status.toLowerCase() == 'confirmed').toList(); break;
      case 3: src = _bookings.where((b) => b.status.toLowerCase() == 'completed').toList(); break;
      case 4: src = _bookings.where((b) => b.status.toLowerCase() == 'cancelled').toList(); break;
      default: src = _bookings.where((b) => b.status.toLowerCase() != 'cancelled').toList();
    }
    // Apply local dismissed filter only on Cancelled tab
    if (_selectedFilter == 4) {
      src = src.where((b) => !_dismissed.contains(b.id)).toList();
    }
    return src;
  }

  String? _statusFromFilter(int f) {
    switch (f) {
      case 1: return 'pending';
      case 2: return 'confirmed';
      case 3: return 'completed';
      case 4: return 'cancelled';
      default: return null;
    }
  }

  Widget _list(LanguageService languageService, bool isMobile, bool isTablet, bool isDesktop) {
    final list = _filtered();
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(AppStrings.getString('noBookingsFound', languageService.currentLanguage), style: GoogleFonts.cairo(color: AppColors.grey)),
      );
    }
    final groups = _groupBookings(list);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final g = groups[i];
        if (g.length == 1) return _card(g.first, isMobile);
        return _groupCard(g, isMobile);
      },
    );
  }

  // Group by providerId (relationship across dates/services)
  List<List<BookingModel>> _groupBookings(List<BookingModel> items) {
    final Map<String, List<BookingModel>> map = {};
    for (final b in items) {
    final provKey = (b.providerId != null && b.providerId!.isNotEmpty)
      ? b.providerId!
      : ((b.providerName != null && b.providerName!.isNotEmpty)
        ? 'name:${b.providerName}'
        : 'booking:${b.id}');
    (map[provKey] ??= <BookingModel>[]).add(b);
    }
    final groups = map.values.toList();
    groups.sort((a,b){
      final da = a.map((x)=>x.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).fold<DateTime>(DateTime.fromMillisecondsSinceEpoch(0),(p,n)=> n.isAfter(p)?n:p);
      final db = b.map((x)=>x.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).fold<DateTime>(DateTime.fromMillisecondsSinceEpoch(0),(p,n)=> n.isAfter(p)?n:p);
      return db.compareTo(da);
    });
    for (final g in groups) {
      g.sort((x,y){
        final c = x.schedule.date.compareTo(y.schedule.date);
        if (c != 0) return c;
        return x.schedule.startTime.compareTo(y.schedule.startTime);
      });
    }
    return groups;
  }

  Widget _groupCard(List<BookingModel> group, bool isMobile) {
    final b0 = group.first;
    final statusAllSame = group.every((b) => b.status.toLowerCase() == group.first.status.toLowerCase());
    final statusInfo = BookingService.getStatusInfo(statusAllSame ? b0.status : 'multiple');
    final Map<String, List<BookingModel>> byDate = {};
    for (final b in group) { (byDate[b.schedule.date] ??= <BookingModel>[]).add(b); }
    final lines = byDate.entries.toList()..sort((a,b)=> a.key.compareTo(b.key));
    final dateDisp = lines.map((e){
      final times = (e.value..sort((x,y)=> x.schedule.startTime.compareTo(y.schedule.startTime)))
          .map((b)=>'${b.schedule.startTime} - ${b.schedule.endTime}')
          .join(', ');
      return '${_formatDate(e.key)} • $times';
    }).join('; ');
    final total = group.fold<double>(0.0, (sum, b) => sum + b.pricing.totalAmount);
    final price = '₪${total.toStringAsFixed(0)}';
    final providerName = b0.providerName ?? '';
    final address = b0.location.address;
    final notes = b0.notes ?? '';
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children:[
            Expanded(child: Text(b0.serviceDetails.title, style: GoogleFonts.cairo(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            if (_selectedFilter == 4 && group.every((b)=> b.status.toLowerCase()=='cancelled'))
              IconButton(
                tooltip: AppStrings.getString('remove', Provider.of<LanguageService>(context, listen:false).currentLanguage),
                icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
                onPressed: () {
                  setState(() {
                    for (final b in group) { _dismissed.add(b.id); }
                  });
                },
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 4 : 6),
              decoration: BoxDecoration(color: (statusInfo['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
              child: Text(statusAllSame ? statusInfo['label'] : 'Multiple', style: GoogleFonts.cairo(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600, color: statusInfo['color'] as Color)),
            )
          ]),
          if ((notes.toLowerCase()).contains('admin set to') || (notes.toLowerCase()).contains('admin cancelled')) ...[
            const SizedBox(height: 6), Row(children:[const Icon(Icons.shield, size:14, color: Colors.blueGrey), const SizedBox(width:6), Text('Admin update', style: GoogleFonts.cairo(fontSize:12, color: Colors.blueGrey))]),
          ],
          const SizedBox(height: 8),
          if (providerName.isNotEmpty) ...[
            _row(Icons.person, AppStrings.getString('providerName', Provider.of<LanguageService>(context, listen:false).currentLanguage), providerName, isMobile),
            const SizedBox(height: 8),
          ],
          _row(Icons.calendar_today, AppStrings.getString('dateTime', Provider.of<LanguageService>(context, listen:false).currentLanguage), dateDisp, isMobile),
          const SizedBox(height: 8),
          _row(Icons.location_on, AppStrings.getString('address', Provider.of<LanguageService>(context, listen:false).currentLanguage), address, isMobile),
          const SizedBox(height: 8),
          _row(Icons.attach_money, AppStrings.getString('estimatedCost', Provider.of<LanguageService>(context, listen:false).currentLanguage), price, isMobile),
          const SizedBox(height: 12),
          // Per-slot actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: group.map((b) {
              final line = '${b.schedule.startTime} - ${b.schedule.endTime} • ₪${b.pricing.totalAmount.toStringAsFixed(0)}';
              final canCancel = ['pending','confirmed'].contains(b.status.toLowerCase());
              final chip = BookingService.getStatusInfo(b.status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Row(children:[
                      Expanded(child: Text(line, style: GoogleFonts.cairo(fontSize: isMobile ? 13 : 14, color: AppColors.textPrimary))),
                      const SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8, vertical: 3),
                        decoration: BoxDecoration(color: (chip['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(chip['label'] as String, style: GoogleFonts.cairo(fontSize: isMobile ? 10 : 12, color: chip['color'] as Color)),
                      ),
                    ])),
                    if (canCancel)
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await BookingService().cancelBookingAction(b.id);
                            final status = _statusFromFilter(_selectedFilter);
                            final list = await BookingService().getMyBookings(page:1, limit:50, asClient:true, status: status);
                            if (mounted) setState(()=>_bookings=list);
                          } catch(_){ }
                        },
                        icon: const Icon(Icons.cancel, color: AppColors.error, size: 18),
                        label: Text(AppStrings.getString('cancel', Provider.of<LanguageService>(context, listen:false).currentLanguage), style: GoogleFonts.cairo(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(String ymd) {
    try {
      if (ymd.contains('T')) {
        final dt = DateTime.parse(ymd).toLocal();
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}
    final parts = ymd.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]) ?? parts[0];
      final m = int.tryParse(parts[1]) ?? parts[1];
      final dRaw = parts[2];
      final d = int.tryParse(dRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? dRaw;
      return '$d/$m/$y';
    }
    return ymd;
  }

  Widget _card(BookingModel b, bool isMobile) {
    final statusInfo = BookingService.getStatusInfo(b.status);
    final displayDate = BookingService.formatBookingTime(b.schedule);
  final price = '₪${b.pricing.totalAmount.toStringAsFixed(0)}';
    final address = b.location.address;
    final notes = b.notes ?? '';
  final providerName = b.providerName ?? '';
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0,2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b.serviceDetails.title,
                  style: GoogleFonts.cairo(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              if (_selectedFilter == 4 && b.status.toLowerCase()=='cancelled')
                IconButton(
                  tooltip: AppStrings.getString('remove', Provider.of<LanguageService>(context, listen:false).currentLanguage),
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
                  onPressed: () { setState(() { _dismissed.add(b.id); }); },
                ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 4 : 6),
                decoration: BoxDecoration(color: (statusInfo['color'] as Color).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(isMobile ? 8 : 12)),
                child: Text(statusInfo['label'], style: GoogleFonts.cairo(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600, color: statusInfo['color'] as Color)),
              ),
            ],
          ),
          if ((notes.toLowerCase()).contains('admin set to') || (notes.toLowerCase()).contains('admin cancelled')) ...[
            const SizedBox(height: 6),
            Row(children:[const Icon(Icons.shield, size:14, color: Colors.blueGrey), const SizedBox(width:6), Text('Admin update', style: GoogleFonts.cairo(fontSize:12, color: Colors.blueGrey))]),
          ],
          const SizedBox(height: 8),
          if (providerName.isNotEmpty) ...[
            _row(Icons.person, AppStrings.getString('providerName', Provider.of<LanguageService>(context, listen:false).currentLanguage), providerName, isMobile),
            const SizedBox(height: 8),
          ],
          _row(Icons.calendar_today, AppStrings.getString('dateTime', Provider.of<LanguageService>(context, listen:false).currentLanguage), displayDate, isMobile),
          const SizedBox(height: 8),
          _row(Icons.location_on, AppStrings.getString('address', Provider.of<LanguageService>(context, listen:false).currentLanguage), address, isMobile),
          const SizedBox(height: 8),
          _row(Icons.attach_money, AppStrings.getString('estimatedCost', Provider.of<LanguageService>(context, listen:false).currentLanguage), price, isMobile),
          const SizedBox(height: 12),
          _actions(b, isMobile),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, bool isMobile) {
    return Row(children:[
      Icon(icon, size: isMobile ? 16 : 18, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Text('$label: ', style: GoogleFonts.cairo(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      Expanded(child: Text(value, style: GoogleFonts.cairo(fontSize: isMobile ? 14 : 16, color: AppColors.textPrimary))),
    ]);
  }

  Widget _actions(BookingModel b, bool isMobile) {
    final lang = Provider.of<LanguageService>(context, listen: false).currentLanguage;
    final canCancel = ['pending','confirmed'].contains(b.status.toLowerCase());
    return Wrap(
      spacing: isMobile ? 8 : 12,
      children: [
        if (canCancel)
          OutlinedButton.icon(
            onPressed: () async {
              try { await BookingService().cancelBookingAction(b.id); final list = await BookingService().getMyBookings(page:1, limit:50, asClient:true); if (mounted) setState(()=>_bookings=list);} catch(_){ }
            },
            icon: const Icon(Icons.cancel, color: AppColors.error, size: 18),
            label: Text(AppStrings.getString('cancel', lang), style: GoogleFonts.cairo(color: AppColors.error)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
          ),
      ],
    );
  }
}
