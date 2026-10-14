import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/kiddo_voice.dart' show comparePolish, plainName;
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../discovery/reference_widgets.dart';
import 'catalog_providers.dart';

enum AllSort { alphabet, newest, shortest }

/// What the "Wszystkie zabawy" list can be narrowed to.
enum AllKind { all, audioGame, song, interactiveGame, free }

/// Every play of the catalog on one flat list, no packs: A–Z by default, a search field on
/// top that finds a title typed with or without Polish letters, pieces of it or the pack's name.
/// [titles] and [matches] are plain functions so they can be tested without a screen.
List<ContentItem> allPlays(
  Catalog catalog, {
  required DateTime now,
  String query = '',
  AllSort sort = AllSort.alphabet,
  AllKind kind = AllKind.all,
}) {
  final words = [
    for (final w in plainName(query.trim()).split(RegExp(r'\s+')))
      if (w.isNotEmpty) w,
  ];
  String haystack(ContentItem i) =>
      plainName('${i.title} ${i.packId == null ? '' : catalog.pack(i.packId!)?.title ?? ''}');
  bool kindOk(ContentItem i) => switch (kind) {
    AllKind.all => true,
    AllKind.audioGame => i.kind == ContentKind.audioGame,
    AllKind.song => i.kind == ContentKind.song,
    AllKind.interactiveGame => i.kind == ContentKind.interactiveGame,
    AllKind.free => i.isFree,
  };
  final items = [
    for (final i in catalog.items)
      if (i.releasedOn?.isAfter(now) != true && kindOk(i) && words.every(haystack(i).contains)) i,
  ];
  int byTitle(ContentItem a, ContentItem b) => comparePolish(a.title.toLowerCase(), b.title.toLowerCase());
  switch (sort) {
    case AllSort.alphabet:
      items.sort(byTitle);
    case AllSort.newest:
      items.sort((a, b) {
        final d = (b.releasedOn ?? DateTime(2000)).compareTo(a.releasedOn ?? DateTime(2000));
        return d != 0 ? d : byTitle(a, b);
      });
    case AllSort.shortest:
      items.sort((a, b) {
        final d = a.durationSec.compareTo(b.durationSec);
        return d != 0 ? d : byTitle(a, b);
      });
  }
  // With a search, the titles that start with what was typed come first.
  if (words.isNotEmpty) {
    final first = words.first;
    final starts = [
      for (final i in items)
        if (plainName(i.title).startsWith(first)) i,
    ];
    return [
      ...starts,
      for (final i in items)
        if (!starts.contains(i)) i,
    ];
  }
  return items;
}

class AllPlaysView extends ConsumerStatefulWidget {
  const AllPlaysView({super.key, required this.catalog, this.autofocus = false, this.onTyped});

  final Catalog catalog;
  final bool autofocus;

  /// What was typed and how many plays it found (for the statistics: what parents look for).
  final void Function(String query, int results)? onTyped;

  @override
  ConsumerState<AllPlaysView> createState() => _AllPlaysViewState();
}

class _AllPlaysViewState extends ConsumerState<AllPlaysView> {
  final _field = TextEditingController();
  String _query = '';
  AllSort _sort = AllSort.alphabet;
  AllKind _kind = AllKind.all;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  static const _kindLabels = {
    AllKind.all: 'Wszystkie',
    AllKind.audioGame: 'Audiozabawy',
    AllKind.song: 'Piosenki',
    AllKind.interactiveGame: 'Z odpowiedziami',
    AllKind.free: 'Darmowe',
  };
  static const _sortLabels = {
    AllSort.alphabet: 'A–Z',
    AllSort.newest: 'Najnowsze',
    AllSort.shortest: 'Najkrótsze',
  };

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final items = allPlays(widget.catalog, now: now, query: _query, sort: _sort, kind: _kind);
    final text = Theme.of(context).textTheme;
    final letters = _sort == AllSort.alphabet;
    String? lastLetter;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        TextField(
          controller: _field,
          autofocus: widget.autofocus,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Wpisz tytuł zabawy lub piosenki',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Wyczyść',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _field.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: const OutlineInputBorder(),
          ),
          onChanged: (q) {
            setState(() => _query = q);
            widget.onTyped?.call(
              q,
              allPlays(widget.catalog, now: now, query: q, sort: _sort, kind: _kind).length,
            );
          },
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final k in AllKind.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_kindLabels[k]!),
                    selected: _kind == k,
                    labelStyle: selectableChipLabel(context, selected: _kind == k),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const SizedBox(height: 2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('Kolejność:', style: text.labelLarge?.copyWith(color: context.palette.inkMuted)),
              ),
              for (final s in AllSort.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_sortLabels[s]!),
                    selected: _sort == s,
                    labelStyle: selectableChipLabel(context, selected: _sort == s),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _sort = s),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            items.length == 1 ? '1 zabawa' : '${items.length} zabaw',
            style: text.labelLarge?.copyWith(color: context.palette.inkMuted),
          ),
        ),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Nie znaleźliśmy takiej zabawy. Sprawdź pisownię albo wpisz tylko początek tytułu.'),
          ),
        for (final item in items) ...[
          if (letters && _query.isEmpty && _letter(item) != lastLetter)
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 2),
              child: Text(
                lastLetter = _letter(item),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AkBrand.tealDeep),
              ),
            ),
          AudioRow(item: item),
        ],
      ],
    );
  }

  static String _letter(ContentItem i) {
    final t = i.title.trim();
    return t.isEmpty ? '#' : t[0].toUpperCase();
  }
}
