import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../welcome/szop_tour.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../discovery/reference_widgets.dart';
import '../downloads/download_providers.dart';
import '../family/family.dart' hide progressProvider;
import '../kids_mode/kids_mode_setup.dart';
import '../purchases/shop.dart';
import '../purchases/purchase_controller.dart';
import '../purchases/shop_screen.dart';
import '../purchases/store_gateway.dart';
import '../insights/events.dart';
import 'catalog_providers.dart';
import 'library_filter.dart';
import 'widgets/catalog_loader.dart';
import 'seasonal.dart';
import 'widgets/content_cover.dart';

/// The library: the packs the family has (with how far the child got), the ones to unlock,
/// parent shortcuts for everyday situations, then filters and categories. Any filter or a
/// search turns it into a list of matching plays.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.filter = const LibraryFilter()});
  final LibraryFilter filter;
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _search = '';
  bool _searching = false;
  Timer? _searchPause;

  @override
  void dispose() {
    _searchPause?.cancel();
    super.dispose();
  }

  /// What parents look for tells what the library lacks: sent once typing pauses.
  void _typed(String query, int Function(String) results) {
    setState(() => _search = query);
    _searchPause?.cancel();
    final q = query.trim().toLowerCase();
    if (q.length < 2) return;
    _searchPause = Timer(const Duration(milliseconds: 1500), () {
      ref
          .read(eventSinkProvider)
          .track(
            AppEvent.searchPerformed,
            props: {'query': q.length > 40 ? q.substring(0, 40) : q, 'results': results(q)},
          );
    });
  }

  /// From the library a filter opens as its own page (swipe back returns); changing a filter
  /// on that page replaces it.
  void _set(LibraryFilter f) {
    if (f.isEmpty) {
      context.canPop() ? context.pop() : context.go(f.toLocation());
    } else if (widget.filter.isEmpty) {
      context.push(f.toLocation());
    } else {
      context.replace(f.toLocation());
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.filter;
    final searching = _searching || GoRouterState.of(context).uri.queryParameters['szukaj'] == '1';
    final browsing = f.isEmpty && !searching;
    return Scaffold(
      appBar: AppBar(
        title: Text(browsing ? 'Biblioteka' : _title(f)),
        leading: browsing
            ? null
            : IconButton(
                tooltip: 'Wróć',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _searching = false;
                    _search = '';
                  });
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    _set(const LibraryFilter());
                  }
                },
              ),
        actions: [
          if (!searching)
            IconButton(
              tooltip: 'Szukaj',
              onPressed: () => setState(() => _searching = true),
              icon: const Icon(Icons.search_rounded),
            ),
          IconButton(
            tooltip: 'Ulubione',
            onPressed: () => context.push('/ulubione'),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: CatalogLoader(
        builder: (context, catalog) => browsing
            ? _Browse(catalog: catalog, onFilter: _set, onSearch: () => setState(() => _searching = true))
            : _results(context, catalog, f, searching),
      ),
    );
  }

  String _title(LibraryFilter f) => switch (f) {
    LibraryFilter(:final category?) => category.label.replaceAll('\n', ' '),
    LibraryFilter(noPrep: true) => 'Bez przygotowań',
    LibraryFilter(printable: true) => 'Do druku',
    LibraryFilter(lyingDown: true) => 'Na leżąco',
    LibraryFilter(kind: ContentKind.song) => 'Piosenki',
    LibraryFilter(kind: ContentKind.interactiveGame) => 'Gry z odpowiedziami',
    LibraryFilter(kind: ContentKind.audioGame) => 'Audiozabawy',
    _ => 'Wyniki',
  };

  Widget _results(BuildContext context, Catalog catalog, LibraryFilter f, bool searching) {
    final query = _search.toLowerCase();
    final items = f
        .apply(catalog.items, canPlay: (i) => ref.watch(canPlayProvider(i)))
        .where((i) => i.title.toLowerCase().contains(query))
        .toList();
    final pack = f.packId == null ? null : catalog.pack(f.packId!);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (searching)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Tytuł zabawy lub piosenki',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
              onChanged: (s) => _typed(
                s,
                (q) => f
                    .apply(catalog.items, canPlay: (i) => ref.read(canPlayProvider(i)))
                    .where((i) => i.title.toLowerCase().contains(q))
                    .length,
              ),
            ),
          ),
        if (pack != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(pack.title, style: Theme.of(context).textTheme.titleLarge),
          ),
        _FilterChips(filter: f, onChanged: _set),
        RefSection(items.length == 1 ? '1 propozycja' : '${items.length} propozycji'),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Nie znaleźliśmy takiej zabawy. Zmień wiek, czas lub wpisany tytuł.'),
          ),
        for (final item in items) AudioRow(item: item),
      ],
    );
  }
}

