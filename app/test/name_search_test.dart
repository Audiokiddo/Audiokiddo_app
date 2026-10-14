import 'dart:convert';
import 'dart:io';

import 'package:audiokiddo/core/audio/kiddo_voice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final index = (jsonDecode(File('assets/audio/names/index.json').readAsStringSync()) as Map<String, Object?>)
      .map((k, v) => MapEntry(k, v! as String));
  final groups = (jsonDecode(File('assets/audio/names/groups.json').readAsStringSync()) as Map<String, Object?>)
      .map((k, v) => MapEntry(k, (v! as List).cast<String>()));
  final recorded = (names: [for (final n in index.keys.toList()..sort(comparePolish)) capitalizeName(n)], related: groups);

  test('every name has its recording', () {
    expect(index.length, greaterThan(300));
    for (final file in index.values) {
      expect(File('assets/audio/names/$file.m4a').existsSync(), isTrue, reason: file);
    }
  });

  test('search: first letters, the other form of the name, no Polish letters needed', () {
    expect(searchNames('Zo', recorded).take(3), containsAll(['Zofia', 'Zosia']));
    expect(searchNames('Zofia', recorded), ['Zofia', 'Zosia']);
    expect(searchNames('lucj', recorded), contains('Łucja'));
    expect(searchNames('Wacek', recorded), containsAll(['Wacek', 'Wacław']));
    expect(searchNames('Qwerty', recorded), isEmpty);
  });

  test('Szop’en finds the clip for a name typed with or without Polish letters', () {
    expect(nameClip('Łucja', index), 'lucja');
    expect(nameClip('lucja ', index), 'lucja');
    expect(nameClip('Zosia Kowalska', index), 'zosia');
    expect(nameClip('Ffg', index), isNull);
  });
}
