import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/motion.dart';
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
import '../pdf/guide_links.dart';
import '../promotions/promotions.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import 'shop.dart';
import 'store_gateway.dart';
import 'subscription_value.dart';

/// Shop tab: the subscription, every pack with a free taste, bundles and how to restore.
/// Parent area; every purchase and link out passes the parental gate.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    listenPurchaseMessages(context, ref);
    return Scaffold(
      body: SafeArea(
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
                Text('Sklep', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Zabawy bez ekranu na każdy dzień. Kupujesz raz albo masz wszystko w abonamencie.',
                  style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
                ),
                const PromotionBanner(),
                if (!subscribed && catalog.packs.where((p) => ownsPack(scopes, p.id)).length >= 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      'Masz ${catalog.packs.where((p) => ownsPack(scopes, p.id)).length} z ${catalog.packs.length} pakietów. '
                      'W abonamencie masz wszystkie, z grami i każdą nowością, a Twoje pakiety zostają Twoje na zawsze.',
                      style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(height: 18),
                if (subscribed)
                  const _FullAccessCard()
                else
                  _SubscriptionCard(
                    yearly: byId[ProductIds.yearly],
                    monthly: byId[ProductIds.monthly],
                    itemCount: catalog.items.length,
                    loading: products.isLoading,
                  ),
                if (!subscribed) SubscriptionValue(catalog: catalog, byId: byId),
                if (products.hasValue && byId.isEmpty) const _StoreUnavailable(),
                const RefSection('Pakiety'),
                for (final pack in catalog.packs)
                  _PackCard(
                    summary: PackSummary(pack, catalog),
                    product: byId[pack.storeProductId],
                    owned: ownsPack(scopes, pack.id),
                  ),
                if (!subscribed) ...[
                  const RefSection('Zestawy, taniej razem'),
                  for (final id in [ProductIds.bundleTwo, ProductIds.bundleThree])
                    _BundleCard(
                      productId: id,
                      packs: bundlePacks(id, catalog),
                      product: byId[id],
                      packProducts: [for (final p in bundlePacks(id, catalog)) byId[p.storeProductId]],
                      owned: bundlePacks(id, catalog).every((p) => ownsPack(scopes, p.id)),
                    ),
                ],
                if (!subscribed) _SinglePlays(catalog: catalog, byId: byId),
                _PriceList(catalog: catalog, byId: byId),
                const SizedBox(height: 12),
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
                  onPressed: busy == null
                      ? () => buyWithGate(context, ref, widget.byId[item.storeProductId]!)
                      : null,
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

/// Every price in one place, the same as on audiokiddo.pl. Bundles show the packs' total
/// crossed out, because that is what they really save.
class _PriceList extends StatelessWidget {
  const _PriceList({required this.catalog, required this.byId});

  final Catalog catalog;
  final Map<String, StoreProduct> byId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final rows = <(String, StoreProduct, String?)>[
      if (byId[ProductIds.monthly] case final m?) ('Abonament miesięczny', m, null),
      if (byId[ProductIds.yearly] case final y?) ('Abonament roczny', y, null),
      for (final pack in catalog.packs)
        if (byId[pack.storeProductId] case final p?) ('Pakiet ${pack.title}', p, null),
      for (final id in [ProductIds.bundleTwo, ProductIds.bundleThree])
        if (byId[id] case final b?)
          (
            'Zestaw ${bundlePacks(id, catalog).length} pakietów',
            b,
            _sum([for (final p in bundlePacks(id, catalog)) byId[p.storeProductId]], b.currencyCode),
          ),
    ];
    final singles = [for (final i in catalog.items) ?byId[i.storeProductId]?.rawPrice];
    if (rows.isEmpty) return const SizedBox.shrink();
    final from = singles.isEmpty ? null : singles.reduce((a, b) => a < b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RefSection('Cennik'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: akSoftShadow(context),
          ),
          child: Column(
            children: [
              for (final (label, product, crossed) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(label, style: text.bodyMedium)),
                      if (crossed != null) ...[
                        Text(
                          crossed,
                          style: text.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: context.palette.inkMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(product.price, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              if (from != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text('Pojedyncza zabawa', style: text.bodyMedium)),
                      Text(
                        'od ${formatMoney(from, byId.values.first.currencyCode)}',
                        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ceny są takie same jak na audiokiddo.pl. Pakiety kupujesz raz i zostają na zawsze.',
          style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
        ),
      ],
    );
  }

  static String? _sum(List<StoreProduct?> products, String? currency) {
    if (products.isEmpty || products.any((p) => p?.rawPrice == null)) return null;
    return formatMoney(products.fold(0.0, (a, p) => a + p!.rawPrice!), currency);
  }
}

class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard({this.yearly, this.monthly, required this.itemCount, required this.loading});

  final StoreProduct? yearly;
  final StoreProduct? monthly;
  final int itemCount;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final busy = ref.watch(purchaseControllerProvider).busyProductId;
    final trial = yearly?.freeTrialDays ?? monthly?.freeTrialDays;
    final discount = yearly != null && monthly != null ? yearlyDiscountPercent(yearly!, monthly!) : null;
    final perMonth = yearly?.rawPrice == null
        ? null
        : formatMoney(yearly!.rawPrice! / 12, yearly!.currencyCode);
    const onDark = Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(color: referencePurple, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Wszystko w jednym',
                  style: text.titleLarge?.copyWith(color: onDark, fontWeight: FontWeight.w800),
                ),
              ),
              if (trial != null)
                _Badge('$trial dni za darmo', color: AkBrand.sun, ink: const Color(0xFF211C35)),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in [
            'Wszystkie ${playsCount(itemCount)}: pakiety, piosenki i gry',
            'Jeden nowy pakiet zabaw co miesiąc',
            'Na wszystkie dzieci w rodzinie, bez reklam',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AkBrand.sun, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(line, style: text.bodyMedium?.copyWith(color: onDark)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(color: onDark)),
            ),
          if (yearly case final y?)
            _PlanButton(
              title: 'Rocznie',
              price: '${y.price} / rok',
              note: [
                if (perMonth != null) 'to $perMonth miesięcznie',
                if (discount != null) 'taniej o $discount%',
              ].join(' · '),
              highlight: true,
              busy: busy == y.id,
              onTap: busy == null ? () => buyWithGate(context, ref, y) : null,
            ),
          if (monthly case final m?)
            _PlanButton(
              title: 'Miesięcznie',
              price: '${m.price} / mies.',
              note: 'możesz zrezygnować w każdej chwili',
              busy: busy == m.id,
              onTap: busy == null ? () => buyWithGate(context, ref, m) : null,
            ),
          if (trial != null)
            Text(
              'Pierwsze $trial dni za darmo. Zrezygnujesz przed ich końcem, a nie zapłacisz ani grosza.',
              style: text.bodySmall?.copyWith(color: onDark.withValues(alpha: .8)),
            ),
        ],
      ),
    );
  }
}

