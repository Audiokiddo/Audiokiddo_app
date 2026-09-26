import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access/access_controller.dart';

/// Source of the catalog manifest. Etap 1 reads the bundled mock; Etap 3 adds the
/// server manifest with the last good version cached on the device.
abstract interface class CatalogSource {
  Future<Map<String, Object?>> load();
}

class BundledCatalogSource implements CatalogSource {
  const BundledCatalogSource([this.assetPath = 'assets/mock/catalog.json']);

  final String assetPath;

  @override
  Future<Map<String, Object?>> load() async =>
      jsonDecode(await rootBundle.loadString(assetPath, cache: false)) as Map<String, Object?>;
}

final catalogSourceProvider = Provider<CatalogSource>((ref) => const BundledCatalogSource());

final catalogProvider = FutureProvider<Catalog>((ref) async {
  final result = parseCatalog(await ref.watch(catalogSourceProvider).load());
  for (final skipped in result.skipped) {
    debugPrint('catalog: skipped $skipped');
  }
  return result.catalog;
});

/// Entitlements known on this device (dev source until Etap 3 — see access_controller.dart).
final entitlementsProvider = Provider<List<Entitlement>>(
  (ref) => ref.watch(accessProvider).value?.entitlements ?? const [],
);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final accessPolicyProvider = Provider<AccessPolicy>((ref) => AccessPolicy(ref.watch(entitlementsProvider)));

/// Offline lease for paid content (ARCHITECTURE §8).
final leaseStateProvider = Provider<LeaseState>((ref) {
  final access = ref.watch(accessProvider).value;
  return evaluateLease(
    now: ref.watch(clockProvider)(),
    validUntil: access?.leaseValidUntil,
    lastSeenAt: access?.lastSeenAt,
  );
});

enum ItemAccess { playable, locked, needsRefresh }

/// Free content always plays; paid content needs an entitlement and a valid lease.
final itemAccessProvider = Provider.family<ItemAccess, ContentItem>((ref, item) {
  if (item.isFree) return ItemAccess.playable;
  if (!ref.watch(accessPolicyProvider).canPlay(item, ref.watch(clockProvider)())) return ItemAccess.locked;
  return ref.watch(leaseStateProvider) == LeaseState.valid ? ItemAccess.playable : ItemAccess.needsRefresh;
});

final canPlayProvider = Provider.family<bool, ContentItem>(
  (ref, item) => ref.watch(itemAccessProvider(item)) == ItemAccess.playable,
);
