import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/storage/storage_providers.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../parental_gate/parental_gate.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import 'store_gateway.dart';

/// Everything the Shop tab can sell: both subscriptions, every pack, both bundles and single plays.
Set<String> shopProductIds(Catalog catalog) => {
  ...ProductIds.subscriptions,
  for (final p in catalog.packs) ?p.storeProductId,
  ProductIds.bundleTwo,
  ProductIds.bundleThree,
  for (final i in catalog.items) ?i.storeProductId,
};

/// Packs of a bundle product, in catalog order.
List<Pack> bundlePacks(String productId, Catalog catalog) {
  final scopes = scopesForProduct(productId, catalog).toSet();
  return [
    for (final p in catalog.packs)
      if (scopes.contains(Scopes.pack(p.id))) p,
  ];
}

/// Scopes the family can use right now (subscription, packs, single items).
final activeScopesProvider = Provider<Set<String>>(
  (ref) => ref.watch(accessPolicyProvider).activeScopes(ref.watch(clockProvider)()),
);

bool ownsPack(Set<String> scopes, String packId) =>
    scopes.contains(Scopes.allContent) || scopes.contains(Scopes.pack(packId));

/// What a pack holds, for its card and page.
class PackSummary {
  PackSummary(this.pack, Catalog catalog) : items = catalog.itemsInPack(pack.id);

  final Pack pack;
  final List<ContentItem> items;

  List<ContentItem> get freeItems => [
    for (final i in items)
      if (i.isFree) i,
  ];
  int get minutes => items.fold(0, (s, i) => s + i.durationSec) ~/ 60;

  /// The skills most of its items train, most frequent first.
  List<String> get skills {
    final counts = <String, int>{};
    for (final i in items) {
      for (final s in i.skills) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => e.key).toList();
  }
}

/// How much cheaper [bundle] is than buying its packs one by one; null when unknown or none.
double? bundleSavings(StoreProduct bundle, List<StoreProduct?> packs) {
  if (bundle.rawPrice == null || packs.isEmpty) return null;
  var sum = 0.0;
  for (final p in packs) {
    if (p?.rawPrice == null || p!.currencyCode != bundle.currencyCode) return null;
    sum += p.rawPrice!;
  }
  final saved = sum - bundle.rawPrice!;
  return saved >= 0.01 ? saved : null;
}

/// The yearly plan's discount against twelve months, in whole percent; null when unknown.
int? yearlyDiscountPercent(StoreProduct yearly, StoreProduct monthly) {
  final y = yearly.rawPrice, m = monthly.rawPrice;
  if (y == null || m == null || m <= 0 || yearly.currencyCode != monthly.currencyCode) return null;
  final percent = ((1 - y / (m * 12)) * 100).floor();
  return percent > 0 ? percent : null;
}

/// A money amount in the store's currency, e.g. "12,49 zł".
String formatMoney(double amount, String? currencyCode) =>
    NumberFormat.simpleCurrency(locale: 'pl', name: currencyCode ?? 'PLN').format(amount);

/// After a free taste of a pack the child finished, the rest of that pack is the natural next
/// step: the most recent such pack the family does not own yet.
({ContentItem tried, PackSummary pack})? nextPackSuggestion({
  required List<ActivityResult> results,
  required Catalog catalog,
  required Set<String> scopes,
}) {
  final sorted = [...results]..sort((a, b) => b.at.compareTo(a.at));
  for (final r in sorted) {
    if (!r.completed) continue;
    final item = catalog.item(r.itemId);
    final pack = item?.packId == null ? null : catalog.pack(item!.packId!);
    if (item == null || pack == null || !item.isFree || ownsPack(scopes, pack.id)) continue;
    return (tried: item, pack: PackSummary(pack, catalog));
  }
  return null;
}

