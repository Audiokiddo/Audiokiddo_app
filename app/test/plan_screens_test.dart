import 'dart:async';

import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/player/player_providers.dart';
import 'package:audiokiddo/features/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';
import 'queue_runner_test.dart' show QueueAudio;
import 'session_test.dart' show FakeSessionAudio;

void main() {
  // 17:00: inside Start's dinner window.
  final evening = DateTime(2026, 10, 16, 17);

  Future<FakeSessionAudio> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = memoryDatabase();
    addTearDown(db.close);
    final audio = FakeSessionAudio();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(db),
          clockProvider.overrideWithValue(() => evening),
          sessionAudioProvider.overrideWithValue(audio),
          sessionTimeScaleProvider.overrideWithValue(0.001),
          audioHandlerProvider.overrideWithValue(QueueAudio()),
        ],
        child: const AudioKiddoApp(),
      ),
    );
    await tester.pumpAndSettle();
    return audio;
  }

  /// Scrolls until [finder] is built and sits near the top, clear of the floating tab bar.
  Future<void> bringUp(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 150, scrollable: find.byType(Scrollable).first);
    await Scrollable.ensureVisible(tester.element(finder), alignment: .2);
    await tester.pumpAndSettle();
  }

  GoRouter router(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));

  testWidgets('the whole Teraz card (after kindergarten at 17:00) opens the plan, not only its button', (tester) async {
    await pump(tester);
    final card = find.text('Po przedszkolu');
    await bringUp(tester, card);
    // The title, outside the button.
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.textContaining('Plan:'), findsOneWidget);
    await bringUp(tester, find.text('Włącz'));
    expect(find.text('Włącz'), findsOneWidget);
  });

  testWidgets('the dinner plan is edited, then runs with a countdown and a plan sheet', (tester) async {
    final audio = await pump(tester);
    unawaited(router(tester).push('/obiad'));
    await tester.pumpAndSettle();
    expect(find.text('Na ile?'), findsOneWidget);
    for (final m in ['15 min', '25 min', '40 min']) {
      expect(find.text(m), findsOneWidget);
    }
    // Drop the first play of the plan.
    final remove = find.byIcon(Icons.close_rounded);
    final before = remove.evaluate().length;
    expect(before, greaterThan(1));
    await tester.tap(remove.first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_rounded).evaluate().length, before - 1);
    // More time adds plays.
    await bringUp(tester, find.text('+10 min'));
    await tester.tap(find.text('+10 min'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close_rounded).evaluate().length, greaterThanOrEqualTo(before - 1));

    await bringUp(tester, find.text('Włącz'));
    await tester.tap(find.text('Włącz'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('OBIAD BEZ WOŁANIA'), findsOneWidget);
    expect(audio.log.where((l) => l.startsWith('item:')), isNotEmpty);
    // The plan button shows how long is left and opens the editor.
    final planButton = find.textContaining('· plan');
    expect(planButton, findsOneWidget);
    expect(find.textContaining('Zostało'), findsWidgets);
    await tester.tap(planButton);
    await tester.pumpAndSettle();
    expect(find.text('Dodaj czas'), findsOneWidget);
    expect(find.text('+5 min'), findsOneWidget);
    Navigator.of(tester.element(find.text('Dodaj czas'))).pop();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Zakończ').hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Zakończ'));
    await tester.pumpAndSettle();
  });

  testWidgets('a ride: three suggested times and "Własny" in one row, with an editable plan', (tester) async {
    await pump(tester);
    unawaited(router(tester).push('/podroz'));
    await tester.pumpAndSettle();
    for (final m in ['15 min', '30 min', '60 min', 'Własny']) {
      expect(find.text(m), findsOneWidget);
    }
    expect(find.text('45 min'), findsNothing);
    final fifteen = tester.getTopLeft(find.text('15 min')).dy;
    final own = tester.getTopLeft(find.text('Własny')).dy;
    expect((fifteen - own).abs(), lessThan(8), reason: 'all four in the same row');
    expect(find.textContaining('Plan:'), findsOneWidget);
    expect(find.text('Dodaj czas'), findsOneWidget);
    await tester.tap(find.text('60 min'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Plan:'), findsOneWidget);
  });

  testWidgets('a card on Start closes with a cross, stays closed and comes back from Więcej', (tester) async {
    await pump(tester);
    final card = find.text('Po przedszkolu');
    await bringUp(tester, card);
    expect(card, findsOneWidget);
    final cross = find.descendant(
      of: find.ancestor(of: card, matching: find.byType(InkWell)).first,
      matching: find.byTooltip('Ukryj tę kartę'),
    );
    await tester.tap(cross);
    await tester.pumpAndSettle();
    expect(find.text('Po przedszkolu'), findsNothing);
    expect(find.textContaining('Ukryto: Teraz'), findsOneWidget);

    // Back in Więcej → Ustawienia i zgody → Karty na Starcie.
    await tester.tap(find.byIcon(Icons.menu_rounded).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Co potrafi AudioKiddo'), 200, scrollable: find.byWidget(tester.widget(find.ancestor(of: find.text('Na co dzień'), matching: find.byType(Scrollable)).first)));
    await tester.tap(find.text('Ustawienia i zgody'));
    await tester.pumpAndSettle();
    final sw = find.widgetWithText(SwitchListTile, 'Teraz: podpowiedź na tę porę dnia');
    await bringUp(tester, sw);
    expect(find.text('Karty na Starcie'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(sw).value, isFalse);
    await tester.tap(sw);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    final startTab = find.byIcon(Icons.home_outlined).hitTestable();
    expect(startTab, findsOneWidget);
    await tester.tap(startTab);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Po przedszkolu'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Po przedszkolu'), findsOneWidget);
  });
}
