import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'library_filter.dart';
import 'widgets/catalog_loader.dart';
import 'widgets/item_views.dart';
import 'widgets/labels.dart';
import 'widgets/pack_row.dart';

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
    final kinds = {for (final i in catalog.items) i.kind}.toList()..sort((a, b) => a.index - b.index);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (filter.isEmpty && catalog.packs.isNotEmpty) ...[
                SectionHeader(l10n.homePacks),
                PackRow(catalog: catalog),
                const SizedBox(height: AkSpace.s),
              ],
              _ChipRow(
                children: [
                  ChoiceChip(
                    label: Text(l10n.kindAll),
                    selected: filter.kind == null,
                    labelStyle: selectableChipLabel(context, selected: filter.kind == null),
                    onSelected: (_) => _set(context, filter.copyWith(kind: () => null)),
                  ),
                  for (final k in kinds)
                    ChoiceChip(
                      label: Text(l10n.kind(k)),
                      selected: filter.kind == k,
                      labelStyle: selectableChipLabel(context, selected: filter.kind == k),
                      onSelected: (on) => _set(context, filter.copyWith(kind: () => on ? k : null)),
                    ),
                ],
              ),
              // One row always visible; the rest waits behind "Filtry" and shows as chips when used.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
                child: Wrap(
                  spacing: AkSpace.s,
                  runSpacing: AkSpace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showFilters(context, catalog, filter, (next) => _set(context, next)),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                      icon: const Icon(Icons.tune_rounded, size: 20),
                      label: Text(l10n.filtersButton(filter.extraCount)),
                    ),
                    if (filter.packId case final id?)
                      InputChip(
                        label: Text(catalog.pack(id)?.title ?? id),
                        onDeleted: () => _set(context, filter.copyWith(packId: () => null)),
                      ),
                    if (filter.age case final age?)
                      InputChip(
                        label: Text(l10n.ageFrom(age)),
                        onDeleted: () => _set(context, filter.copyWith(age: () => null)),
                      ),
                    if (filter.situation case final situation?)
                      InputChip(
                        avatar: Icon(situationIcon(situation), size: 18),
                        label: Text(l10n.situation(situation)),
                        onDeleted: () => _set(context, filter.copyWith(situation: () => null)),
                      ),
                  ],
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
        SliverToBoxAdapter(child: SizedBox(height: AkSpace.xl + MediaQuery.paddingOf(context).bottom)),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
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

/// Pack, age and situation in one sheet; every change applies at once.
Future<void> _showFilters(
  BuildContext context,
  Catalog catalog,
  LibraryFilter initial,
  ValueChanged<LibraryFilter> apply,
) {
  final l10n = AppLocalizations.of(context);
  final ages = {for (final p in catalog.packs) p.ageMin}.toList()..sort();
  var filter = initial;
  return showModalBottomSheet<void>(
    context: context,
    // Above the tab bar, not inside the tab.
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        void set(LibraryFilter next) {
          setSheet(() => filter = next);
          apply(next);
        }

        Widget group(String title, List<Widget> chips) => Padding(
          padding: const EdgeInsets.only(bottom: AkSpace.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AkSpace.xs),
              Wrap(spacing: AkSpace.s, runSpacing: AkSpace.s, children: chips),
            ],
          ),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                group(l10n.filterAge, [
                  for (final a in ages)
                    FilterChip(
                      label: Text(l10n.ageFrom(a)),
                      selected: filter.age == a,
                      labelStyle: selectableChipLabel(context, selected: filter.age == a),
                      onSelected: (on) => set(filter.copyWith(age: () => on ? a : null)),
                    ),
                ]),
                group(l10n.filterSituation, [
                  for (final s in Situation.values)
                    FilterChip(
                      avatar: Icon(situationIcon(s), size: 18),
                      label: Text(l10n.situation(s)),
                      selected: filter.situation == s,
                      labelStyle: selectableChipLabel(context, selected: filter.situation == s),
                      onSelected: (on) => set(filter.copyWith(situation: () => on ? s : null)),
                    ),
                ]),
                group(l10n.filterPack, [
                  for (final p in catalog.packs)
                    FilterChip(
                      label: Text(p.title),
                      selected: filter.packId == p.id,
                      labelStyle: selectableChipLabel(context, selected: filter.packId == p.id),
                      onSelected: (on) => set(filter.copyWith(packId: () => on ? p.id : null)),
                    ),
                ]),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: () => Navigator.pop(context), child: Text(l10n.filtersDone)),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
