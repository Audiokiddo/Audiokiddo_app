import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/widgets/catalog_loader.dart';
import '../discovery/discovery_model.dart';
import '../discovery/reference_widgets.dart';
import '../family/family.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import 'shop.dart';
import 'store_gateway.dart';

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
            'Nowe przygody, gdy tylko się pojawią',
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: referenceMint, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AkBrand.tealDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Masz pełny dostęp',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Wszystkie pakiety i nowości są odblokowane. Miłego słuchania.', style: text.bodyMedium),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
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

/// Pack artwork from the kind of play most of its items are.
class PackArt extends StatelessWidget {
  const PackArt({super.key, required this.summary, this.radius = 18});

  final PackSummary summary;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: ArtScene(
      category: summary.items.isEmpty ? PlayCategory.adventure : itemCategory(summary.items.first),
      seed: summary.pack.id.codeUnits.fold(0, (a, b) => a + b) % 5,
    ),
  );
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
                        Text(pack.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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
          title: const Text('Kupione na audiokiddo.pl?'),
          subtitle: const Text('Zaloguj się tym samym adresem e-mail, a pakiety pojawią się tutaj.'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/konto'),
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
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: PackArt(summary: summary, radius: 24),
                    ),
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
