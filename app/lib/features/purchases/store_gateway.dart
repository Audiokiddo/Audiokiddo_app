/// What the family can buy (ARCHITECTURE §7). Prices always come from the store.
enum StoreProductKind { subscription, oneTime }

enum BillingPeriod { month, year }

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.kind,
    this.period,
    this.freeTrialDays,
  });

  final String id;
  final String title;

  /// Localised price exactly as the store formats it, e.g. "24,99 zł".
  final String price;
  final StoreProductKind kind;
  final BillingPeriod? period;

  /// Set only when the store offers a free trial to *this* user.
  final int? freeTrialDays;
}

enum PurchaseStatus { pending, purchased, restored, canceled, error }

class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.status,
    this.transactionId,
    this.verificationData,
    this.error,
    this.needsCompletion = false,
  });

  final String productId;
  final PurchaseStatus status;
  final String? transactionId;

  /// iOS: signed JWS transaction; Android: purchase token. Sent to the server for verification.
  final String? verificationData;
  final String? error;

  /// The store waits for acknowledgement; done only after the server verified the purchase.
  final bool needsCompletion;
}

/// Seam over App Store / Google Play so the purchase flow can be developed and tested
/// without store accounts.
abstract interface class StoreGateway {
  Future<bool> isAvailable();
  Future<List<StoreProduct>> products(Set<String> ids);
  Stream<List<StorePurchase>> get purchases;

  /// [accountToken]: the (anonymous) account UUID, stored by the store with the purchase.
  Future<void> buy(StoreProduct product, {String? accountToken});
  Future<void> restore();
  Future<void> complete(StorePurchase purchase);
}
