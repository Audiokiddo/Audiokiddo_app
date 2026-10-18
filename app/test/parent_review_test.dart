import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/theme/appearance.dart';
import 'package:audiokiddo/features/catalog/details_screen.dart' show firstSentences;
import 'package:audiokiddo/features/day/day_routine.dart';
import 'package:audiokiddo/features/day/play_moments.dart';
import 'package:audiokiddo/features/session/session.dart';
import 'package:audiokiddo/features/family/birthday.dart';
import 'package:audiokiddo/features/family/listeners.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ChildProfile _child(String id, int age) =>
    ChildProfile(id: id, name: id, age: age, startedOn: DateTime(2026, 10, 1));

void main() {
  test('the description shows two sentences, the rest behind "więcej"', () {
    expect(firstSentences('Jedno. Dwa! Trzy? Cztery.'), 'Jedno. Dwa!');
    expect(firstSentences('Jedno. Dwa.'), isNull, reason: 'nothing more to hide');
  });

  test('siblings: plans for the youngest of those listening', () {
    final kids = [_child('zosia', 6), _child('stas', 3)];
    expect(listening(kids, {}).map((c) => c.id), ['zosia', 'stas'], reason: 'nobody chosen means everyone');
    expect(listening(kids, {'zosia'}).single.id, 'zosia');
    expect(listening(kids, {'gone'}), kids, reason: 'a removed child falls back to everyone');
  });

  test('the evening starts half an hour before bedtime, between 18:00 and 21:00', () {
    expect(eveningFor(null), 20 * 60);
    expect(eveningFor(19 * 60 + 30), 19 * 60);
    expect(eveningFor(17 * 60), 18 * 60);
    expect(effectiveThemeMode(ThemeMode.system, DateTime(2026, 10, 18, 19, 10), evening: 19 * 60), ThemeMode.dark);
    expect(effectiveThemeMode(ThemeMode.system, DateTime(2026, 10, 18, 18, 50), evening: 19 * 60), ThemeMode.light);
    expect(nextAppearanceChange(DateTime(2026, 10, 18, 12), evening: 19 * 60), DateTime(2026, 10, 18, 19));
  });

  test('a birthday is the day and the month, any year', () {
    expect(isBirthday((month: 10, day: 18), DateTime(2026, 10, 18, 8)), isTrue);
    expect(isBirthday((month: 10, day: 18), DateTime(2027, 10, 19)), isFalse);
    expect(isBirthday(null, DateTime(2026, 10, 18)), isFalse);
  });

  test('a moment is hosted by Szop’en: hello for the day, asides between plays, goodbye', () {
    final item = ContentItem(
      id: 'a',
      kind: ContentKind.audioGame,
      title: 'A',
      parentDescription: '',
      ageMin: 3,
      durationSec: 300,
      access: ContentAccess.free,
      audio: const [],
    );
    // A Tuesday with kindergarten: the morning says so and ends with shoes.
    const routine = DayRoutine(configured: true);
    final tuesday = DateTime(2026, 10, 20, 7);
    final day = DayContext.of(routine, tuesday);
    expect(day.daycare, isTrue);
    final plan = buildMomentPlan([item, item], PlayMoment.rano, day);
    final lines = [for (final s in plan) if (s is LineStep) s.line];
    expect(lines.first, startsWith('c_rano_przedszkole_'));
    expect(lines.where((l) => l.startsWith('m_rano_link_')), hasLength(1));
    expect(lines.last, startsWith('c_rano_buty_'));
    expect(momentStart(PlayMoment.auto, DayContext.of(routine, DateTime(2026, 10, 20, 15)), 0), 'c_auto_powrot_1');
    expect(momentStart(PlayMoment.rano, DayContext.of(routine, DateTime(2026, 10, 23, 7)), 0), 'c_piatek');
    // Sunday: no kindergarten, no shoes.
    final sunday = DayContext.of(routine, DateTime(2026, 10, 25, 8));
    expect(momentStart(PlayMoment.rano, sunday, 0), 'c_rano_wolne_1');
    expect(momentEnd(PlayMoment.rano, sunday, 0), 'm_rano_end_1');
    // Every line he can say is recorded.
    for (final m in PlayMoment.values) {
      for (var v = 0; v < 6; v++) {
        for (final d in [day, sunday]) {
          for (final line in [momentStart(m, d, v), momentEnd(m, d, v)]) {
            expect(File('assets/audio/kiddo/$line.m4a').existsSync(), isTrue, reason: line);
          }
        }
      }
      for (var k = 1; k <= m.links; k++) {
        expect(File('assets/audio/kiddo/m_${m.name}_link_$k.m4a').existsSync(), isTrue);
      }
    }
  });
}
