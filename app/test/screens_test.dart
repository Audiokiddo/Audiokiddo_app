import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/parental_gate/gate_challenge.dart';
import 'package:audiokiddo/features/parental_gate/parental_gate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Pumps the app with the bundled mock catalog (the same file the app ships in Etap 1).
Future<void> pumpApp(
  WidgetTester tester, {
  List<Entitlement> entitlements = const [],
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final db = memoryDatabase();
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(db),
        entitlementsProvider.overrideWithValue(entitlements),
        leaseStateProvider.overrideWithValue(LeaseState.valid),
      ],
      child: const AudioKiddoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// The vertical page scroll (shelves inside it scroll horizontally).
Finder get mainScroll =>
    find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

Future<void> openLibrary(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.library_music_rounded));
  await tester.pumpAndSettle();
}

Future<void> openItem(WidgetTester tester, String title) async {
  await tester.scrollUntilVisible(find.text(title), 200, scrollable: mainScroll);
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Wstecz'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows greeting, featured game and packs', (tester) async {
    await pumpApp(tester);
    expect(find.text('Czas na zabawę!'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Zabawa dnia'), 200, scrollable: mainScroll);
    expect(find.text('Zaginiony skarb'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Na drogę'), 200, scrollable: mainScroll);
    expect(find.text('10 zabaw · 3+'), findsWidgets);
  });

  testWidgets('pack shortcut opens the filtered library', (tester) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(find.text('Na drogę'), 200, scrollable: mainScroll);
    final packCard = find.text('10 zabaw · 3+').first;
    await tester.ensureVisible(packCard);
    await tester.pumpAndSettle();
    await tester.tap(packCard);
    await tester.pumpAndSettle();
    expect(find.text('10 pozycji'), findsOneWidget);
    expect(find.text('Magiczny sklep'), findsOneWidget);
  });

  testWidgets('free item can be played, paid item asks to unlock', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);

    await openItem(tester, 'Magiczny sklep');
    expect(find.text('Słuchaj'), findsOneWidget);
    await goBack(tester);

    await openItem(tester, 'Zaginiony skarb');
    expect(find.text('Odblokuj'), findsOneWidget);
  });

  testWidgets('pack purchase unlocks its games', (tester) async {
    await pumpApp(
      tester,
      entitlements: [
        Entitlement(
          scope: Scopes.pack('wyobraznia'),
          status: EntitlementStatus.active,
          source: EntitlementSource.woocommerce,
        ),
      ],
    );
    await openLibrary(tester);
    await openItem(tester, 'Zaginiony skarb');
    expect(find.text('Słuchaj'), findsOneWidget);
    await goBack(tester);
    await openItem(tester, 'Co to za przedmiot?');
    expect(find.text('Odblokuj'), findsOneWidget, reason: 'other packs stay locked');
  });

  testWidgets('screens have no overflow with large text', (tester) async {
    await pumpApp(tester, textScale: 1.6);
    await tester.drag(mainScroll, const Offset(0, -4000));
    await tester.pumpAndSettle();
    await openLibrary(tester);
    await openItem(tester, 'Złodziej naszyjnika');
    await tester.drag(mainScroll, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('favourite appears on the Moje tab', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);
    await openItem(tester, 'Magiczny sklep');
    await tester.tap(find.byTooltip('Dodaj do ulubionych'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Usuń z ulubionych'), findsOneWidget);
    await goBack(tester);
    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Magiczny sklep'), findsOneWidget);
    expect(find.text('Pobierz zabawy przed podróżą. Bez nich po 10 minutach jazdy padnie pytanie: „daleko jeszcze?”.'), findsOneWidget);
  });

  testWidgets('playable item offers a download with its size', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);
    await openItem(tester, 'Magiczny sklep');
    expect(find.textContaining('Pobierz ('), findsOneWidget);
  });

  group('parental gate', () {
    setUp(() => debugGateChallengeFactory = () => GateChallenge.fixed(47, [74, 47, 12, 33]));
    tearDown(() => debugGateChallengeFactory = null);

    testWidgets('unlock asks an adult first, then shows store prices', (tester) async {
      await pumpApp(tester);
      await openLibrary(tester);
      await openItem(tester, 'Zaginiony skarb');
      await tester.tap(find.text('Odblokuj'));
      await tester.pumpAndSettle();
      expect(find.text('czterdzieści siedem'), findsOneWidget);

      await tester.tap(find.text('74'));
      await tester.pumpAndSettle();
      expect(find.text('To nie ta liczba. Spróbuj jeszcze raz.'), findsOneWidget);

      await tester.tap(find.text('47'));
      await tester.pumpAndSettle();
      expect(find.text('Odblokuj zabawy'), findsOneWidget);
      expect(find.textContaining('7 dni za darmo, zanim dojedziemy'), findsOneWidget, reason: 'the car gag');
      await tester.drag(mainScroll, const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.text('7 dni za darmo, potem 149,99 zł / rok'), findsOneWidget);
      expect(find.text('49,99 zł'), findsWidgets);
      await tester.scrollUntilVisible(find.textContaining('odnawia się automatycznie'), 200, scrollable: mainScroll);
      expect(find.text('Przywróć zakupy'), findsOneWidget);
    });

    testWidgets('kids mode: only playable games, no escape, exit through the gate', (tester) async {
      await pumpApp(tester);
      // Scroll a section further, so the card is out from under the floating tab bar.
      await tester.scrollUntilVisible(find.text('Zabawa dnia'), 200, scrollable: mainScroll);
      await tester.tap(find.text('Tryb dziecka'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Włącz tryb dziecka'));
      await tester.pumpAndSettle();

      expect(find.text('Moje zabawy'), findsOneWidget);
      expect(find.text('Magiczny sklep'), findsOneWidget);
      expect(
        find.text('Zaginiony skarb'),
        findsNothing,
        reason: 'locked content is hidden, not shown with a lock',
      );
      expect(find.byType(NavigationBar), findsNothing);

      // A deep link or programmatic navigation cannot leave kids mode.
      GoRouter.of(tester.element(find.text('Moje zabawy'))).go('/biblioteka');
      await tester.pumpAndSettle();
      expect(find.text('Moje zabawy'), findsOneWidget);

      await tester.tap(find.byTooltip('Dla rodzica'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('74'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Anuluj'));
      await tester.pumpAndSettle();
      expect(find.text('Moje zabawy'), findsOneWidget, reason: 'cancelled gate keeps kids mode');

      await tester.tap(find.byTooltip('Dla rodzica'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('47'));
      await tester.pumpAndSettle();
      expect(find.text('Czas na zabawę!'), findsOneWidget);
    });
  });
}
