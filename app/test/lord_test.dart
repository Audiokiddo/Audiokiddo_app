import 'package:audiokiddo/features/home/home_widget_sync.dart';
import 'package:audiokiddo/features/lord/lord_lines.dart';
import 'package:audiokiddo/features/lord/lord_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const parentPools = {
  LordPool.launchMorning,
  LordPool.launchMidday,
  LordPool.launchAfternoon,
  LordPool.launchEvening,
  LordPool.gameListening,
  LordPool.gameWaiting,
  LordPool.gameFinished,
  LordPool.trip,
  LordPool.bedtime,
  LordPool.kidsHome,
  LordPool.hello,
};

void main() {
  test('parent mode follows the house style: no exclamation marks, no emoji, short', () {
    final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    for (final pool in parentPools) {
      for (final line in lordLines[pool]!) {
        expect(line.contains('!'), isFalse, reason: line);
        expect(emoji.hasMatch(line), isFalse, reason: line);
        expect(line.length, lessThanOrEqualTo(pool == LordPool.hello ? 90 : 60), reason: line);
      }
    }
  });

  test('every pool has several lines, the widget line changes every day', () {
    for (final pool in LordPool.values) {
      expect(lordLines[pool]!.length, greaterThanOrEqualTo(3), reason: pool.name);
    }
    final monday = widgetJokes(DateTime(2026, 9, 28));
    final tuesday = widgetJokes(DateTime(2026, 9, 29));
    expect(monday.keys, containsAll(['joke_morning', 'joke_midday', 'joke_afternoon', 'joke_evening']));
    expect(monday['joke_evening'], isNot(tuesday['joke_evening']));
  });

  test('a pool continues where it stopped, so lines do not repeat back to back', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final cursor = LordCursor(db);
    await cursor.ready;
    final first = cursor.next(LordPool.trip);
    final second = cursor.next(LordPool.trip);
    expect(second, isNot(first));
  });

  testWidgets('Start note and parent aside render with Szop’en in his coat', (tester) async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(db),
        child: const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LordNote(),
                ParentAside(pool: LordPool.bedtime, dark: false),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('SZOP’EN'), findsOneWidget);
    expect(find.textContaining('ZMIANA #'), findsOneWidget);
    expect(find.text('DLA RODZICA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
