import 'package:flutter/material.dart';
import '../services/availability_service.dart';

class AvailabilityCalendar extends StatelessWidget {
  final AvailabilityResolved resolved;
  final DateTime initialMonth;
  final ValueChanged<_SlotRef> onSelect;

  const AvailabilityCalendar({super.key, required this.resolved, required this.initialMonth, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final days = {for (final d in resolved.days) d.date: d};
    final first = DateTime(initialMonth.year, initialMonth.month, 1);
    final last = DateTime(initialMonth.year, initialMonth.month + 1, 0);
    final weeks = <List<_DayCell>>[];

    DateTime cursor = first;
    // Fill leading empty days
    final startWeekday = (cursor.weekday % 7); // 0=Sun
    List<_DayCell> current = List.generate(startWeekday, (_) => _DayCell.empty());

    while (cursor.isBefore(last.add(const Duration(days: 1)))) {
      final key = _dateKey(cursor);
      final rd = days[key];
      final has = rd != null && rd.slots.isNotEmpty;
      current.add(_DayCell(
        date: cursor,
        enabled: has,
        badge: has ? rd!.slots.length : 0,
        onTap: has ? () => onSelect(_SlotRef(date: cursor, slots: rd!.slots)) : null,
      ));
      if (current.length == 7) {
        weeks.add(current);
        current = [];
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    if (current.isNotEmpty) {
      // trailing blanks
      while (current.length < 7) current.add(_DayCell.empty());
      weeks.add(current);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekHeader(),
        const SizedBox(height: 8),
        ...weeks.map((w) => Row(children: w.map((c) => Expanded(child: c)).toList())).toList(),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labels = ['S','M','T','W','T','F','S'];
    return Row(children: labels.map((l) => Expanded(child: Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold))))).toList());
  }
}

class _DayCell extends StatelessWidget {
  final DateTime? date;
  final bool enabled;
  final int badge;
  final VoidCallback? onTap;

  const _DayCell({this.date, required this.enabled, required this.badge, this.onTap});
  const _DayCell.empty() : date = null, enabled = false, badge = 0, onTap = null;

  @override
  Widget build(BuildContext context) {
    if (date == null) return SizedBox(height: 40, child: Container());
    final color = enabled ? Colors.green.shade600 : Colors.grey.shade400;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: enabled ? Colors.green.shade50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Stack(
          children: [
            Align(alignment: Alignment.center, child: Text('${date!.day}')),
            if (badge > 0) Positioned(right: 4, top: 4, child: _Badge(count: badge))
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }
}

class _SlotRef {
  final DateTime date;
  final List<AvailabilitySlot> slots;
  _SlotRef({required this.date, required this.slots});
}

String _dateKey(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
