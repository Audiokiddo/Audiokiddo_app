import 'package:audiokiddo/core/storage/storage_providers.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/day/day_notifications.dart';
import 'package:audiokiddo/features/day/day_routine.dart';
import 'package:audiokiddo/features/day/day_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const r = DayRoutine(); // Mon–Fri kindergarten and car, 7:00 up, 7:45 out, 16:00 pick-up

  test('Polish holidays include Easter-based days and Wigilia', () {
    expect(easterSunday(2026), DateTime(2026, 4, 5));
    final h = polishHolidays(2026);
    expect(h['2026-04-06'], 'Poniedziałek Wielkanocny');
    expect(h['2026-06-04'], 'Boże Ciało');
    expect(h['2026-11-11'], 'Święto Niepodległości');
    expect(h['2026-12-24'], 'Wigilia');
  });

  test('a kindergarten day moves from morning to the car, after kindergarten, dinner and bedtime', () {
    final day = DateTime(2026, 10, 16); // Friday
    DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
    expect(homeReason(r, day), isNull);
    expect(momentAt(r, at(6, 30)), isNull);
    expect(momentAt(r, at(7, 10))!.kind, DayMomentKind.morning);
    expect(momentAt(r, at(7, 35))!.kind, DayMomentKind.car);
    expect(momentAt(r, at(15, 50))!.kind, DayMomentKind.car);
    expect(momentAt(r, at(16, 30))!.kind, DayMomentKind.afterDaycare);
    expect(momentAt(r, at(17, 30))!.kind, DayMomentKind.meal);
    expect(momentAt(r, at(19, 40))!.kind, DayMomentKind.bedtime);
    expect(momentAt(r, at(22, 0)), isNull);
    expect(momentAt(r, at(7, 35))!.route, '/podroz?minuty=20');
  });

  test('weekends, holidays and a sick child are days at home without the car', () {
    final sunday = DateTime(2026, 10, 18, 12);
    expect(homeReason(r, sunday), 'Weekend');
    expect(momentAt(r, sunday)!.kind, DayMomentKind.homeDay);
    final holiday = DateTime(2026, 11, 11, 7, 35);
    expect(homeReason(r, holiday), 'Święto Niepodległości');
    expect(momentsOf(r, holiday).any((m) => m.kind == DayMomentKind.car), isFalse);
    final ill = r.copyWith(sickUntil: DateTime(2026, 10, 20));
    final monday = DateTime(2026, 10, 19, 12);
    expect(homeReason(ill, monday), 'Dziecko choruje');
    expect(momentAt(ill, monday)!.route, contains('pora=chory'));
    expect(homeReason(ill, DateTime(2026, 10, 21)), isNull, reason: 'healthy again after the date');
  });

  test('the routine survives saving, and notifications only after it was set', () {
    final saved = r.copyWith(morningMinutes: 20, homeDates: {'2026-10-23'});
    final back = DayRoutine.fromJson(saved.toJson());
    expect(back.morningMinutes, 20);
    expect(back.homeDates, {'2026-10-23'});
    expect(back.configured, isTrue);
    final now = DateTime(2026, 10, 16, 6);
    expect(dayMomentSlots(r, now), isEmpty, reason: 'never set: no notifications');
    final slots = dayMomentSlots(back, now);
    expect(slots, isNotEmpty);
    expect(slots.every((s) => s.at.isAfter(now) && s.route != null), isTrue);
    expect(slots.map((s) => s.id).toSet().length, slots.length);
  });

  testWidgets('Mój dzień shows the week, the hours, the calendar and today', (tester) async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await tester.binding.setSurfaceSize(const Size(430, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 16, 7, 35)),
        ],
        child: const MaterialApp(home: DayScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dziecko się rozchorowało'), findsOneWidget);
    expect(find.text('Przedszkole albo szkoła'), findsOneWidget);
    expect(find.text('7:45'), findsOneWidget);
    expect(find.textContaining('Wszystkich Świętych'), findsOneWidget);
    expect(find.text('Za chwilę wyjazd'), findsOneWidget);
  });
}
