import 'dart:math';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/storage/database.dart';
import 'package:audiokiddo/core/storage/storage_providers.dart';
import 'package:audiokiddo/features/access/access_controller.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/kids_mode/kids_home_screen.dart';
import 'package:audiokiddo/features/kids_mode/kids_mode_controller.dart';
import 'package:audiokiddo/core/router.dart';
import 'package:audiokiddo/features/parental_gate/gate_challenge.dart';
import 'package:audiokiddo/features/purchases/fake_store.dart';
import 'package:audiokiddo/features/purchases/iap_store.dart';
import 'package:audiokiddo/features/purchases/offer_catalog.dart';
import 'package:audiokiddo/features/purchases/purchase_controller.dart';
import 'package:audiokiddo/features/purchases/store_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audiokiddo/features/purchases/shop.dart' show childSeats;
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('parental gate', () {
    test('Polish number words', () {
      expect(polishNumberWords(21), 'dwadzieścia jeden');
      expect(polishNumberWords(47), 'czterdzieści siedem');
      expect(polishNumberWords(90), 'dziewięćdziesiąt');
      expect(polishNumberWords(99), 'dziewięćdziesiąt dziewięć');
    });

    test('challenge has the target, its digit swap and four distinct options', () {
      for (var seed = 0; seed < 200; seed++) {
        final c = GateChallenge.random(Random(seed));
        final swapped = (c.target % 10) * 10 + c.target ~/ 10;
        expect(c.options.toSet(), hasLength(4));
        expect(c.options, containsAll([c.target, swapped]));
        expect(c.check(c.target), isTrue);
        expect(c.check(swapped), isFalse);
      }
    });

    test('three wrong answers lock the gate for 30 seconds', () {
      var now = DateTime(2026);
      final attempts = GateAttempts(clock: () => now);
      attempts
        ..recordFailure()
        ..recordFailure();
      expect(attempts.isLocked, isFalse);
      attempts.recordFailure();
      expect(attempts.isLocked, isTrue);
      now = now.add(const Duration(seconds: 31));
      expect(attempts.isLocked, isFalse);
    });
  });

  group('kids mode', () {
    test('redirect keeps kids mode inside /dziecko and parents outside it', () async {
      final db = memoryDatabase();
      addTearDown(db.close);
      final kids = KidsModeController(db);
      expect(kidsModeRedirect(kids, '/biblioteka'), isNull);
      expect(kidsModeRedirect(kids, '/dziecko'), '/');
      await kids.enter(age: 3, onlyDownloaded: false);
      for (final escape in ['/', '/biblioteka', '/zabawa/magiczny-sklep', '/sklep', '/moje/narzedzia']) {
        expect(kidsModeRedirect(kids, escape), '/dziecko', reason: escape);
      }
      expect(kidsModeRedirect(kids, '/dziecko/graj'), isNull);
    });

    test('kids mode survives an app restart', () async {
      final db = memoryDatabase();
      addTearDown(db.close);
      await KidsModeController(db).enter(age: 6, onlyDownloaded: true);
      final restarted = KidsModeController(db);
      await restarted.load();
      expect(restarted.active, isTrue);
      expect(restarted.settings.age, 6);
      expect(restarted.settings.onlyDownloaded, isTrue);
    });

    test('kids see only playable, age-appropriate (and optionally downloaded) items', () {
      ContentItem item(String id, int age) => ContentItem(
        id: id,
        kind: ContentKind.audioGame,
        title: id,
        parentDescription: '',
        ageMin: age,
        durationSec: 60,
        access: ContentAccess.free,
        audio: const [],
      );
      final catalog = Catalog(
        version: 1,
        packs: const [],
        items: [item('a', 3), item('b', 6), item('c', 3)],
        shelves: const [],
      );
      List<String> ids(KidsModeSettings s, {Set<String> downloaded = const {}}) => [
        for (final i in kidsItems(catalog, s, canPlay: (i) => i.id != 'c', downloaded: downloaded)) i.id,
      ];
      expect(ids(const KidsModeSettings(age: 3)), ['a']);
      expect(ids(const KidsModeSettings(age: 6)), ['a', 'b']);
      expect(ids(const KidsModeSettings(age: 6, onlyDownloaded: true), downloaded: {'b'}), ['b']);
    });
  });

  group('offers', () {
    late Catalog catalog;

    setUpAll(() async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      TestWidgetsFlutterBinding.ensureInitialized();
      catalog = await container.read(catalogProvider.future);
    });

    test('products map to scopes', () {
      expect(scopesForProduct(ProductIds.yearly, catalog), [Scopes.allContent, 'children:1']);
      expect(scopesForProduct(ProductIds.duoMonthly, catalog), [Scopes.allContent, 'children:2']);
      expect(scopesForProduct(ProductIds.familyYearly, catalog), [Scopes.allContent, 'children:5']);
      expect(SubscriptionPlan.forChildren(2), SubscriptionPlan.duo);
      expect(SubscriptionPlan.forChildren(4), SubscriptionPlan.family);
      // How many child profiles the subscription covers.
      expect(childSeats({'pack:wyobraznia'}), isNull, reason: 'no subscription, no limit');
      expect(childSeats({Scopes.allContent}), 99, reason: 'web shop: the whole family');
      expect(childSeats({Scopes.allContent, 'children:1'}), 1);
      expect(childSeats({Scopes.allContent, 'children:1', 'children:5'}), 5);
      expect(scopesForProduct('pl.audiokiddo.pack.detektyw', catalog), [Scopes.pack('detektyw')]);
      expect(scopesForProduct(ProductIds.bundleThree, catalog), hasLength(3));
      expect(scopesForProduct(ProductIds.bundleTwo, catalog), [
        Scopes.pack('slowa-i-wiedza'),
        Scopes.pack('wyobraznia'),
      ]);
      expect(scopesForProduct('pl.audiokiddo.item.mikstura', catalog), [Scopes.item('mikstura')]);
      expect(scopesForProduct('unknown', catalog), isEmpty);
    });

    test('offers for a Detektyw game skip the two-pack bundle', () {
      final ids = productIdsFor(catalog.item('gadajacy-smietnik'), catalog);
      expect(
        ids,
        containsAll(['pl.audiokiddo.pack.detektyw', ProductIds.bundleThree, 'pl.audiokiddo.item.gadajacy_smietnik']),
      );
      expect(ids, isNot(contains(ProductIds.bundleTwo)));
    });

    test('ISO billing periods', () {
      expect(isoPeriodDays('P7D'), 7);
      expect(isoPeriodDays('P1W'), 7);
      expect(isoPeriodDays('P1M'), 30);
      expect(isoPeriodDays('weird'), isNull);
    });
  });

  group('purchase flow', () {
    late AppDatabase db;
    late FakeStoreGateway store;
    late ProviderContainer container;

    ProviderContainer build({PurchaseVerifier? verifier}) => ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        storeGatewayProvider.overrideWithValue(store),
        if (verifier != null) purchaseVerifierProvider.overrideWithValue(verifier),
      ],
    );

    setUp(() {
      db = memoryDatabase();
      store = FakeStoreGateway();
    });

    tearDown(() async {
      container.dispose();
      await store.dispose();
      await db.close();
    });

    Future<void> buy(String productId) async {
      container.read(purchaseControllerProvider); // start listening to the store
      final product = (await store.products({productId})).single;
      await container.read(purchaseControllerProvider.notifier).buy(product);
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (container.read(purchaseControllerProvider).busyProductId == null) break;
      }
    }

    Set<String> scopes() => {for (final e in container.read(entitlementsProvider)) e.scope};

    test('verified pack purchase unlocks the pack and completes the transaction', () async {
      container = build();
      await container.read(accessProvider.future);
      await buy('pl.audiokiddo.pack.wyobraznia');
      expect(scopes(), contains(Scopes.pack('wyobraznia')));
      expect(store.completed, ['pl.audiokiddo.pack.wyobraznia']);
    });

    test('subscription grants all content', () async {
      container = build();
      await container.read(accessProvider.future);
      await buy(ProductIds.monthly);
      expect(scopes(), contains(Scopes.allContent));
    });

    test('when verification fails nothing is granted and the store keeps the transaction', () async {
      container = build(verifier: const UnavailablePurchaseVerifier());
      await container.read(accessProvider.future);
      await buy('pl.audiokiddo.pack.detektyw');
      expect(scopes(), isEmpty);
      expect(store.completed, isEmpty);
    });

    test('cancelled and pending purchases grant nothing', () async {
      container = build();
      await container.read(accessProvider.future);
      store.nextOutcome = PurchaseStatus.canceled;
      await buy('pl.audiokiddo.pack.detektyw');
      store.nextOutcome = PurchaseStatus.pending;
      await buy('pl.audiokiddo.pack.detektyw');
      expect(scopes(), isEmpty);
    });

    test('trial is offered once and disappears after subscribing', () async {
      container = build();
      expect((await store.products({ProductIds.yearly})).single.freeTrialDays, 7);
      await buy(ProductIds.yearly);
      expect((await store.products({ProductIds.yearly})).single.freeTrialDays, isNull);
    });
  });
}
