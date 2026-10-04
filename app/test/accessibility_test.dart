import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/kids_mode/kids_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Tap targets (Android 48 dp, iOS 44 pt), labels for screen readers and text contrast.
Future<void> expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

Future<void> pump(WidgetTester tester, {bool onboardingDone = true, KidsModeController? kids}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final db = memoryDatabase();
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(db, onboardingDone: onboardingDone, kidsMode: kids),
      child: const AudioKiddoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, onboardingDone: false);
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('home', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('library', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await tester.tap(find.byIcon(Icons.auto_stories_outlined));
    await tester.pumpAndSettle();
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('details', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    await tester.tap(find.byIcon(Icons.auto_stories_outlined));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Audiozabawy'));
    await tester.tap(find.text('Audiozabawy'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Magiczny sklep'),
      150,
      scrollable: find
          .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .first,
    );
    await tester.tap(find.text('Magiczny sklep'));
    await tester.pumpAndSettle();
    await expectAccessible(tester);
    handle.dispose();
  });

  testWidgets('kids mode', (tester) async {
    final handle = tester.ensureSemantics();
    final db = memoryDatabase();
    addTearDown(db.close);
    final kids = KidsModeController(db);
    await kids.enter(age: 3, onlyDownloaded: false);
    await pump(tester, kids: kids);
    await expectAccessible(tester);
    handle.dispose();
  });

  for (final (name, brightness, scale) in [
    ('dark mode', Brightness.dark, 1.0),
    ('large text 200%', Brightness.light, 2.0),
  ]) {
    testWidgets('home and details in $name', (tester) async {
      final handle = tester.ensureSemantics();
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester);
      await expectAccessible(tester);
      await tester.tap(find.byIcon(Icons.auto_stories_outlined));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Audiozabawy'));
      await tester.tap(find.text('Audiozabawy'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Magiczny sklep'),
        150,
        scrollable: find
            .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
            .first,
      );
      await tester.tap(find.text('Magiczny sklep'));
      await tester.pumpAndSettle();
      await expectAccessible(tester);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  }
}
