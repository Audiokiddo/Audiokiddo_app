import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/studio_controller.dart';
import '../widgets/fields.dart';

class PacksScreen extends ConsumerWidget {
  const PacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studioProvider);
    final controller = ref.read(studioProvider.notifier);
    void set(int index, String key, Object? value) => controller.update((c) {
      final pack = (c['packs'] as List)[index] as Json;
      value == null || value == '' ? pack.remove(key) : pack[key] = value;
    });

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (final (i, pack) in state.packs.indexed)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${pack['id']}', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SyncedTextField(
                    label: 'Nazwa',
                    value: pack['title'] as String? ?? '',
                    onChanged: (v) => set(i, 'title', v),
                  ),
                  SyncedTextField(
                    label: 'Opis',
                    maxLines: 3,
                    value: pack['description'] as String? ?? '',
                    onChanged: (v) => set(i, 'description', v),
                  ),
                  SyncedTextField(
                    label: 'Wiek od',
                    digitsOnly: true,
                    value: '${pack['age_min'] ?? ''}',
                    onChanged: (v) => set(i, 'age_min', int.tryParse(v)),
                  ),
                  LabeledDropdown<String>(
                    label: 'Kolor',
                    value: pack['color'] as String? ?? 'lavender',
                    options: colorLabels,
                    onChanged: (v) => set(i, 'color', v),
                  ),
                  SyncedTextField(
                    label: 'ID produktu w sklepach',
                    value: pack['store_product_id'] as String? ?? '',
                    onChanged: (v) => set(i, 'store_product_id', v),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ShelvesScreen extends ConsumerWidget {
  const ShelvesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studioProvider);
    final controller = ref.read(studioProvider.notifier);
    final titles = {for (final i in state.items) i['id'] as String: i['title'] as String? ?? ''};

    List<String> ids(Json shelf) => (shelf['item_ids'] as List? ?? const []).cast<String>();
    void setIds(int index, List<String> next) =>
        controller.update((c) => ((c['shelves'] as List)[index] as Json)['item_ids'] = next);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Półki na ekranie Start. „Zabawa dnia” pokazuje pierwszą pozycję swojej półki.'),
        const SizedBox(height: 16),
        for (final (i, shelf) in state.shelves.indexed)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SyncedTextField(
                    label: 'Tytuł półki',
                    value: shelf['title'] as String? ?? '',
                    onChanged: (v) => controller.update((c) => ((c['shelves'] as List)[i] as Json)['title'] = v),
                  ),
                  ReorderableListView(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorderItem: (from, to) {
                      final next = ids(shelf);
                      next.insert(to, next.removeAt(from));
                      setIds(i, next);
                    },
                    children: [
                      for (final (j, id) in ids(shelf).indexed)
                        ListTile(
                          key: ValueKey('$i-$id'),
                          leading: ReorderableDragStartListener(index: j, child: const Icon(Icons.drag_indicator)),
                          title: Text(titles[id] ?? '⚠ brak pozycji „$id”'),
                          trailing: IconButton(
                            tooltip: 'Usuń z półki',
                            icon: const Icon(Icons.close),
                            onPressed: () => setIds(i, ids(shelf)..remove(id)),
                          ),
                        ),
                    ],
                  ),
                  LabeledDropdown<String>(
                    key: ValueKey('add-$i-${ids(shelf).length}'),
                    label: 'Dodaj do półki',
                    value: '',
                    options: {
                      '': '—',
                      for (final MapEntry(:key, :value) in titles.entries)
                        if (!ids(shelf).contains(key)) key: value,
                    },
                    onChanged: (v) {
                      if (v.isNotEmpty) setIds(i, [...ids(shelf), v]);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
