import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/features/home/launch_greeting.dart';

void main() {
  Widget host({VoidCallback? onSkip, bool reduceMotion = false, Brightness brightness = Brightness.light}) =>
      MaterialApp(
        theme: buildTheme(brightness),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: LaunchCurtain(onSkip: onSkip),
        ),
      );

  testWidgets('the curtain plays through on the smallest phone, light and dark, without overflow', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      await tester.pumpWidget(host(brightness: brightness));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(LaunchGreeting.curtainTime);
      expect(find.text('Szop’en odkurza mikrofon…'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('a tap skips it', (tester) async {
    var skipped = 0;
    await tester.pumpWidget(host(onSkip: () => skipped++));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(100, 300));
    expect(skipped, 1);
  });

  testWidgets('with reduced motion it is the finished picture at once', (tester) async {
    await tester.pumpWidget(host(reduceMotion: true));
    expect(find.text('Szop’en odkurza mikrofon…'), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Szop’en odkurza mikrofon…'), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, 1);
  });
}
