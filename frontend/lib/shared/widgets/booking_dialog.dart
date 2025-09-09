import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Shared imports
import '../models/provider.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/language_service.dart';
import 'app_toast.dart';
import '../services/auth_service.dart';
import '../services/services_service.dart';
import '../services/services_service.dart' as svc;
import '../services/location_service.dart';
// Legacy emergency whitelist removed; we now respect provider-configured flags only.
import '../services/availability_service.dart';
// Calendar UI will be declared at bottom of this file for simplicity

// Simple value class for a merged time range
class _TimeRange {
  final String start; // HH:mm
  final String end;   // HH:mm
  const _TimeRange({required this.start, required this.end});
}

class BookingDialog extends StatefulWidget {
  final ProviderModel provider;
  final String? selectedService;

  const BookingDialog({
    super.key,
    required this.provider,
    this.selectedService,
  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final BookingService _bookingService = BookingService();
  final ServicesService _servicesService = ServicesService();
  final AvailabilityService _availabilityService = AvailabilityService();

  // Form controllers
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedAddressId; // index as string for saved addresses

  // Form state
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  // Persist selected slot keys per day (key: 'YYYY-MM-DD' -> set of 'HH:mm-HH:mm')
  final Map<String, Set<String>> _selectedByDate = {};
  String? _selectedService;
  String? _selectedServiceId; // backend service _id
  List<svc.ServiceModel> _providerServices = const [];
  bool _loading = false;
  AvailabilityModel? _availability; // provider availability
  AvailabilityResolved? _resolved;  // day+slot view
  DateTime _calendarMonth = DateTime.now();
  // Calendar UX state
  String _calendarMode = 'month'; // 'month' | 'day'
  DateTime? _dayViewDate; // when in day mode
  // Same-day booking is not allowed per product rules (UI mirrors backend)
  bool _emergency = false; // emergency booking mode
  bool get _supportsEmergency {
    // Only respect provider-configured per-service flags
    if (_providerServices.isNotEmpty) {
      if (_selectedServiceId != null && _selectedServiceId!.isNotEmpty) {
        final selected = _providerServices.firstWhere(
          (s) => s.id == _selectedServiceId,
          orElse: () => _providerServices.first,
        );
        return (selected.emergencyEnabled == true);
      }
      return _providerServices.any((s) => s.emergencyEnabled == true);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
  _selectedService = widget.selectedService ?? widget.provider.services.first;
  // Do not preselect date/time; user must choose explicitly
  _selectedDate = null;
  _startTime = null;
  _endTime = null;

  // Load provider services from backend to get real service IDs
  // Ignore errors and gracefully fall back to provider.services list
  _loadProviderServices(); // This will call _loadResolved() after completion
  _loadAvailability();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    try {
      final a = await _availabilityService.getAvailability(widget.provider.id);
      if (!mounted) return;
      setState(() { _availability = a; });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadResolved() async {
    try {
      // Debug logging to see what provider ID is being used
      if (kDebugMode) {
        print('🔍 BookingDialog._loadResolved called with:');
        print('  Provider ID: ${widget.provider.id}');
        print('  Provider Name: ${widget.provider.name}');
        print('  Emergency Mode: $_emergency');
        print('  Selected Service ID: $_selectedServiceId');
      }
      
      // Validate provider ID - allow mock providers to work
      if (widget.provider.id.isEmpty) {
        if (kDebugMode) {
          print('⚠️ Provider ID is empty, returning empty availability');
        }
        if (mounted) {
          setState(() {
            _resolved = AvailabilityResolved(
              days: [],
              step: 60,
              timezone: 'UTC',
            );
          });
        }
        return;
      }
      
      final now = DateTime.now();
      final DateTime from;
      
      if (_emergency && _supportsEmergency) {
        // Emergency mode: 2-hour lead time (same day booking allowed)
        from = now.add(const Duration(hours: 2));
      } else {
        // Normal mode: 2-day lead time (48 hours ahead)
        from = now.add(const Duration(days: 2));
      }
      
      final to = from.add(const Duration(days: 31));
      
      if (kDebugMode) {
        print('🔍 Date range for availability:');
        print('  Now: $now');
        print('  From: $from');
        print('  To: $to');
        print('  Emergency mode: $_emergency');
      }
      
  final r = await _availabilityService.getResolvedAvailability(
    widget.provider.id,
    from: from,
    to: to,
    stepMinutes: 60,
    emergency: _emergency,
    serviceId: _selectedServiceId,
  );
      
      if (kDebugMode) {
        print('🔍 Availability API call completed:');
        print('  Result: ${r != null ? 'Success' : 'Failed'}');
        if (r != null) {
          print('  Timezone: ${r.timezone}');
          print('  Step: ${r.step}');
          print('  Days: ${r.days.length}');
          if (r.days.isNotEmpty) {
            print('  First day: ${r.days.first.date} - Available: ${r.days.first.slots.length}, Booked: ${r.days.first.booked.length}');
          }
        }
      }
      
      if (!mounted) return;
      setState(() {
        _resolved = r ?? AvailabilityResolved(
          days: [],
          step: 60,
          timezone: 'UTC',
        );
        _calendarMonth = DateTime(from.year, from.month, 1);
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in _loadResolved: $e');
        print('  Provider ID: ${widget.provider.id}');
        print('  Provider Name: ${widget.provider.name}');
      }
      // Show a fallback or error state instead of silent failure
      if (mounted) {
        setState(() {
          // Set a minimal resolved state to show calendar with no available times
          _resolved = AvailabilityResolved(
            days: [],
            step: 60,
            timezone: 'UTC',
          );
        });
      }
    }
  }

  Future<void> _loadResolvedForMonth(DateTime monthStart) async {
    try {
      final now = DateTime.now();
      final DateTime minDate;
      
      if (_emergency && _supportsEmergency) {
        // Emergency mode: 2-hour lead time (same day booking allowed)
        minDate = now.add(const Duration(hours: 2));
      } else {
        // Normal mode: 2-day lead time (48 hours ahead)
        minDate = now.add(const Duration(days: 2));
      }
      
      // Use the later of the requested month start or the minimum allowed date
      final from = DateTime(monthStart.year, monthStart.month, 1).isBefore(minDate)
          ? minDate
          : DateTime(monthStart.year, monthStart.month, 1);
      final to = DateTime(monthStart.year, monthStart.month + 1, 0);
      
    final r = await _availabilityService.getResolvedAvailability(
        widget.provider.id,
        from: from,
        to: to,
  stepMinutes: 60,
  emergency: _emergency,
  serviceId: _selectedServiceId,
      );
      if (!mounted) return;
      setState(() {
        _resolved = r;
        _calendarMonth = DateTime(monthStart.year, monthStart.month, 1);
      });
    } catch (e) {
      // Show a fallback state instead of silent failure
      if (mounted) {
        setState(() {
          _resolved = AvailabilityResolved(
            days: [],
            step: 60,
            timezone: 'UTC',
          );
        });
      }
    }
  }

  void _toggleEmergency(bool value) {
    if (!_supportsEmergency) {
      return;
    }
    setState(() {
      _emergency = value;
      // Refresh resolved availability with emergency consideration
      _loadResolved();
    });
  }

  void _changeMonth(int delta) {
    final base = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final limitNext = DateTime(base.year, base.month + 1, 1); // only current and next month allowed
    final next = DateTime(_calendarMonth.year, _calendarMonth.month + delta, 1);
    // Guard: allow only [base, limitNext]
    if (next.isBefore(base) || next.isAfter(limitNext)) {
      return;
    }
    setState(() {
      _calendarMonth = next;
      _resolved = null; // indicate loading state until fetched
      _calendarMode = 'month';
      _dayViewDate = null;
  // Do not clear selections on month change; persist across navigation
    });
    _loadResolvedForMonth(next);
  }
  Future<void> _openDayView(DateTime date) async {
    // Ensure resolved has the selected date's month
    final needsMonth = _resolved == null || _calendarMonth.year != date.year || _calendarMonth.month != date.month;
    if (needsMonth) {
      await _loadResolvedForMonth(DateTime(date.year, date.month, 1));
    } else {
      // If day isn't present (edge case after db changes), also reload month
      final key = _dateKey(date);
      final hasDay = (_resolved?.days.any((d) => d.date == key) ?? false);
      if (!hasDay) {
        await _loadResolvedForMonth(DateTime(date.year, date.month, 1));
      }
    }
    if (!mounted) return;
    setState(() {
      _calendarMode = 'day';
      _dayViewDate = date;
  // keep selections; reset the focused time for new day until user selects
  _startTime = null;
  _endTime = null;
    });
  }
  void _backToMonth() {
    setState(() {
      _calendarMode = 'month';
      // keep month as-is
    });
  }



  void _validateTimeAgainstAvailability() {
    if (_availability == null || _selectedDate == null || _startTime == null || _endTime == null) return;
    final date = _selectedDate!;
    final dayName = [
      'sunday','monday','tuesday','wednesday','thursday','friday','saturday'
    ][date.weekday % 7];
    final start = _formatTime(_startTime!);
    final end = _formatTime(_endTime!);
    // Exceptions take precedence
    final dateKey = '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
    final ex = _availability!.exceptions[dateKey];
    List<TimeWindow> windows;
    if (ex != null) {
      windows = ex; // empty list means unavailable
    } else {
      windows = _availability!.weekly[dayName] ?? <TimeWindow>[];
    }
    bool ok = true;
    if (windows.isEmpty) {
      // Treat empty as not allowed to avoid user confusion
      ok = false;
    } else {
      ok = windows.any((w) => w.start.compareTo(start) <= 0 && w.end.compareTo(end) >= 0);
    }
    if (!ok) {
      AppToast.show(context, message: 'Selected time is outside provider availability');
    }
  }

  Future<void> _loadProviderServices() async {
    try {
      final providerId = widget.provider.id;
      
      if (providerId.isEmpty) {
        // Skip fetching if the provider id is empty
        return;
      }
      final items = await _servicesService.getServicesByProvider(providerId);
      
      if (!mounted) return;
      setState(() {
        // Keep only services whose subcategory exists in provider.services
        final keys = widget.provider.services.map((e) => e.toLowerCase()).toList();
        var filtered = items.where((s) =>
            s.subcategory != null && keys.contains(s.subcategory!.toLowerCase())
        ).toList();
        // Preserve the order as shown on provider card chips
        filtered.sort((a, b) {
          final ia = keys.indexOf((a.subcategory ?? '').toLowerCase());
          final ib = keys.indexOf((b.subcategory ?? '').toLowerCase());
          return ia.compareTo(ib);
        });
        _providerServices = filtered.isNotEmpty ? filtered : items;
        
        // Preselect by incoming selectedService key when possible
        if (_providerServices.isNotEmpty) {
          // Match using subcategory first (exact service key used on provider card),
          // then fall back to category/title.
          final sel = widget.selectedService;
          final matched = (sel != null && sel.isNotEmpty)
              ? _providerServices.firstWhere(
                  (s) {
                    final sub = (s.subcategory ?? '').toLowerCase();
                    final cat = (s.category).toLowerCase();
                    final title = (s.title).toLowerCase();
                    final target = sel.toLowerCase();
                    return sub == target || cat == target || title == target;
                  },
                  orElse: () => _providerServices.first,
                )
              : _providerServices.first;
          _selectedServiceId = matched.id;
        }
      });
      
      // Load resolved availability after services are loaded
      _loadResolved();
    } catch (_) {
      // Silent fallback; dropdown will use provider.services (strings)
      // Still try to load resolved availability even if services failed
      _loadResolved();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double _calculateEstimatedCost() {
    // Prefer summing all selected segments across days; fall back to single focused slot
    final segs = _computeSelectedSegments();
    int totalMinutes = 0;
    if (segs.isNotEmpty) {
      for (final ranges in segs.values) {
        for (final r in ranges) {
          totalMinutes += _minutesBetween(r.start, r.end);
        }
      }
    } else if (_startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      totalMinutes = (endMinutes - startMinutes).clamp(0, 24 * 60);
    }
    // Try to use selected backend service price type if available
    svc.ServiceModel? selected;
    if (_providerServices.isNotEmpty) {
      try {
        selected = _providerServices.firstWhere(
          (s) => s.id == _selectedServiceId,
          orElse: () => _providerServices.first,
        );
      } catch (_) {
        selected = _providerServices.first;
      }
    }
    final priceType = (selected?.price.type ?? 'hourly');
    double amount = (selected?.price.amount ?? widget.provider.hourlyRate).toDouble();
    // Apply emergency multiplier if selected and supported by configured flags only
    if (_emergency && selected != null && selected.emergencyEnabled) {
      final multiplier = selected.emergencyRateMultiplier;
      amount = (amount * multiplier);
    }
    if (priceType == 'hourly') {
      final hours = totalMinutes / 60.0;
      double total = hours * amount;
      // Apply emergency surcharge (flat or percent)
      if (_emergency && selected != null && selected.emergencyEnabled) {
        final type = selected.emergencySurchargeType;
        final amt = selected.emergencySurchargeAmount;
        if (type == 'percent') {
          total += (total * (amt / 100.0));
        } else {
          total += amt;
        }
      }
      return total;
    }
    // fixed/daily: multiply by number of segments if any, else single
    final segmentsCount = segs.isNotEmpty ? segs.values.fold<int>(0, (acc, v) => acc + v.length) : 1;
    return amount * segmentsCount;
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    final segs = _computeSelectedSegments();
    final hasMulti = segs.isNotEmpty;
    if (!hasMulti && (_selectedDate == null || _startTime == null || _endTime == null)) {
      AppToast.show(context, message: 'Please select date and time');
      return;
    }

  // Require login and a valid token
  final auth = Provider.of<AuthService>(context, listen: false);
  final hasToken = (auth.token != null && auth.token!.isNotEmpty);
  if (!auth.isAuthenticated || !hasToken) {
      AppToast.show(context, message: 'Please login to place a booking');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
  // Final UI-side guard: enforce availability if known (for each segment)
  _validateAllSegmentsAgainstAvailability(segs);

      // Determine serviceId to send to backend
      String? serviceId = _selectedServiceId;
      if ((serviceId == null || serviceId.isEmpty) && _providerServices.isNotEmpty) {
        serviceId = _providerServices.first.id;
      }
      // As a final fallback, attempt to resolve by fetching provider services once
      if (serviceId == null || serviceId.isEmpty) {
        try {
          final items = await _servicesService.getServicesByProvider(widget.provider.id);
          // Try to match selected subcategory key to a service document
          if (items.isNotEmpty) {
            final selKey = _selectedService;
            if (selKey != null && selKey.isNotEmpty) {
              final match = items.firstWhere(
                (s) => (s.subcategory ?? '').toLowerCase() == selKey.toLowerCase(),
                orElse: () => items.first,
              );
              serviceId = match.id;
            } else {
              serviceId = items.first.id;
            }
          }
        } catch (_) {}
      }
      if (serviceId == null || serviceId.isEmpty) {
        throw Exception('No service available for this provider. Please choose a different service.');
      }

      final location = Location(
        address: _addressController.text,
        instructions: _instructionsController.text.isNotEmpty 
            ? _instructionsController.text 
            : null,
      );
      
      final tz = _availability?.timezone ?? 'Asia/Jerusalem';
      int success = 0, fail = 0;
      if (hasMulti) {
        for (final entry in segs.entries) {
          final dateKey = entry.key;
          for (final r in entry.value) {
            try {
              final schedule = Schedule(
                date: dateKey,
                startTime: r.start,
                endTime: r.end,
                timezone: tz,
              );
              final request = CreateBookingRequest(
                serviceId: serviceId,
                schedule: schedule,
                location: location,
                notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                emergency: _emergency,
              );
              await _bookingService.createBooking(request);
              success++;
            } catch (_) {
              fail++;
            }
          }
        }
      } else {
        final schedule = Schedule(
          date: _selectedDate!.toIso8601String().split('T')[0],
          startTime: _formatTime(_startTime!),
          endTime: _formatTime(_endTime!),
          timezone: tz,
        );
        final request = CreateBookingRequest(
          serviceId: serviceId,
          schedule: schedule,
          location: location,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          emergency: _emergency,
        );
        await _bookingService.createBooking(request);
        success = 1;
      }

      if (mounted) {
        Navigator.of(context).pop();
        if (fail == 0) {
          AppToast.show(context, message: success > 1 ? 'Created $success bookings' : 'Booking created successfully!');
        } else if (success > 0) {
          AppToast.show(context, message: 'Created $success bookings; $fail failed');
        } else {
          AppToast.show(context, message: 'Failed to create bookings');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to create booking: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Compute selected ranges per date, merging adjacent slots into a single segment
  Map<String, List<_TimeRange>> _computeSelectedSegments() {
    Map<String, List<_TimeRange>> out = {};
    if (_selectedByDate.isEmpty) return out;
    String start(String key) => key.split('-')[0];
    String end(String key) => key.split('-')[1];
    for (final entry in _selectedByDate.entries) {
      final sorted = entry.value.toList()..sort((a,b)=>a.compareTo(b));
      if (sorted.isEmpty) continue;
      List<_TimeRange> ranges = [];
      String curStart = start(sorted.first);
      String curEnd = end(sorted.first);
      for (int i=1;i<sorted.length;i++) {
        final s = start(sorted[i]);
        final e = end(sorted[i]);
        if (s == curEnd) {
          // contiguous, extend current
          curEnd = e;
        } else {
          ranges.add(_TimeRange(start: curStart, end: curEnd));
          curStart = s; curEnd = e;
        }
      }
      ranges.add(_TimeRange(start: curStart, end: curEnd));
      out[entry.key] = ranges;
    }
    return out;
  }

  int _minutesBetween(String start, String end) {
    final sp = start.split(':');
    final ep = end.split(':');
    final sm = (int.tryParse(sp[0]) ?? 0) * 60 + (int.tryParse(sp[1]) ?? 0);
    final em = (int.tryParse(ep[0]) ?? 0) * 60 + (int.tryParse(ep[1]) ?? 0);
    return (em - sm).clamp(0, 24*60);
  }

  void _validateAllSegmentsAgainstAvailability(Map<String, List<_TimeRange>> segs) {
    if (_availability == null) return;
    if (segs.isEmpty) {
      _validateTimeAgainstAvailability();
      return;
    }
    for (final entry in segs.entries) {
      final dateParts = entry.key.split('-').map((e) => int.tryParse(e) ?? 0).toList();
      final d = DateTime(dateParts[0], dateParts[1], dateParts[2]);
      for (final r in entry.value) {
        _selectedDate = d;
        _startTime = _parseHHmm(r.start);
        _endTime = _parseHHmm(r.end);
        _validateTimeAgainstAvailability();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final lang = languageService.currentLanguage;
    final isRtl = languageService.textDirection == TextDirection.rtl;
    
    // Debug logging to see calendar state
    if (kDebugMode) {
      print('📅 BookingDialog build - Availability: ${_availability != null}, Resolved: ${_resolved != null}');
      if (_resolved != null) {
        print('📅 Resolved data - Days: ${_resolved!.days.length}, Timezone: ${_resolved!.timezone}');
        final daysWithData = _resolved!.days.where((d) => d.slots.isNotEmpty || d.booked.isNotEmpty).toList();
        print('📅 Days with data: ${daysWithData.length}');
        for (var day in daysWithData.take(3)) {
          print('  📅 ${day.date}: Available=${day.slots.length}, Booked=${day.booked.length}');
        }
      }
    }
  final media = MediaQuery.of(context);
  final screenW = media.size.width;
  final screenH = media.size.height;
  final isCompact = screenW < 480; // very small/mobile
  final isNarrow = screenW < 640;  // small tablets/narrow windows
  final dialogMaxWidth = isCompact ? screenW - 24 : (isNarrow ? 560.0 : 640.0);
    final auth = Provider.of<AuthService>(context, listen: true);
    final user = auth.currentUser;
    final isProvider = user?['role'] == 'provider';
    final useGpsLocation = user?['useGpsLocation'] ?? false;
    final shouldShowGpsAddress = isProvider || useGpsLocation;
    
    final savedAddresses = (user?['addresses'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const <Map<String, dynamic>>[];
    
    // Prefill GPS address if GPS is enabled, otherwise use saved addresses
    if (_addressController.text.isEmpty) {
      if (shouldShowGpsAddress) {
        // Try to get GPS address from user's profile
        String gpsAddress = '';
        if (user != null) {
          if (user['address'] is String && user['address'].isNotEmpty) {
            gpsAddress = user['address'];
          } else if (user['address'] is Map) {
            final addressMap = user['address'] as Map;
            final line1 = addressMap['line1'] ?? '';
            final city = addressMap['city'] ?? '';
            final street = addressMap['street'] ?? '';
            if (line1.isNotEmpty) {
              gpsAddress = line1;
            } else if (street.isNotEmpty && city.isNotEmpty) {
              gpsAddress = '$street, $city';
            }
          }
        }
        
        if (gpsAddress.isNotEmpty) {
          _addressController.text = gpsAddress;
          _selectedAddressId = 'gps';
        } else if (savedAddresses.isNotEmpty) {
          // Fallback to saved addresses if no GPS address found
          final def = savedAddresses.firstWhere(
            (a) => a['isDefault'] == true,
            orElse: () => savedAddresses.first,
          );
          _addressController.text = _formatAddress(def, lang);
          _selectedAddressId = savedAddresses.indexOf(def).toString();
        }
      } else if (savedAddresses.isNotEmpty) {
        // Use saved addresses if GPS is not enabled
        final def = savedAddresses.firstWhere(
          (a) => a['isDefault'] == true,
          orElse: () => savedAddresses.first,
        );
        _addressController.text = _formatAddress(def, lang);
        _selectedAddressId = savedAddresses.indexOf(def).toString();
      }
    }
    
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
        width: dialogMaxWidth,
        constraints: BoxConstraints(
          // On small screens allow taller dialogs while still staying within view
          maxHeight: screenH * (isCompact ? 0.95 : 0.85),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.getString('bookNow', lang)} • ${widget.provider.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Provider info
                      _buildProviderInfo(),
                      const SizedBox(height: 16),
                      
                      // Service selection
                      _buildServiceSelection(lang),
                      const SizedBox(height: 16),
                      
                      // Date and time
                      _buildDateTimeSelection(lang),
                      const SizedBox(height: 16),
                      
                      // Address
                      _buildAddressField(savedAddresses, lang),
                      const SizedBox(height: 16),
                      
                      // Instructions
                      _buildInstructionsField(lang),
                      const SizedBox(height: 16),
                      
                      // Notes
                      _buildNotesField(lang),
                      const SizedBox(height: 16),
                      
                      // Cost estimate
                      _buildCostEstimate(lang),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 420;
                  final buttons = [
                    OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.of(context).pop(),
                      child: Text(AppStrings.getString('cancel', lang)),
                    ),
                    const SizedBox(width: 12, height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(AppStrings.getString('bookNow', lang)),
                    ),
                  ];
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buttons[0],
                        const SizedBox(height: 12),
                        buttons[2],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: buttons[0]),
                      const SizedBox(width: 12),
                      Expanded(child: buttons[2]),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  

  Widget _buildProviderInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.provider.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.provider.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final languageCode = Provider.of<LanguageService>(context, listen: false).currentLanguage;
                    final cityKey = widget.provider.city.toLowerCase();
                    final city = AppStrings.getString(cityKey, languageCode);
                    final years = widget.provider.experienceYears;
                    final yearsLabel = years == 1
                        ? AppStrings.getString('year', languageCode)
                        : AppStrings.getString('years', languageCode);
                    final expLabel = AppStrings.getString('experience', languageCode);
                    return Text(
                      '$city • $years $yearsLabel $expLabel',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                // Hourly rate: only show once per-service data is loaded so it matches the preselected service
                Builder(
                  builder: (context) {
                    final languageCode = Provider.of<LanguageService>(context, listen: false).currentLanguage;
                    if (_providerServices.isEmpty || _selectedServiceId == null) {
                      // Subtle placeholder until service list loads to avoid flashing provider-level rate
                      return const SizedBox(height: 16);
                    }
                    svc.ServiceModel? selected;
                    try {
                      selected = _providerServices.firstWhere((s) => s.id == _selectedServiceId);
                    } catch (_) { selected = _providerServices.first; }
                    double baseRate = (selected.price.amount).toDouble();
                    double displayRate = baseRate;
                    if (_emergency && selected.emergencyEnabled) {
                      displayRate = baseRate * selected.emergencyRateMultiplier;
                    }
                    final rateText = displayRate.toStringAsFixed(0);
                    final per = AppStrings.getString('hourly', languageCode);
                    final isRtl = Directionality.of(context) == TextDirection.rtl;
                    final text = isRtl ? '$per /₪$rateText' : '₪$rateText/$per';
                    return Text(
                      text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('service', lang),
          style: const TextStyle(
      fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
    const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _providerServices.isNotEmpty ? _selectedServiceId : _selectedService,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: () {
            if (_providerServices.isNotEmpty) {
              return _providerServices
                  .map((s) => DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(
                          // Prefer localized subcategory label (matches provider card chips),
                          // then fall back to category label, then title/id.
                          () {
                            final sub = s.subcategory;
                            final fromSub = sub != null && sub.isNotEmpty
                                ? AppStrings.getString(sub, lang)
                                : '';
                            if (fromSub.isNotEmpty) return fromSub;
                            final fromCat = AppStrings.getString(s.category, lang);
                            if (fromCat.isNotEmpty) return fromCat;
                            return s.title.isNotEmpty ? s.title : s.id;
                          }(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList();
            }
            // Fallback to provider.services (string keys)
            return widget.provider.services
                .map((service) => DropdownMenuItem<String>(
                      value: service,
                      child: Text(AppStrings.getString(service, lang), overflow: TextOverflow.ellipsis),
                    ))
                .toList();
          }(),
          onChanged: (value) {
            setState(() {
              if (_providerServices.isNotEmpty) {
                _selectedServiceId = value;
                // Keep a user-friendly selected key for fallback resolution
                try {
                  final svcItem = _providerServices.firstWhere((s) => s.id == value);
                  _selectedService = (svcItem.subcategory != null && svcItem.subcategory!.isNotEmpty)
                      ? svcItem.subcategory
                      : svcItem.title;
                } catch (_) {}
              } else {
                _selectedService = value;
              }
              
              // Reload availability for the newly selected service
              _loadResolved();
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
        return AppStrings.getString('pleaseSelectService', lang);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeSelection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
    AppStrings.getString('dateAndTime', lang),
          style: const TextStyle(
      fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
    const SizedBox(height: 8),
    // Helper text about earliest booking date (UI hint; backend enforces exact rule)
    Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        _emergency
            ? (lang == 'ar' ? 'الطوارئ: يمكن الحجز بعد ساعتين من الآن' : 'Emergency: bookings available 2 hours from now')
            : (lang == 'ar' ? 'الحد الأدنى للحجز: يومين من الآن' : 'Minimum booking time: 2 days from now'),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    ),
    if (_availability != null) Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        'Availability loaded for provider (${_availability!.timezone}). Times outside availability will be rejected.',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
    ),
    Row(
      children: [
        Switch(
          value: _emergency && _supportsEmergency,
          onChanged: _supportsEmergency ? (v) => _toggleEmergency(v) : null,
        ),
        const SizedBox(width: 8),
        Text('Emergency (short notice)', style: TextStyle(color: Colors.grey.shade800)),
        if (!_supportsEmergency) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: 'Not available for this service',
            child: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
          )
        ]
      ],
    ),
    // Calendar with resolved availability (always show calendar)
    Builder(builder: (context) {
      if (_resolved != null) {
        // Show calendar with data
        return Column(children: [
          // Month navigation
          if (_calendarMode == 'month') ...[
            Row(
              children: [
                Builder(builder: (context) {
                  // Compute navigation availability (only current + next month)
                  final base = DateTime(DateTime.now().year, DateTime.now().month, 1);
                  final canPrev = _calendarMonth.isAfter(base);
                  return IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous month',
                    onPressed: canPrev ? () => _changeMonth(-1) : null,
                  );
                }),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_calendarMonth.year}-${_calendarMonth.month.toString().padLeft(2,'0')}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Builder(builder: (context) {
                  final base = DateTime(DateTime.now().year, DateTime.now().month, 1);
                  final limitNext = DateTime(base.year, base.month + 1, 1);
                  final canNext = _calendarMonth.isBefore(limitNext);
                  return IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next month',
                    onPressed: canNext ? () => _changeMonth(1) : null,
                  );
                }),
              ],
            ),
            _CalendarSection(
              month: _calendarMonth,
              resolved: _resolved!,
          onSelect: (date, slot) {
                setState(() {
                  _selectedDate = date;
            final dateKey = _dateKey(date);
            final key = '${slot.start}-${slot.end}';
            final set = _selectedByDate.putIfAbsent(dateKey, () => <String>{});
            if (set.contains(key)) {
              set.remove(key);
            } else {
              set.add(key);
            }
            _startTime = _parseHHmm(slot.start);
            _endTime = _parseHHmm(slot.end);
                });
              },
              onOpenDay: (date) => _openDayView(date),
            ),
            const SizedBox(height: 8),
      _Legend(),
            const SizedBox(height: 6),
            Builder(builder: (context) {
              final dateKey = _selectedDate != null ? _dateKey(_selectedDate!) : null;
              final count = dateKey != null ? (_selectedByDate[dateKey]?.length ?? 0) : 0;
              final hasSelection = count > 0 && _startTime != null && _endTime != null;
              return Text(
                hasSelection
                    ? 'Selected ($count): ${_formatDate(_selectedDate!)} • ${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}'
                    : 'Select a day to view available times',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
              );
            }),
          ] else ...[
            _DaySlotList(
              date: _dayViewDate ?? DateTime.now(),
              resolved: _resolved!,
              selectedKeys: _selectedByDate[_dateKey(_dayViewDate ?? DateTime.now())] ?? const <String>{},
              onToggle: (slot) {
                final d = _dayViewDate ?? DateTime.now();
                setState(() {
                  _selectedDate = d;
                  final key = _dateKey(d);
                  final m = _selectedByDate.putIfAbsent(key, () => <String>{});
                  final slotKey = '${slot.start}-${slot.end}';
                  if (m.contains(slotKey)) {
                    m.remove(slotKey);
                  } else {
                    m.add(slotKey);
                  }
                  // Update focused start/end to this single slot
                  _startTime = _parseHHmm(slot.start);
                  _endTime = _parseHHmm(slot.end);
                });
              },
              onBack: _backToMonth,
            ),
          ],
        ]);
      } else {
        // Show loading state
        return Container(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  lang == 'ar' ? 'جاري تحميل الأوقات المتاحة...' : 'Loading available times...',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        );
      }
    }),
      ],
    );
  }

  TimeOfDay _parseHHmm(String s) {
    final parts = s.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  // Helpers to compute previous/next slot string key using step minutes from resolved
  // (no-op)

  // Removed unused helpers related to chain selection.

  String _formatAddress(Map<String, dynamic> a, String lang) {
    final parts = <String>[];
    final city = (a['city'] ?? '').toString();
    final street = (a['street'] ?? '').toString();
    final area = (a['area'] ?? '').toString();
    if (street.isNotEmpty) parts.add(AppStrings.getString(street, lang));
    if (area.isNotEmpty) parts.add(area);
    if (city.isNotEmpty) parts.add(AppStrings.getString(city, lang));
    return parts.join(', ');
  }

  Widget _buildAddressField(List<Map<String, dynamic>> savedAddresses, String lang) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    final isProvider = user?['role'] == 'provider';
    final useGpsLocation = user?['useGpsLocation'] ?? false;
    
    // For providers, GPS is always mandatory, so always show GPS address
    // For clients/admins, only show GPS address if GPS toggle is enabled
    final shouldShowGpsAddress = isProvider || useGpsLocation;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('serviceAddress', lang),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // GPS Address option (if GPS is enabled or user is provider)
        if (shouldShowGpsAddress) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green.shade300),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.green.shade50,
            ),
            child: RadioListTile<String>(
              value: 'gps',
              groupValue: _selectedAddressId,
              onChanged: (v) async {
                setState(() {
                  _selectedAddressId = v;
                });
                
                // Get GPS address from user's profile instead of generating new one
                final auth = Provider.of<AuthService>(context, listen: false);
                final user = auth.currentUser;
                String gpsAddress = '';
                
                if (user != null) {
                  // Try to get GPS address from user's profile
                  if (user['address'] is String && user['address'].isNotEmpty) {
                    gpsAddress = user['address'];
                  } else if (user['address'] is Map) {
                    final addressMap = user['address'] as Map;
                    final line1 = addressMap['line1'] ?? '';
                    final city = addressMap['city'] ?? '';
                    final street = addressMap['street'] ?? '';
                    if (line1.isNotEmpty) {
                      gpsAddress = line1;
                    } else if (street.isNotEmpty && city.isNotEmpty) {
                      gpsAddress = '$street, $city';
                    }
                  }
                }
                
                // If no GPS address found in profile, generate one as fallback
                if (gpsAddress.isEmpty) {
                  final locationService = LocationService();
                  final userLoc = await locationService.simulateGpsForAddress();
                  final coupled = await locationService.coupleAddressFromGps(userLoc.position);
                  final city = (coupled.city ?? '').toString();
                  final street = (coupled.street ?? '').toString();
                  gpsAddress = [street, city].where((e) => e.isNotEmpty).join(', ');
                }
                
                setState(() {
                  _addressController.text = gpsAddress;
                });
              },
              title: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.getString('gpsLocation', lang),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppStrings.getString('live', lang),
                      style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                lang == 'ar' ? 'العنوان المستمد من نظام تحديد المواقع العالمي' : 'Address derived from GPS location',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
          ),
        ],
        
        // Saved addresses
        if (savedAddresses.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...savedAddresses.asMap().entries.map((entry) {
                final idx = entry.key;
                final a = entry.value;
                final id = idx.toString();
                final isDefault = a['isDefault'] == true;
                final labelKey = (a['type'] ?? 'home').toString();
                final label = AppStrings.getString(labelKey, lang);
                final subtitle = _formatAddress(a, lang);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.white,
                  ),
                  child: RadioListTile<String>(
                    value: id,
                    groupValue: _selectedAddressId,
                    onChanged: (v) {
                      setState(() {
                        _selectedAddressId = v;
                        _addressController.text = subtitle;
                      });
                    },
                    title: Row(
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(AppStrings.getString('defaultText', lang), style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        // Only show text field if no address is selected (GPS or saved address)
        if (_selectedAddressId == null || _addressController.text.isEmpty)
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              hintText: AppStrings.getString('enterYourAddress', lang),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.getString('pleaseEnterAddress', lang);
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildInstructionsField(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('specialInstructions', lang),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _instructionsController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.getString('specialInstructionsHelp', lang),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildNotesField(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('additionalNotesOptional', lang),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: AppStrings.getString('additionalNotesHint', lang),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCostEstimate(String lang) {
    final estimatedCost = _calculateEstimatedCost();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.getString('estimatedCost', lang),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '₪${estimatedCost.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

}

// Helper to format DateTime as yyyy-MM-dd
String _dateKey(DateTime d) {
  return '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}

// --- Inline calendar and slot list for resolved availability ---
class _CalendarSection extends StatelessWidget {
  final DateTime month;
  final AvailabilityResolved resolved;
  final void Function(DateTime date, AvailabilitySlot slot) onSelect;
  final void Function(DateTime date)? onOpenDay; // open day timeline
  const _CalendarSection({required this.month, required this.resolved, required this.onSelect, this.onOpenDay});

  @override
  Widget build(BuildContext context) {
    final byDate = {for (final d in resolved.days) d.date: d};
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);

    List<Widget> rows = [];
    // Week header
    rows.add(Row(
      children: const ['S','M','T','W','T','F','S']
          .map((l) => Expanded(child: Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)))))
          .toList(),
    ));
    rows.add(const SizedBox(height: 8));

    DateTime cursor = first;
    int lead = cursor.weekday % 7; // 0=Sun
    List<Widget> current = [];
    for (int i=0; i<lead; i++) {
      current.add(const Expanded(child: SizedBox(height: 40)));
    }

    while (!cursor.isAfter(last)) {
      final dayDate = DateTime(cursor.year, cursor.month, cursor.day);
      final key = _dateKey(dayDate);
      final day = byDate[key];
      final availCount = day?.slots.length ?? 0;
      final bookedCount = day?.booked.length ?? 0; // includes pending + confirmed
      final hasAny = (availCount + bookedCount) > 0;
      
      // Debug logging to see what data we're getting from the database
      if (kDebugMode && (availCount > 0 || bookedCount > 0)) {
        print('📅 Date: $key - Available: $availCount, Booked: $bookedCount');
        if (day?.booked.isNotEmpty == true) {
          for (var booking in day!.booked) {
            print('  📋 Booking: ${booking.start}-${booking.end} Status: ${booking.status}');
          }
        }
      }
      
      // Determine the primary color and background based on availability status
      Color primaryColor;
      Color backgroundColor;
      Color borderColor;
      
      if (availCount > 0) {
        // Has available slots - Green background
        primaryColor = Colors.green.shade600;
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green.shade600;
      } else if (bookedCount > 0) {
        // Only booked slots - Red background
        primaryColor = Colors.red.shade600;
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red.shade600;
      } else {
        // Not available - Grey
        primaryColor = Colors.grey.shade400;
        backgroundColor = Colors.grey.shade200;
        borderColor = Colors.grey.shade400;
      }
      
      current.add(Expanded(
        child: GestureDetector(
          onTap: !hasAny ? null : () async {
            // Prefer open day view if provided; else show sheet of slots
            if (onOpenDay != null) {
              onOpenDay!(dayDate);
            } else {
              final slot = await _pickSlot(context, dayDate, day!.slots);
              if (slot != null) onSelect(dayDate, slot);
            }
          },
          child: Container(
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Stack(children: [
              Align(alignment: Alignment.center, child: Text('${dayDate.day}')),
              // Show available count in green (top-right)
              if (availCount > 0)
                Positioned(right: 4, top: 4, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(10)),
                  child: Text('$availCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                )),
              // Show booked count in red (bottom-right)
              if (bookedCount > 0)
                Positioned(right: 4, bottom: 4, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(10)),
                  child: Text('$bookedCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                )),
            ]),
          ),
        ),
      ));
      if (current.length == 7) {
        rows.add(Row(children: current));
        current = [];
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    if (current.isNotEmpty) {
      while (current.length < 7) { current.add(const Expanded(child: SizedBox(height: 40))); }
      rows.add(Row(children: current));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ...rows,
    ]);
  }

  Future<AvailabilitySlot?> _pickSlot(BuildContext context, DateTime date, List<AvailabilitySlot> slots) async {
    return await showModalBottomSheet<AvailabilitySlot>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('Available on ${date.day}/${date.month}/${date.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: slots.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final s = slots[i];
                    return ListTile(
                      title: Text('${s.start} - ${s.end}'),
                      onTap: () => Navigator.of(context).pop(s),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}


// Simple color legend for slot states
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label) => Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
      const SizedBox(width: 12),
    ]);
    return Row(children: [
  item(Colors.green.shade600, 'Available'),
  item(Colors.orange.shade600, 'Pending'),
  item(Colors.red.shade600, 'Booked'),
  item(Colors.orange.shade300, 'Selected'),
  item(Colors.grey.shade400, 'Not available'),
    ]);
  }
}

// Day slot list: shows only selected day's slots with multi-select toggle
class _DaySlotList extends StatelessWidget {
  final DateTime date;
  final AvailabilityResolved resolved;
  final Set<String> selectedKeys;
  final void Function(AvailabilitySlot slot) onToggle;
  final VoidCallback onBack;
  const _DaySlotList({required this.date, required this.resolved, required this.selectedKeys, required this.onToggle, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final key = _dateKey(date);
    final day = {for (final d in resolved.days) d.date: d}[key];
    final slots = day?.slots ?? const <AvailabilitySlot>[];
    final booked = day?.booked ?? const <AvailabilitySlot>[];

    String k(AvailabilitySlot s) => '${s.start}-${s.end}';
    final byAvail = { for (final s in slots) k(s): s };
    final byBooked = { for (final s in booked) k(s): s };
    final allKeys = <String>{...byAvail.keys, ...byBooked.keys}.toList()
      ..sort((a,b)=>a.compareTo(b));

  bool isSelected(AvailabilitySlot s) => selectedKeys.contains('${s.start}-${s.end}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left)),
          Expanded(child: Center(child: Text('Select time on ${date.day}/${date.month}/${date.year}', style: const TextStyle(fontWeight: FontWeight.w600)))),
          const SizedBox(width: 40),
        ]),
        const SizedBox(height: 8),
        if (allKeys.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('No available slots on this day', style: TextStyle(color: Colors.grey.shade700)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in allKeys)
                Builder(builder: (context) {
                  final s = byAvail[key] ?? byBooked[key]!;
                  final sel = isSelected(s);
                  final idx = booked.indexWhere((x) => k(x) == key);
                  final bookedState = idx >= 0;
                  final status = bookedState ? booked[idx].status : null;
                  final pending = status == 'pending';
                  final confirmed = status == 'confirmed';
      final bg = confirmed
                      ? Colors.red.shade600
                      : pending
                          ? Colors.orange.shade600
        : (sel ? Colors.orange.shade300 : Colors.green.shade600);
                  final enabled = !bookedState;
                  return InkWell(
                    onTap: enabled ? () => onToggle(s) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
                      child: Text('${s.start}-${s.end}', style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }),
            ],
          ),
      ],
    );
  }
}

// (Old day timeline removed in favor of focused slot list)
