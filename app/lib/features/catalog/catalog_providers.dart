import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Entitlements known on this device. Etap 1: none (only free content plays);
/// replaced by the verified server state in Etap 3.
final entitlementsProvider = Provider<List<Entitlement>>((ref) => const []);

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final accessPolicyProvider = Provider<AccessPolicy>((ref) => AccessPolicy(ref.watch(entitlementsProvider)));

/// Whether [item] can be played right now.
final canPlayProvider = Provider.family<bool, ContentItem>(
  (ref, item) => ref.watch(accessPolicyProvider).canPlay(item, ref.watch(clockProvider)()),
);
