import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/home/home_widget_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('week notes follow the melody staff of the current week', () {
    expect(weekNotes(currentDay: 1, completedDays: 0), 0);
    expect(weekNotes(currentDay: 3, completedDays: 2), 2);
    expect(weekNotes(currentDay: 7, completedDays: 7), 7, reason: 'last day of the week done');
    expect(weekNotes(currentDay: 8, completedDays: 7), 0, reason: 'a new week starts empty');
    expect(weekNotes(currentDay: 10, completedDays: 9), 2);
  });

  test('widget data compares by value, so unchanged weeks are not pushed again', () {
    const a = HomeWidgetData(line: 'Zosia · dzień 3 · 2 z 7 nut', notes: 2, todayDone: false);
    const b = HomeWidgetData(line: 'Zosia · dzień 3 · 2 z 7 nut', notes: 2, todayDone: false);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('the widget offers today\'s play from the plan, started with one tap', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final db = memoryDatabase();
    addTearDown(db.close);
    final child = ChildProfile(
      id: 'z',
      name: 'Zosia',
      age: 6,
      startedOn: DateTime(2026, 9, 1),
      goals: const {DevGoal.imagination},
      dailyMinutes: 10,
    );
    await db.writeValue('family_children', jsonEncode([child.toJson()]));
    final container = ProviderContainer(overrides: testOverrides(db));
    addTearDown(container.dispose);
    container.listen(homeWidgetDataProvider, (_, _) {});
    await container.read(catalogProvider.future);
    for (var i = 0; i < 20 && container.read(homeWidgetDataProvider)?.next == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final data = container.read(homeWidgetDataProvider)!;
    expect(data.line, startsWith('Zosia'));
    expect(data.next, isNotNull);
    expect(data.next!.path, matches(RegExp(r'^/zabawa/.+\?graj=1$')));
    expect(data.next!.detail, endsWith('min'));
  });
}
