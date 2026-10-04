import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/parental_gate/gate_challenge.dart';
import 'package:audiokiddo/features/parental_gate/parental_gate.dart';
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
    expect(yearlyDiscountPercent(product(ProductIds.yearly, 149.99), monthly), 49);
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
      await tester.tap(find.byTooltip('Sklep'));
      await tester.pumpAndSettle();
      expect(find.text('Wszystko w jednym'), findsOneWidget);
      expect(find.text('7 dni za darmo'), findsOneWidget);
      expect(find.textContaining('taniej o 49%'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Detektyw'), 200, scrollable: mainScroll);
      expect(find.textContaining('Za darmo:'), findsWidgets);
      await tester.scrollUntilVisible(find.textContaining('taniej o 9,99'), 200, scrollable: mainScroll);
      expect(find.textContaining('taniej o 9,98'), findsOneWidget, reason: 'three packs: 169,97 − 159,99');
      await tester.scrollUntilVisible(
        find.text('Masz już dostęp z audiokiddo.pl?'),
        200,
        scrollable: mainScroll,
      );
    });

    testWidgets('a pack page sells after the gate; owned packs say so', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byTooltip('Sklep'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Wyobraźnia'), 200, scrollable: mainScroll);
      await tester.tap(find.text('Wyobraźnia'));
      await tester.pumpAndSettle();
      final packScroll = find
          .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .last;
      await tester.scrollUntilVisible(find.text('Wypróbuj za darmo'), 200, scrollable: packScroll);
      expect(find.text('Wypróbuj za darmo'), findsOneWidget);
      await tester.tap(find.text('Kup pakiet · 49,99 zł'));
      await tester.pumpAndSettle();
      expect(find.text('czterdzieści siedem'), findsOneWidget, reason: 'buying asks an adult first');
    });

    testWidgets('the pack page offers the free guide for parents', (tester) async {
      await pumpApp(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/pakiet/detektyw');
      await tester.pumpAndSettle();
      final scroll = find
          .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .last;
      await tester.scrollUntilVisible(find.text('Przewodnik po pakiecie (PDF)'), 200, scrollable: scroll);
      await Scrollable.ensureVisible(
        tester.element(find.text('Przewodnik po pakiecie (PDF)')),
        alignment: .4,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Przewodnik po pakiecie (PDF)'));
      await tester.pumpAndSettle();
      expect(find.text('czterdzieści siedem'), findsOneWidget, reason: 'a link out asks an adult first');
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
      await tester.tap(find.byTooltip('Sklep'));
      await tester.pumpAndSettle();
      expect(find.text('Masz pełny dostęp'), findsOneWidget);
      expect(find.text('Wszystko w jednym'), findsNothing);
      await tester.scrollUntilVisible(find.text('Detektyw'), 200, scrollable: mainScroll);
      expect(find.text('Masz ten pakiet'), findsWidgets);
      expect(find.byType(FilledButton), findsNothing, reason: 'nothing left to buy');
    });
  });
}
