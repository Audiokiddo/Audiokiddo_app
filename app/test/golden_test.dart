import 'package:audiokiddo/core/widgets/ambient_motion.dart';
import 'package:audiokiddo/core/widgets/golden_hello.dart';
import 'package:audiokiddo/core/widgets/kiddo.dart';
import 'package:audiokiddo/core/widgets/szop.dart';
import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// How far Szop’en has bobbed right now.
double bob(WidgetTester t) => t
    .widget<Transform>(find.descendant(of: find.byType(Kiddo), matching: find.byType(Transform)).first)
    .transform
    .getTranslation()
    .y;

/// Whether he is still bobbing: his offset changes between two frames.
Future<bool> moving(WidgetTester t) async {
  final before = bob(t);
  await t.pump(const Duration(milliseconds: 170));
  return bob(t) != before;
}

SzopPose pose(WidgetTester t) =>
    t.widget<SzopSticker>(find.descendant(of: find.byType(Kiddo), matching: find.byType(SzopSticker))).pose;

void main() {
  test('outfit respects local day boundaries', () {
    for (final (hour, expected) in [
      (4, GoldenOutfit.pajamas),
      (5, GoldenOutfit.day),
      (10, GoldenOutfit.day),
      (11, GoldenOutfit.adventure),
      (18, GoldenOutfit.adventure),
      (19, GoldenOutfit.pajamas),
    ]) {
      expect(goldenOutfitAt(DateTime(2026, 9, 28, hour)), expected);
    }
  });
  testWidgets('all motion freezes with reduced motion and hidden ticker mode', (t) async {
    Future<void> mount({bool reduce = false, bool visible = true}) async {
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduce),
              child: TickerMode(
                enabled: visible,
                child: const Kiddo(mood: KiddoMood.talking, wave: true),
              ),
            ),
          ),
        ),
      );
    }

    await mount();
    await t.pump(const Duration(milliseconds: 400));
    expect(await moving(t), isTrue);
    await mount(reduce: true);
    await t.pump(const Duration(seconds: 1));
    expect(await moving(t), isFalse);
    expect(bob(t), 0);
    await mount(visible: false);
    await t.pump(const Duration(seconds: 1));
    expect(await moving(t), isFalse);
    await mount();
    await t.pump(const Duration(milliseconds: 100));
    expect(await moving(t), isTrue);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('background suspends motion and foreground restores it', (t) async {
    await t.pumpWidget(const ProviderScope(child: MaterialApp(home: Kiddo())));
    await t.pump(const Duration(milliseconds: 100));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await t.pump();
    expect(await moving(t), isFalse);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(await moving(t), isTrue);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('parent encounter remains usable on small screen with large text', (t) async {
    t.view.physicalSize = const Size(640, 1136);
    t.view.devicePixelRatio = 2;
    t.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpWidget(
      ProviderScope(
        overrides: [ambientMotionProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(onPressed: () => showGoldenHello(context), child: const Text('Golden')),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Golden'));
    await t.pumpAndSettle();
    expect(find.text('Szop’en von Ekran'), findsOneWidget);
    await t.ensureVisible(find.text('Masz coś jeszcze?'));
    await t.tap(find.text('Masz coś jeszcze?'));
    await t.pump();
    expect(pose(t), SzopPose.klaszcze, reason: 'amused: he claps');
    await t.pump(const Duration(milliseconds: 1200));
    expect(pose(t), SzopPose.chytry, reason: 'back to his cheeky self');
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.ensureVisible(find.text('Wybieram zabawę'));
    await t.tap(find.text('Wybieram zabawę'));
    await t.pumpAndSettle();
    expect(find.text('Szop’en von Ekran'), findsNothing);
  });
}
