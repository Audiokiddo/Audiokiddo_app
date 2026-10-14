import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/catalog/home_screen.dart' show isSickSeason;
import 'package:audiokiddo/features/home/quick_pick.dart' show showQuickPick;
import 'package:audiokiddo/features/session/session_screens.dart' show TripScreen;
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

/// Opens the library on its pack view ("Wszystkie zabawy", the flat list, is the way in).
Future<void> openLibrary(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.auto_stories_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pakiety').first);
  await tester.pumpAndSettle();
}

Future<void> openItem(WidgetTester tester, String title) async {
  final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
  router.go('/biblioteka?typ=audio_game');
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text(title), 200, scrollable: mainScroll);
  await Scrollable.ensureVisible(tester.element(find.text(title)), alignment: .5);
  await tester.pumpAndSettle();
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

/// Scrolls Start until [text] is clear of the floating tab bar, then taps it.
Future<void> tapOnStart(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(find.text(text), 100, scrollable: mainScroll);
  // Up to the top of the list, well above the tab bar.
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Wstecz'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('"Moje pakiety" only in the library (Start sells nothing per pack): free plays', (tester) async {
    await pumpApp(tester);
    expect(find.text('Moje pakiety'), findsNothing, reason: 'Start has no pack shelf since 2026-10-13');
    expect(find.text('Wasze pakiety'), findsNothing);
    await openLibrary(tester);
    expect(find.textContaining('do włączenia od razu · w tym darmowe'), findsOneWidget);
    await tester.tap(find.text('Moje pakiety'));
    await tester.pumpAndSettle();
    expect(find.text('Wszystko tutaj możecie włączyć od razu.'), findsOneWidget);
    expect(find.text('Darmowe zabawy z pakietów'), findsOneWidget);
    expect(find.textContaining('za darmo'), findsWidgets);
    expect(find.text('Wasz pakiet'), findsNothing);
  });

  testWidgets('library opens on "Wszystkie zabawy": one flat list with a search that finds a play', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.auto_stories_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Wszystkie zabawy'), findsOneWidget);
    expect(find.text('Moje pakiety'), findsNothing, reason: 'packs are the other view');
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'magiczny');
    await tester.pumpAndSettle();
    expect(find.text('Magiczny sklep'), findsOneWidget);
    expect(find.text('Zaginiony skarb'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzzzqq');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nie znaleźliśmy takiej zabawy'), findsOneWidget);
  });

  testWidgets('library: a subscriber opens "Moje pakiety" and sees every pack', (tester) async {
    await pumpApp(
      tester,
      entitlements: const [
        Entitlement(scope: Scopes.allContent, status: EntitlementStatus.active, source: EntitlementSource.appStore),
      ],
    );
    await openLibrary(tester);
    expect(find.textContaining('do włączenia od razu · 3 pakiety'), findsOneWidget);
    await tester.tap(find.text('Moje pakiety'));
    await tester.pumpAndSettle();
    expect(find.text('Wasz pakiet'), findsWidgets);
    expect(find.text('Darmowe zabawy z pakietów'), findsNothing);
  });

  testWidgets('home: what to play today, six kinds of play, quick situations', (tester) async {
    await pumpApp(tester);
    expect(find.text('Co dziś robimy?'), findsOneWidget);
    for (final label in [
      'Mam 20 minut',
      'W podróży',
      'Na dobranoc',
      isSickSeason(DateTime.now()) ? 'Na leżąco' : 'Bez przygotowań',
    ]) {
      await tester.scrollUntilVisible(find.text(label), 200, scrollable: mainScroll);
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Kontynuuj słuchanie'), findsNothing, reason: 'nothing to continue yet, so no empty block');
    // Age and kinds of play right under the big tiles (2026-10-13), "Darmowe" first.
    await tester.scrollUntilVisible(find.text('3–4'), -200, scrollable: mainScroll);
    for (final label in ['3–4', '5–6', '7–9', 'Darmowe', 'Kreatywne']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Piosenki'), findsNothing, reason: 'no songs in the catalog yet, so no empty chip');
  });
  testWidgets('"Co teraz?" → "Jedziemy autem" opens the trip mode with the chosen time', (tester) async {
    await pumpApp(tester);
    showQuickPick(tester.element(find.text('Co dziś robimy?')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('45 min'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Jedziemy autem'));
    await tester.tap(find.text('Jedziemy autem'));
    await tester.pumpAndSettle();
    expect(find.byType(TripScreen), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '45 min'));
    expect(chip.selected, isTrue);
  });

  testWidgets('search from Start has a visible back action', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Szukaj zabawy'));
    await tester.pumpAndSettle();
    expect(find.text('Wpisz tytuł zabawy lub piosenki'), findsOneWidget, reason: 'the flat list with its search field');
    expect(find.byTooltip('Wróć'), findsOneWidget);
    await tester.tap(find.byTooltip('Wróć'));
    await tester.pumpAndSettle();
    expect(find.text('Co dziś robimy?'), findsOneWidget);
  });

  testWidgets('rescue flow has time, mood and material selection', (tester) async {
    await pumpApp(tester);
    await tapOnStart(tester, 'Mam 20 minut');
    expect(find.text('Ile masz czasu?'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pokaż propozycje'), 200, scrollable: mainScroll);
    await tester.tap(find.text('Pokaż propozycje'));
    await tester.pumpAndSettle();
    expect(find.text('Mamy coś.'), findsOneWidget);
  });
  testWidgets('category shortcut opens the filtered library', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);
    await tester.scrollUntilVisible(find.text('Fabularne'), 200, scrollable: mainScroll);
    await Scrollable.ensureVisible(tester.element(find.text('Fabularne')), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fabularne'));
    await tester.pumpAndSettle();
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

  testWidgets('an owned case file can be printed or sent, one or all at once', (tester) async {
    await pumpApp(
      tester,
      entitlements: [
        Entitlement(
          scope: Scopes.pack('detektyw'),
          status: EntitlementStatus.active,
          source: EntitlementSource.woocommerce,
        ),
      ],
    );
    await openLibrary(tester);
    await openItem(tester, 'Złodziej naszyjnika');
    await tester.scrollUntilVisible(find.text('Ta sprawa: drukuj lub wyślij'), 200, scrollable: mainScroll);
    expect(find.text('Wydrukuj wszystkie naraz'), findsOneWidget);
    expect(
      find.text('Rozwiązuj w telefonie'),
      findsNothing,
      reason: 'the case is solved away from the phone',
    );
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

  testWidgets('favourite appears on the Ulubione screen', (tester) async {
    await pumpApp(tester);
    await openLibrary(tester);
    await openItem(tester, 'Magiczny sklep');
    await tester.tap(find.byTooltip('Dodaj do ulubionych'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Usuń z ulubionych'), findsOneWidget);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/ulubione');
    await tester.pumpAndSettle();
    expect(find.text('Magiczny sklep'), findsOneWidget);
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

    testWidgets('unlock shows store prices', (tester) async {
      await pumpApp(tester);
      await openLibrary(tester);
      await openItem(tester, 'Zaginiony skarb');
      await tester.tap(find.text('Odblokuj'));
      await tester.pumpAndSettle();
      expect(find.text('czterdzieści siedem'), findsNothing, reason: 'looking at prices needs no gate');
      expect(find.text('Odblokuj zabawy'), findsOneWidget);
      expect(find.textContaining('7 dni za darmo, zanim dojedziemy'), findsOneWidget, reason: 'the car gag');
      await tester.drag(mainScroll, const Offset(0, -350));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Wypróbuj 7 dni za darmo'), 200, scrollable: mainScroll);
      expect(find.textContaining('Potem 269,99 zł za rok'), findsOneWidget);
      // Only the subscription: nothing for good (2026-10-13).
      expect(find.text('Na zawsze, bez subskrypcji'), findsNothing);
      await tester.scrollUntilVisible(
        find.textContaining('odnawia się automatycznie'),
        200,
        scrollable: mainScroll,
      );
      expect(find.text('Przywróć zakupy'), findsOneWidget);
    });

    testWidgets('kids mode: only playable games, no escape, exit through the gate', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tryb dziecka'));
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
      expect(find.text('Co dziś robimy?'), findsOneWidget);
    });
  });
}
