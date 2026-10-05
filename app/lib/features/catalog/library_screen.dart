import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/szop.dart';
import '../discovery/reference_widgets.dart';
import '../downloads/download_providers.dart';
import '../family/family.dart' hide progressProvider;
import '../kids_mode/kids_mode_setup.dart';
import '../pdf/guide_links.dart';
import '../purchases/shop.dart';
import '../purchases/purchase_controller.dart';
import '../purchases/shop_screen.dart';
import '../purchases/store_gateway.dart';
import 'catalog_providers.dart';
import 'library_filter.dart';
import 'widgets/catalog_loader.dart';

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
              onChanged: (s) => setState(() => _search = s),
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

/// The library before any filter: packs first, then the parent toolbox, then ways to browse.
class _Browse extends ConsumerWidget {
  const _Browse({required this.catalog, required this.onFilter, required this.onSearch});

  final Catalog catalog;
  final ValueChanged<LibraryFilter> onFilter;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopes = ref.watch(activeScopesProvider);
    final summaries = [for (final p in catalog.packs) PackSummary(p, catalog)];
    final owned = [
      for (final s in summaries)
        if (ownsPack(scopes, s.pack.id)) s,
    ];
    final locked = [
      for (final s in summaries)
        if (!ownsPack(scopes, s.pack.id)) s,
    ];
    final products = ref.watch(storeProductsProvider(productsKey(shopProductIds(catalog))));
    final byId = {for (final p in products.value ?? const <StoreProduct>[]) p.id: p};
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        _SearchField(onTap: onSearch),
        const SizedBox(height: 6),
        _Panel(
          color: AkBrand.teal.withValues(alpha: .14),
          title: owned.isEmpty ? 'Wasze zabawy' : 'Wasze pakiety',
          children: [
            if (owned.isEmpty)
              _FreeStart(onTap: () => onFilter(const LibraryFilter(available: true)))
            else
              for (final s in owned)
                _OwnedPackCard(
                  summary: s,
                  onPlay: () => onFilter(LibraryFilter(packId: s.pack.id)),
                ),
          ],
        ),
        if (locked.isNotEmpty)
          _Panel(
            color: referenceLilac.withValues(alpha: .35),
            title: 'Do odblokowania',
            subtitle: 'W każdym pakiecie część zabaw jest za darmo. Posłuchajcie, zanim kupicie.',
            children: [
              for (final s in locked) _LockedPackCard(summary: s, product: byId[s.pack.storeProductId]),
              const Center(child: RedeemAccessLink()),
            ],
          ),
        const RefSection('Dla rodzica'),
        _ParentTools(onFilter: onFilter),
        const RefSection('Filtry zabaw'),
        _QuickFilters(onFilter: onFilter),
        const RefSection('Kategorie'),
        TwoColumns(
          children: [
            for (final c in ref.watch(shownCategoriesProvider))
              CategoryTile(
                category: c,
                onTap: () => onFilter(LibraryFilter(category: c)),
              ),
          ],
        ),
      ],
    );
  }
}

/// A tinted block that sets a group apart (your packs, packs to unlock).
class _Panel extends StatelessWidget {
  const _Panel({required this.color, required this.title, this.subtitle, required this.children});

  final Color color;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(26)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
              child: Text(subtitle!, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
            ),
          const SizedBox(height: 10),
          ...children,
        ],
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

/// No pack yet: the free plays are the way in.
class _FreeStart extends StatelessWidget {
  const _FreeStart({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        decoration: BoxDecoration(color: referenceMint, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const SzopSticker(SzopPose.zadowolony, height: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Darmowe zabawy na start',
                    style: text.titleSmall?.copyWith(
                      color: const Color(0xFF211C35),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Wszystko, czego możecie słuchać od razu, bez zakupu.',
                    style: text.bodySmall?.copyWith(color: const Color(0xFF211C35)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF211C35)),
          ],
        ),
      ),
    );
  }
}

