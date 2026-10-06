import 'package:flutter/material.dart';

import 'crm_widgets.dart';

const monthNames = [
  'Styczeń',
  'Luty',
  'Marzec',
  'Kwiecień',
  'Maj',
  'Czerwiec',
  'Lipiec',
  'Sierpień',
  'Wrzesień',
  'Październik',
  'Listopad',
  'Grudzień',
];

String isoDay(DateTime d) => '${d.year}-${'${d.month}'.padLeft(2, '0')}-${'${d.day}'.padLeft(2, '0')}';

/// The publication calendar as a month: premieres, posts, reels, newsletters on their days.
/// Drag a card to another day (or to "Bez daty") to move it; tap to edit.
class CalendarMonth extends StatefulWidget {
  const CalendarMonth({super.key, required this.items, required this.onTap, required this.onMove, this.today});

  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onTap;

  /// The item and its new day (null: no date).
  final void Function(Map<String, dynamic> item, String? day) onMove;
  final DateTime? today;

  @override
  State<CalendarMonth> createState() => _CalendarMonthState();
}

class _CalendarMonthState extends State<CalendarMonth> {
  late DateTime _month = DateTime((widget.today ?? DateTime.now()).year, (widget.today ?? DateTime.now()).month);

  static const _colors = {
    'release': Color(0xFFFAC119),
    'post': Color(0xFF3EADB2),
    'reel': Color(0xFFA98EC1),
    'newsletter': Color(0xFFFF9A6B),
    'promotion': Color(0xFFB8431C),
    'update': Color(0xFF8A8A8A),
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final today = isoDay(widget.today ?? DateTime.now());
    final first = _month;
    final lead = first.weekday - 1; // Monday first
    final days = DateTime(first.year, first.month + 1, 0).day;
    final cells = ((lead + days) / 7).ceil() * 7;
    final byDay = <String, List<Map<String, dynamic>>>{};
    final undated = <Map<String, dynamic>>[];
    for (final i in widget.items) {
      final due = i['due'] as String?;
      due == null ? undated.add(i) : byDay.putIfAbsent(due, () => []).add(i);
    }

    Widget card(Map<String, dynamic> i) {
      final chip = Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: (_colors[i['area']] ?? Colors.grey).withValues(alpha: .28),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: _colors[i['area']] ?? Colors.grey, width: 3)),
        ),
        child: Text(
          '${i['title']}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
      );
      return Draggable<Map<String, dynamic>>(
        data: i,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(width: 140, child: chip),
        ),
        childWhenDragging: Opacity(opacity: .3, child: chip),
        child: GestureDetector(onTap: () => widget.onTap(i), child: chip),
      );
    }

    Widget target(String? day, Widget Function(bool hovering) child) => DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (d) => d.data['due'] != day,
      onAcceptWithDetails: (d) => widget.onMove(d.data, day),
      builder: (context, candidates, _) => child(candidates.isNotEmpty),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Poprzedni miesiąc',
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('${monthNames[_month.month - 1]} ${_month.year}', style: text.titleLarge),
                  IconButton(
                    tooltip: 'Następny miesiąc',
                    onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final MapEntry(:key, :value) in _colors.entries)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, color: value),
                            const SizedBox(width: 4),
                            Text(areaLabel(key), style: text.labelSmall),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  for (final d in const ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'Sb', 'Nd'])
                    Expanded(
                      child: Center(child: Text(d, style: text.labelMedium)),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              for (var week = 0; week < cells ~/ 7; week++)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var d = 0; d < 7; d++)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final n = week * 7 + d - lead + 1;
                              if (n < 1 || n > days) return const SizedBox(height: 90);
                              final day = isoDay(DateTime(_month.year, _month.month, n));
                              return target(
                                day,
                                (hovering) => Container(
                                  constraints: const BoxConstraints(minHeight: 90),
                                  margin: const EdgeInsets.all(2),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: hovering
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Theme.of(context).colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(8),
                                    border: day == today
                                        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text('$n', style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                                      for (final i in byDay[day] ?? const <Map<String, dynamic>>[]) card(i),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 190,
          child: target(
            null,
            (hovering) => Container(
              constraints: const BoxConstraints(minHeight: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hovering
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Bez daty (${undated.length})', style: text.titleSmall),
                  const Text('Przeciągnij na dzień.', style: TextStyle(fontSize: 11)),
                  const SizedBox(height: 6),
                  for (final i in undated) card(i),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
