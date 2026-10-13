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

  test('every pack and both bundles are on sale; bundles hold the right packs', () {
    final ids = shopProductIds(catalog);
    for (final p in catalog.packs) {
      expect(ids, contains(p.storeProductId));
    }
    expect(bundlePacks(ProductIds.bundleTwo, catalog).map((p) => p.id), unorderedEquals(bundleTwoPacks));
    expect(bundlePacks(ProductIds.bundleThree, catalog).length, catalog.packs.length);
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

    testWidgets('shows the subscription, packs with a free taste and bundle savings', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Sklep').last);
      await tester.pumpAndSettle();
      // The subscription first, said simply: crossed-out monthly price, the yearly per month.
      expect(find.text('Abonament AudioKiddo'), findsOneWidget);
      expect(find.text('NAJLEPIEJ SIĘ OPŁACA'), findsOneWidget);
      // Yearly first, with the cloud saying how much it saves and the year crossed out
      // against twelve months; one subscription, no plans by the number of children.
      expect(find.text('Rocznie'), findsOneWidget);
      expect(find.textContaining('oszczędzasz 89,89'), findsOneWidget);
      expect(find.textContaining('359,88'), findsOneWidget, reason: '12 × 29,99 crossed out');
      expect(find.textContaining('22,50'), findsWidgets);
      expect(find.text('2 dzieci'), findsNothing);
      expect(find.text('3–5 dzieci'), findsNothing);
      expect(find.text('Wypróbuj 7 dni za darmo'), findsOneWidget);
      await tester.tap(find.text('Miesięcznie'));
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'^29,99\s+zł / miesiąc$')), findsOneWidget);
      // Buying for good is folded below.
      expect(find.text('Detektyw'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Wolisz kupić pakiet na zawsze?'),
        200,
        scrollable: mainScroll,
      );
      await tester.tap(find.text('Wolisz kupić pakiet na zawsze?'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Detektyw').first, 200, scrollable: mainScroll);
      expect(find.textContaining('Za darmo:'), findsWidgets);
      await tester.scrollUntilVisible(find.textContaining('taniej o 9,99'), 200, scrollable: mainScroll);
      expect(find.textContaining('taniej o 9,98'), findsOneWidget, reason: 'three packs: 169,97 − 159,99');
      await tester.scrollUntilVisible(
        find.text('Masz już dostęp z audiokiddo.pl?'),
        200,
        scrollable: mainScroll,
      );
    });

    testWidgets('a pack page sells; owned packs say so', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Sklep').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Wolisz kupić pakiet na zawsze?'),
        200,
        scrollable: mainScroll,
      );
      await tester.tap(find.text('Wolisz kupić pakiet na zawsze?'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Wyobraźnia').first, 200, scrollable: mainScroll);
      await tester.tap(find.text('Wyobraźnia').first);
      await tester.pumpAndSettle();
      final packScroll = find
          .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .last;
      await tester.scrollUntilVisible(find.text('Wypróbuj za darmo'), 200, scrollable: packScroll);
      expect(find.text('Wypróbuj za darmo'), findsOneWidget);
      expect(
        find.textContaining('Wszystkie pakiety za 22,50'),
        findsOneWidget,
        reason: 'the subscription first',
      );
      await tester.tap(find.text('albo tylko Wyobraźnia na zawsze · 49,99 zł'));
      await tester.pumpAndSettle();
      expect(
        find.byType(ParentalGateScreen),
        askInParentArea ? findsOneWidget : findsNothing,
        reason: 'the parent area buys without the number question',
      );
    });

    testWidgets('the pack page offers films and materials', (tester) async {
      await pumpApp(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/pakiet/detektyw');
      await tester.pumpAndSettle();
      final scroll = find
          .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .last;
      await tester.scrollUntilVisible(find.text('Filmy i materiały do zabaw'), 200, scrollable: scroll);
      await Scrollable.ensureVisible(tester.element(find.text('Filmy i materiały do zabaw')), alignment: .4);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filmy i materiały do zabaw'));
      await tester.pumpAndSettle();
      expect(
        find.byType(ParentalGateScreen),
        askInParentArea ? findsOneWidget : findsNothing,
        reason: 'the parent area opens links without the number question',
      );
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

    testWidgets('after a free play from a pack: the pack or the subscription', (tester) async {
      await pumpApp(tester);
      final free = catalog.items.firstWhere((i) => i.isFree && i.packId == 'wyobraznia');
      await showOffer(tester, free);
      expect(find.text('Brawo! Lecimy dalej?'), findsOneWidget);
      expect(find.text('Następna darmowa zabawa'), findsOneWidget, reason: 'another free play first');
      expect(find.text('Abonament AudioKiddo'), findsOneWidget);
      expect(find.textContaining('Nowy pakiet co miesiąc'), findsOneWidget);
      expect(find.textContaining('albo tylko pakiet Wyobraźnia na zawsze'), findsOneWidget);
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
      await tester.tap(find.text('Sklep').last);
      await tester.pumpAndSettle();
      expect(find.text('Masz pełny dostęp'), findsOneWidget);
      expect(find.text('Abonament AudioKiddo'), findsNothing);
      await tester.scrollUntilVisible(find.text('Masz ten pakiet').first, 200, scrollable: mainScroll);
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
    expect(find.text('Abonament i pakiety'), findsOneWidget, reason: 'the plans as a closable page');
  });
}
