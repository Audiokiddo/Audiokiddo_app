import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/family/family.dart';
import 'package:audiokiddo/features/reminders/reminders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('reminders', () {
    const texts = [('A', 'a'), ('B', 'b'), ('C', 'c')];
    const s = ReminderSettings(enabled: true, hour: 18, minute: 30);

    test('a week ahead at the parent\'s hour, texts rotating', () {
      final slots = reminderSlots(s, texts, now: DateTime(2026, 9, 28, 10));
      expect(slots, hasLength(7));
      expect(slots.first.at, DateTime(2026, 9, 28, 18, 30));
      expect(slots.map((r) => r.title).toSet(), hasLength(3));
      expect(slots.map((r) => r.id).toSet(), hasLength(7));
    });

    test('today is skipped once the portion is done or the hour has passed', () {
      expect(reminderSlots(s, texts, now: DateTime(2026, 9, 28, 10), todayDone: true).first.at.day, 29);
      expect(reminderSlots(s, texts, now: DateTime(2026, 9, 28, 20)).first.at.day, 29);
    });

    test('a few days in, once: who makes AudioKiddo (no thank-you screen at the start)', () {
      final note = aboutUsSlot(hour: 18, minute: 30, now: DateTime(2026, 9, 28, 10));
      expect(note.at, DateTime(2026, 10, 2, 18, 30));
      expect(note.id, greaterThanOrEqualTo(1000), reason: 'not replaced with the daily reminders');
      expect(note.body, contains('Nela i Dawid'));
    });

    test('the weekend road reminder: Friday 15:30, next week once it passed', () {
      expect(tripReminderSlot(now: DateTime(2026, 10, 14, 9)).at, DateTime(2026, 10, 16, 15, 30));
      expect(tripReminderSlot(now: DateTime(2026, 10, 16, 10)).at, DateTime(2026, 10, 16, 15, 30));
      expect(tripReminderSlot(now: DateTime(2026, 10, 16, 16)).at, DateTime(2026, 10, 23, 15, 30));
      expect(tripReminderSlot(now: DateTime(2026, 10, 18, 9)).at, DateTime(2026, 10, 23, 15, 30));
      expect(tripReminderSlot(now: DateTime(2026, 10, 14)).id, greaterThanOrEqualTo(1000));
    });
  });

  testWidgets('Więcej → Mapa przygód: steps, the next chest and an opened one', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = memoryDatabase();
    addTearDown(db.close);
    final zosia = ChildProfile(
      id: 'z',
      name: 'Zosia',
      age: 4,
      startedOn: DateTime(2026, 9, 1),
      goals: const {DevGoal.language},
      dailyMinutes: 10,
    );
    await db.writeValue('family_children', jsonEncode([zosia.toJson()]));
    await db.writeValue(
      'family_results',
      jsonEncode([
        for (var i = 0; i < 4; i++)
          ActivityResult(childId: 'z', itemId: 'magiczny-sklep', at: DateTime(2026, 10, 1 + i), seconds: 300).toJson(),
      ]),
    );
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(db), child: const AudioKiddoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa przygód'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Zosia: 4 kroki na mapie'), findsOneWidget);
    expect(find.text('Sekret Szop’ena nr 1'), findsOneWidget, reason: 'chest 1 opened after 3 plays');
    expect(find.text('Jeszcze 2 zabawy'), findsOneWidget, reason: 'chest 2 at step 6');
  });

  test('results are credited to the active child and move the plan on', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: testOverrides(db));
    addTearDown(container.dispose);
    final family = container.read(familyProvider.notifier);
    await container.read(familyProvider.future);
    await family.saveChild(ChildProfile(id: 'a', name: 'A', age: 4, startedOn: DateTime(2026)));
    await family.saveChild(ChildProfile(id: 'b', name: 'B', age: 6, startedOn: DateTime(2026)));
    await family.record(itemId: 'prawda-czy-nie', seconds: 240, answers: 6, correct: 5);
    await family.setActive('b');
    await family.record(itemId: 'magiczny-sklep', seconds: 360);
    final state = container.read(familyProvider).value!;
    expect(state.resultsOf('a').single.correct, 5);
    expect(state.resultsOf('b').single.itemId, 'magiczny-sklep');
    expect(state.frozen['a'], isNotEmpty, reason: 'the day A is on keeps its activities');
  });
}
