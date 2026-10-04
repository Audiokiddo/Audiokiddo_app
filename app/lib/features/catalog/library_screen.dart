import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../discovery/discovery_model.dart';
import '../discovery/reference_widgets.dart';
import 'library_filter.dart';
import 'widgets/catalog_loader.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.filter = const LibraryFilter()});
  final LibraryFilter filter;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _search = '';
  bool _searching = false;
  bool _series = false;
  void _set(LibraryFilter f) => context.go(f.toLocation());
  @override
  Widget build(BuildContext context) {
    final f = widget.filter;
    final category = f.category;
    final searching = _searching || GoRouterState.of(context).uri.queryParameters['szukaj'] == '1';
    return Scaffold(
      appBar: AppBar(
        title: Text(category?.label.replaceAll('\n', ' ') ?? 'Biblioteka'),
        leading: searching
            ? IconButton(
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
                    context.go(f.toLocation());
                  }
                },
              )
            : category == null
            ? null
            : IconButton(
                tooltip: 'Wszystkie kategorie',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => _set(const LibraryFilter()),
              ),
        actions: [
          IconButton(
            tooltip: 'Szukaj',
            onPressed: () => setState(() => _searching = !_searching),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: CatalogLoader(
        builder: (context, catalog) {
          final items = f
              .apply(catalog.items)
              .where((i) => i.title.toLowerCase().contains(_search.toLowerCase()))
              .toList();
          final search = _searching || GoRouterState.of(context).uri.queryParameters['szukaj'] == '1';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              if (search)
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
              if (category == null)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final choice in [
                        (null, 'Wszystkie'),
                        (ContentKind.audioGame, 'Audiozabawy'),
                        (ContentKind.song, 'Piosenki'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(choice.$2),
                            selected: !_series && f.kind == choice.$1,
                            showCheckmark: false,
                            labelStyle: selectableChipLabel(
                              context,
                              selected: !_series && f.kind == choice.$1,
                            ),
                            onSelected: (_) {
                              setState(() => _series = false);
                              _set(f.copyWith(kind: () => choice.$1));
                            },
                          ),
                        ),
                      ChoiceChip(
                        label: const Text('Serie'),
                        selected: _series,
                        onSelected: (v) => setState(() => _series = v),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final a in [(4, '3–4'), (6, '5–6'), (9, '7–9'), (null, 'Wszystkie')])
                    ChoiceChip(
                      label: Text(a.$2),
                      selected: f.age == a.$1,
                      labelStyle: selectableChipLabel(context, selected: f.age == a.$1),
                      showCheckmark: false,
                      onSelected: (_) => _set(
                        f.copyWith(
                          age: () => a.$1,
                          ageFrom: () => switch (a.$1) {
                            4 => 3,
                            6 => 5,
                            9 => 7,
                            _ => null,
                          },
                        ),
                      ),
                    ),
                  if (category != null)
                    DropdownButton<int>(
                      hint: const Text('Czas trwania'),
                      value: f.maxMinutes,
                      items: [
                        for (final m in ({
                          10,
                          20,
                          30,
                          60,
                          if (f.maxMinutes != null) f.maxMinutes!,
                        }.toList()..sort()))
                          DropdownMenuItem(value: m, child: Text('Do $m min')),
                      ],
                      onChanged: (v) => _set(f.copyWith(maxMinutes: () => v)),
                    ),
                  if (f.maxMinutes != null)
                    ActionChip(
                      label: const Text('Dowolny czas'),
                      onPressed: () => _set(f.copyWith(maxMinutes: () => null)),
                    ),
                ],
              ),
              if (_series && category == null) ...[
                const RefSection('Serie audiozabaw'),
                for (final pack in catalog.packs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(pack.title),
                    subtitle: Text(pack.description),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      setState(() => _series = false);
                      _set(f.copyWith(packId: () => pack.id));
                    },
                  ),
              ] else if (category == null && f.kind == null && f.packId == null && !search) ...[
                const RefSection('Kategorie'),
                TwoColumns(
                  children: [
                    for (final c in PlayCategory.values)
                      CategoryTile(
                        category: c,
                        onTap: () => _set(f.copyWith(category: () => c)),
                      ),
                  ],
                ),
                RefSection(
                  'Wszystkie zabawy',
                  action: 'Przeglądaj',
                  onTap: () => setState(() => _searching = true),
                ),
                for (final item in items.take(3)) AudioRow(item: item),
              ] else ...[
                RefSection('${items.length} propozycji'),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Nie znaleźliśmy takiej zabawy. Zmień wiek, czas lub wpisany tytuł.'),
                  ),
                for (final item in items) AudioRow(item: item),
              ],
            ],
          );
        },
      ),
    );
  }
}
