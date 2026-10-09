import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/theme/appearance.dart';
import 'package:audiokiddo/features/purchases/after_free_play.dart';
import 'package:audiokiddo/features/purchases/offer_catalog.dart';
import 'package:audiokiddo/features/purchases/purchase_controller.dart';
import 'package:audiokiddo/features/purchases/store_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StoreProduct product(String id, double price) => StoreProduct(
  id: id,
  title: id,
  price: '$price zł',
  kind: StoreProductKind.oneTime,
  rawPrice: price,
  currencyCode: 'PLN',
);

/// A store that never answers (StoreKit without products in a test build).
class SilentStore implements StoreGateway {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<StoreProduct>> products(Set<String> ids) => Completer<List<StoreProduct>>().future;

  @override
  Stream<List<StorePurchase>> get purchases => const Stream.empty();

  @override
  Future<void> buy(StoreProduct product, {String? accountToken}) async {}

  @override
  Future<void> restore() async {}

  @override
  Future<void> complete(StorePurchase purchase) async {}
}

void main() {
  final catalog = parseCatalog(
    jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>,
  ).catalog;

  test('a year of the subscription against packs bought one by one', () {
    final s = subscriptionSavings(
      packs: [product('a', 49.99), product('b', 49.99), product('c', 69.99)],
      yearly: product(ProductIds.yearly, 239.88),
      monthly: product(ProductIds.monthly, 24.99),
    )!;
    expect(s.packsToday, closeTo(169.97, .001));
    expect(s.yearValue, closeTo(169.97 + 12 * 169.97 / 3, .001), reason: 'plus a new pack every month');
    expect(s.saving, closeTo(s.yearValue - 239.88, .001));
    expect(s.vsMonthly, closeTo(60, .001));
    expect(subscriptionSavings(packs: const [], yearly: null, monthly: null), isNull);
  });

  test('after a free play: the next free one not heard yet, for the child\'s age', () {
    final free = catalog.items.where((i) => i.isFree && i.kind == ContentKind.audioGame).toList();
    final next = nextFreePlay(catalog, after: free.first.id, heard: {free.first.id}, age: 9);
    expect(next, isNotNull);
    expect(next!.isFree, isTrue);
    expect(next.id, isNot(free.first.id));
    final young = nextFreePlay(catalog, after: 'x', heard: const {}, age: 3);
    expect(young == null || young.ageMin <= 3, isTrue);
    expect(nextFreePlay(catalog, after: 'x', heard: {for (final i in free) i.id}, age: 9), isNull);
  });

  test('a store that never answers shows the reference prices and refuses to hang', () async {
    final store = PreviewStoreGateway(SilentStore(), timeout: const Duration(milliseconds: 50));
    final products = await store.products({ProductIds.yearly, 'pl.audiokiddo.pack.wyobraznia'});
    expect(
      {for (final p in products) p.id: p.price},
      {ProductIds.yearly: '269,99 zł', 'pl.audiokiddo.pack.wyobraznia': '49,99 zł'},
    );
    await expectLater(store.buy(products.first), throwsA(isA<StoreNotReady>()));
  });

  test('automatic look: light by day, dark from 20:00 to 6:00', () {
    expect(effectiveThemeMode(ThemeMode.system, DateTime(2026, 10, 5, 12)), ThemeMode.light);
    expect(effectiveThemeMode(ThemeMode.system, DateTime(2026, 10, 5, 20)), ThemeMode.dark);
    expect(effectiveThemeMode(ThemeMode.system, DateTime(2026, 10, 6, 5, 59)), ThemeMode.dark);
    expect(effectiveThemeMode(ThemeMode.light, DateTime(2026, 10, 5, 22)), ThemeMode.light);
    expect(nextAppearanceChange(DateTime(2026, 10, 5, 12)), DateTime(2026, 10, 5, 20));
    expect(nextAppearanceChange(DateTime(2026, 10, 5, 21)), DateTime(2026, 10, 6, 6));
  });
}