/// The library before any filter, like a catalog: "Moje pakiety" on top (what the family has,
/// one tap away), search and quick filters, the newest plays, categories as a list with counts,
/// every pack as a collection (cover, what it is, how many plays, what is free and the price),
/// then songs and the parent's tools.
class _Browse extends ConsumerWidget {
  const _Browse({required this.catalog, required this.onFilter, required this.onSearch});

  final Catalog catalog;
  final ValueChanged<LibraryFilter> onFilter;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopes = ref.watch(activeScopesProvider);
    final summaries = [for (final p in catalog.packs) PackSummary(p, catalog)];
    final owned = [for (final s in summaries) if (ownsPack(scopes, s.pack.id)) s];
    final toDiscover = [for (final s in summaries) if (!ownsPack(scopes, s.pack.id)) s];
    final loose = [
      for (final i in catalog.items)
        if (i.packId == null && i.releasedOn?.isAfter(ref.watch(clockProvider)()) != true) i,
    ];
    final fresh = ref.watch(newItemsProvider);
    final products = ref.watch(storeProductsProvider(productsKey(shopProductIds(catalog))));
    final byId = {for (final p in products.value ?? const <StoreProduct>[]) p.id: p};
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        const MyPacksTile(),
        const SizedBox(height: 14),
        _SearchField(onTap: onSearch),
        const SizedBox(height: 10),
        _QuickChips(onFilter: onFilter),
        const SizedBox(height: 14),
        _PrintBanner(catalog: catalog, onFilter: onFilter),
        if (fresh.isNotEmpty) ...[
          const RefSection('Najnowsze'),
          _Covers(items: fresh.take(10).toList()),
        ],
        const RefSection('Kategorie'),
        _CategoryList(onFilter: onFilter),
        if (toDiscover.isNotEmpty) ...[
          RefSection(owned.isEmpty ? 'Pakiety' : 'Do odkrycia'),
          for (final s in toDiscover) _CollectionRow(summary: s, product: byId[s.pack.storeProductId]),
        ],
        if (loose.isNotEmpty) _Shelf(title: 'Piosenki i inne', items: loose),
        const Padding(padding: EdgeInsets.only(top: 8), child: Center(child: RedeemAccessLink())),
        const RefSection('Dla rodzica'),
        _ParentTools(onFilter: onFilter),
      ],
    );
  }
}

/// "Do druku": case files, cards and guides, as a bright card near the top of the library so
/// parents find the printables without scrolling to the tools.
class _PrintBanner extends StatelessWidget {
  const _PrintBanner({required this.catalog, required this.onFilter});

