import 'package:ak_core/ak_core.dart';

/// Store product ids. They must match App Store Connect and Play Console exactly.
abstract final class ProductIds {
  /// The subscription for one child (the plan everyone starts with).
  static const monthly = 'pl.audiokiddo.sub.monthly';
  static const yearly = 'pl.audiokiddo.sub.yearly';
  static const duoMonthly = 'pl.audiokiddo.sub.duo.monthly';
  static const duoYearly = 'pl.audiokiddo.sub.duo.yearly';
  static const familyMonthly = 'pl.audiokiddo.sub.family.monthly';
  static const familyYearly = 'pl.audiokiddo.sub.family.yearly';
  static const bundleTwo = 'pl.audiokiddo.bundle.two';
  static const bundleThree = 'pl.audiokiddo.bundle.three';

  static const subscriptions = {monthly, yearly, duoMonthly, duoYearly, familyMonthly, familyYearly};

  static bool isYearly(String id) => subscriptions.contains(id) && id.endsWith('.yearly');
}

/// Subscription plans by the number of children, simple to remember: the second child
/// +5 zł a month, the whole family (up to 5) +10 zł. All plans are in one subscription
/// group, so moving up is the store's upgrade (supabase/migrations/…_family_plans.sql).
enum SubscriptionPlan {
  solo(1, '1 dziecko', ProductIds.monthly, ProductIds.yearly),
  duo(2, '2 dzieci', ProductIds.duoMonthly, ProductIds.duoYearly),
  family(5, '3–5 dzieci', ProductIds.familyMonthly, ProductIds.familyYearly);

  const SubscriptionPlan(this.children, this.label, this.monthlyId, this.yearlyId);

  /// Child profiles the plan covers.
  final int children;
  final String label;
  final String monthlyId;
  final String yearlyId;

  String productId({required bool yearly}) => yearly ? yearlyId : monthlyId;

  /// The smallest plan that covers [count] children.
  static SubscriptionPlan forChildren(int count) => values.firstWhere((p) => p.children >= count, orElse: () => family);

  static SubscriptionPlan? ofProduct(String productId) =>
      values.where((p) => p.monthlyId == productId || p.yearlyId == productId).firstOrNull;
}

/// How many child profiles a subscription covers (`children:N`; none = the whole family).
String childrenScope(int count) => 'children:$count';

/// Packs in the two-pack bundle (as on audiokiddo.pl: Słowa i Wiedza + Wyobraźnia).
const bundleTwoPacks = ['slowa-i-wiedza', 'wyobraznia'];

/// Scopes a product grants. Mirrors the server table `store_products` (ARCHITECTURE §6.1);
/// the app uses it only to label offers and in the development store.
List<String> scopesForProduct(String productId, Catalog catalog) {
  if (SubscriptionPlan.ofProduct(productId) case final plan?) {
    return [Scopes.allContent, childrenScope(plan.children)];
  }
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
