import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:test/test.dart';

Catalog realCatalog() => parseCatalog(
  jsonDecode(File('../../app/assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>,
).catalog;

ChildProfile child({int age = 4, Set<DevGoal> goals = const {DevGoal.language}, int minutes = 10}) =>
    ChildProfile(
      id: 'c1',
      name: 'Zosia',
      age: age,
      startedOn: DateTime(2026, 9, 1),
      goals: goals,
      situations: const {Situation.podroz},
      dailyMinutes: minutes,
    );

ActivityResult done(String item, DateTime at, {int answers = 0, int? correct}) =>
    ActivityResult(childId: 'c1', itemId: item, at: at, seconds: 300, answers: answers, correct: correct);

void main() {
  final catalog = realCatalog();

  group('plan', () {
    test('a portion every day, within the daily minutes, no repeats on consecutive days', () {
      final plan = buildPlan(catalog, child());
      expect(plan, hasLength(30));
      for (final day in plan) {
        expect(day.itemIds, isNotEmpty);
        expect(day.itemIds.length, lessThanOrEqualTo(3));
        final seconds = day.itemIds.map((id) => catalog.item(id)!.durationSec).reduce((a, b) => a + b);
        if (day.itemIds.length > 1) expect(seconds, lessThanOrEqualTo(10 * 60 + 90));
      }
      for (var i = 1; i < plan.length; i++) {
        expect(
          plan[i].itemIds.toSet().intersection(plan[i - 1].itemIds.toSet()),
          isEmpty,
          reason: 'day ${i + 1}',
        );
      }
    });

    test('level 1 is gentle: no interactive games and nothing over 8 minutes', () {
      final plan = buildPlan(catalog, child());
      for (final day in plan.where((d) => d.level.number == 1)) {
        for (final id in day.itemIds) {
          final item = catalog.item(id)!;
          expect(item.kind, isNot(ContentKind.interactiveGame));
          expect(item.durationSec, lessThanOrEqualTo(8 * 60));
        }
      }
      expect(
        plan.skip(7).expand((d) => d.itemIds).map((id) => catalog.item(id)!.kind),
        contains(ContentKind.interactiveGame),
      );
    });

    test('goals steer the choice and the age is respected', () {
      final words = buildPlan(catalog, child(goals: {DevGoal.language}), days: 7);
      final skills = words.expand((d) => d.itemIds).expand((id) => catalog.item(id)!.skills);
      expect(skills.where((s) => s == 'słownictwo').length, greaterThan(3));
      final small = buildPlan(catalog, child(age: 3), days: 30);
      expect(small.expand((d) => d.itemIds).every((id) => catalog.item(id)!.ageMin <= 3), isTrue);
    });

    test('what the family can play comes first', () {
      final free = {
        for (final i in catalog.items)
          if (i.access == ContentAccess.free) i.id,
      };
      final plan = buildPlan(catalog, child(), days: 3, canPlay: (i) => free.contains(i.id));
      expect(free.contains(plan.first.itemIds.first), isTrue);
    });

    test('features are introduced one at a time and each week ends with a chest', () {
      final plan = buildPlan(catalog, child());
      expect(plan[0].tip, PlanTip.phoneDown);
      expect(plan[7].tip, PlanTip.microphone);
      expect(
        [
          for (final d in plan)
            if (d.chest) d.day,
        ],
        [7, 14, 21, 28],
      );
    });
  });

  group('position on the path', () {
    final plan = buildPlan(catalog, child(), days: 5);

    test('one new day per calendar day, even if the child binges', () {
      final monday = DateTime(2026, 9, 7, 17);
      var results = [for (final id in plan[0].itemIds) done(id, monday)];
      var pos = planPosition(plan, results, monday);
      expect((pos.completedDays, pos.currentDay, pos.todayDone), (1, 1, true));

      // Day 2's activities played the same evening do not count for day 2 yet.
      results = [...results, for (final id in plan[1].itemIds) done(id, monday)];
      pos = planPosition(plan, results, monday);
      expect(pos.completedDays, 1);

      final tuesday = monday.add(const Duration(days: 1));
      pos = planPosition(plan, results, tuesday);
      expect((pos.currentDay, pos.todayDone), (2, false));
      results = [...results, for (final id in plan[1].itemIds) done(id, tuesday)];
      pos = planPosition(plan, results, tuesday);
      expect((pos.completedDays, pos.todayDone), (2, true));
    });
  });

  group('progress', () {
    test('streak, minutes and accuracy per skill', () {
      final now = DateTime(2026, 9, 10, 18);
      final results = [
        done('prawda-czy-nie', now, answers: 6, correct: 5),
        done('co-to-za-dzwiek', now.subtract(const Duration(days: 1))),
        done('magiczny-sklep', now.subtract(const Duration(days: 2))),
        done('magiczny-sklep', now.subtract(const Duration(days: 5))),
      ];
      final p = summarizeProgress(results, catalog, now);
      expect(p.streak, 3);
      expect(p.activeDays, 4);
      expect(p.minutes, 20);
      expect(p.accuracy, closeTo(5 / 6, 0.001));
      expect(p.skillPractice['słuchanie'], greaterThan(0));
    });

    test('advice praises, suggests a pack for an untouched goal and brings the family back', () {
      final now = DateTime(2026, 9, 20);
      final kid = child(age: 6, goals: {DevGoal.logic, DevGoal.imagination});
      final results = [
        for (var i = 0; i < 3; i++)
          done('prawda-czy-nie', now.subtract(Duration(days: 10 + i)), answers: 6, correct: 6),
      ];
      final p = summarizeProgress(results, catalog, now);
      final advice = adviseParent(kid, p, catalog, lastActivity: results.first.at, now: now);
      expect(
        advice.map((a) => a.kind),
        containsAll([AdviceKind.comeBack, AdviceKind.excelling, AdviceKind.untouchedGoal]),
      );
      expect(advice.firstWhere((a) => a.kind == AdviceKind.excelling).packId, 'detektyw');
    });

    test('profiles survive a JSON round trip', () {
      final kid = child(goals: {DevGoal.calm, DevGoal.logic});
      final back = ChildProfile.fromJson(jsonDecode(jsonEncode(kid.toJson())) as Map<String, Object?>);
      expect((back.name, back.age, back.dailyMinutes), (kid.name, kid.age, kid.dailyMinutes));
      expect(back.goals, kid.goals);
      expect(back.situations, kid.situations);
    });
  });

  group('locked content', () {
    final free = {
      for (final i in catalog.items)
        if (i.access == ContentAccess.free) i.id,
    };

    test('locked items appear only when nothing playable fits', () {
      final plan = buildPlan(catalog, child(), days: 10, canPlay: (i) => free.contains(i.id));
      for (final day in plan) {
        final locked = day.itemIds.where((id) => !free.contains(id));
        if (locked.isNotEmpty) expect(day.itemIds, hasLength(1), reason: 'day ${day.day}');
      }
    });

    test('a day counts once the playable activities are done', () {
      final plan = [
        const PlanDay(day: 1, itemIds: ['magiczny-sklep', 'zaginiony-skarb']),
        const PlanDay(day: 2, itemIds: ['co-to-za-dzwiek']),
      ];
      final now = DateTime(2026, 9, 7, 18);
      final pos = planPosition(plan, [done('magiczny-sklep', now)], now, playable: free.contains);
      expect((pos.completedDays, pos.todayDone), (1, true));
    });

    test('started days keep their activities', () {
      final plan = buildPlan(catalog, child(), days: 3);
      final frozen = withFrozenDays(plan, [
        ['magiczny-sklep'],
      ]);
      expect(frozen.first.itemIds, ['magiczny-sklep']);
      expect(frozen[1].itemIds, plan[1].itemIds);
    });
  });
}