/// Purchases happen only after the parental gate (Kids Category, ARCHITECTURE §12).
Future<void> buyWithGate(BuildContext context, WidgetRef ref, StoreProduct product) async {
  if (!await showParentalGate(context) || !context.mounted) return;
  await ref.read(purchaseControllerProvider.notifier).buy(product);
}

/// Links out of the app are for parents only, too.
Future<void> openWithGate(BuildContext context, Uri url) async {
  if (!await showParentalGate(context) || !context.mounted) return;
  await openExternal(url);
}

/// Opens a page outside the app; callers ask for an adult first (Kids Category).
Future<void> openExternal(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);

final termsUrl = Uri.parse('https://audiokiddo.pl/regulamin/');
final privacyUrl = Uri.parse('https://audiokiddo.pl/polityka-prywatnosci-aplikacji/');
Uri get manageSubscriptionsUrl => Platform.isIOS
    ? Uri.parse('https://apps.apple.com/account/subscriptions')
    : Uri.parse('https://play.google.com/store/account/subscriptions');

/// Shows the outcome of a purchase or restore as a snackbar; [onSuccess] runs after a purchase.
void listenPurchaseMessages(BuildContext context, WidgetRef ref, {VoidCallback? onSuccess}) {
  ref.listen(purchaseControllerProvider.select((s) => s.message), (_, message) {
    final l10n = AppLocalizations.of(context);
    final text = switch (message) {
      PurchaseMessage.success => l10n.purchaseSuccess,
      PurchaseMessage.pendingApproval => l10n.purchasePending,
      PurchaseMessage.storeError => l10n.purchaseStoreError,
      PurchaseMessage.storeNotReady =>
        'Zakupy w aplikacji ruszą, gdy AudioKiddo pojawi się w App Store. Ceny są już takie, jak widzisz.',
      PurchaseMessage.verifyLater => l10n.purchaseVerifyLater,
      PurchaseMessage.nothingToRestore => l10n.purchaseNothingToRestore,
      PurchaseMessage.canceled || PurchaseMessage.none => null,
    };
    if (text != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    if (message == PurchaseMessage.success) onSuccess?.call();
    if (message != PurchaseMessage.none) ref.read(purchaseControllerProvider.notifier).clearMessage();
  });
}

/// Opens a pack's page in the shop.
void openPack(BuildContext context, String packId) => context.push('/pakiet/$packId');

/// "1 zabawa", "3 zabawy", "9 zabaw".
String playsCount(int n) {
  final word = n == 1
      ? 'zabawa'
      : (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 12 || n % 100 > 14))
      ? 'zabawy'
      : 'zabaw';
  return '$n $word';
}

const _hiddenSuggestionKey = 'shop_suggestion_hidden';

/// The Start suggestion the parent closed: that pack stays quiet for a week.
final hiddenPackSuggestionProvider = FutureProvider<({String packId, DateTime until})?>((ref) async {
  final raw = await ref.watch(databaseProvider).readValue(_hiddenSuggestionKey);
  final parts = raw?.split('|');
  if (parts == null || parts.length != 2) return null;
  final until = DateTime.tryParse(parts[1]);
  return until == null ? null : (packId: parts[0], until: until);
});

Future<void> hidePackSuggestion(WidgetRef ref, String packId) async {
  final until = ref.read(clockProvider)().add(const Duration(days: 7));
  await ref.read(databaseProvider).writeValue(_hiddenSuggestionKey, '$packId|${until.toIso8601String()}');
  ref.invalidate(hiddenPackSuggestionProvider);
}

/// For families who bought on audiokiddo.pl or got a gift code: the way to their access.
/// Only redeeming here; the app itself never sends anyone to buy outside the store.
class RedeemAccessLink extends StatelessWidget {
  const RedeemAccessLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => context.push('/dostep'),
    icon: const Icon(Icons.redeem_rounded),
    label: const Text('Masz zakup z audiokiddo.pl albo kod? Odbierz dostęp'),
  );
}
