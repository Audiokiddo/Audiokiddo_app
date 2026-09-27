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
  });

  testWidgets('plan tab: child, stats, levels, today opens the day', (tester) async {
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
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(db), child: const AudioKiddoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.route_rounded));
    await tester.pumpAndSettle();
    expect(find.textContaining('Zosia'), findsWidgets);
    expect(find.text('POZIOM 1 · DNI 1–7'), findsOneWidget);
    expect(find.text('Poznajemy się'), findsOneWidget);
    expect(find.text('0/30'), findsOneWidget);

    expect(find.bySemanticsLabel('Dzień 1, dzisiaj. Otwórz zabawy.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Dzień 1'), findsOneWidget);
    expect(find.textContaining('ekranem w dół'), findsOneWidget, reason: 'the tip of day 1');
    await tester.tapAt(const Offset(20, 40)); // close the sheet
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.lock_rounded).first);
    await tester.pump();
    expect(find.textContaining('Najpierw skończcie dzień 1'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.insights_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Postęp: Zosia'), findsOneWidget);
    expect(find.textContaining('Na razie jest tu cicho'), findsOneWidget);
    expect(find.text('Wiek, cele i czas'), findsOneWidget);
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
  });
}
