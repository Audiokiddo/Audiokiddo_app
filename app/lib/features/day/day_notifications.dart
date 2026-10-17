import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../reminders/reminders.dart';
import 'day_routine.dart';

/// Notification ids of Mój dzień: 2000 + day × 10 + moment (a week ahead).
const dayMomentFirstId = 2000;
const dayMomentDays = 7;

/// The week's moments worth a notification: only the kinds the parent switched on, only after
/// the routine was saved once, never in the past.
List<ReminderSlot> dayMomentSlots(DayRoutine r, DateTime now) {
  if (!r.configured) return const [];
  final slots = <ReminderSlot>[];
  for (var day = 0; day < dayMomentDays; day++) {
    final date = DateTime(now.year, now.month, now.day + day);
    final moments = momentsOf(r, date);
    for (final (i, m) in moments.indexed) {
      if (!r.notify.contains(m.kind) || !m.startsAt.isAfter(now)) continue;
      slots.add(
        ReminderSlot(
          id: dayMomentFirstId + day * 10 + i,
          at: m.startsAt,
          title: m.title,
          body: m.line,
          route: m.route,
        ),
      );
    }
  }
  return slots;
}

Future<void> _reschedule(ReminderScheduler scheduler, DayRoutine r) async {
  for (var id = dayMomentFirstId; id < dayMomentFirstId + dayMomentDays * 10; id++) {
    await scheduler.cancel(id);
  }
  for (final slot in dayMomentSlots(r, DateTime.now())) {
    await scheduler.schedule(slot);
  }
}

/// After the routine changes, and whenever the parent zone opens (a week ahead stays fresh).
Future<void> rescheduleDayMoments(WidgetRef ref) async {
  try {
    await _reschedule(ref.read(reminderSchedulerProvider), await ref.read(dayRoutineProvider.future));
  } on Object {
    // A notification that does not come is better than a crash.
  }
}
