import 'package:ak_core/ak_core.dart';

/// Store product ids. They must match App Store Connect and Play Console exactly.
abstract final class ProductIds {
  static const monthly = 'pl.audiokiddo.sub.monthly';
  static const yearly = 'pl.audiokiddo.sub.yearly';
  static const bundleTwo = 'pl.audiokiddo.bundle.two';
  static const bundleThree = 'pl.audiokiddo.bundle.three';

  static const subscriptions = {monthly, yearly};
}

/// Packs in the two-pack bundle (as on audiokiddo.pl: Słowa i Wiedza + Wyobraźnia).
const bundleTwoPacks = ['slowa-i-wiedza', 'wyobraznia'];

/// Scopes a product grants. Mirrors the server table `store_products` (ARCHITECTURE §6.1);
/// the app uses it only to label offers and in the development store.
List<String> scopesForProduct(String productId, Catalog catalog) {
  if (ProductIds.subscriptions.contains(productId)) return [Scopes.allContent];
  if (productId == ProductIds.bundleTwo) return [for (final p in bundleTwoPacks) Scopes.pack(p)];
  if (productId == ProductIds.bundleThree) return [for (final p in catalog.packs) Scopes.pack(p.id)];
  for (final pack in catalog.packs) {
    if (pack.storeProductId == productId) return [Scopes.pack(pack.id)];
  }
  for (final item in catalog.items) {
    if (item.storeProductId == productId) return [Scopes.item(item.id)];
  }
  return const [];
}

/// Products worth offering for [item]: subscriptions, its pack, bundles and the item alone.
Set<String> productIdsFor(ContentItem? item, Catalog catalog) {
  final pack = item?.packId == null ? null : catalog.pack(item!.packId!);
  return {
    ...ProductIds.subscriptions,
    ?pack?.storeProductId,
    if (pack == null || bundleTwoPacks.contains(pack.id)) ProductIds.bundleTwo,
    ProductIds.bundleThree,
    ?item?.storeProductId,
  };
}
