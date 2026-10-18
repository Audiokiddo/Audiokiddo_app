import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/studio_controller.dart';
import '../theme.dart';
import 'crm_calendar.dart';

/// The subscription promises 2 new plays every week (owners' decision, 13.10).
const playsPerWeek = 2;

/// One week of the plan: Monday to Sunday and the plays whose premiere falls in it.
class PlanWeek {
  const PlanWeek(this.monday, this.plays);
  final DateTime monday;
  final List<Map<String, dynamic>> plays;

  int get missing => (playsPerWeek - plays.length).clamp(0, playsPerWeek);
}

/// A play still needs its recording when no audio file is set yet.
bool hasRecording(Map<String, dynamic> item) =>
    (item['audio'] as List? ?? const []).any((a) => '${(a as Map)['path'] ?? ''}'.isNotEmpty);

/// [weeks] weeks from the one with [today], each with the catalog [items] that premiere in it
/// (the `released` date), in date order.
List<PlanWeek> planWeeks(List<Map<String, dynamic>> items, DateTime today, {int weeks = 10}) {
  final day = DateTime(today.year, today.month, today.day);
  final first = day.subtract(Duration(days: day.weekday - 1));
  return [
    for (var w = 0; w < weeks; w++)
      () {
        final monday = DateTime(first.year, first.month, first.day + 7 * w);
        final from = isoDay(monday), to = isoDay(DateTime(monday.year, monday.month, monday.day + 6));
        final plays = [
          for (final i in items)
            if ('${i['released'] ?? ''}'.compareTo(from) >= 0 && '${i['released'] ?? ''}'.compareTo(to) <= 0)
              i,
        ]..sort((a, b) => '${a['released']}'.compareTo('${b['released']}'));
        return PlanWeek(monday, plays);
      }(),
  ];
}

/// CRM → Kalendarz: the coming weeks at a glance, two places a week. An empty place or a play
/// without its recording shows up while there is still time to make it.
class WeeklyPlanCard extends ConsumerWidget {
  const WeeklyPlanCard({super.key, this.today});

  /// For tests; the real day otherwise.
  final DateTime? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final items = ref.watch(studioProvider).items;
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Plan nowych zabaw pokaże się po wczytaniu katalogu (Serwer → Katalog w aplikacji).'),
        ),
      );
    }
    final weeks = planWeeks(items, today ?? DateTime.now());
    final gaps = weeks.fold(0, (a, w) => a + w.missing);
    final noAudio = weeks.expand((w) => w.plays).where((i) => !hasRecording(i)).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nowe zabawy: ${weeks.length} tygodni do przodu', style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              gaps == 0 && noAudio == 0
                  ? 'Każdy tydzień ma $playsPerWeek zabawy z nagraniem.'
                  : [
                      if (gaps > 0) 'Wolnych miejsc: $gaps',
                      if (noAudio > 0) 'Bez nagrania: $noAudio',
                    ].join(' · '),
              style: text.bodyMedium?.copyWith(
                color: gaps == 0 && noAudio == 0 ? Brand.tealDeep : Brand.coral,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Zabawa trafia tutaj, gdy w Treściach ma datę premiery w tym tygodniu.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [for (final w in weeks) _Week(week: w)]),
          ],
        ),
      ),
    );
  }
}

class _Week extends StatelessWidget {
  const _Week({required this.week});
  final PlanWeek week;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sunday = week.monday.add(const Duration(days: 6));
    String d(DateTime x) => '${x.day}.${'${x.month}'.padLeft(2, '0')}';
    final ok = week.missing == 0 && week.plays.every(hasRecording);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ok ? Brand.tealSoft : Brand.coralSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${d(week.monday)} – ${d(sunday)}',
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          for (final p in week.plays)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    hasRecording(p) ? Icons.check_circle_rounded : Icons.mic_off_rounded,
                    size: 16,
                    color: hasRecording(p) ? Brand.tealDeep : Brand.coral,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${p['title'] ?? p['id']}${hasRecording(p) ? '' : ' (bez nagrania)'}',
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          for (var k = 0; k < week.missing; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, size: 16, color: Brand.coral),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Wolne miejsce', style: text.bodySmall?.copyWith(color: Brand.coral)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
