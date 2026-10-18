import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/theme/appearance.dart';
import 'package:audiokiddo/features/catalog/details_screen.dart' show firstSentences;
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
}