/// An owned pack: how far the child got, and straight in.
class _OwnedPackCard extends ConsumerWidget {
  const _OwnedPackCard({required this.summary, required this.onPlay});

  final PackSummary summary;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: onPlay,
        child: Semantics(
          button: true,
          label: '${summary.pack.title}, ${playsCount(total)}, przesłuchane $heard z $total',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: akSoftShadow(context),
            ),
            child: Row(
              children: [
                SizedBox.square(dimension: 76, child: PackArt(summary: summary, radius: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.pack.title,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${playsCount(total)} · ${summary.minutes} min',
                        style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : heard / total,
                          minHeight: 6,
                          color: AkBrand.teal,
                          backgroundColor: AkBrand.teal.withValues(alpha: .15),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        heard == total && total > 0
                            ? 'Wszystko przesłuchane!'
                            : 'Przesłuchane $heard z $total',
                        style: text.labelSmall?.copyWith(color: context.palette.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AkBrand.teal, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pack to unlock: what is inside, what is free to try, the price; the pack page sells it.
class _LockedPackCard extends StatelessWidget {
  const _LockedPackCard({required this.summary, this.product});

  final PackSummary summary;
  final StoreProduct? product;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final free = summary.freeItems.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable(
        onTap: () => openPack(context, summary.pack.id),
        child: Semantics(
          button: true,
          label:
              '${summary.pack.title}, ${playsCount(summary.items.length)}, $free za darmo'
              '${product == null ? '' : ', ${product!.price}'}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: referenceLilac.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 76,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PackArt(summary: summary, radius: 16),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AkBrand.sun, shape: BoxShape.circle),
                          child: const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF211C35)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.pack.title,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        summary.pack.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Tag('${playsCount(summary.items.length)} · ${summary.minutes} min'),
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
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.strong = false});

  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: strong ? AkBrand.sun : Colors.white.withValues(alpha: .7),
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
      (
        Icons.child_care_rounded,
        'Tryb dziecka',
        'Telefon tylko z zabawami',
        () => showKidsModeSetup(context, ref),
      ),
      (Icons.favorite_rounded, 'Ulubione', 'Te, do których wracacie', () => context.push('/ulubione')),
      (Icons.history_rounded, 'Historia', 'Co już słuchaliście', () => context.push('/historia')),
    ];
    return TwoColumns(
      children: [
        for (final (icon, title, subtitle, onTap) in tools)
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
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: context.palette.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The most common narrowing, as one row of chips.
class _QuickFilters extends ConsumerWidget {
  const _QuickFilters({required this.onFilter});

  final ValueChanged<LibraryFilter> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songs = ref.watch(hasSongsProvider);
    final chips = <(String, LibraryFilter)>[
      ('Audiozabawy', const LibraryFilter(kind: ContentKind.audioGame)),
      if (songs) ('Piosenki', const LibraryFilter(kind: ContentKind.song)),
      ('Gry z odpowiedziami', const LibraryFilter(kind: ContentKind.interactiveGame)),
      ('Bez przygotowań', const LibraryFilter(noPrep: true)),
      ('Do 10 min', const LibraryFilter(maxMinutes: 10)),
      ('Do 20 min', const LibraryFilter(maxMinutes: 20)),
      ('3–5 lat', const LibraryFilter(age: 5, ageFrom: 3)),
      ('5–7 lat', const LibraryFilter(age: 7, ageFrom: 5)),
      ('7–9 lat', const LibraryFilter(age: 9, ageFrom: 7)),
      ('Tylko dostępne', const LibraryFilter(available: true)),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (label, f) in chips) ActionChip(label: Text(label), onPressed: () => onFilter(f)),
      ],
    );
  }
}

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
              () =>
                  f.copyWith(age: () => f.age == age ? null : age, ageFrom: () => f.age == age ? null : from),
            ),
          for (final m in [10, 20, 30])
            chip(
              'Do $m min',
              f.maxMinutes == m,
              () => f.copyWith(maxMinutes: () => f.maxMinutes == m ? null : m),
            ),
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
