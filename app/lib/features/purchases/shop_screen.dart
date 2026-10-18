import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../welcome/szop_tour.dart';

import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/catalog_loader.dart';
import '../catalog/widgets/item_art.dart';
import '../discovery/discovery_model.dart';
import '../discovery/reference_widgets.dart';
import '../family/family.dart';
import '../downloads/pack_download.dart';
import '../home/quick_pick.dart';
import '../pdf/case_files_card.dart';
import '../promotions/promotions.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import '../insights/events.dart';
import 'manage_subscription.dart';
import 'shop.dart';
import '../discovery/parent_screens.dart' show DownloadsScreen;
import 'store_gateway.dart';
import 'subscription_value.dart';
import 'winback.dart';

/// The third tab: the subscription offer, or the downloads once the family has it.
class SubscriptionTab extends ConsumerWidget {
  const SubscriptionTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(hasSubscriptionProvider) ? const DownloadsScreen(inTab: true) : const ShopScreen();
}

/// Shop tab: the subscription, every pack with a free taste, bundles and how to restore.
/// Parent area; every purchase and link out passes the parental gate.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key, this.standalone = false});

  /// Opened on top of another screen (a banner, the subscription card): with a back arrow
  /// and swipe-back, unlike the Shop tab itself.
  final bool standalone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenPurchaseMessages(context, ref);
    return TrackOnce(
      event: AppEvent.paywallView,
      props: const {'from': 'subscription_screen'},
      child: _shop(context, ref),
    );
  }

  Widget _shop(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: standalone ? AppBar(title: const Text('Abonament')) : null,
      body: SafeArea(
        top: !standalone,
        child: CatalogLoader(
          builder: (context, catalog) {
            final products = ref.watch(storeProductsProvider(productsKey(shopProductIds(catalog))));
            final byId = {for (final p in products.value ?? const <StoreProduct>[]) p.id: p};
            final scopes = ref.watch(activeScopesProvider);
            final subscribed = scopes.contains(Scopes.allContent);
            final text = Theme.of(context).textTheme;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // Simpler and clearer (Nela, 2026-10-18): the title, the offer, help. No pack
                // counts, no list of what is included, no description of how plays work.
                Text('Abonament', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const PromotionBanner(),
                const SizedBox(height: 14),
                if (!subscribed) const WinBackCard(withButton: false),
                if (subscribed)
                  const _FullAccessCard()
                else
                  TourTarget(
                    id: 'subscription',
                    child: products.isLoading
                        ? const Center(
                            child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                          )
                        : SubscriptionOffer(catalog: catalog, byId: byId),
                  ),
                if (products.hasValue && byId.isEmpty) const _StoreUnavailable(),
                const SizedBox(height: 18),
                const _HelpBlock(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Single plays for families who want just one: by pack, with price and a buy button.
class _SinglePlays extends ConsumerStatefulWidget {
  const _SinglePlays({required this.catalog, required this.byId});

  final Catalog catalog;
  final Map<String, StoreProduct> byId;

  @override
  ConsumerState<_SinglePlays> createState() => _SinglePlaysState();
}

class _SinglePlaysState extends ConsumerState<_SinglePlays> {
  String? _open;

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(purchaseControllerProvider).busyProductId;
    final text = Theme.of(context).textTheme;
    final groups = [
      for (final pack in widget.catalog.packs)
        (
          pack,
          [
            for (final i in widget.catalog.itemsInPack(pack.id))
              if (!ref.watch(canPlayProvider(i)) && widget.byId[i.storeProductId] != null) i,
          ],
        ),
    ].where((g) => g.$2.isNotEmpty).toList();
    if (groups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RefSection('Pojedyncze zabawy'),
        Text(
          'Chcesz tylko jedną przygodę? Kup ją osobno. Cały pakiet wychodzi taniej w przeliczeniu na zabawę.',
          style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
        ),
        const SizedBox(height: 6),
        for (final (pack, items) in groups) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(pack.title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            subtitle: Text('${playsCount(items.length)} do kupienia osobno'),
            trailing: Icon(_open == pack.id ? Icons.expand_less_rounded : Icons.expand_more_rounded),
            onTap: () => setState(() => _open = _open == pack.id ? null : pack.id),
          ),
          if (_open == pack.id)
            for (final item in items)
              AudioRow(
                item: item,
                trailing: FilledButton.tonal(
                  onPressed: busy == null ? () => buyWithGate(context, ref, widget.byId[item.storeProductId]!) : null,
                  child: busy == item.storeProductId
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.byId[item.storeProductId]!.price),
                ),
              ),
        ],
      ],
    );
  }
}

class _FullAccessCard extends ConsumerWidget {
  const _FullAccessCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    const ink = Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AkBrand.tealDeep, Color(0xFF145457)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AkBrand.sun),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Masz pełny dostęp',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Wszystkie pakiety i nowości są odblokowane. Miłego słuchania.',
            style: text.bodyMedium?.copyWith(color: ink),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: AkBrand.sun),
              onPressed: () => manageSubscription(context, ref),
              child: const Text('Zarządzaj subskrypcją'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreUnavailable extends StatelessWidget {
  const _StoreUnavailable();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      'Sklep ${Platform.isIOS ? 'App Store' : 'Google Play'} jest teraz niedostępny. '
      'Pakiety możesz przeglądać i wypróbować za darmo, a kupisz je, gdy połączenie wróci.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.palette.inkMuted),
    ),
  );
}

