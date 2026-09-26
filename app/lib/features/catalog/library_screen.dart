import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'library_filter.dart';
import 'widgets/catalog_loader.dart';
import 'widgets/item_views.dart';
import 'widgets/labels.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.filter});

  final LibraryFilter filter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).navLibrary,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: CatalogLoader(
        builder: (context, catalog) => _LibraryContent(catalog: catalog, filter: filter),
      ),
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({required this.catalog, required this.filter});

  final Catalog catalog;
  final LibraryFilter filter;

  void _set(BuildContext context, LibraryFilter next) => context.go(next.toLocation());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = filter.apply(catalog.items);
    final ages = {for (final p in catalog.packs) p.ageMin}.toList()..sort();
    final kinds = {for (final i in catalog.items) i.kind}.toList()..sort((a, b) => a.index - b.index);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ChipRow(
                children: [
                  ChoiceChip(
                    label: Text(l10n.kindAll),
                    selected: filter.kind == null,
                    onSelected: (_) => _set(context, filter.copyWith(kind: () => null)),
                  ),
                  for (final k in kinds)
                    ChoiceChip(
                      label: Text(l10n.kind(k)),
                      selected: filter.kind == k,
                      onSelected: (on) => _set(context, filter.copyWith(kind: () => on ? k : null)),
                    ),
                ],
              ),
              _ChipRow(
                label: l10n.filterPack,
                children: [
                  for (final p in catalog.packs)
                    FilterChip(
                      label: Text(p.title),
                      selected: filter.packId == p.id,
                      onSelected: (on) => _set(context, filter.copyWith(packId: () => on ? p.id : null)),
                    ),
                ],
              ),
              _ChipRow(
                label: l10n.filterAge,
                children: [
                  for (final a in ages)
                    FilterChip(
                      label: Text(l10n.ageFrom(a)),
                      selected: filter.age == a,
                      onSelected: (on) => _set(context, filter.copyWith(age: () => on ? a : null)),
                    ),
                ],
              ),
              _ChipRow(
                label: l10n.filterSituation,
                children: [
                  for (final s in Situation.values)
                    FilterChip(
                      avatar: Icon(situationIcon(s), size: 18),
                      label: Text(l10n.situation(s)),
                      selected: filter.situation == s,
                      onSelected: (on) => _set(context, filter.copyWith(situation: () => on ? s : null)),
                    ),
                ],
              ),
              if (!filter.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AkSpace.s),
                  child: TextButton.icon(
                    onPressed: () => _set(context, const LibraryFilter()),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l10n.filterClear),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.s, AkSpace.m, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.resultsCount(items.length),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: context.palette.inkMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AkSpace.l),
                child: Text(l10n.libraryEmpty, textAlign: TextAlign.center),
              ),
            ),
          )
        else
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => ItemTile(item: items[i], catalog: catalog),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AkSpace.xl)),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children, this.label});

  final String? label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.xs, AkSpace.m, AkSpace.xs),
        child: Row(
          children: [
            for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(width: AkSpace.s), c],
          ],
        ),
      ),
    );
  }
}
