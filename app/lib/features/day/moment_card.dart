import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../home/start_cards.dart';
import 'day_routine.dart';

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
