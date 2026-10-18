import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/parental_gate/gate_challenge.dart';
import 'package:audiokiddo/features/parental_gate/parental_gate.dart';
import 'package:audiokiddo/features/purchases/after_free_play.dart';
import 'package:audiokiddo/features/purchases/offer_catalog.dart';
import 'package:audiokiddo/features/purchases/shop.dart';
import 'package:audiokiddo/features/purchases/store_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'screens_test.dart' show mainScroll, pumpApp;

StoreProduct product(String id, double price, {String currency = 'PLN'}) => StoreProduct(
  id: id,
  title: id,
  price: '$price',
  kind: StoreProductKind.oneTime,
  rawPrice: price,
  currencyCode: currency,
);

void main() {
  final catalog = parseCatalog(
    jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>,
  ).catalog;

  test('bundle savings are the honest difference, only in one currency', () {
    final bundle = product(ProductIds.bundleTwo, 89.99);
    expect(bundleSavings(bundle, [product('a', 49.99), product('b', 49.99)]), closeTo(9.99, .001));
    expect(bundleSavings(bundle, [product('a', 49.99), null]), isNull, reason: 'a price is missing');
    expect(bundleSavings(bundle, [product('a', 49.99), product('b', 49.99, currency: 'EUR')]), isNull);
    expect(bundleSavings(product('x', 120), [product('a', 49.99), product('b', 49.99)]), isNull);
  });

  test('yearly discount is rounded down, never promised when unknown', () {
    final monthly = product(ProductIds.monthly, 24.99);
    expect(yearlyDiscountPercent(product(ProductIds.yearly, 239.88), monthly), 20);
    expect(yearlyDiscountPercent(product(ProductIds.yearly, 400), monthly), isNull);
  });

  test('Polish plural for plays, money in złoty', () {
    expect([1, 2, 4, 5, 9, 12, 14, 22, 25].map(playsCount), [
      '1 zabawa',
      '2 zabawy',
      '4 zabawy',
      '5 zabaw',
      '9 zabaw',
      '12 zabaw',
      '14 zabaw',
      '22 zabawy',
      '25 zabaw',
    ]);
    expect(formatMoney(9.99, 'PLN'), allOf(contains('9,99'), contains('zł')));
  });

  test('only the subscription is on sale (2026-10-13); bundle contents still known for old buyers', () {
    expect(shopProductIds(catalog), ProductIds.subscriptions);
    expect(productIdsFor(catalog.items.first, catalog), ProductIds.subscriptions);
    expect(bundlePacks(ProductIds.bundleTwo, catalog).map((p) => p.id), unorderedEquals(bundleTwoPacks));
  });

  test('after a free taste the rest of that pack is suggested, unless the family owns it', () {
    final free = catalog.items.firstWhere((i) => i.isFree && i.packId != null);
    final results = [ActivityResult(childId: 'c', itemId: free.id, at: DateTime(2026, 10, 1), seconds: 300)];
    final next = nextPackSuggestion(results: results, catalog: catalog, scopes: const {});
    expect(next?.tried.id, free.id);
    expect(next?.pack.pack.id, free.packId);
    expect(
      nextPackSuggestion(results: results, catalog: catalog, scopes: {Scopes.pack(free.packId!)}),
      isNull,
    );
    expect(nextPackSuggestion(results: results, catalog: catalog, scopes: {Scopes.allContent}), isNull);
    final unfinished = [
      ActivityResult(childId: 'c', itemId: free.id, at: DateTime(2026, 10, 1), seconds: 20, completed: false),
    ];
    expect(nextPackSuggestion(results: unfinished, catalog: catalog, scopes: const {}), isNull);
  });

  group('Shop tab', () {
    setUp(() => debugGateChallengeFactory = () => GateChallenge.fixed(47, [74, 47, 12, 33]));
    tearDown(() => debugGateChallengeFactory = null);

    testWidgets('shows only the subscription: free plays and the plan, no packs for good', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Abonament').last);
      await tester.pumpAndSettle();
      // Simpler since 2026-10-18: the offer itself, no list of ways. No pack for good.
      expect(find.bySemanticsLabel(RegExp('Pakiet na zawsze')), findsNothing);
      expect(find.text('Abonament audiokiddo'), findsOneWidget);
      expect(find.text('NAJLEPIEJ SIĘ OPŁACA'), findsOneWidget);
      // Yearly first; the year is compared with twelve months, never crossed out (Omnibus).
      expect(find.text('Rocznie'), findsOneWidget);
      expect(find.textContaining('oszczędzasz 89,89'), findsOneWidget);
      expect(find.textContaining('12 × 29,99'), findsOneWidget);
      expect(find.textContaining('22,50'), findsWidgets);
      expect(find.textContaining('co tydzień'), findsWidgets);
      await tester.tap(find.text('Miesięcznie'));
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'^29,99\s+zł / miesiąc$')), findsOneWidget);
      expect(find.text('Wolisz kupić pakiet na zawsze?'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Masz już dostęp z audiokiddo.pl?'),
        200,
        scrollable: mainScroll,
      );
      expect(find.textContaining('taniej o'), findsNothing);
    });

    testWidgets('a pack page offers the subscription, not the pack', (tester) async {
      await pumpApp(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/pakiet/wyobraznia');
      await tester.pumpAndSettle();
      final packScroll = find
          .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .last;
      await tester.scrollUntilVisible(find.text('Wypróbuj za darmo'), 200, scrollable: packScroll);
      expect(find.text('Wypróbuj za darmo'), findsOneWidget);
      // The amount billed first, the month beside it (App Store 3.1.2).
      expect(find.textContaining('Abonament roczny: 269,99'), findsOneWidget);
      expect(find.textContaining('ok. 22,50'), findsOneWidget);
      expect(find.textContaining('na zawsze ·'), findsNothing);
    });

    testWidgets('the pack page has no films or Drive links any more', (tester) async {
      await pumpApp(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/pakiet/detektyw');
      await tester.pumpAndSettle();
      expect(find.text('Filmy i materiały do zabaw'), findsNothing);
    });

    Future<void> showOffer(WidgetTester tester, ContentItem item) async {
      Navigator.of(tester.element(find.byType(Scaffold).first)).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: ListView(children: [AfterFreePlayOffer(item: item)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('after a free play from a pack: the subscription', (tester) async {
      await pumpApp(tester);
      final free = catalog.items.firstWhere((i) => i.isFree && i.packId == 'wyobraznia');
      await showOffer(tester, free);
      // First the question; "Tak, od razu" opens the offer.
      expect(find.text('Czy dziecko chce jeszcze?'), findsOneWidget);
      expect(find.text('Abonament audiokiddo'), findsNothing);
      await tester.tap(find.text('Tak, od razu'));
      await tester.pumpAndSettle();
      expect(find.text('Jest ciąg dalszy. Tak go otworzycie:'), findsOneWidget);
      expect(find.text('Następna darmowa zabawa'), findsOneWidget, reason: 'another free play first');
      expect(find.text('Abonament audiokiddo'), findsOneWidget);
      expect(find.textContaining('2 nowe zabawy co tydzień'), findsOneWidget);
      expect(find.textContaining('na zawsze'), findsNothing, reason: 'packs are not sold any more');
      await tester.ensureVisible(find.text('Wypróbuj 7 dni za darmo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wypróbuj 7 dni za darmo'));
      await tester.pumpAndSettle();
      expect(
        find.byType(ParentalGateScreen),
        askInParentArea ? findsOneWidget : findsNothing,
        reason: 'the parent area buys without the number question',
      );
    });

    testWidgets('"Nie dziś" after a free play: the next free play, no offer', (tester) async {
      await pumpApp(tester);
      final free = catalog.items.firstWhere((i) => i.isFree && i.packId == 'wyobraznia');
      await showOffer(tester, free);
      await tester.tap(find.text('Nie dziś'));
      await tester.pumpAndSettle();
      expect(find.text('Następna darmowa zabawa'), findsOneWidget);
      expect(find.text('Abonament audiokiddo'), findsNothing);
    });

    testWidgets('with the subscription everything is unlocked', (tester) async {
      await pumpApp(
        tester,
        entitlements: [
          Entitlement(
            scope: Scopes.allContent,
            status: EntitlementStatus.active,
            source: EntitlementSource.appStore,
          ),
        ],
      );
      // With the subscription the tab holds the downloads; the subscription is one tap away.
      await tester.tap(find.text('Pobrane').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Twój abonament'));
      await tester.pumpAndSettle();
      expect(find.text('Masz pełny dostęp'), findsOneWidget);
      expect(find.text('Abonament audiokiddo'), findsNothing);
      expect(find.byType(FilledButton), findsNothing, reason: 'nothing left to buy');
    });
  });

  testWidgets('Więcej: manage the subscription, change the plan or restore', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Więcej').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Zarządzaj subskrypcją'), 200, scrollable: mainScroll);
    expect(find.textContaining('miesięcznie albo rocznie'), findsOneWidget);
    await tester.tap(find.text('Zarządzaj subskrypcją'));
    await tester.pumpAndSettle();
    expect(find.text('Wybierz abonament'), findsOneWidget);
    expect(find.text('Przywróć zakupy'), findsOneWidget);
    await tester.tap(find.text('Wybierz abonament'));
    await tester.pumpAndSettle();
    expect(find.text('Abonament'), findsWidgets, reason: 'the plans as a closable page');
  });
}