class _PlanButton extends StatelessWidget {
  const _PlanButton({
    required this.title,
    required this.price,
    required this.note,
    required this.busy,
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final String price;
  final String note;
  final bool busy;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bg = highlight ? AkBrand.sun : Colors.white.withValues(alpha: .12);
    final ink = highlight ? const Color(0xFF211C35) : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: '$title, $price${note.isEmpty ? '' : ', $note'}',
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (busy)
                      SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 3, color: ink),
                      )
                    else
                      Flexible(
                        flex: 2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            price,
                            style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                if (note.isNotEmpty) Text(note, style: text.bodySmall?.copyWith(color: ink)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullAccessCard extends StatelessWidget {
  const _FullAccessCard();

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => openWithGate(context, manageSubscriptionsUrl),
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
      decoration: BoxDecoration(
        color: AkBrand.teal.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
      ),
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

class _PackCard extends ConsumerWidget {
  const _PackCard({required this.summary, required this.product, required this.owned});

  final PackSummary summary;
  final StoreProduct? product;
  final bool owned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final pack = summary.pack;
    final free = summary.freeItems.firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () => openPack(context, pack.id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: akSoftShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox.square(dimension: 84, child: PackArt(summary: summary)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                pack.title,
                                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (isNewAt(pack.releasedOn, ref.watch(clockProvider)())) ...[
                              const SizedBox(width: 6),
                              const _Badge('Nowy', color: AkBrand.sun),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${playsCount(summary.items.length)} · ${summary.minutes} min · od ${pack.ageMin} lat',
                          style: text.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [for (final s in summary.skills.take(2)) _Badge(s)],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (owned)
                    const _Badge('Masz ten pakiet', color: referenceMint, icon: Icons.check_rounded)
                  else if (free != null)
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => context.push('/zabawa/${free.id}'),
                        icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                        label: Text('Za darmo: ${free.title}', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  if (owned || free == null) const Spacer(),
                  if (!owned)
                    Text(product?.price ?? '', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleCard extends ConsumerWidget {
  const _BundleCard({
    required this.productId,
    required this.packs,
    required this.product,
    required this.packProducts,
    required this.owned,
  });

  final String productId;
  final List<Pack> packs;
  final StoreProduct? product;
  final List<StoreProduct?> packProducts;
  final bool owned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final busy = ref.watch(purchaseControllerProvider).busyProductId;
    final saved = product == null ? null : bundleSavings(product!, packProducts);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: referenceLilac.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    packs.length == 2 ? 'Zestaw 2 pakietów' : 'Wszystkie ${packs.length} pakiety',
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(packs.map((p) => p.title).join(' + '), style: text.bodySmall),
                  if (saved != null && !owned)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _Badge(
                        'taniej o ${formatMoney(saved, product!.currencyCode)}',
                        color: AkBrand.sun,
                        ink: const Color(0xFF211C35),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (owned)
              const _Badge('Masz', color: referenceMint, icon: Icons.check_rounded)
            else if (product case final p?)
              FilledButton(
                onPressed: busy == null ? () => buyWithGate(context, ref, p) : null,
                child: busy == p.id
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(p.price),
              ),
          ],
        ),
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
  const _Badge(this.label, {this.color, this.ink, this.icon});

  final String label;
  final Color? color;
  final Color? ink;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = ink ?? const Color(0xFF211C35);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
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
    return Scaffold(
      appBar: AppBar(
        // Opened from a link there is nothing to go back to: lead to the Shop tab instead.
        leading: context.canPop()
            ? null
            : IconButton(
                tooltip: 'Sklep',
                onPressed: () => context.go('/sklep'),
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
          final product = byId[pack.storeProductId];
          final text = Theme.of(context).textTheme;
          final child = ref.watch(familyProvider).value?.active;
          final done = child == null
              ? 0
              : {
                  for (final r in ref.watch(familyProvider).value!.resultsOf(child.id))
                    if (r.completed && summary.items.any((i) => i.id == r.itemId)) r.itemId,
                }.length;
          final bundle = [ProductIds.bundleTwo, ProductIds.bundleThree]
              .where((id) => bundlePacks(id, catalog).any((p) => p.id == pack.id))
              .map((id) => (id: id, product: byId[id], packs: bundlePacks(id, catalog)))
              .where((b) => b.product != null)
              .firstOrNull;
          final bundleSaved = bundle == null
              ? null
              : bundleSavings(bundle.product!, [for (final p in bundle.packs) byId[p.storeProductId]]);
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
                    if (pack.guide != null) ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () => openPackMaterials(context, pack.id),
                        icon: const Icon(Icons.smart_display_rounded),
                        label: const Text('Filmy i materiały do zabaw'),
                      ),
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
                      Text(
                        '${child.name.isEmpty ? 'Dziecko' : child.name}: ukończone $done z ${summary.items.length}',
                      ),
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
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      boxShadow: akSoftShadow(context),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: product == null || busy != null
                                ? null
                                : () => buyWithGate(context, ref, product),
                            child: busy == product?.id && product != null
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    product == null ? 'Sklep niedostępny' : 'Kup pakiet · ${product.price}',
                                  ),
                          ),
                        ),
                        if (bundle != null && bundleSaved != null)
                          TextButton(
                            onPressed: busy == null ? () => buyWithGate(context, ref, bundle.product!) : null,
                            child: Text(
                              'Zestaw z ${bundle.packs.length > 2 ? 'pakietami' : 'pakietem'} ${bundle.packs.where((p) => p.id != pack.id).map((p) => p.title).join(' i ')}: '
                              '${bundle.product!.price} (taniej o ${formatMoney(bundleSaved, bundle.product!.currencyCode)})',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        TextButton(
                          onPressed: () => context.go('/sklep'),
                          child: const Text('Albo wszystko w abonamencie'),
                        ),
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
