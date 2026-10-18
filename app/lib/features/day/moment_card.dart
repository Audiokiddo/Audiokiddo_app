import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ak_core/ak_core.dart';

import '../purchases/shop.dart' show playsCount;
import '../../core/theme/app_theme.dart';
import '../../core/widgets/szop.dart';
import '../downloads/download_providers.dart';
import '../family/family.dart';
import '../family/listeners.dart';
import '../catalog/catalog_providers.dart';
import '../home/start_cards.dart';
import 'day_routine.dart';
import '../lord/lord_lines.dart';

/// The top of Start: what fits the family right now (Mój dzień), from the hour, the routine
/// and the calendar. Mornings a warm-up of the length the parent picked, before leaving the
/// car, after kindergarten a quiet quarter, at home a longer block, then dinner and bedtime.
class MomentCard extends ConsumerWidget {
  const MomentCard({super.key});

  static const _colors = {
    DayMomentKind.morning: (Color(0xFFFFF0C2), SzopPose.zadowolony, Icons.wb_sunny_rounded),
    DayMomentKind.car: (Color(0xFFCDEDEA), SzopPose.chytry, Icons.directions_car_rounded),
    DayMomentKind.afterDaycare: (Color(0xFFE8DDF4), SzopPose.zmeczony, Icons.weekend_rounded),
    DayMomentKind.homeDay: (Color(0xFFDDEFD9), SzopPose.klaszcze, Icons.home_rounded),
    DayMomentKind.meal: (Color(0xFFFFE3C2), SzopPose.prosi, Icons.restaurant_rounded),
    DayMomentKind.bedtime: (Color(0xFFDAD6F0), SzopPose.zmeczony, Icons.bedtime_rounded),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (startCardClosed(ref, 'moment')) return const SizedBox.shrink();
    final routine = ref.watch(dayRoutineProvider).value;
    if (routine == null) return const SizedBox.shrink();
    final now = ref.watch(currentTimeProvider);
    final moment = momentAt(routine, now);
    if (moment == null) return const SizedBox.shrink();
    final (color, pose, icon) = _colors[moment.kind]!;
    final home = homeReason(routine, now);
    final pool = switch (moment.kind) {
      DayMomentKind.morning => LordPool.momentMorning,
      DayMomentKind.car => LordPool.momentCar,
      DayMomentKind.afterDaycare => LordPool.momentAfterDaycare,
      DayMomentKind.homeDay => home == 'Dziecko choruje' ? LordPool.momentSick : LordPool.momentHomeDay,
      DayMomentKind.meal => LordPool.momentMeal,
      DayMomentKind.bedtime => LordPool.momentBedtime,
    };
    // A different line from Szop’en every day.
    final aside = lordLine(pool, now.difference(DateTime(now.year)).inDays);
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push(moment.route),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: ink, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ['Teraz', ?home].join(' · ').toUpperCase(),
                        style: text.labelSmall?.copyWith(color: ink, letterSpacing: .8, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const StartCardClose(id: 'moment', color: ink),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(moment.title, style: text.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(moment.line, style: text.bodyMedium?.copyWith(color: ink)),
                          const SizedBox(height: 4),
                          Text(
                            '„$aside”',
                            style: text.bodySmall?.copyWith(color: ink.withValues(alpha: .75), fontStyle: FontStyle.italic),
                          ),
                          if (moment.kind == DayMomentKind.car ||
                              (moment.kind == DayMomentKind.bedtime && routine.configured))
                            _ReadyOffline(ink: ink, tomorrow: moment.kind == DayMomentKind.bedtime),
                          const _Listeners(ink: ink),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: ink, foregroundColor: Colors.white),
                                onPressed: () => context.push(moment.route),
                                child: Text(moment.action),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(foregroundColor: ink),
                                onPressed: () => context.push('/moj-dzien'),
                                child: Text(routine.configured ? 'Mój dzień' : 'Ustaw mój dzień'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SzopSticker(pose, height: 76),
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
}

/// Before the car (and the evening before): what is on the phone for a ride without the
/// internet, or one button to get it (parent review, 2026-10-18).
class _ReadyOffline extends ConsumerWidget {
  const _ReadyOffline({required this.ink, required this.tomorrow});

  final Color ink;

  /// The evening before: "na jutro".
  final bool tomorrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(downloadSummaryProvider).value?.itemIds ?? const <String>[];
    final catalog = ref.watch(catalogProvider).value;
    final ready = [for (final id in ids) ?catalog?.item(id)];
    final minutes = (ready.fold<int>(0, (s, i) => s + i.durationSec) / 60).round();
    final text = Theme.of(context).textTheme;
    if (ready.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: ink, side: BorderSide(color: ink.withValues(alpha: .4))),
          onPressed: () => context.push('/pobrane'),
          icon: const Icon(Icons.download_rounded),
          label: Text(tomorrow ? 'Pobierz na jutrzejszą drogę' : 'Pobierz na drogę'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.offline_pin_rounded, size: 18, color: ink),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Gotowe bez internetu: ${playsCount(ready.length)}, $minutes min',
              style: text.bodySmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Słuchają: Zosia, Staś": with siblings, who is listening now; plans take the youngest of
/// them. Tapping a name leaves that child out (or back in).
class _Listeners extends ConsumerWidget {
  const _Listeners({required this.ink});

  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(familyProvider).value?.children ?? const <ChildProfile>[];
    if (children.length < 2) return const SizedBox.shrink();
    final on = {...listening(children, ref.watch(listenersProvider).value ?? const {}).map((c) => c.id)};
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(on.length > 1 ? 'Słuchają razem:' : 'Słucha:', style: text.bodySmall?.copyWith(color: ink)),
          for (final c in children)
            FilterChip(
              label: Text(c.name.isEmpty ? '${c.age} lat' : c.name),
              selected: on.contains(c.id),
              labelStyle: selectableChipLabel(context, selected: on.contains(c.id)),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => ref.read(listenersProvider.notifier).toggle(c.id, children),
            ),
        ],
      ),
    );
  }
}

/// "Wyjeżdżacie zwykle o 7:40. Ustawić?": the hour learned from the car plans started.
class LeaveHint extends ConsumerWidget {
  const LeaveHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hour = ref.watch(leaveHintProvider).value;
    final routine = ref.watch(dayRoutineProvider).value;
    if (hour == null || routine == null) return const SizedBox.shrink();
    final clock = '${hour ~/ 60}:${(hour % 60).toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Zwykle wyjeżdżacie o $clock', style: Theme.of(context).textTheme.titleSmall),
            const Text('Ustawić tę godzinę w Moim dniu? Podpowiedź do auta przyjdzie wtedy na czas.'),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    await ref.read(tripLogProvider.notifier).dismiss(hour);
                    ref.invalidate(leaveHintProvider);
                  },
                  child: const Text('Nie, dziękuję'),
                ),
                FilledButton(
                  onPressed: () async {
                    await ref.read(dayRoutineProvider.notifier).save(routine.copyWith(leave: hour));
                    ref.invalidate(leaveHintProvider);
                  },
                  child: Text('Ustaw $clock'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
