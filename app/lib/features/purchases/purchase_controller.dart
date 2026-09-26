import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access/access_controller.dart';
import '../catalog/catalog_providers.dart';
import 'fake_store.dart';
import 'iap_store.dart';
import 'offer_catalog.dart';
import 'store_gateway.dart';

enum VerificationResult { verified, rejected, retryLater }

/// Confirms a store purchase and records the entitlement. Etap 3: the `verify-purchase`
/// server function (App Store Server API / Google Play Developer API).
abstract interface class PurchaseVerifier {
  Future<VerificationResult> verify(StorePurchase purchase);
}

/// Release builds until the server exists: never grants anything locally.
class UnavailablePurchaseVerifier implements PurchaseVerifier {
  const UnavailablePurchaseVerifier();

  @override
  Future<VerificationResult> verify(StorePurchase purchase) async => VerificationResult.retryLater;
}

/// Development: grants the product's scopes in the development backend.
class DevPurchaseVerifier implements PurchaseVerifier {
  DevPurchaseVerifier(this._ref);

  final Ref _ref;

  @override
  Future<VerificationResult> verify(StorePurchase purchase) async {
    final catalog = await _ref.read(catalogProvider.future);
    final scopes = scopesForProduct(purchase.productId, catalog);
    if (scopes.isEmpty) return VerificationResult.rejected;
    final backend = _ref.read(entitlementBackendProvider);
    if (backend is! DevEntitlementBackend) return VerificationResult.retryLater;
    final days = purchase.productId == ProductIds.yearly
        ? 365
        : purchase.productId == ProductIds.monthly
        ? 30
        : null;
    await backend.addPurchase(
      scopes,
      validUntil: days == null ? null : DateTime.now().add(Duration(days: days)),
    );
    return VerificationResult.verified;
  }
}

const _realStore = bool.fromEnvironment('REAL_STORE');

final storeGatewayProvider = Provider<StoreGateway>((ref) {
  if (kDebugMode && !_realStore) {
    final fake = FakeStoreGateway();
    ref.onDispose(fake.dispose);
    return fake;
  }
  return InAppPurchaseGateway();
});

final purchaseVerifierProvider = Provider<PurchaseVerifier>(
  (ref) => kDebugMode && !_realStore ? DevPurchaseVerifier(ref) : const UnavailablePurchaseVerifier(),
);

enum PurchaseMessage { none, success, pendingApproval, canceled, storeError, verifyLater, nothingToRestore }

@immutable
class PurchaseUiState {
  const PurchaseUiState({this.busyProductId, this.message = PurchaseMessage.none});

  final String? busyProductId;
  final PurchaseMessage message;
}

class PurchaseController extends Notifier<PurchaseUiState> {
  StreamSubscription<List<StorePurchase>>? _subscription;
  bool _restoring = false;

  @override
  PurchaseUiState build() {
    _subscription = ref.watch(storeGatewayProvider).purchases.listen(_onPurchases);
    ref.onDispose(() => _subscription?.cancel());
    return const PurchaseUiState();
  }

  Future<void> buy(StoreProduct product) async {
    state = PurchaseUiState(busyProductId: product.id);
    try {
      // TODO(Etap 3): pass the anonymous account UUID (appAccountToken / obfuscatedAccountId).
      await ref.read(storeGatewayProvider).buy(product);
    } on Exception {
      state = const PurchaseUiState(message: PurchaseMessage.storeError);
    }
  }

  Future<void> restore() async {
    _restoring = true;
    state = const PurchaseUiState(busyProductId: 'restore');
    await ref.read(storeGatewayProvider).restore();
    // The store answers through the purchase stream; with nothing owned it stays silent.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (_restoring && ref.mounted) {
      _restoring = false;
      state = const PurchaseUiState(message: PurchaseMessage.nothingToRestore);
    }
  }

  void clearMessage() => state = const PurchaseUiState();

  Future<void> _onPurchases(List<StorePurchase> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          state = const PurchaseUiState(message: PurchaseMessage.pendingApproval);
        case PurchaseStatus.canceled:
          state = const PurchaseUiState(message: PurchaseMessage.canceled);
        case PurchaseStatus.error:
          state = const PurchaseUiState(message: PurchaseMessage.storeError);
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          _restoring = false;
          final result = await ref.read(purchaseVerifierProvider).verify(p);
          if (!ref.mounted) return;
          if (result == VerificationResult.verified) {
            // Acknowledge only after the entitlement is recorded, so the store redelivers
            // anything we failed to process.
            if (p.needsCompletion) await ref.read(storeGatewayProvider).complete(p);
            await ref.read(accessProvider.notifier).refresh();
            if (ref.mounted) state = const PurchaseUiState(message: PurchaseMessage.success);
          } else {
            state = const PurchaseUiState(message: PurchaseMessage.verifyLater);
          }
      }
    }
  }
}

final purchaseControllerProvider = NotifierProvider<PurchaseController, PurchaseUiState>(
  PurchaseController.new,
);

/// Store products for the paywall, prices from the store. Key: sorted ids joined by ','
/// (a Set would not compare by value and would refetch on every build).
final storeProductsProvider = FutureProvider.autoDispose.family<List<StoreProduct>, String>((ref, key) async {
  final store = ref.watch(storeGatewayProvider);
  if (!await store.isAvailable()) return const [];
  return store.products(key.split(',').toSet());
});

String productsKey(Set<String> ids) => (ids.toList()..sort()).join(',');
