import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'library_filter.dart';
import 'widgets/catalog_loader.dart';
import 'widgets/content_cover.dart';
import 'widgets/item_views.dart';
import 'widgets/labels.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CatalogLoader(builder: (context, catalog) => _HomeContent(catalog: catalog)),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final featured = catalog.shelves.where((s) => s.kind == ShelfKind.featured && s.itemIds.isNotEmpty);
    final rows = catalog.shelves.where((s) => s.kind == ShelfKind.row && s.itemIds.isNotEmpty);
    final ages = {for (final p in catalog.packs) p.ageMin}.toList()..sort();

    return ListView(
      padding: const EdgeInsets.only(bottom: AkSpace.xl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeGreeting, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AkSpace.xs),
              Text(
                l10n.homeSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.palette.inkMuted),
              ),
            ],
          ),
        ),
        if (featured.isNotEmpty) ...[
          SectionHeader(l10n.homeFeatured),
          _FeaturedCard(item: catalog.item(featured.first.itemIds.first)!, catalog: catalog),
        ],
        SectionHeader(l10n.homeStartHere),
        _AgeGroups(ages: ages),
        SectionHeader(l10n.homeWhatAreYouDoing),
        const _Situations(),
        SectionHeader(l10n.homePacks),
        _Packs(catalog: catalog),
        for (final shelf in rows) ...[
          SectionHeader(shelf.title),
          _ShelfRow(items: [for (final id in shelf.itemIds) catalog.item(id)!], catalog: catalog),
        ],
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.catalog});

  final ContentItem item;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pack = item.packId == null ? null : catalog.pack(item.packId!);
    final color = pack == null ? AkBrand.cream : AkPalette.packColor(pack.colorToken);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
      child: Semantics(
        button: true,
        label: '${l10n.homeFeatured}: ${item.title}, ${l10n.duration(item.durationSec)}',
        excludeSemantics: true,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(AkRadius.card),
          child: InkWell(
            borderRadius: BorderRadius.circular(AkRadius.card),
            onTap: () => context.push(itemRoute(item)),
            child: Padding(
              padding: const EdgeInsets.all(AkSpace.m),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pack != null)
                          Text(pack.title, style: text.labelLarge?.copyWith(color: AkBrand.ink)),
                        const SizedBox(height: AkSpace.xs),
                        Text(
                          item.title,
                          style: text.headlineSmall?.copyWith(
                            color: AkBrand.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AkSpace.s),
                        Text(
                          '${l10n.duration(item.durationSec)} · ${l10n.ageFrom(item.ageMin)}',
                          style: text.bodyMedium?.copyWith(color: AkBrand.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AkSpace.m),
                  ContentCover(item: item, pack: pack, size: 96),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgeGroups extends StatelessWidget {
  const _AgeGroups({required this.ages});

  final List<int> ages;

  static const _colors = [AkBrand.lavender, AkBrand.teal, AkBrand.sun, AkBrand.orange];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 88 + MediaQuery.textScalerOf(context).scale(24),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
        itemCount: ages.length,
        separatorBuilder: (_, _) => const SizedBox(width: AkSpace.m),
        itemBuilder: (context, i) => Semantics(
          button: true,
          label: l10n.ageGroupLabel(ages[i]),
          excludeSemantics: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.go(LibraryFilter(age: ages[i]).toLocation()),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: _colors[i % _colors.length],
                  child: Text(
                    l10n.ageFrom(ages[i]),
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: AkBrand.ink, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AkSpace.xs),
                Text(l10n.ageGroupLabel(ages[i]), style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Situations extends StatelessWidget {
  const _Situations();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AkSpace.s,
        crossAxisSpacing: AkSpace.s,
        childAspectRatio: 2.4,
        children: [
          for (final s in Situation.values)
            Material(
              color: palette.surface,
              borderRadius: BorderRadius.circular(AkRadius.card),
              child: InkWell(
                borderRadius: BorderRadius.circular(AkRadius.card),
                onTap: () => context.go(LibraryFilter(situation: s).toLocation()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
                  child: Row(
                    children: [
                      Icon(situationIcon(s), color: palette.primary),
                      const SizedBox(width: AkSpace.s),
                      Expanded(child: Text(l10n.situation(s), style: Theme.of(context).textTheme.titleSmall)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Packs extends StatelessWidget {
  const _Packs({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: 84 + MediaQuery.textScalerOf(context).scale(56),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
        itemCount: catalog.packs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AkSpace.s),
        itemBuilder: (context, i) {
          final pack = catalog.packs[i];
          final count = catalog.itemsInPack(pack.id).length;
          return Material(
            color: AkPalette.packColor(pack.colorToken),
            borderRadius: BorderRadius.circular(AkRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AkRadius.card),
              onTap: () => context.go(LibraryFilter(packId: pack.id).toLocation()),
              child: SizedBox(
                width: 190,
                child: Padding(
                  padding: const EdgeInsets.all(AkSpace.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pack.title,
                        style: text.titleLarge?.copyWith(color: AkBrand.ink, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${l10n.itemsCount(count)} · ${l10n.ageFrom(pack.ageMin)}',
                        style: text.bodyMedium?.copyWith(color: AkBrand.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({required this.items, required this.catalog});

  final List<ContentItem> items;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemCardShelfHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AkSpace.m),
        itemBuilder: (context, i) => ItemCard(item: items[i], catalog: catalog),
      ),
    );
  }
}
