import 'package:audiokiddo/features/insights/sitting.dart';
import 'package:audiokiddo/features/player/countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the countdown shows the time left, a game only roughly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            PlayCountdown(remaining: Duration(minutes: 12, seconds: 5)),
            PlayCountdown(remaining: Duration(minutes: 5, seconds: 20), approximate: true),
            PlayCountdown(remaining: Duration(seconds: 30), approximate: true),
          ],
        ),
      ),
    );
    expect(find.text('12:05'), findsOneWidget);
    expect(find.text('ok. 6 min'), findsOneWidget);
    expect(find.text('Zaraz koniec'), findsOneWidget);
    expect(find.textContaining('koniec ok.'), findsNWidgets(2));
  });

  test('plays and games close together are one sitting', () {
    var now = DateTime(2026, 10, 17, 18);
    final clock = SittingClock(clock: () => now);
    final first = clock.begin();
    now = now.add(const Duration(minutes: 8));
    clock.touch();
    now = now.add(const Duration(minutes: 9));
    expect(clock.begin(), first, reason: '9 minutes after the last activity');
    now = now.add(const Duration(minutes: 11));
    expect(clock.begin(), isNot(first), reason: 'more than 10 minutes apart');
  });
}
