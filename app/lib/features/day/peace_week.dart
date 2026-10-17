import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_providers.dart';
import '../family/family.dart';
import '../home/start_cards.dart';
import 'day_routine.dart';

/// Minutes of quiet AudioKiddo gave the parent in the last seven days, by moment of the day
/// (report 2026-10-17: parents buy minutes, so we show them the minutes). Siblings listening
/// together count once.
Map<DayMomentKind?, int> peaceMinutes(Iterable<ActivityResult> results, DayRoutine r, DateTime now) {
  final since = now.subtract(const Duration(days: 7));
  final seen = <String>{};
  final seconds = <DayMomentKind?, int>{};
  for (final res in results) {
    if (res.at.isBefore(since) || res.at.isAfter(now)) continue;
    final key = '${res.itemId}|${res.at.year}-${res.at.month}-${res.at.day} ${res.at.hour}:${res.at.minute}';
    if (!seen.add(key)) continue;
    final kind = momentAt(r, res.at)?.kind;
    seconds[kind] = (seconds[kind] ?? 0) + res.seconds;
  }
  return {for (final e in seconds.entries) e.key: (e.value / 60).round()};
}

/// On Start on Sunday evening and Monday: the week in minutes of quiet.
class PeaceWeekCard extends ConsumerWidget {
  const PeaceWeekCard({super.key});

  static const _labels = {
    DayMomentKind.morning: 'rano',
    DayMomentKind.car: 'w aucie',
    DayMomentKind.afterDaycare: 'po przedszkolu',
    DayMomentKind.homeDay: 'w domu',
    DayMomentKind.meal: 'przy kolacji',
    DayMomentKind.bedtime: 'na dobranoc',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (startCardClosed(ref, 'peace')) return const SizedBox.shrink();
    final now = ref.watch(currentTimeProvider);
    final show = (now.weekday == DateTime.sunday && now.hour >= 17) || now.weekday == DateTime.monday;
    final routine = ref.watch(dayRoutineProvider).value;
    final family = ref.watch(familyProvider).value;
    if (!show || routine == null || family == null) return const SizedBox.shrink();
    final minutes = peaceMinutes(family.results, routine, now);
    final total = minutes.values.fold(0, (a, b) => a + b);
    if (total < 15) return const SizedBox.shrink();
    final parts = [
      for (final k in DayMomentKind.values)
        if ((minutes[k] ?? 0) > 0) '${minutes[k]} min ${_labels[k]}',
    ];
    final h = total ~/ 60, m = total % 60;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Twój tydzień z AudioKiddo', style: text.labelLarge)),
                const StartCardClose(id: 'peace'),
              ],
            ),
            Text(
              h == 0 ? '$m minut spokoju' : '$h h ${m > 0 ? '$m min ' : ''}spokoju',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (parts.isNotEmpty) Text(parts.join(', '), style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}