/// A pack's picture: a mosaic of its plays' covers (two or more), one cover, or the drawn
/// scene of the kind of play most of its items are while no cover exists yet.
class PackArt extends ConsumerWidget {
  const PackArt({super.key, required this.summary, this.radius = 18});

  final PackSummary summary;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final covered = withCovers(ref, summary.items);
    final Widget art;
    if (ref.watch(hasPackCoverProvider(summary.pack.id))) {
      art = CoverImage(asset: packCoverAssetPath(summary.pack.id));
    } else if (covered.length >= 2) {
      final tiles = covered.take(4).toList();
      art = Column(
        children: [
          for (var row = 0; row < 2; row++)
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < 2; col++)
                    Expanded(child: ItemArt(item: tiles[(row * 2 + col) % tiles.length])),
                ],
              ),
            ),
        ],
      );
    } else if (covered.length == 1) {
      art = ItemArt(item: covered.first);
    } else {
      art = ArtScene(
        category: summary.items.isEmpty ? PlayCategory.adventure : itemCategory(summary.items.first),
        seed: summary.pack.id.codeUnits.fold(0, (a, b) => a + b) % 5,
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: art);
  }
}

/// The pack page header: up to three covers side by side, or the drawn scene before covers exist.
class PackBanner extends ConsumerWidget {
  const PackBanner({super.key, required this.summary});

  final PackSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasPackCoverProvider(summary.pack.id))) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: CoverImage(asset: packCoverAssetPath(summary.pack.id)),
            ),
          ),
        ),
      );
    }
    final covered = withCovers(ref, summary.items).take(3).toList();
    if (covered.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: PackArt(summary: summary, radius: 24),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < covered.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ItemArt(item: covered[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Under the start button: the pack works without the internet once downloaded, in one tap.
class _OfflineHint extends ConsumerWidget {
  const _OfflineHint({required this.items});

  final List<ContentItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!items.any((i) => ref.watch(canPlayProvider(i)))) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AkBrand.teal.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Słuchajcie bez internetu', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text(
            'Pobierz zabawy na telefon przed drogą: zagrają w aucie, samolocie i na działce.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 8),
          PackDownloadButton(items: items),
        ],
      ),
    );
  }
}

/// Right under the cover: start the pack without scrolling. An owned pack goes on with the
/// first play the child has not finished; otherwise its first free play.
class _PackStartButton extends ConsumerWidget {
  const _PackStartButton({required this.summary, required this.owned});

