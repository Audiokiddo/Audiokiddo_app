import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'offer_catalog.dart';
import 'store_gateway.dart' as gw;

/// App Store (StoreKit 2) and Google Play Billing through the official Flutter plugin.
///
/// NOT verified against real stores yet: needs App Store Connect / Play Console products
/// and sandbox testers (Etap 3, after the developer accounts exist).
class InAppPurchaseGateway implements gw.StoreGateway {
  InAppPurchaseGateway([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  final _details = <String, ProductDetails>{};

  /// Plugin objects waiting for completion (the plugin needs the original instance).
  final _pending = <String, PurchaseDetails>{};

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<gw.StoreProduct>> products(Set<String> ids) async {
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) throw StateError(response.error!.message);
    final result = <String, gw.StoreProduct>{};
    for (final d in response.productDetails) {
      final subscription = ProductIds.subscriptions.contains(d.id);
      final trial = subscription ? _freeTrialDays(d) : null;
      // Google returns one entry per subscription offer; prefer the one with a trial.
      if (result[d.id]?.freeTrialDays != null) continue;
      _details[d.id] = d;
      result[d.id] = gw.StoreProduct(
        id: d.id,
        title: d.title,
        price: _basePrice(d),
        kind: subscription ? gw.StoreProductKind.subscription : gw.StoreProductKind.oneTime,
        period: subscription
            ? (d.id == ProductIds.yearly ? gw.BillingPeriod.year : gw.BillingPeriod.month)
            : null,
        freeTrialDays: trial,
      );
    }
    return result.values.toList();
  }

  /// The regular (after-trial) price.
  static String _basePrice(ProductDetails d) {
    if (d is GooglePlayProductDetails && d.subscriptionIndex != null) {
      return d
          .productDetails
          .subscriptionOfferDetails![d.subscriptionIndex!]
          .pricingPhases
          .last
          .formattedPrice;
    }
    return d.price;
  }

  static int? _freeTrialDays(ProductDetails d) {
    if (d is GooglePlayProductDetails && d.subscriptionIndex != null) {
      final phases = d.productDetails.subscriptionOfferDetails![d.subscriptionIndex!].pricingPhases;
      final free = phases.where((p) => p.priceAmountMicros == 0).firstOrNull;
      return free == null ? null : isoPeriodDays(free.billingPeriod);
    }
    if (d is AppStoreProduct2Details) {
      // TODO(Etap 3): the plugin does not expose StoreKit 2 introductoryOffer /
      // isEligibleForIntroOffer; add a small native call. Until then the paywall shows no
      // trial on iOS — it never promises one the user would not get.
      return null;
    }
    return null;
  }

  @override
  Stream<List<gw.StorePurchase>> get purchases => _iap.purchaseStream.map((list) {
    return [for (final p in list) _map(p)];
  });

  gw.StorePurchase _map(PurchaseDetails p) {
    final key = p.purchaseID ?? '${p.productID}-${p.transactionDate}';
    if (p.pendingCompletePurchase) _pending[key] = p;
    return gw.StorePurchase(
      productId: p.productID,
      status: switch (p.status) {
        PurchaseStatus.pending => gw.PurchaseStatus.pending,
        PurchaseStatus.purchased => gw.PurchaseStatus.purchased,
        PurchaseStatus.restored => gw.PurchaseStatus.restored,
        PurchaseStatus.canceled => gw.PurchaseStatus.canceled,
        PurchaseStatus.error => gw.PurchaseStatus.error,
      },
      transactionId: key,
      verificationData: p.verificationData.serverVerificationData,
      error: p.error?.message,
      needsCompletion: p.pendingCompletePurchase,
    );
  }

  @override
  Future<void> buy(gw.StoreProduct product, {String? accountToken}) async {
    final details =
        _details[product.id] ?? (await _iap.queryProductDetails({product.id})).productDetails.first;
    // Subscriptions and one-time unlocks both use the non-consumable path of the plugin.
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details, applicationUserName: accountToken),
    );
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<void> complete(gw.StorePurchase purchase) async {
    final original = _pending.remove(purchase.transactionId);
    if (original != null) await _iap.completePurchase(original);
  }
}

/// "P7D" → 7, "P1W" → 7, "P1M" → 30, "P1Y" → 365.
int? isoPeriodDays(String iso) {
  final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(iso);
  if (match == null) return null;
  final n = int.parse(match.group(1)!);
  return switch (match.group(2)) {
    'D' => n,
    'W' => n * 7,
    'M' => n * 30,
    _ => n * 365,
  };
}
