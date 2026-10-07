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
import '../pdf/guide_links.dart';
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
        if (f.printable) _Guides(catalog: catalog),
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

/// The library before any filter, plays first: search and quick filters on top, then every
/// pack as a shelf of covers (yours first; a locked one says what is free and the price), then
/// the kinds of play, and the parent's tools at the end.
class _Browse extends ConsumerWidget {
  const _Browse({required this.catalog, required this.onFilter, required this.onSearch});

  final Catalog catalog;
  final ValueChanged<LibraryFilter> onFilter;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopes = ref.watch(activeScopesProvider);
    final summaries = [for (final p in catalog.packs) PackSummary(p, catalog)]
      ..sort((a, b) => (ownsPack(scopes, a.pack.id) ? 0 : 1).compareTo(ownsPack(scopes, b.pack.id) ? 0 : 1));
    final loose = [
      for (final i in catalog.items)
        if (i.packId == null && i.releasedOn?.isAfter(ref.watch(clockProvider)()) != true) i,
    ];
    final products = ref.watch(storeProductsProvider(productsKey(shopProductIds(catalog))));
    final byId = {for (final p in products.value ?? const <StoreProduct>[]) p.id: p};
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        _SearchField(onTap: onSearch),
        const SizedBox(height: 10),
        _QuickChips(onFilter: onFilter),
        for (final s in summaries)
          _PackShelf(
            summary: s,
            owned: ownsPack(scopes, s.pack.id),
            product: byId[s.pack.storeProductId],
          ),
        if (loose.isNotEmpty) _Shelf(title: 'Piosenki i inne', items: loose),
        const Padding(padding: EdgeInsets.only(top: 8), child: Center(child: RedeemAccessLink())),
        const RefSection('Rodzaje zabaw'),
        TwoColumns(
          children: [
            for (final c in ref.watch(shownCategoriesProvider))
              CategoryTile(
                category: c,
                onTap: () => onFilter(LibraryFilter(category: c)),
              ),
          ],
        ),
        const RefSection('Dla rodzica'),
        _ParentTools(onFilter: onFilter),
      ],
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

/// A pack as a shelf: a header that opens the pack page (what it gives, price, buying) and its
/// plays as covers, each straight to its page. Locked plays carry a lock, free ones play.
class _PackShelf extends ConsumerWidget {
  const _PackShelf({required this.summary, required this.owned, this.product});

  final PackSummary summary;
  final bool owned;
  final StoreProduct? product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final free = summary.freeItems.length;
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final ids = {for (final i in summary.items) i.id};
    final heard = child == null
        ? 0
        : {
            for (final r in family!.resultsOf(child.id))
              if (r.completed && ids.contains(r.itemId)) r.itemId,
          }.length;
    final total = summary.items.length;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: owned
                ? '${summary.pack.title}, ${playsCount(total)}, przesłuchane $heard z $total'
                : '${summary.pack.title}, ${playsCount(total)}, $free za darmo${product == null ? '' : ', ${product!.price}'}',
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
                          children: owned
                              ? [
                                  _Tag('Wasz pakiet', color: AkBrand.teal.withValues(alpha: .2)),
                                  _Tag(heard == total && total > 0 ? 'Wszystko przesłuchane' : 'Przesłuchane $heard z $total'),
                                ]
                              : [
                                  _Tag('${playsCount(total)} · ${summary.minutes} min'),
                                  if (free > 0) _Tag(free == 1 ? '1 za darmo' : '$free za darmo', strong: true),
                                  if (product != null) _Tag(product!.price, strong: true),
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
          _Covers(items: summary.items),
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
        'Akta, karty, przewodniki',
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

/// Films and printables of every pack, on top of the printable plays.
class _Guides extends StatelessWidget {
  const _Guides({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const RefSection('Filmy i materiały do pakietów'),
      for (final pack in catalog.packs)
        if (pack.guide != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.smart_display_rounded, color: AkBrand.tealDeep),
            title: Text(pack.title),
            subtitle: const Text('Filmy do zabaw i pliki do druku'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => openPackMaterials(context, pack.id),
          ),
    ],
  );
}
