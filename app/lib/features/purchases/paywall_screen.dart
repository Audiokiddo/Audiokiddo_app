import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/car_scene.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/widgets/catalog_loader.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import 'subscription_value.dart';
import 'shop.dart';
import 'store_gateway.dart';

/// Parent zone only — reached through the parental gate.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key, this.itemId});

  final String? itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    listenPurchaseMessages(
      context,
      ref,
      onSuccess: () {
        if (context.canPop()) context.pop();
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paywallTitle)),
      body: CatalogLoader(
        builder: (context, catalog) =>
            _PaywallContent(catalog: catalog, item: itemId == null ? null : catalog.item(itemId!)),
      ),
    );
  }
}

class _PaywallContent extends ConsumerWidget {
  const _PaywallContent({required this.catalog, this.item});

  final Catalog catalog;
  final ContentItem? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final ids = productIdsFor(item, catalog);
    final products = ref.watch(storeProductsProvider(productsKey(ids)));
    final busy = ref.watch(purchaseControllerProvider).busyProductId;
    final store = Platform.isIOS ? 'App Store' : 'Google Play';

    return products.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.paywallUnavailable, textAlign: TextAlign.center)),
      data: (list) {
        if (list.isEmpty) return Center(child: Text(l10n.paywallUnavailable, textAlign: TextAlign.center));
        final byId = {for (final p in list) p.id: p};
        final pack = item?.packId == null ? null : catalog.pack(item!.packId!);
        final packProduct = byId[pack?.storeProductId];
        final subs = [?byId[ProductIds.yearly], ?byId[ProductIds.monthly]];
        final hasTrial = subs.any((s) => s.freeTrialDays != null);

        _OfferTile tile(StoreProduct p, {required String title, String? subtitle, bool highlight = false}) =>
            _OfferTile(
              product: p,
              title: title,
              subtitle: subtitle,
              highlight: highlight,
              busy: busy == p.id,
              enabled: busy == null,
            );

        return ListView(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.xl),
          children: [
            // A wink for the parent: the "are we there yet?" of subscriptions.
            CarScene(line: hasTrial ? l10n.paywallCarTrial : l10n.paywallCar),
            const SizedBox(height: AkSpace.m),
            if (item != null) Text(l10n.paywallFor(item!.title), style: text.titleMedium),
            const SizedBox(height: AkSpace.m),
            // The subscription is the main offer; buying for good is folded below it.
            SubscriptionOffer(catalog: catalog, byId: byId),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l10n.paywallOneTimeHeader, style: text.titleSmall),
                subtitle: Text(l10n.paywallOneTimeBody),
                children: [
                  if (packProduct != null)
                    tile(
                      packProduct,
                      title: packProduct.title,
                      subtitle: l10n.itemsCount(catalog.itemsInPack(pack!.id).length),
                    ),
                  if (byId[ProductIds.bundleTwo] case final p?)
                    tile(p, title: p.title, subtitle: l10n.paywallBundleTwo),
                  if (byId[ProductIds.bundleThree] case final p?)
                    tile(p, title: p.title, subtitle: l10n.paywallBundleThree),
                  if (byId[item?.storeProductId] case final p?)
                    tile(
                      p,
                      title: l10n.paywallSingle,
                      subtitle: packProduct == null ? null : l10n.paywallSingleHint(packProduct.price),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AkSpace.m),
            Center(
              child: TextButton(
                onPressed: busy == null ? () => ref.read(purchaseControllerProvider.notifier).restore() : null,
                child: Text(l10n.paywallRestore),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: busy == null ? () => context.push('/konto') : null,
                child: Text(l10n.paywallHaveAccess),
              ),
            ),
            const SizedBox(height: AkSpace.m),
            Text(
              [
                l10n.paywallLegalRenewal(store),
                if (hasTrial) l10n.paywallLegalTrial,
                l10n.paywallLegalManage(store),
              ].join(' '),
              style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
            ),
            Wrap(
              children: [
                TextButton(onPressed: () => openWithGate(context, termsUrl), child: Text(l10n.paywallTerms)),
                TextButton(onPressed: () => openWithGate(context, privacyUrl), child: Text(l10n.paywallPrivacy)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _OfferTile extends ConsumerWidget {
  const _OfferTile({
    required this.product,
    required this.title,
    required this.busy,
    required this.enabled,
    this.subtitle,
    this.highlight = false,
  });

  final StoreProduct product;
  final String title;
  final String? subtitle;
  final bool highlight;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AkSpace.s),
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkRadius.card),
          side: BorderSide(color: highlight ? palette.primary : palette.surfaceMuted, width: highlight ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AkRadius.card),
          onTap: enabled ? () => ref.read(purchaseControllerProvider.notifier).buy(product) : null,
          child: Padding(
            padding: const EdgeInsets.all(AkSpace.m),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      if (subtitle != null) Text(subtitle!, style: text.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: AkSpace.s),
                if (busy)
                  const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                else
                  Text(product.price, style: text.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