  final Catalog catalog;
  final ValueChanged<LibraryFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    const filter = LibraryFilter(printable: true);
    final count = filter.apply(catalog.items).length;
    if (count == 0) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Material(
      color: AkBrand.sun,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onFilter(filter),
        child: Semantics(
          button: true,
          label: 'Do druku: akta sprawy, ${playsLabel(count)} z pakietu Detektyw',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), shape: BoxShape.circle),
                  child: const Icon(Icons.print_rounded, color: ink, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Do druku', style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800)),
                      Text(
                        'Akta sprawy z pakietu Detektyw: ${playsLabel(count)} z kartą do wydrukowania.',
                        style: text.bodySmall?.copyWith(color: ink),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the family can start right now: whole packs they have, and from the other packs the
/// plays that are free (or bought one by one), plus playable plays outside packs.
({List<PackSummary> owned, List<(PackSummary, List<ContentItem>)> partial, List<ContentItem> loose}) playableNow(
  WidgetRef ref,
  Catalog catalog,
) {
  final scopes = ref.watch(activeScopesProvider);
  final now = ref.watch(clockProvider)();
  bool open(ContentItem i) => i.releasedOn?.isAfter(now) != true && ref.watch(canPlayProvider(i));
  final owned = <PackSummary>[];
  final partial = <(PackSummary, List<ContentItem>)>[];
  for (final p in catalog.packs) {
    final s = PackSummary(p, catalog);
    if (ownsPack(scopes, p.id)) {
      owned.add(s);
    } else {
      final playable = s.items.where(open).toList();
      if (playable.isNotEmpty) partial.add((s, playable));
    }
  }
  final loose = [
    for (final i in catalog.items)
      if (i.packId == null && open(i)) i,
  ];
  return (owned: owned, partial: partial, loose: loose);
}

/// "Moje pakiety": on Start and first in the library. Everything the family can start right
/// now, in one place: their packs, the free plays of the others and free plays outside packs.
class MyPacksTile extends ConsumerWidget {
  const MyPacksTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    if (catalog == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    const ink = Colors.white;
    final now = playableNow(ref, catalog);
    final items = [
      for (final s in now.owned) ...s.items,
      for (final (_, free) in now.partial) ...free,
      ...now.loose,
    ];
    final heard = _heardIn(ref, items);
    final subtitle = [
      '${playsCount(items.length)} do włączenia od razu',
      if (now.owned.isNotEmpty) packsCount(now.owned.length) else 'w tym darmowe',
      if (heard > 0) 'przesłuchane $heard',
    ].join(' · ');
    final art = now.owned.firstOrNull ?? now.partial.firstOrNull?.$1;
    return Semantics(
      button: true,
      label: 'Moje pakiety. $subtitle',
      excludeSemantics: true,
      child: Material(
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AkBrand.tealDeep, Color(0xFF145457)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            onTap: () => context.push('/biblioteka/moje-pakiety'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (art != null)
                    SizedBox.square(dimension: 56, child: PackArt(summary: art, radius: 14))
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.collections_bookmark_rounded, color: AkBrand.sun, size: 30),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Moje pakiety',
                          style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: text.bodySmall?.copyWith(color: ink.withValues(alpha: .9))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plays of [items] the active child finished.
int _heardIn(WidgetRef ref, List<ContentItem> items) {
  final family = ref.watch(familyProvider).value;
  final child = family?.active;
  if (child == null) return 0;
  final ids = {for (final i in items) i.id};
  return {
    for (final r in family!.resultsOf(child.id))
      if (r.completed && ids.contains(r.itemId)) r.itemId,
  }.length;
}

/// "1 pakiet", "2 pakiety", "5 pakietów".
String packsCount(int n) {
  final word = n == 1
      ? 'pakiet'
      : (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 12 || n % 100 > 14))
      ? 'pakiety'
      : 'pakietów';
  return '$n $word';
}

/// Everything the family can start right now: their packs whole, then the free plays of the
/// other packs (each shelf says how many are free and opens the pack), then other free plays.
class MyPacksScreen extends ConsumerWidget {
  const MyPacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Moje pakiety')),
      body: CatalogLoader(
        builder: (context, catalog) {
          final now = playableNow(ref, catalog);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text(
                'Wszystko tutaj możecie włączyć od razu.',
                style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
              ),
              if (now.owned.isNotEmpty) ...[
                const RefSection('Wasze pakiety'),
                for (final s in now.owned) _PackShelf(summary: s),
              ],
              if (now.partial.isNotEmpty) ...[
                RefSection(now.owned.isEmpty ? 'Darmowe zabawy z pakietów' : 'Darmowe z innych pakietów'),
                for (final (s, free) in now.partial) _PackShelf(summary: s, playable: free),
              ],
              if (now.loose.isNotEmpty) _Shelf(title: 'Inne darmowe zabawy', items: now.loose),
              if (now.owned.isEmpty) ...[
                const SizedBox(height: 18),
                Text('Abonament otwiera wszystkie pakiety, a co tydzień dochodzą 2 nowe zabawy.', style: text.bodyMedium),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: () => context.go('/sklep'),
                    child: const Text('Zobacz abonament'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Categories as a list, like a catalog: icon, name, how many plays, chevron.
class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.onFilter});

  final ValueChanged<LibraryFilter> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(catalogProvider).value?.items ?? const <ContentItem>[];
    final text = Theme.of(context).textTheme;
    final categories = ref.watch(shownCategoriesProvider);
    return Column(
      children: [
        for (final (i, c) in categories.indexed) ...[
          if (i > 0) Divider(height: 1, indent: 52, color: context.palette.inkMuted.withValues(alpha: .25)),
          Semantics(
            button: true,
            label: '${c.label.replaceAll('\n', ' ')}, ${playsCount(items.where(c.matches).length)}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onFilter(LibraryFilter(category: c)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: categoryLook[c]!.$1, shape: BoxShape.circle),
                      child: Icon(categoryLook[c]!.$3, color: categoryLook[c]!.$2, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        c.label.replaceAll('\n', ' '),
                        style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${items.where(c.matches).length}',
                      style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
                    ),
                    Icon(Icons.chevron_right_rounded, color: context.palette.inkMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A pack as a collection: its picture, name, what it is about, how many plays, what is free.
class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.summary, this.product});

  final PackSummary summary;
  final StoreProduct? product;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final free = summary.freeItems.length;
    final total = summary.items.length;
    return Semantics(
      button: true,
      label: '${summary.pack.title}, ${playsCount(total)}, $free za darmo${product == null ? '' : ', ${product!.price}'}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openPack(context, summary.pack.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(dimension: 92, child: PackArt(summary: summary, radius: 16)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.pack.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      summary.pack.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Tag('${playsCount(total)} · ${summary.minutes} min'),
                        if (free > 0) _Tag(free == 1 ? '1 za darmo' : '$free za darmo', strong: true),
                        if (product != null) _Tag(product!.price, strong: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the filters parents reach for most, scrolled sideways.
class _QuickChips extends ConsumerWidget {
  const _QuickChips({required this.onFilter});

  final ValueChanged<LibraryFilter> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = <(String, LibraryFilter)>[
      ('3–5 lat', const LibraryFilter(age: 5, ageFrom: 3)),
      ('5–7 lat', const LibraryFilter(age: 7, ageFrom: 5)),
      ('7–9 lat', const LibraryFilter(age: 9, ageFrom: 7)),
      ('Do 10 min', const LibraryFilter(maxMinutes: 10)),
      ('Bez przygotowań', const LibraryFilter(noPrep: true)),
      ('Na leżąco', const LibraryFilter(lyingDown: true)),
      ('Gry z odpowiedziami', const LibraryFilter(kind: ContentKind.interactiveGame)),
      if (ref.watch(hasSongsProvider)) ('Piosenki', const LibraryFilter(kind: ContentKind.song)),
      ('Dostępne dla nas', const LibraryFilter(available: true)),
    ];
    return SizedBox(
      height: 44 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(label: Text(chips[i].$1), onPressed: () => onFilter(chips[i].$2)),
      ),
    );
  }
}

/// One of the family's packs as a shelf: a header that opens the pack page, how far the child
/// got, and its plays as covers, each straight to its page.
class _PackShelf extends ConsumerWidget {
  const _PackShelf({required this.summary, this.playable});

  final PackSummary summary;

  /// For a pack the family does not have: only the plays they can start (the free ones).
  final List<ContentItem>? playable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final heard = _heardIn(ref, summary.items);
    final total = summary.items.length;
    final free = playable;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: free == null
                ? '${summary.pack.title}, ${playsCount(total)}, przesłuchane $heard z $total'
                : '${summary.pack.title}, ${free.length} z $total za darmo',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => openPack(context, summary.pack.id),
              child: Row(
                children: [
                  SizedBox.square(dimension: 48, child: PackArt(summary: summary, radius: 12)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(summary.pack.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: free == null
                              ? [
                                  _Tag('Wasz pakiet', color: AkBrand.teal.withValues(alpha: .2)),
                                  _Tag(heard == total && total > 0 ? 'Wszystko przesłuchane' : 'Przesłuchane $heard z $total'),
                                ]
                              : [
                                  _Tag('${free.length} z $total za darmo', strong: true),
                                  _Tag('reszta w abonamencie'),
                                ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _Covers(items: free ?? summary.items),
        ],
      ),
    );
  }
}

/// Plays without a pack (songs and others) as one more shelf.
class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.items});

  final String title;
  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        _Covers(items: items),
      ],
    ),
  );
}

/// Covers in a row, scrolled sideways: the cover, the title and how long it takes.
class _Covers extends ConsumerWidget {
  const _Covers({required this.items});

  final List<ContentItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      // Cover plus two lines of title and one of minutes, at any text size.
      height: 120 + MediaQuery.textScalerOf(context).scale(58),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return SizedBox(
            width: 116,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/zabawa/${item.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContentCover(
                    item: item,
                    size: 116,
                    locked: !ref.watch(canPlayProvider(item)),
                    fresh: ref.watch(isNewItemProvider(item)),
                    free: ref.watch(showFreeBadgeProvider(item)),
                  ),
                  const SizedBox(height: 6),
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    '${(item.durationSec / 60).ceil()} min · ${item.ageMin}+',
                    maxLines: 1,
                    style: text.labelSmall?.copyWith(color: context.palette.inkMuted),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Szukaj zabawy lub piosenki',
    excludeSemantics: true,
    child: Material(
      color: context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: context.palette.inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Szukaj zabawy lub piosenki',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.palette.inkMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.strong = false, this.color});

  final String label;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color ?? (strong ? AkBrand.sun : context.palette.surfaceMuted),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: const Color(0xFF211C35), fontWeight: strong ? FontWeight.w800 : FontWeight.w600),
    ),
  );
}

/// Everyday situations and parent tools, one tap each.
class _ParentTools extends ConsumerWidget {
  const _ParentTools({required this.onFilter});

  final ValueChanged<LibraryFilter> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = ref.watch(downloadSummaryProvider).value?.itemIds.length ?? 0;
    final tools = <(IconData, String, String, VoidCallback)>[
      (Icons.schedule_rounded, 'Mam 20 minut', 'Dobierzemy zabawy', () => context.push('/ratunku')),
      (Icons.directions_car_rounded, 'Do auta', 'Cykl na całą drogę', () => context.push('/podroz')),
      (
        Icons.offline_pin_rounded,
        'Bez internetu',
        downloaded == 0 ? 'Pobierz na wyjazd' : 'Pobrane: $downloaded',
        () => context.push('/pobrane'),
      ),
      (
        Icons.print_rounded,
        'Do druku',
        'Akta sprawy Detektywa',
        () => onFilter(const LibraryFilter(printable: true)),
      ),
      (Icons.queue_music_rounded, 'Kolejka', 'Ułóż własną listę', () => context.push('/kolejka')),
      (Icons.child_care_rounded, 'Tryb dziecka', 'Telefon tylko z zabawami', () => showKidsModeSetup(context, ref)),
      (Icons.favorite_rounded, 'Ulubione', 'Te, do których wracacie', () => context.push('/ulubione')),
      (Icons.history_rounded, 'Historia', 'Co już słuchaliście', () => context.push('/historia')),
    ];
    return TwoColumns(
      children: [
        for (final (icon, title, subtitle, onTap) in tools)
          _tourWrap(
            title,
            Material(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: onTap,
                child: Semantics(
                  button: true,
                  label: '$title. $subtitle',
                  excludeSemantics: true,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 84),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.palette.inkMuted.withValues(alpha: .18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: AkBrand.tealDeep, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          subtitle,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.palette.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Szop’en's tour lights up these tools.
  Widget _tourWrap(String title, Widget child) => switch (title) {
    'Bez internetu' => TourTarget(id: 'offline', child: child),
    'Do druku' => TourTarget(id: 'print', child: child),
    'Tryb dziecka' => TourTarget(id: 'kids', child: child),
    _ => child,
  };
}

/// The most common narrowing, as one row of chips.
/// Filters on the result list: each chip toggles one of them.
class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.filter, required this.onChanged});

  final LibraryFilter filter;
  final ValueChanged<LibraryFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(hasSongsProvider);
    final f = filter;
    Widget chip(String label, bool selected, LibraryFilter Function() toggle) => ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: selectableChipLabel(context, selected: selected),
      onSelected: (_) => onChanged(toggle()),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final (kind, label) in [
            (ContentKind.audioGame, 'Audiozabawy'),
            if (songs) (ContentKind.song, 'Piosenki'),
            (ContentKind.interactiveGame, 'Gry'),
          ])
            chip(label, f.kind == kind, () => f.copyWith(kind: () => f.kind == kind ? null : kind)),
          for (final (age, from, label) in [(5, 3, '3–5'), (7, 5, '5–7'), (9, 7, '7–9')])
            chip(
              label,
              f.age == age,
              () => f.copyWith(age: () => f.age == age ? null : age, ageFrom: () => f.age == age ? null : from),
            ),
          for (final m in [10, 20, 30])
            chip('Do $m min', f.maxMinutes == m, () => f.copyWith(maxMinutes: () => f.maxMinutes == m ? null : m)),
          chip('Bez przygotowań', f.noPrep, () => f.copyWith(noPrep: !f.noPrep)),
          chip('Tylko dostępne', f.available, () => f.copyWith(available: !f.available)),
        ],
      ),
    );
  }
}

