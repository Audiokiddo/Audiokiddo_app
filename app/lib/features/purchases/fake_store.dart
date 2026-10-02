import 'dart:async';

import 'store_gateway.dart';

/// Development store with the approved prices (ARCHITECTURE §7). Used in debug builds
/// until App Store Connect and Play Console are set up. Never used in release builds.
class FakeStoreGateway implements StoreGateway {
  FakeStoreGateway({this.trialDays = 7, this.nextOutcome = PurchaseStatus.purchased});

  /// Free trial offered to this (simulated) user; null = already used.
  int? trialDays;

  /// What the next `buy` produces — lets the developer screen and tests simulate
  /// cancellation, Ask to Buy (pending) and errors.
  PurchaseStatus nextOutcome;

  final _purchases = StreamController<List<StorePurchase>>.broadcast();
  final _owned = <String>{};
  final completed = <String>[];
  var _counter = 0;

  static const _prices = {
    'pl.audiokiddo.sub.monthly': '24,99 zł',
    'pl.audiokiddo.sub.yearly': '149,99 zł',
    'pl.audiokiddo.pack.wyobraznia': '49,99 zł',
    'pl.audiokiddo.pack.slowa_i_wiedza': '49,99 zł',
    'pl.audiokiddo.pack.detektyw': '69,99 zł',
    'pl.audiokiddo.bundle.two': '89,99 zł',
    'pl.audiokiddo.bundle.three': '159,99 zł',
  };

  static const _titles = {
    'pl.audiokiddo.sub.monthly': 'AudioKiddo miesięcznie',
    'pl.audiokiddo.sub.yearly': 'AudioKiddo rocznie',
    'pl.audiokiddo.pack.wyobraznia': 'Pakiet Wyobraźnia',
    'pl.audiokiddo.pack.slowa_i_wiedza': 'Pakiet Słowa i Wiedza',
    'pl.audiokiddo.pack.detektyw': 'Pakiet Detektyw',
    'pl.audiokiddo.bundle.two': 'Zestaw 2 pakietów',
    'pl.audiokiddo.bundle.three': 'Zestaw 3 pakietów',
  };

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<StoreProduct>> products(Set<String> ids) async => [
    for (final id in ids)
      if (id.startsWith('pl.audiokiddo.sub.'))
        StoreProduct(
          id: id,
          title: _titles[id]!,
          price: _prices[id]!,
          kind: StoreProductKind.subscription,
          period: id.endsWith('yearly') ? BillingPeriod.year : BillingPeriod.month,
          freeTrialDays: trialDays,
          rawPrice: _raw(_prices[id]!),
          currencyCode: 'PLN',
        )
      else
        StoreProduct(
          id: id,
          title: _titles[id] ?? 'Pojedyncza zabawa',
          // Single games: 19,99 zł for Detektyw, 9,99 zł otherwise (approved 2026-09-26).
          price: _prices[id] ?? (_isDetektywItem(id) ? '19,99 zł' : '9,99 zł'),
          kind: StoreProductKind.oneTime,
          rawPrice: _raw(_prices[id] ?? (_isDetektywItem(id) ? '19,99 zł' : '9,99 zł')),
          currencyCode: 'PLN',
        ),
  ];

  static double _raw(String price) =>
      double.parse(price.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.'));

  static bool _isDetektywItem(String id) => const [
    'zlodziej_naszyjnika',
    'znikajace_dzwonki',
    'na_ratunek_budce_z_lodami',
    'tajemnicze_znaki',
    'gadajacy_smietnik',
  ].any(id.endsWith);

  @override
  Stream<List<StorePurchase>> get purchases => _purchases.stream;

  @override
  Future<void> buy(StoreProduct product, {String? accountToken}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final outcome = nextOutcome;
    if (outcome == PurchaseStatus.purchased) {
      _owned.add(product.id);
      if (product.kind == StoreProductKind.subscription) trialDays = null;
    }
    _purchases.add([
      StorePurchase(
        productId: product.id,
        status: outcome,
        transactionId: 'dev-${++_counter}',
        verificationData: 'dev-token-${product.id}',
        error: outcome == PurchaseStatus.error ? 'Symulowany błąd sklepu' : null,
        needsCompletion: outcome == PurchaseStatus.purchased,
      ),
    ]);
  }

  @override
  Future<void> restore() async {
    _purchases.add([
      for (final id in _owned)
        StorePurchase(
          productId: id,
          status: PurchaseStatus.restored,
          transactionId: 'dev-restore-$id',
          verificationData: 'dev-token-$id',
          needsCompletion: true,
        ),
    ]);
  }

  @override
  Future<void> complete(StorePurchase purchase) async => completed.add(purchase.productId);

  Future<void> dispose() => _purchases.close();
}
