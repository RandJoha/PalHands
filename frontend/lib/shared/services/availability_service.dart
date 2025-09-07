import 'base_api_service.dart';
import '../../core/constants/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimeWindow {
  final String start;
  final String end;
  TimeWindow({required this.start, required this.end});
  factory TimeWindow.fromJson(Map<String, dynamic> json) => TimeWindow(
    start: json['start'] ?? '',
    end: json['end'] ?? '',
  );
}

class AvailabilityModel {
  final String timezone;
  final Map<String, List<TimeWindow>> weekly;
  final Map<String, List<TimeWindow>> exceptions;
  final Map<String, List<TimeWindow>> emergencyWeekly;
  final Map<String, List<TimeWindow>> emergencyExceptions;

  AvailabilityModel({required this.timezone, required this.weekly, required this.exceptions, required this.emergencyWeekly, required this.emergencyExceptions});

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    final weekly = <String, List<TimeWindow>>{};
    final w = (json['weekly'] as Map<String, dynamic>? ) ?? {};
    for (final entry in w.entries) {
      final list = (entry.value as List? )?.map((e) => TimeWindow.fromJson(Map<String, dynamic>.from(e))).toList() ?? <TimeWindow>[];
      weekly[entry.key] = list;
    }
    final exceptions = <String, List<TimeWindow>>{};
    final ex = (json['exceptions'] as List? ) ?? [];
    for (final e in ex) {
      final m = Map<String, dynamic>.from(e as Map);
      final date = (m['date'] ?? '').toString();
      final list = (m['windows'] as List? )?.map((x) => TimeWindow.fromJson(Map<String, dynamic>.from(x))).toList() ?? <TimeWindow>[];
      exceptions[date] = list;
    }
    final emergencyWeekly = <String, List<TimeWindow>>{};
    final ew = (json['emergencyWeekly'] as Map<String, dynamic>? ) ?? {};
    for (final entry in ew.entries) {
      final list = (entry.value as List? )?.map((e) => TimeWindow.fromJson(Map<String, dynamic>.from(e))).toList() ?? <TimeWindow>[];
      emergencyWeekly[entry.key] = list;
    }
    final emergencyExceptions = <String, List<TimeWindow>>{};
    final eex = (json['emergencyExceptions'] as List? ) ?? [];
    for (final e in eex) {
      final m = Map<String, dynamic>.from(e as Map);
      final date = (m['date'] ?? '').toString();
      final list = (m['windows'] as List? )?.map((x) => TimeWindow.fromJson(Map<String, dynamic>.from(x))).toList() ?? <TimeWindow>[];
      emergencyExceptions[date] = list;
    }
    return AvailabilityModel(
      timezone: (json['timezone'] ?? 'Asia/Jerusalem').toString(),
      weekly: weekly,
      exceptions: exceptions,
      emergencyWeekly: emergencyWeekly,
      emergencyExceptions: emergencyExceptions,
    );
  }
}

class AvailabilityService with BaseApiService {
  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        return {
          'Authorization': 'Bearer $token',
          ...ApiConfig.defaultHeaders,
        };
      }
    } catch (_) {}
    return ApiConfig.defaultHeaders;
  }
  Future<AvailabilityModel?> getAvailability(String providerId) async {
    try {
      final data = await get(
        '${ApiConfig.availabilityEndpoint}/$providerId',
        headers: await _getAuthHeaders(),
      );
      final a = (data['data'] ?? data);
      if (a == null || (a is Map && a.isEmpty)) return null;
      return AvailabilityModel.fromJson(Map<String, dynamic>.from(a));
    } catch (e) {
      // Non-fatal; fallback to null
      return null;
    }
  }

  Future<AvailabilityResolved?> getResolvedAvailability(
    String providerId, {
    DateTime? from,
    DateTime? to,
  int stepMinutes = 60,
  bool emergency = false,
  String? serviceId,
  }) async {
    try {
      final params = <String, String>{
        'step': stepMinutes.toString(),
      };
  if (emergency) params['emergency'] = 'true';
      if (serviceId != null && serviceId.isNotEmpty) params['serviceId'] = serviceId;
      if (from != null) params['from'] = _dateKey(from);
      if (to != null) params['to'] = _dateKey(to);
  // cache-buster to avoid any intermediary/browser caching when provider updates availability
  params['_ts'] = DateTime.now().millisecondsSinceEpoch.toString();
      final qp = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      
      final data = await get(
        '${ApiConfig.availabilityEndpoint}/$providerId/resolve${qp.isNotEmpty ? '?$qp' : ''}',
        headers: await _getAuthHeaders(),
      );
      
      final body = data['data'] ?? data;
      return AvailabilityResolved.fromJson(Map<String, dynamic>.from(body));
    } catch (e) {
      return null;
    }
  }

  Future<bool> upsertAvailability(
    String providerId, {
    required String timezone,
    required Map<String, List<TimeWindow>> weekly,
    List<Map<String, dynamic>> exceptions = const [],
  Map<String, List<TimeWindow>> emergencyWeekly = const {},
  List<Map<String, dynamic>> emergencyExceptions = const [],
  }) async {
    try {
      final body = <String, dynamic>{
        'timezone': timezone,
    'weekly': weekly.map((k, v) => MapEntry(k, v.map((w) => {'start': w.start, 'end': w.end}).toList())),
    'exceptions': exceptions,
    'emergencyWeekly': emergencyWeekly.map((k, v) => MapEntry(k, v.map((w) => {'start': w.start, 'end': w.end}).toList())),
    'emergencyExceptions': emergencyExceptions,
      };
      await put(
        '${ApiConfig.availabilityEndpoint}/$providerId',
        body: body,
        headers: await _getAuthHeaders(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

// ---- Resolved availability types ----

class AvailabilitySlot {
  final String start; // HH:mm
  final String end;   // HH:mm
  final String? status; // for booked slots: 'pending' | 'confirmed'
  AvailabilitySlot({required this.start, required this.end, this.status});
  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) => AvailabilitySlot(
    start: (json['start'] ?? '').toString(),
    end: (json['end'] ?? '').toString(),
    status: (json['status'] as String?)
  );
}

class AvailabilityDayResolved {
  final String date; // YYYY-MM-DD
  final List<AvailabilitySlot> slots;
  final List<AvailabilitySlot> booked; // booked (unavailable) slots for legend/visuals
  AvailabilityDayResolved({required this.date, required this.slots, required this.booked});
  factory AvailabilityDayResolved.fromJson(Map<String, dynamic> json) => AvailabilityDayResolved(
    date: (json['date'] ?? '').toString(),
    slots: ((json['slots'] as List?) ?? const <dynamic>[]) 
      .map((e) => AvailabilitySlot.fromJson(Map<String, dynamic>.from(e)))
      .toList(),
    booked: ((json['booked'] as List?) ?? const <dynamic>[]) 
      .map((e) => AvailabilitySlot.fromJson(Map<String, dynamic>.from(e)))
      .toList(),
  );
}

class AvailabilityResolved {
  final String timezone;
  final int step;
  final List<AvailabilityDayResolved> days;
  AvailabilityResolved({required this.timezone, required this.step, required this.days});
  factory AvailabilityResolved.fromJson(Map<String, dynamic> json) => AvailabilityResolved(
    timezone: (json['timezone'] ?? 'Asia/Jerusalem').toString(),
    step: (json['step'] as num?)?.toInt() ?? 30,
    days: ((json['days'] as List?) ?? const <dynamic>[]) 
      .map((e) => AvailabilityDayResolved.fromJson(Map<String, dynamic>.from(e)))
      .toList(),
  );
}

String _dateKey(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