  final PackSummary summary;
  final bool owned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final done = child == null
        ? const <String>{}
        : {
            for (final r in family!.resultsOf(child.id))
              if (r.completed) r.itemId,
          };
    final playable = [
      for (final i in summary.items)
        if (ref.watch(canPlayProvider(i))) i,
    ];
    final next = playable.where((i) => !done.contains(i.id)).firstOrNull ?? playable.firstOrNull;
    if (next == null) return const SizedBox.shrink();
    final first = summary.items.indexOf(next) == 0 && !done.contains(next.id);
    return FilledButton.icon(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      onPressed: () => startItem(context, next),
      icon: const Icon(Icons.play_arrow_rounded, size: 28),
      label: Text(
        owned ? '${first ? 'Zacznij' : 'Graj dalej'}: ${next.title}' : 'Posłuchaj za darmo: ${next.title}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HelpBlock extends ConsumerWidget {
  const _HelpBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final busy = ref.watch(purchaseControllerProvider).busyProductId;
    final store = Platform.isIOS ? 'App Store' : 'Google Play';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.storefront_rounded, color: AkBrand.tealDeep),
          title: const Text('Masz już dostęp z audiokiddo.pl?'),
          subtitle: const Text('Zaloguj się e-mailem, podaj numer zamówienia albo wpisz kod.'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/dostep'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore_rounded, color: AkBrand.tealDeep),
          title: Text(l10n.paywallRestore),
          subtitle: Text('Zakupy z $store na tym koncie sklepu.'),
          enabled: busy == null,
          onTap: () => ref.read(purchaseControllerProvider.notifier).restore(),
        ),
        const SizedBox(height: 8),
        Text(
          [l10n.paywallLegalRenewal(store), l10n.paywallLegalManage(store)].join(' '),
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
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, {this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const fg = Color(0xFF211C35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color ?? context.palette.surfaceMuted, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// One pack: what is inside, what it trains, the free taste, and buying it.
class PackScreen extends ConsumerWidget {
  const PackScreen({super.key, required this.packId});

  final String packId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenPurchaseMessages(context, ref);
    return TrackOnce(
      event: AppEvent.paywallView,
      props: {'from': 'package_open', 'pack': packId},
      child: _page(context, ref),
    );
  }

  Widget _page(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        // Opened from a link there is nothing to go back to: lead to the Shop tab instead.
        leading: context.canPop()
            ? null
            : IconButton(
                tooltip: 'Abonament',
                onPressed: () => context.push('/abonament'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
      ),
      body: CatalogLoader(
        builder: (context, catalog) {
          final pack = catalog.pack(packId);
          if (pack == null) return const Center(child: Text('Nie ma takiego pakietu.'));
          final summary = PackSummary(pack, catalog);
          final scopes = ref.watch(activeScopesProvider);
          final owned = ownsPack(scopes, pack.id);
          final products = ref.watch(storeProductsProvider(productsKey(shopProductIds(catalog))));
          final byId = {for (final p in products.value ?? const <StoreProduct>[]) p.id: p};
          final text = Theme.of(context).textTheme;
          final child = ref.watch(familyProvider).value?.active;
          final done = child == null
              ? 0
              : {
                  for (final r in ref.watch(familyProvider).value!.resultsOf(child.id))
                    if (r.completed && summary.items.any((i) => i.id == r.itemId)) r.itemId,
                }.length;
          final busy = ref.watch(purchaseControllerProvider).busyProductId;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    PackBanner(summary: summary),
                    const SizedBox(height: 12),
                    _PackStartButton(summary: summary, owned: owned),
                    if (!owned) const Center(child: RedeemAccessLink()),
                    _OfflineHint(items: summary.items),
                    PromotionBanner(target: pack.id),
                    const SizedBox(height: 14),
                    Text('Pakiet', style: text.labelMedium?.copyWith(color: context.palette.inkMuted)),
                    Text(pack.title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(playsCount(summary.items.length), icon: Icons.headphones_rounded),
                        _Badge('${summary.minutes} min słuchania', icon: Icons.schedule_rounded),
                        _Badge('od ${pack.ageMin} lat', icon: Icons.child_care_rounded),
                      ],
                    ),
                    if (pack.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(pack.description, style: text.bodyMedium),
                    ],
                    if (owned && summary.items.any((i) => i.pdf.isNotEmpty) && pack.id == 'detektyw') ...[
                      const SizedBox(height: 16),
                      AllCaseFilesCard(
                        packTitle: pack.title,
                        items: [
                          for (final i in summary.items)
                            if (i.pdf.isNotEmpty) i,
                        ],
                      ),
                    ],
                    if (summary.skills.isNotEmpty) ...[
                      const RefSection('Co ćwiczy'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final s in summary.skills.take(6)) _Badge(s, color: referenceMint)],
                      ),
                    ],
                    if (owned && child != null) ...[
                      const RefSection('Postęp'),
                      Text('${child.name.isEmpty ? 'Dziecko' : child.name}: ukończone $done z ${summary.items.length}'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: summary.items.isEmpty ? 0 : done / summary.items.length,
                          minHeight: 8,
                        ),
                      ),
                      if (summary.items.isNotEmpty && done == summary.items.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FilledButton.tonalIcon(
                            onPressed: () => context.push('/dyplom/${pack.id}'),
                            icon: const Icon(Icons.workspace_premium_rounded),
                            label: const Text('Zobacz dyplom'),
                          ),
                        ),
                    ],
                    if (!owned && summary.freeItems.isNotEmpty) ...[
                      const RefSection('Wypróbuj za darmo'),
                      for (final i in summary.freeItems) AudioRow(item: i),
                    ],
                    RefSection(owned ? 'W pakiecie' : 'Co jest w środku'),
                    for (final i in summary.items.where((i) => owned || !i.isFree)) AudioRow(item: i),
                  ],
                ),
              ),
              if (!owned)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    decoration: BoxDecoration(color: context.palette.surface, boxShadow: akSoftShadow(context)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The subscription first; this pack alone is the quieter option.
                        if (byId[ProductIds.yearly] case final yearly?)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                              onPressed: busy != null ? null : () => buyWithGate(context, ref, yearly),
                              child: busy == yearly.id
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      // The amount billed comes first (App Store 3.1.2), the month after it.
                                      'Abonament roczny: ${yearly.price}',
                                    ),
                            ),
                          ),
                        if (byId[ProductIds.yearly] != null)
                          Text(switch (byId[ProductIds.yearly]) {
                            StoreProduct(:final rawPrice?, :final currencyCode) =>
                              'czyli ok. ${formatMoney(rawPrice / 12, currencyCode)} / mies. '
                                  'Wszystkie pakiety i 2 nowe zabawy co tydzień.',
                            _ => 'Wszystkie pakiety i 2 nowe zabawy co tydzień',
                          }, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
