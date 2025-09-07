import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Shared imports
import '../../../../shared/services/language_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/provider_services_service.dart';
import '../../../../shared/services/services_service.dart';
import '../../../../shared/services/availability_service.dart';

// --- Helper types for availability editor ---
class TimeRangePair {
  TimeOfDay? start;
  TimeOfDay? end;
  TimeRangePair(this.start, this.end);
}

class _EmergencyDayEditorRow extends StatelessWidget {
  final String dayKey;
  final ValueNotifier<Map<String, List<TimeRangePair>>> emergencyController;
  final List<TimeRangePair> baselineSlots; // From normal mode, read-only

  const _EmergencyDayEditorRow({
    required this.dayKey,
    required this.emergencyController,
    required this.baselineSlots,
  });

  @override
  Widget build(BuildContext context) {
    String keyOf(TimeRangePair p) => '${_fmt(p.start!)}-${_fmt(p.end!)}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_label(dayKey), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  // Open time range picker for emergency-only additions
                  showDialog<void>(
                    context: context,
                    builder: (context) => _TimeRangePickerDialog(
                      onConfirm: (start, end) {
                        final current = emergencyController.value[dayKey] ?? <TimeRangePair>[];
                        final updated = List<TimeRangePair>.from(current);
                        
                        // Split the range into individual hour slots
                        int currentHour = start.hour;
                        int endHour = end.hour;
                        if (endHour < currentHour) endHour += 24;
                        
                        while (currentHour < endHour) {
                          final slotStart = TimeOfDay(hour: currentHour % 24, minute: 0);
                          final slotEnd = TimeOfDay(hour: (currentHour + 1) % 24, minute: 0);
                          updated.add(TimeRangePair(slotStart, slotEnd));
                          currentHour++;
                        }
                        
                        emergencyController.value = {...emergencyController.value, dayKey: updated};
                        debugPrint('[Emergency] Added ${endHour - start.hour} emergency-only slots for day=$dayKey');
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add emergency slots'),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<int>(
                tooltip: 'Add 1h emergency slot',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.orange),
                      SizedBox(width: 6),
                      Text('Add hour', style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
                itemBuilder: (context) {
                  return List.generate(24, (h) {
                    final start = '${h.toString().padLeft(2,'0')}:00';
                    final end = '${((h+1)%24).toString().padLeft(2,'0')}:00';
                    return PopupMenuItem<int>(value: h, child: Text('$start - $end'));
                  });
                },
                onSelected: (h) {
                  final start = TimeOfDay(hour: h, minute: 0);
                  final end = TimeOfDay(hour: (h+1)%24, minute: 0);
                  final current = emergencyController.value[dayKey] ?? <TimeRangePair>[];
                  final updated = List<TimeRangePair>.from(current);
                  final exists = updated.any((p) => p.start?.hour == start.hour && p.start?.minute == 0 && p.end?.hour == end.hour && p.end?.minute == 0);
                  if (!exists) {
                    updated.add(TimeRangePair(start, end));
                    emergencyController.value = {...emergencyController.value, dayKey: updated};
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<Map<String, List<TimeRangePair>>>(
            valueListenable: emergencyController,
            builder: (context, value, _) {
              final emergencySlots = value[dayKey] ?? <TimeRangePair>[];
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show baseline slots from normal mode (read-only, gray)
                  for (final baselineSlot in baselineSlots) ...[
                    _EmergencyBaselineSlot(
                      pair: baselineSlot,
                      isBaseline: true,
                    ),
                  ],
                  
                  // Show emergency-only additions (green, removable)
                  for (int i = 0; i < emergencySlots.length; i++)
                    if (emergencySlots[i].start != null && emergencySlots[i].end != null) ...[
                      _ServiceRangeRow(
                        pair: emergencySlots[i],
                        onChanged: (p) {
                          final updated = List<TimeRangePair>.from(emergencySlots);
                          updated[i] = p;
                          emergencyController.value = {...emergencyController.value, dayKey: updated};
                        },
                        onRemove: () {
                          final updated = List<TimeRangePair>.from(emergencySlots)..removeAt(i);
                          emergencyController.value = {...emergencyController.value, dayKey: updated};
                        },
                        isGlobalSlot: false, // Emergency additions are service-specific
                        isExcluded: false,
                      ),
                    ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _label(String k) {
    switch (k) {
      case 'monday': return 'Monday';
      case 'tuesday': return 'Tuesday';
      case 'wednesday': return 'Wednesday';
      case 'thursday': return 'Thursday';
      case 'friday': return 'Friday';
      case 'saturday': return 'Saturday';
      case 'sunday': return 'Sunday';
      default: return k;
    }
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
}

class _EmergencyBaselineSlot extends StatelessWidget {
  final TimeRangePair pair;
  final bool isBaseline;

  const _EmergencyBaselineSlot({
    required this.pair,
    required this.isBaseline,
  });

  @override
  Widget build(BuildContext context) {
    final startText = _fmt(pair.start!);
    final endText = _fmt(pair.end!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            '$startText-$endText',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '(from normal)',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
}

class _ServiceDayEditorRow extends StatelessWidget {
  final String dayKey;
  final ValueNotifier<Map<String, List<TimeRangePair>>> controller;
  final ValueNotifier<Map<String, Set<String>>> excludedController; // Track excluded global slots
  final List<TimeRangePair> globalSlots;
  
  const _ServiceDayEditorRow({
    required this.dayKey, 
    required this.controller, 
    required this.excludedController,
    required this.globalSlots,
  });

  @override
  Widget build(BuildContext context) {
    String keyOf(TimeRangePair p) => '${_fmt(p.start!)}-${_fmt(p.end!)}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_label(dayKey), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  // Open time range picker dialog
                  showDialog<void>(
                    context: context,
                    builder: (context) => _TimeRangePickerDialog(
                      onConfirm: (start, end) {
                        final current = controller.value[dayKey] ?? <TimeRangePair>[];
                        final updated = List<TimeRangePair>.from(current);
                        
                        // Split the range into individual hour slots
                        int currentHour = start.hour;
                        int endHour = end.hour;
                        
                        // Handle overnight ranges
                        if (endHour < currentHour) endHour += 24;
                        
                        while (currentHour < endHour) {
                          final slotStart = TimeOfDay(hour: currentHour % 24, minute: 0);
                          final slotEnd = TimeOfDay(hour: (currentHour + 1) % 24, minute: 0);
                          updated.add(TimeRangePair(slotStart, slotEnd));
                          currentHour++;
                        }
                        
                        controller.value = {...controller.value, dayKey: updated};
                        debugPrint('[Availability] Added ${endHour - start.hour} hourly slots for day=$dayKey');
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add service slots'),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<int>(
                tooltip: 'Add 1h service slot',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.green),
                      SizedBox(width: 6),
                      Text('Add hour', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
                itemBuilder: (context) {
                  return List.generate(24, (h) {
                    final start = '${h.toString().padLeft(2,'0')}:00';
                    final end = '${((h+1)%24).toString().padLeft(2,'0')}:00';
                    return PopupMenuItem<int>(value: h, child: Text('$start - $end'));
                  });
                },
                onSelected: (h) {
                  final start = TimeOfDay(hour: h, minute: 0);
                  final end = TimeOfDay(hour: (h+1)%24, minute: 0);
                  final current = controller.value[dayKey] ?? <TimeRangePair>[];
                  final updated = List<TimeRangePair>.from(current);
                  final exists = updated.any((p) => p.start?.hour == start.hour && p.start?.minute == 0 && p.end?.hour == end.hour && p.end?.minute == 0);
                  if (!exists) {
                    updated.add(TimeRangePair(start, end));
                    controller.value = {...controller.value, dayKey: updated};
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<Map<String, Set<String>>>(
            valueListenable: excludedController,
            builder: (context, excludedMap, _) {
              return ValueListenableBuilder<Map<String, List<TimeRangePair>>>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final current = value[dayKey] ?? <TimeRangePair>[];
                  final excludedKeys = excludedMap[dayKey] ?? <String>{};
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show global slots as individual hours (editable)
                      for (final globalSlot in globalSlots) ...[
                        () {
                          final globalKey = keyOf(globalSlot);
                          final isExcluded = excludedKeys.contains(globalKey);
                          // Only show global slots that are NOT excluded (Fix #3: canceled slots disappear)
                          if (!isExcluded) {
                            return _ServiceRangeRow(
                              pair: globalSlot,
                              onChanged: (_) {}, // No direct editing of global slot times
                              onRemove: () {
                                // Toggle exclusion - clicking remove will exclude this slot
                                final currentExcluded = Set<String>.from(excludedKeys);
                                currentExcluded.add(globalKey);
                                excludedController.value = {...excludedController.value, dayKey: currentExcluded};
                              },
                              isGlobalSlot: true, // Always show as blue when visible
                              isExcluded: false, // Never show as red
                            );
                          } else {
                            return const SizedBox.shrink(); // Hidden when excluded
                          }
                        }(),
                      ],
                      // Show service-specific slots (not overlapping with global)
                      for (int i = 0; i < current.length; i++)
                        if (current[i].start != null && current[i].end != null) ...[
                          () {
                            final serviceKey = keyOf(current[i]);
                            final isGlobalSlot = globalSlots.any((g) => keyOf(g) == serviceKey);
                            // Only show if it's not a duplicate of a global slot
                            if (!isGlobalSlot) {
                              return _ServiceRangeRow(
                                pair: current[i],
                                onChanged: (p) {
                                  final updated = List<TimeRangePair>.from(current);
                                  updated[i] = p;
                                  controller.value = {...controller.value, dayKey: updated};
                                },
                                onRemove: () {
                                  final updated = List<TimeRangePair>.from(current)..removeAt(i);
                                  controller.value = {...controller.value, dayKey: updated};
                                },
                                isGlobalSlot: false,
                                isExcluded: false,
                              );
                            } else {
                              return const SizedBox.shrink(); // Skip global duplicates
                            }
                          }(),
                        ],
                      // Show excluded slots with restore option  
                      if (excludedKeys.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        Row(
                          children: [
                            Icon(Icons.visibility_off, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('Previously excluded slots (click to restore):', style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final globalSlot in globalSlots)
                              if (excludedKeys.contains(keyOf(globalSlot)))
                                InkWell(
                                  onTap: () {
                                    // Restore this slot
                                    final currentExcluded = Set<String>.from(excludedKeys);
                                    currentExcluded.remove(keyOf(globalSlot));
                                    excludedController.value = {...excludedController.value, dayKey: currentExcluded};
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.red.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.restore, size: 14, color: Colors.red),
                                        const SizedBox(width: 4),
                                        Text('${_fmt(globalSlot.start!)}-${_fmt(globalSlot.end!)}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }

  String _label(String k) {
    switch (k) {
      case 'monday': return 'Monday';
      case 'tuesday': return 'Tuesday';
      case 'wednesday': return 'Wednesday';
      case 'thursday': return 'Thursday';
      case 'friday': return 'Friday';
      case 'saturday': return 'Saturday';
      case 'sunday': return 'Sunday';
      default: return k;
    }
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
}

class _DayEditorRow extends StatelessWidget {
  final String dayKey;
  final ValueNotifier<Map<String, List<TimeRangePair>>> controller;
  const _DayEditorRow({required this.dayKey, required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = controller.value[dayKey] ?? <TimeRangePair>[];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_label(dayKey), style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  // Open time range picker dialog
                  showDialog<void>(
                    context: context,
                    builder: (context) => _TimeRangePickerDialog(
                      onConfirm: (start, end) {
                        final updated = List<TimeRangePair>.from(items);
                        debugPrint('[Availability] Add slots tapped day=$dayKey, range=${start.hour}:${start.minute.toString().padLeft(2,'0')}-${end.hour}:${end.minute.toString().padLeft(2,'0')}');
                        
                        // Split the range into individual hour slots
                        int currentHour = start.hour;
                        int endHour = end.hour;
                        
                        // Handle overnight ranges
                        if (endHour < currentHour) endHour += 24;
                        
                        while (currentHour < endHour) {
                          final slotStart = TimeOfDay(hour: currentHour % 24, minute: 0);
                          final slotEnd = TimeOfDay(hour: (currentHour + 1) % 24, minute: 0);
                          
                          // Check if this slot already exists
                          final exists = updated.any((p) => 
                            p.start?.hour == slotStart.hour && p.start?.minute == 0 && 
                            p.end?.hour == slotEnd.hour && p.end?.minute == 0
                          );
                          
                          if (!exists) {
                            updated.add(TimeRangePair(slotStart, slotEnd));
                          }
                          currentHour++;
                        }
                        
                        controller.value = {...controller.value, dayKey: updated};
                        debugPrint('[Availability] Added ${endHour - start.hour} hourly slots for day=$dayKey');
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add slots'),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<int>(
                tooltip: 'Add 1h slot',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.black54),
                      SizedBox(width: 6),
                      Text('Add hour', style: TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
                itemBuilder: (context) {
                  return List.generate(24, (h) {
                    final start = '${h.toString().padLeft(2,'0')}:00';
                    final end = '${((h+1)%24).toString().padLeft(2,'0')}:00';
                    return PopupMenuItem<int>(value: h, child: Text('$start - $end'));
                  });
                },
                onSelected: (h) {
                  final start = TimeOfDay(hour: h, minute: 0);
                  final end = TimeOfDay(hour: (h+1)%24, minute: 0);
                  final updated = List<TimeRangePair>.from(items);
                  final exists = updated.any((p) => p.start?.hour == start.hour && p.start?.minute == 0 && p.end?.hour == end.hour && p.end?.minute == 0);
                  if (!exists) {
                    debugPrint('[Availability] Add hour tapped day=$dayKey, slot=${start.hour.toString().padLeft(2,'0')}:00-${end.hour.toString().padLeft(2,'0')}:00, before=${updated.length}');
                    updated.add(TimeRangePair(start, end));
                    controller.value = {...controller.value, dayKey: updated};
                    debugPrint('[Availability] Add hour added day=$dayKey, after=${updated.length}');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder<Map<String, List<TimeRangePair>>>(
            valueListenable: controller,
            builder: (context, value, _) {
              final current = value[dayKey] ?? <TimeRangePair>[];
              return Column(
                children: [
                  for (int i = 0; i < current.length; i++)
                    _RangeRow(
                      pair: current[i],
                      onChanged: (p) {
                        final updated = List<TimeRangePair>.from(current);
                        updated[i] = p;
                        controller.value = {...controller.value, dayKey: updated};
                        debugPrint('[Availability] Updated range day=$dayKey index=$i start=${p.start} end=${p.end}');
                      },
                      onRemove: () {
                        final updated = List<TimeRangePair>.from(current)..removeAt(i);
                        controller.value = {...controller.value, dayKey: updated};
                        debugPrint('[Availability] Removed range day=$dayKey index=$i');
                      },
                    )
                ],
              );
            },
          )
        ],
      ),
    );
  }

  String _label(String k) {
    switch (k) {
      case 'monday': return 'Monday';
      case 'tuesday': return 'Tuesday';
      case 'wednesday': return 'Wednesday';
      case 'thursday': return 'Thursday';
      case 'friday': return 'Friday';
      case 'saturday': return 'Saturday';
      case 'sunday': return 'Sunday';
      default: return k;
    }
  }
}

class _ServiceRangeRow extends StatelessWidget {
  final TimeRangePair pair;
  final ValueChanged<TimeRangePair> onChanged;
  final VoidCallback onRemove;
  final bool isGlobalSlot;
  final bool isExcluded;
  
  const _ServiceRangeRow({
    required this.pair, 
    required this.onChanged, 
    required this.onRemove,
    this.isGlobalSlot = false,
    this.isExcluded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExcluded 
          ? Colors.red.shade50 
          : (isGlobalSlot ? Colors.blue.shade50 : Colors.green.shade50),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isExcluded 
            ? Colors.red.shade300
            : (isGlobalSlot ? Colors.blue.shade200 : Colors.green.shade200),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (isExcluded) ...[
            Icon(Icons.remove_circle, size: 16, color: Colors.red.shade600),
            const SizedBox(width: 8),
          ] else if (isGlobalSlot) ...[
            Icon(Icons.public, size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 8),
          ] else ...[
            Icon(Icons.add_circle_outline, size: 16, color: Colors.green.shade600),
            const SizedBox(width: 8),
          ],
          _TimePickerButton(
            label: 'Start',
            value: pair.start,
            onPicked: (!isGlobalSlot && !isExcluded) ? (t) => onChanged(TimeRangePair(t, pair.end)) : null,
          ),
          const SizedBox(width: 8),
          _TimePickerButton(
            label: 'End',
            value: pair.end,
            onPicked: (!isGlobalSlot && !isExcluded) ? (t) => onChanged(TimeRangePair(pair.start, t)) : null,
          ),
          const SizedBox(width: 8),
          if (isExcluded)
            IconButton(
              onPressed: onRemove, // This will "un-exclude" the global slot
              icon: const Icon(Icons.restore, color: Colors.green),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              tooltip: 'Restore slot',
            )
          else if (isGlobalSlot)
            IconButton(
              onPressed: onRemove, // This will "exclude" the global slot
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              tooltip: 'Exclude slot',
            )
          else
            IconButton(
              onPressed: onRemove, 
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              tooltip: 'Delete slot',
            ),
        ],
      ),
    );
  }
}

class _RangeRow extends StatelessWidget {
  final TimeRangePair pair;
  final ValueChanged<TimeRangePair> onChanged;
  final VoidCallback onRemove;
  const _RangeRow({required this.pair, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TimePickerButton(
          label: 'Start',
          value: pair.start,
          onPicked: (t) => onChanged(TimeRangePair(t, pair.end)),
        ),
        const SizedBox(width: 8),
        _TimePickerButton(
          label: 'End',
          value: pair.end,
          onPicked: (t) => onChanged(TimeRangePair(pair.start, t)),
        ),
        const SizedBox(width: 8),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, color: Colors.redAccent))
      ],
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay>? onPicked;
  const _TimePickerButton({required this.label, required this.value, this.onPicked});

  @override
  Widget build(BuildContext context) {
    final text = value != null ? _fmtLocal(value!) : label;
    final isDisabled = onPicked == null;
    return OutlinedButton(
      onPressed: isDisabled ? null : () async {
        final now = TimeOfDay.now();
        final picked = await showTimePicker(context: context, initialTime: value ?? now);
        if (picked != null) onPicked!(picked);
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: isDisabled ? Colors.grey : null,
        side: BorderSide(color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade400),
      ),
      child: Text(text),
    );
  }

  String _fmtLocal(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
}

class _TimeRangePickerDialog extends StatefulWidget {
  final Function(TimeOfDay start, TimeOfDay end) onConfirm;

  const _TimeRangePickerDialog({required this.onConfirm});

  @override
  _TimeRangePickerDialogState createState() => _TimeRangePickerDialogState();
}

class _TimeRangePickerDialogState extends State<_TimeRangePickerDialog> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Time Range', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Choose start and end times. The range will be split into individual hourly slots.',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('Start Time', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context, 
                          initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0)
                        );
                        if (picked != null) {
                          setState(() => startTime = picked);
                        }
                      },
                      child: Text(
                        startTime?.format(context) ?? 'Select',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Text('End Time', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context, 
                          initialTime: endTime ?? const TimeOfDay(hour: 17, minute: 0)
                        );
                        if (picked != null) {
                          setState(() => endTime = picked);
                        }
                      },
                      child: Text(
                        endTime?.format(context) ?? 'Select',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (startTime != null && endTime != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                'This will create ${_calculateSlotCount()} individual hour slots',
                style: GoogleFonts.cairo(fontSize: 12, color: Colors.blue.shade700),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.cairo()),
        ),
        FilledButton(
          onPressed: (startTime != null && endTime != null) ? () {
            widget.onConfirm(startTime!, endTime!);
            Navigator.of(context).pop();
          } : null,
          child: Text('Add Slots', style: GoogleFonts.cairo()),
        ),
      ],
    );
  }

  int _calculateSlotCount() {
    if (startTime == null || endTime == null) return 0;
    
    int start = startTime!.hour;
    int end = endTime!.hour;
    
    if (end < start) end += 24; // Handle overnight
    
    return end - start;
  }
}

class MyServicesWidget extends StatefulWidget {
  const MyServicesWidget({super.key});

  @override
  State<MyServicesWidget> createState() => _MyServicesWidgetState();
}

class _MyServicesWidgetState extends State<MyServicesWidget> {
  bool _isMultiEditMode = false;
  final Set<int> _selectedServices = {};
  bool _showEmergencyOnly = false;
  List<ProviderServiceItem> _items = const [];
  bool _loading = true;
  AvailabilityModel? _availability;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final providerId = auth.userId;
    if (providerId == null) {
      setState(() {
        _items = const [];
        _loading = false;
      });
      return;
    }
    final api = ProviderServicesApi();
    final list = await api.list(providerId, authService: auth);
    final avail = await AvailabilityService().getAvailability(providerId);
    if (!mounted) return;
    setState(() {
      _items = list;
      _availability = avail;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            // Responsive breakpoints
            final isDesktop = screenWidth > 1200;
            final isTablet = screenWidth > 768 && screenWidth <= 1200;
            final isMobile = screenWidth <= 768;

            return _buildMyServicesWidget(
              languageService,
              isMobile,
              isTablet,
              isDesktop,
            );
          },
        );
      },
    );
  }

  Widget _buildMyServicesWidget(
    LanguageService languageService,
    bool isMobile,
    bool isTablet,
  bool isDesktop,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 8.0 : (isTablet ? 12.0 : 16.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedServices.length} ${AppStrings.getString('selected', languageService.currentLanguage)}',
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 12.0 : (isTablet ? 13.0 : 14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              // Multi-edit toggle
              Row(
                children: [
                  Switch(
                    value: _isMultiEditMode,
                    onChanged: (v) => setState(() => _isMultiEditMode = v),
                  ),
                  Text(
                    AppStrings.getString('multiSelect', languageService.currentLanguage),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(width: isMobile ? 8 : 12),
              // Emergency only filter
              Row(
                children: [
                  Switch(
                    value: _showEmergencyOnly,
                    onChanged: (v) => setState(() => _showEmergencyOnly = v),
                  ),
                  Text(
                    AppStrings.getString('emergencyOnly', languageService.currentLanguage),
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(width: isMobile ? 8 : 12),
              // Add service button
              FilledButton.icon(
                onPressed: () => _openAddServiceDialog(languageService),
                icon: const Icon(Icons.add),
                label: Text(AppStrings.getString('addService', languageService.currentLanguage)),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          _buildAvailabilityEditor(languageService, isMobile, isTablet),
          SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),

          // Bulk actions (visible only in multi-edit)
          if (_isMultiEditMode)
            Row(
              children: [
                _buildBulkActionButton(
                  icon: Icons.play_arrow,
                  label: AppStrings.getString('activate', languageService.currentLanguage),
                  onTap: _activateSelectedServices,
                  languageService: languageService,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
                SizedBox(width: isMobile ? 6.0 : (isTablet ? 7.0 : 8.0)),
                _buildBulkActionButton(
                  icon: Icons.pause,
                  label: AppStrings.getString('deactivate', languageService.currentLanguage),
                  onTap: _deactivateSelectedServices,
                  languageService: languageService,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                ),
                SizedBox(width: isMobile ? 6.0 : (isTablet ? 7.0 : 8.0)),
                _buildBulkActionButton(
                  icon: Icons.delete,
                  label: AppStrings.getString('delete', languageService.currentLanguage),
                  onTap: _deleteSelectedServices,
                  languageService: languageService,
                  isMobile: isMobile,
                  isTablet: isTablet,
                  isDesktop: isDesktop,
                  isDestructive: true,
                ),
              ],
            ),

          SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),

          // Grid of services
          _buildServicesGrid(languageService, isMobile, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildAvailabilityEditor(LanguageService lang, bool isMobile, bool isTablet) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final providerId = auth.userId;
    final tz = _availability?.timezone ?? 'Asia/Jerusalem';
    const days = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
  final controller = ValueNotifier<Map<String, List<TimeRangePair>>>(_mapToRanges(_availability));

    Future<void> onSave() async {
      if (providerId == null) return;
      final weekly = <String, List<TimeWindow>>{};
      final value = controller.value;
      for (final d in days) {
        final ranges = value[d] ?? [];
        weekly[d] = ranges.where((r) => r.start != null && r.end != null)
          .map((r) => TimeWindow(start: _fmt(r.start!), end: _fmt(r.end!))).toList();
      }
      final ok = await AvailabilityService().upsertAvailability(providerId, timezone: tz, weekly: weekly);
      if (ok && mounted) {
        // Refresh local state and resolved availability cache via booking dialog later
        final fresh = await AvailabilityService().getAvailability(providerId);
        setState(() { _availability = fresh; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.getString('saved', lang.currentLanguage))));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.getString('saveFailed', lang.currentLanguage))));
      }
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : (isTablet ? 10 : 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.black54),
              const SizedBox(width: 8),
              Text(AppStrings.getString('myAvailability', lang.currentLanguage), style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.save), label: Text(AppStrings.getString('save', lang.currentLanguage)))
            ],
          ),
          const SizedBox(height: 8),
          for (final d in days)
            _DayEditorRow(dayKey: d, controller: controller),
        ],
      ),
    );
  }

  Map<String, List<TimeRangePair>> _mapToRanges(AvailabilityModel? a) {
    final res = <String, List<TimeRangePair>>{};
    if (a == null) {
      for (final d in const ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']) {
        res[d] = [];
      }
      return res;
    }
    a.weekly.forEach((k, list) {
      res[k] = list.map((w) => TimeRangePair(_parse(w.start), _parse(w.end))).toList();
    });
    return res;
  }

  String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  TimeOfDay _parse(String s) {
    final parts = s.split(':');
    final h = int.tryParse(parts[0]) ?? 0; final m = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Widget _buildBulkActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required LanguageService languageService,
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDestructive ? AppColors.error : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0), 
              vertical: isMobile ? 6.0 : (isTablet ? 7.0 : 8.0)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: isMobile ? 14 : (isTablet ? 15 : 16),
                  color: AppColors.white,
                ),
                SizedBox(width: isMobile ? 3.0 : (isTablet ? 3.5 : 4.0)),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid(
    LanguageService languageService,
    bool isMobile,
    bool isTablet,
  bool isDesktop,
  ) {
    // Responsive grid configuration
    int crossAxisCount;
    double childAspectRatio;
    double crossAxisSpacing;
    double mainAxisSpacing;

    if (isMobile) {
      crossAxisCount = 1;
      childAspectRatio = 2.6;
      crossAxisSpacing = 0.0;
      mainAxisSpacing = 12.0;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 2.1;
      crossAxisSpacing = 12.0;
      mainAxisSpacing = 12.0;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 1.8;
      crossAxisSpacing = 16.0;
      mainAxisSpacing = 16.0;
    }

    final list = _showEmergencyOnly
        ? _items.where((s) => s.emergencyEnabled).toList()
        : _items;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(
          list[index],
          index,
          languageService,
          isMobile,
          isTablet,
          isDesktop,
        );
      },
    );
  }

  Widget _buildServiceCard(
    ProviderServiceItem item,
    int index,
    LanguageService languageService,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    final isSelected = _selectedServices.contains(index);
    final isActive = item.status == 'active';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (_isMultiEditMode) {
              setState(() {
                if (isSelected) {
                  _selectedServices.remove(index);
                } else {
                  _selectedServices.add(index);
                }
              });
            } else {
              _openEditDialog(item, languageService);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 10.0 : (isTablet ? 12.0 : 14.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with checkbox and status
                Row(
                  children: [
                    if (_isMultiEditMode) ...[
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedServices.add(index);
                            } else {
                              _selectedServices.remove(index);
                            }
                          });
                        },
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)),
                    ],
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0),
                          vertical: isMobile ? 3.0 : (isTablet ? 4.0 : 6.0),
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isMobile ? 4 : (isTablet ? 6 : 8),
                              height: isMobile ? 4 : (isTablet ? 6 : 8),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.success : AppColors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: isMobile ? 3.0 : (isTablet ? 4.0 : 6.0)),
                            Flexible(
                              child: Text(
                                isActive
                                    ? AppStrings.getString('active', languageService.currentLanguage)
                                    : AppStrings.getString('inactive', languageService.currentLanguage),
                                style: GoogleFonts.cairo(
                                  fontSize: isMobile ? 9.0 : (isTablet ? 10.0 : 11.0),
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? AppColors.success : AppColors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),

                // Service icon and name
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.work,
                        size: isMobile ? 16 : (isTablet ? 18 : 20),
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.serviceTitle.isNotEmpty
                                ? item.serviceTitle
                                : AppStrings.getString('service', languageService.currentLanguage),
                            style: GoogleFonts.cairo(
                              fontSize: isMobile ? 14.0 : (isTablet ? 16.0 : 18.0),
                              fontWeight: FontWeight.bold,
                              color: AppColors.greyDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),

                // Price and stats
                Row(
                  children: [
                    // Price chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0),
                        vertical: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.hourlyRate > 0
                            ? '₪${item.hourlyRate.toStringAsFixed(0)}/hour'
                            : AppStrings.getString('setPrice', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: isMobile ? 12.0 : (isTablet ? 14.0 : 16.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              item.publishable ? Icons.verified : Icons.pending,
                              size: isMobile ? 12 : (isTablet ? 14 : 16),
                              color: item.publishable ? AppColors.success : AppColors.warning,
                            ),
                            SizedBox(width: isMobile ? 2.0 : (isTablet ? 3.0 : 4.0)),
                            Text(
                              item.publishable
                                  ? AppStrings.getString('ready', languageService.currentLanguage)
                                  : AppStrings.getString('incomplete', languageService.currentLanguage),
                              style: GoogleFonts.cairo(
                                fontSize: isMobile ? 11.0 : (isTablet ? 12.0 : 14.0),
                                fontWeight: FontWeight.bold,
                                color: AppColors.greyDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 1.0 : (isTablet ? 2.0 : 3.0)),
                        Text(
                          item.emergencyEnabled
                              ? AppStrings.getString('emergencyEnabled', languageService.currentLanguage)
                              : AppStrings.getString('normalOnly', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: isMobile ? 9.0 : (isTablet ? 10.0 : 11.0),
                            color: AppColors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0)),

                // Per-card actions
                Row(
                  children: [
                    _buildChipButton(
                      icon: Icons.tune,
                      label: AppStrings.getString('edit', languageService.currentLanguage),
                      color: AppColors.primary,
                      onTap: () => _openEditDialog(item, languageService),
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                    SizedBox(width: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                    _buildChipButton(
                      icon: Icons.schedule,
                      label: AppStrings.getString('availability', languageService.currentLanguage),
                      color: AppColors.primary,
                      onTap: () => _openServiceAvailabilityDialog(item, languageService),
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                    SizedBox(width: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                    if (item.status == 'active')
                      _buildChipButton(
                        icon: Icons.pause,
                        label: AppStrings.getString('deactivate', languageService.currentLanguage),
                        color: AppColors.warning,
                        onTap: () => _singleAction(item, (api, pid, id, auth) => api.deactivateMonth(pid, id, authService: auth)),
                        isMobile: isMobile,
                        isTablet: isTablet,
                      )
                    else
                      _buildChipButton(
                        icon: Icons.play_arrow,
                        label: AppStrings.getString('activate', languageService.currentLanguage),
                        color: AppColors.success,
                        onTap: () => _singleAction(item, (api, pid, id, auth) => api.activateMonth(pid, id, authService: auth)),
                        isMobile: isMobile,
                        isTablet: isTablet,
                      ),
                    SizedBox(width: isMobile ? 6.0 : (isTablet ? 8.0 : 10.0)),
                    _buildChipButton(
                      icon: Icons.delete,
                      label: AppStrings.getString('delete', languageService.currentLanguage),
                      color: AppColors.error,
                      onTap: () => _singleAction(item, (api, pid, id, auth) => api.remove(pid, id, authService: auth)),
                      isMobile: isMobile,
                      isTablet: isTablet,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Emergency toggle is controlled via Edit modal only.

  void _activateSelectedServices() {
    _bulkAction((api, providerId, id, auth) => api.activateMonth(providerId, id, authService: auth));
  }

  Future<void> _openServiceAvailabilityDialog(ProviderServiceItem item, LanguageService lang) async {
  // Whether service currently has overrides isn't needed for UI now; inheritance is decided at save time
    const days = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];

    Map<String, List<TimeRangePair>> toPairs(Map<String, List<Map<String, String>>> weekly) {
      final out = <String, List<TimeRangePair>>{};
      for (final d in days) {
        final list = weekly[d] ?? const <Map<String, String>>[];
        out[d] = list.map((w) => TimeRangePair(_parse(w['start'] ?? '00:00'), _parse(w['end'] ?? '00:00'))).toList();
      }
      return out;
    }
    // Build effective NORMAL schedule for display: always show global base + service-specific additions
    final basePairs = _mapToRanges(_availability);
    final serviceCompletePairs = toPairs(item.weeklyOverrides);
    
    // Calculate initial exclusions and service additions based on saved data
    final initialExclusions = <String, Set<String>>{};
    final serviceAdditions = <String, List<TimeRangePair>>{};
    String keyOf(TimeRangePair p) => '${_fmt(p.start!)}-${_fmt(p.end!)}';
    
    // Check if service has any overrides at all. Important: presence of the
    // weeklyOverrides object itself indicates an override, even if all day
    // arrays are empty (meaning: explicitly inherit nothing / exclude all).
    // Backend distinguishes null/undefined (inherit) vs object (override).
    final hasAnyOverrides = item.weeklyOverrides.isNotEmpty;
    
    if (hasAnyOverrides) {
      // Service has saved overrides - need to distinguish between:
      // 1. Previously excluded global slots (should appear excluded)  
      // 2. Newly added global slots (should appear active by default)
      
      for (final d in days) {
        final globalSlots = basePairs[d] ?? <TimeRangePair>[];
        final serviceCompleteSlots = serviceCompletePairs[d] ?? <TimeRangePair>[];
        
        final globalKeys = globalSlots.map(keyOf).toSet();
        final serviceKeys = serviceCompleteSlots.map(keyOf).toSet();
        
        // EXCLUSIONS: Global slots that are NOT in the service's saved schedule
        // These represent previously excluded slots that should stay excluded
        final excludedKeys = globalKeys.difference(serviceKeys);
        if (excludedKeys.isNotEmpty) {
          initialExclusions[d] = excludedKeys;
        }
        
        // ADDITIONS: Service slots that are NOT in global slots (service-specific additions)  
        final additionKeys = serviceKeys.difference(globalKeys);
        if (additionKeys.isNotEmpty) {
          serviceAdditions[d] = serviceCompleteSlots.where((slot) {
            final key = keyOf(slot);
            return additionKeys.contains(key);
          }).toList();
        }
      }
    }
    // If no overrides: service inherits everything from global as active (blue)
    // All new global slots will appear as active for all services by default
    
    final normalController = ValueNotifier<Map<String, List<TimeRangePair>>>(serviceAdditions);
    final excludedController = ValueNotifier<Map<String, Set<String>>>(initialExclusions);
    
    // Debug logging
    debugPrint('[ServiceAvailability] Opening dialog for service ${item.id}:');
    debugPrint('  - Global slots: ${basePairs.map((k, v) => MapEntry(k, v.map((p) => keyOf(p)).toList()))}');
    debugPrint('  - Service complete: ${serviceCompletePairs.map((k, v) => MapEntry(k, v.map((p) => keyOf(p)).toList()))}');
    debugPrint('  - Initial exclusions (previously excluded): $initialExclusions');
    debugPrint('  - Service additions: ${serviceAdditions.map((k, v) => MapEntry(k, v.map((p) => keyOf(p)).toList()))}');
    
    // Calculate the service's CURRENT effective normal schedule for emergency baseline
    // This should match exactly what appears in the normal tab: (Global - Exclusions) + Service Additions
    final serviceEffectiveSchedule = <String, List<TimeRangePair>>{};
    
    for (final d in days) {
      final globalSlots = basePairs[d] ?? <TimeRangePair>[];
      final serviceAdditionsForDay = serviceAdditions[d] ?? <TimeRangePair>[];
      final excludedKeys = initialExclusions[d] ?? <String>{};
      
      // Start with global slots, remove excluded ones
      final activeGlobalSlots = globalSlots.where((slot) {
        final key = keyOf(slot);
        return !excludedKeys.contains(key);
      }).toList();
      
      // Add service-specific additions (non-duplicates)
      final globalKeys = globalSlots.map(keyOf).toSet();
      final uniqueServiceSlots = serviceAdditionsForDay.where((slot) {
        final key = keyOf(slot);
        return !globalKeys.contains(key);
      }).toList();
      
      // Combine to get effective normal schedule
      final effectiveSlots = [...activeGlobalSlots, ...uniqueServiceSlots];
      if (effectiveSlots.isNotEmpty) {
        serviceEffectiveSchedule[d] = effectiveSlots;
      }
    }
    
    // Emergency starts with service's normal schedule + any emergency-specific additions
    final emergencyAdditions = toPairs(item.emergencyWeeklyOverrides);
    final emergencyController = ValueNotifier<Map<String, List<TimeRangePair>>>(emergencyAdditions);
    
    debugPrint('  - Service effective schedule (normal tab baseline for emergency): ${serviceEffectiveSchedule.map((k, v) => MapEntry(k, v.map((p) => keyOf(p)).toList()))}');
    debugPrint('  - Emergency additions (emergency-only): ${emergencyAdditions.map((k, v) => MapEntry(k, v.map((p) => keyOf(p)).toList()))}');
    debugPrint('  - hasAnyOverrides: $hasAnyOverrides');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        int currentTab = 0;
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(AppStrings.getString('availability', lang.currentLanguage), style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
            content: SizedBox(
              width: 700,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Cap height to viewport so content scrolls instead of overflowing
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _tabButton(AppStrings.getString('normal', lang.currentLanguage), currentTab == 0, () => setStateDialog(() { currentTab = 0; })),
                        _tabButton(
                          AppStrings.getString('emergency', lang.currentLanguage),
                          currentTab == 1,
                          item.emergencyEnabled ? () => setStateDialog(() { currentTab = 1; }) : null,
                          disabled: !item.emergencyEnabled,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (currentTab == 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Global slots (blue) are inherited from your general availability. Add service-specific slots (green) as needed.',
                                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hasAnyOverrides 
                                    ? 'Global slots (blue) are inherited. Previously excluded slots are hidden below. Service-specific slots (green) are additions.'
                                    : 'Global slots (blue) are inherited and active by default. Click ⊖ to exclude them. Service-specific slots (green) are additions.',
                                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.amber.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final d in days) _ServiceDayEditorRow(
                          dayKey: d, 
                          controller: normalController,
                          excludedController: excludedController,
                          globalSlots: basePairs[d] ?? <TimeRangePair>[],
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department, color: item.emergencyEnabled ? Colors.redAccent : Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.emergencyEnabled
                                    ? 'Emergency mode inherits your normal schedule as baseline. Add extra emergency-only slots as needed. Booking rule: clients can book within 2 hours instead of 2 days.'
                                    : AppStrings.getString('emergencyIsOffTurnOnInEdit', lang.currentLanguage),
                                  style: GoogleFonts.cairo(fontSize: 13, color: Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: item.emergencyEnabled ? 1.0 : 0.5,
                          child: IgnorePointer(
                            ignoring: !item.emergencyEnabled,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!item.emergencyEnabled)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      AppStrings.getString('emergencyIsOffTurnOnInEdit', lang.currentLanguage),
                                      style: GoogleFonts.cairo(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
                                    ),
                                  ),
                                // Emergency mode: Show baseline from normal + emergency-only additions
                                for (final d in days) _EmergencyDayEditorRow(
                                  dayKey: d, 
                                  emergencyController: emergencyController,
                                  baselineSlots: serviceEffectiveSchedule[d] ?? <TimeRangePair>[],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(AppStrings.getString('cancel', lang.currentLanguage))),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(AppStrings.getString('save', lang.currentLanguage))),
            ],
          );
        });
      }
    );

    if (confirmed == true) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final providerId = auth.userId;
      if (providerId == null) return;

      Map<String, List<Map<String, String>>> pairsToWeekly(Map<String, List<TimeRangePair>> src) {
        final out = <String, List<Map<String, String>>>{};
        for (final d in days) {
          final list = src[d] ?? const <TimeRangePair>[];
          out[d] = list
              .where((p) => p.start != null && p.end != null)
              .map((p) => {'start': _fmt(p.start!), 'end': _fmt(p.end!)})
              .toList();
        }
        return out;
      }

      final body = <String, dynamic>{};
      // Build the complete effective schedule: global + service additions - exclusions
      String keyOf(TimeRangePair p) => '${_fmt(p.start!)}-${_fmt(p.end!)}';
      
      final effectiveSchedule = <String, List<Map<String, String>>>{};
      final excludedMap = excludedController.value;
      final serviceSlots = normalController.value;
      
      for (final d in days) {
        final globalSlots = List<TimeRangePair>.from(basePairs[d] ?? const <TimeRangePair>[]);
        final excludedKeys = excludedMap[d] ?? <String>{};
        final additionalSlots = List<TimeRangePair>.from(serviceSlots[d] ?? const <TimeRangePair>[]);
        
        // Start with global slots, remove excluded ones
        final activeGlobalSlots = globalSlots.where((slot) {
          final key = keyOf(slot);
          return !excludedKeys.contains(key);
        }).toList();
        
        // Add service-specific slots (non-duplicates)
        final globalKeys = globalSlots.map(keyOf).toSet();
        final uniqueServiceSlots = additionalSlots.where((slot) {
          final key = keyOf(slot);
          return !globalKeys.contains(key);
        }).toList();
        
        // Combine effective slots
        final allEffectiveSlots = [...activeGlobalSlots, ...uniqueServiceSlots];
        
        if (allEffectiveSlots.isNotEmpty) {
          effectiveSchedule[d] = allEffectiveSlots
              .where((p) => p.start != null && p.end != null)
              .map((p) => {'start': _fmt(p.start!), 'end': _fmt(p.end!)})
              .toList();
        }
      }
      
      // Save the complete effective schedule as overrides
      // If it matches global exactly, save null (inherit)
      bool isIdenticalToGlobal = true;
      for (final d in days) {
        final globalSlots = basePairs[d] ?? <TimeRangePair>[];
        final effectiveSlots = effectiveSchedule[d] ?? <Map<String, String>>[];
        
        final globalKeys = globalSlots.map(keyOf).toSet()..remove('null-null');
        final effectiveKeys = effectiveSlots.map((s) => '${s['start']}-${s['end']}').toSet();
        
        // If there are any differences between global and effective, they are NOT identical
        if (globalKeys.difference(effectiveKeys).isNotEmpty || effectiveKeys.difference(globalKeys).isNotEmpty) {
          isIdenticalToGlobal = false;
          break;
        }
      }
      
      // Always save the effective schedule when there are exclusions or modifications
      // Only save null if truly identical (no exclusions, no additions)
      final hasExclusions = excludedController.value.values.any((set) => set.isNotEmpty);
      final hasServiceAdditions = normalController.value.values.any((list) => list.isNotEmpty);
      
      if (hasExclusions || hasServiceAdditions) {
        isIdenticalToGlobal = false;
      }

  body['weeklyOverrides'] = isIdenticalToGlobal ? null : effectiveSchedule;
  final emergencyWeekly = pairsToWeekly(emergencyController.value);
  final hasEmergency = emergencyWeekly.values.any((list) => (list).isNotEmpty);
  body['emergencyWeeklyOverrides'] = hasEmergency ? emergencyWeekly : null;

      // Debug logging to help troubleshoot
      debugPrint('[ServiceAvailability] Saving service ${item.id}:');
      debugPrint('  - isIdenticalToGlobal: $isIdenticalToGlobal');
      debugPrint('  - hasExclusions: $hasExclusions');
      debugPrint('  - hasServiceAdditions: $hasServiceAdditions');
  debugPrint('  - weeklyOverrides: ${body['weeklyOverrides']}');
  debugPrint('  - emergencyWeeklyOverrides: ${body['emergencyWeeklyOverrides']}');
      debugPrint('  - excludedMap (user excluded during session): ${excludedController.value}');

      final api = ProviderServicesApi();
      print('🔧 [ServiceAvailability] Attempting to save service ${item.id} with data:');
      print('  - providerId: $providerId');
      print('  - serviceId: ${item.id}');
      print('  - weeklyOverrides: ${body['weeklyOverrides']}');
      print('  - emergencyWeeklyOverrides: ${body['emergencyWeeklyOverrides']}');
      
      final ok = await api.update(providerId, item.id, body, authService: auth);
      print('🔧 [ServiceAvailability] Save result: $ok');
      
      if (ok) {
        print('✅ [ServiceAvailability] Successfully saved service availability');
        // Clear any cached resolved availability for this provider/service in booking flows if present
        try {
          // Invalidate provider-services cache used by Our Services listing
          ServicesService().clearProviderServicesCache(providerId);
        } catch (_) {}
        if (!mounted) return;
        setState(() { _loading = true; });
        await _load();
      } else {
        print('❌ [ServiceAvailability] Failed to save service availability');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.getString('saveFailed', lang.currentLanguage))));
      }
    }
  }

  Widget _tabButton(String label, bool active, VoidCallback? onTap, {bool disabled = false}) {
    return Expanded(
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w700,
              color: disabled
                  ? Colors.black38
                  : (active ? AppColors.primary : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  // removed: global hour quick-add row (replaced by per-day quick-add menu)

  void _deactivateSelectedServices() {
    _bulkAction((api, providerId, id, auth) => api.deactivateMonth(providerId, id, authService: auth));
  }

  void _deleteSelectedServices() {
    _bulkAction((api, providerId, id, auth) => api.remove(providerId, id, authService: auth));
  }

  Future<void> _bulkAction(Future<bool> Function(ProviderServicesApi api, String providerId, String id, AuthService auth) fn) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final providerId = auth.userId;
    if (providerId == null) return;
    final api = ProviderServicesApi();
    final list = _items;
    for (final idx in _selectedServices) {
      if (idx >= 0 && idx < list.length) {
        await fn(api, providerId, list[idx].id, auth);
      }
    }
  // Invalidate public services cache so Our Services reflects latest changes
  try { ServicesService().clearProviderServicesCache(providerId); } catch (_) {}
    if (!mounted) return;
    setState(() { _isMultiEditMode = false; _selectedServices.clear(); _loading = true; });
    await _load();
  }

  Future<void> _singleAction(ProviderServiceItem item, Future<bool> Function(ProviderServicesApi api, String providerId, String id, AuthService auth) fn) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final providerId = auth.userId;
    if (providerId == null) return;
    final api = ProviderServicesApi();
    await fn(api, providerId, item.id, auth);
  // Invalidate public services cache so Our Services reflects latest changes
  try { ServicesService().clearProviderServicesCache(providerId); } catch (_) {}
    if (!mounted) return;
    setState(() { _loading = true; });
    await _load();
  }

  // Small pill button
  Widget _buildChipButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isMobile,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8.0 : (isTablet ? 10.0 : 12.0),
              vertical: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: isMobile ? 14 : (isTablet ? 16 : 18), color: color),
                SizedBox(width: isMobile ? 4.0 : (isTablet ? 6.0 : 8.0)),
                Text(
                  label,
                  style: GoogleFonts.cairo(
                    fontSize: isMobile ? 10.0 : (isTablet ? 11.0 : 12.0),
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditDialog(ProviderServiceItem item, LanguageService lang) async {
    final rateController = TextEditingController(text: item.hourlyRate > 0 ? item.hourlyRate.toStringAsFixed(0) : '');
    final expController = TextEditingController(text: item.experienceYears.toString());
    bool emergency = item.emergencyEnabled;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.getString('editService', lang.currentLanguage)),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: rateController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.getString('hourlyRate', lang.currentLanguage),
                      prefixText: '₪ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppStrings.getString('experienceYears', lang.currentLanguage),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: emergency,
                        onChanged: (v) { setStateDialog(() { emergency = v; }); },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.getString('emergencyEnabled', lang.currentLanguage),
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.getString('cancel', lang.currentLanguage)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppStrings.getString('save', lang.currentLanguage)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final rate = double.tryParse(rateController.text.trim());
      final exp = int.tryParse(expController.text.trim());
      if (rate == null || rate <= 0 || exp == null || exp < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.getString('invalidInputs', lang.currentLanguage))),
        );
        return;
      }

      final auth = Provider.of<AuthService>(context, listen: false);
      final providerId = auth.userId;
      if (providerId == null) return;
      final api = ProviderServicesApi();
      await api.update(providerId, item.id, {
        'hourlyRate': rate,
        'experienceYears': exp,
        'emergencyEnabled': emergency,
      }, authService: auth);
  // Invalidate public services cache so Our Services reflects latest changes
  try { ServicesService().clearProviderServicesCache(providerId); } catch (_) {}
      if (!mounted) return;
      setState(() { _loading = true; });
      await _load();
    }
  }

  Future<void> _openAddServiceDialog(LanguageService lang) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final providerId = auth.userId;
    if (providerId == null) return;

    // Build a set of already linked service IDs to filter options
    final existingServiceIds = _items.map((e) => e.serviceId).toSet();
    // Fetch provider-owned services from existing ServicesService by providerId
    final servicesService = ServicesService();
    final owned = await servicesService.getServicesByProvider(providerId);
    final options = owned.where((s) => !existingServiceIds.contains(s.id)).toList();

    String? selectedServiceId = options.isNotEmpty ? options.first.id : null;
    final rateController = TextEditingController();
    final expController = TextEditingController(text: '0');
    bool emergency = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.getString('addService', lang.currentLanguage)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Service dropdown
              if (options.isEmpty)
                Text(AppStrings.getString('noMoreServicesToAdd', lang.currentLanguage))
              else
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedServiceId,
                  items: options.map((s) => DropdownMenuItem<String>(
                    value: s.id,
                    child: Text(s.title, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) { selectedServiceId = v; },
                ),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.getString('hourlyRate', lang.currentLanguage),
                  prefixText: '₪ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.getString('experienceYears', lang.currentLanguage),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(
                    value: emergency,
                    onChanged: (v) { emergency = v; },
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(AppStrings.getString('emergencyEnabled', lang.currentLanguage))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.getString('cancel', lang.currentLanguage)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppStrings.getString('add', lang.currentLanguage)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (selectedServiceId == null) return;
      final rate = double.tryParse(rateController.text.trim());
      final exp = int.tryParse(expController.text.trim());
      if (rate == null || rate <= 0 || exp == null || exp < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.getString('invalidInputs', lang.currentLanguage))),
        );
        return;
      }

      final api = ProviderServicesApi();
      final ok = await api.add(providerId, {
        'serviceId': selectedServiceId,
        'hourlyRate': rate,
        'experienceYears': exp,
        'emergencyEnabled': emergency,
      }, authService: auth);
      if (ok) {
  // Invalidate public services cache so Our Services reflects latest changes
  try { ServicesService().clearProviderServicesCache(providerId); } catch (_) {}
        if (!mounted) return;
        setState(() { _loading = true; });
        await _load();
      }
    }
  }
}
