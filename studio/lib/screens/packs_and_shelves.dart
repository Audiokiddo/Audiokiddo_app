import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/studio_controller.dart';
import '../theme.dart';
import '../widgets/fields.dart';

/// A free id from a title: "Zimowe zagadki" → zimowe-zagadki (with -2, -3 when taken).
String freeId(String title, Iterable<String> taken, {String fallback = 'nowy'}) {
  const pl = {'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n', 'ó': 'o', 'ś': 's', 'ź': 'z', 'ż': 'z'};
  var base = title.toLowerCase().split('').map((c) => pl[c] ?? c).join();
  base = base.replaceAll(RegExp('[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  if (base.isEmpty) base = fallback;
  var id = base;
  for (var n = 2; taken.contains(id); n++) {
    id = '$base-$n';
  }
  return id;
}

/// Asks for a name; null when cancelled.
Future<String?> askName(BuildContext context, {required String title, required String label}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(d, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Anuluj')),
        FilledButton(onPressed: () => Navigator.pop(d, controller.text.trim()), child: const Text('Dodaj')),
      ],
    ),
  ).then((v) => v == null || v.isEmpty ? null : v);
}

class PacksScreen extends ConsumerWidget {
  const PacksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studioProvider);
    final controller = ref.read(studioProvider.notifier);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    void set(int index, String key, Object? value) => controller.update((c) {
      final pack = (c['packs'] as List)[index] as Json;
      value == null || value == '' ? pack.remove(key) : pack[key] = value;
    });

    Future<void> add() async {
      final name = await askName(context, title: 'Nowy pakiet', label: 'Nazwa pakietu, np. Zimowe zagadki');
      if (name == null) return;
      final id = freeId(name, state.packs.map((p) => '${p['id']}'), fallback: 'pakiet');
      controller.update(
        (c) => (c['packs'] as List).add({
          'id': id,
          'title': name,
          'description': '',
          'age_min': 4,
          'color': 'lavender',
          'store_product_id': 'pl.audiokiddo.pack.${id.replaceAll('-', '_')}',
        }),
      );
    }

    Future<void> remove(Json pack) async {
      final count = state.items.where((i) => i['pack_id'] == pack['id']).length;
      if (!await confirmDelete(
        context,
        'pakiet „${pack['title']}”${count > 0 ? ' ($count zabaw zostanie bez pakietu)' : ''}',
      )) {
        return;
      }
      controller.update((c) {
        (c['packs'] as List).removeWhere((p) => (p as Json)['id'] == pack['id']);
        for (final item in (c['items'] as List).cast<Json>()) {
          if (item['pack_id'] == pack['id']) item.remove('pack_id');
        }
      });
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionHeader(
          tint: Tint.packs,
          pose: 'chytry',
          title: 'Pakiety',
          text: 'Zestawy zabaw, które rodzic kupuje razem, np. Wyobraźnia czy Detektyw. Zabawę do pakietu przypisujesz w „Treści”.',
          actions: [
            FilledButton.icon(onPressed: add, icon: const Icon(Icons.add), label: const Text('Dodaj pakiet')),
          ],
        ),
        for (final (i, pack) in state.packs.indexed)
          Builder(
            builder: (context) {
              final tint = Tint.ofPack(pack['color'] as String?);
              final count = state.items.where((it) => it['pack_id'] == pack['id']).length;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: tint.soft,
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_rounded, color: tint.deep),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${pack['title']}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Chip(label: Text('$count zabaw'), backgroundColor: Colors.white),
                          const SizedBox(width: 4),
                          if (narrow)
                            IconButton(
                              tooltip: 'Usuń pakiet',
                              color: Colors.red.shade700,
                              onPressed: () => remove(pack),
                              icon: const Icon(Icons.delete_outline),
                            )
                          else
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                              onPressed: () => remove(pack),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Usuń'),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SyncedTextField(
                            label: 'Nazwa',
                            value: pack['title'] as String? ?? '',
                            onChanged: (v) => set(i, 'title', v),
                          ),
                          SyncedTextField(
                            label: 'Opis dla rodzica',
                            maxLines: 3,
                            value: pack['description'] as String? ?? '',
                            onChanged: (v) => set(i, 'description', v),
                          ),
                          if (narrow) ...[
                            SyncedTextField(
                              label: 'Wiek od',
                              digitsOnly: true,
                              value: '${pack['age_min'] ?? ''}',
                              onChanged: (v) => set(i, 'age_min', int.tryParse(v)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                for (final MapEntry(:key, :value) in colorLabels.entries)
                                  ChoiceChip(
                                    avatar: CircleAvatar(backgroundColor: Tint.ofPack(key).deep, radius: 8),
                                    label: Text(value),
                                    selected: (pack['color'] ?? 'lavender') == key,
                                    onSelected: (_) => set(i, 'color', key),
                                  ),
                              ],
                            ),
                          ] else
                            Row(
                              children: [
                                Expanded(
                                  child: SyncedTextField(
                                    label: 'Wiek od',
                                    digitsOnly: true,
                                    value: '${pack['age_min'] ?? ''}',
                                    onChanged: (v) => set(i, 'age_min', int.tryParse(v)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      for (final MapEntry(:key, :value) in colorLabels.entries)
                                        ChoiceChip(
                                          avatar: CircleAvatar(
                                            backgroundColor: Tint.ofPack(key).deep,
                                            radius: 8,
                                          ),
                                          label: Text(value),
                                          selected: (pack['color'] ?? 'lavender') == key,
                                          onSelected: (_) => set(i, 'color', key),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          SyncedTextField(
                            label: 'ID produktu w sklepach',
                            helper: 'Taki sam w App Store Connect i Google Play Console. Ustawia się sam przy nowym pakiecie.',
                            value: pack['store_product_id'] as String? ?? '',
                            onChanged: (v) => set(i, 'store_product_id', v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
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
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final titles = {for (final i in state.items) i['id'] as String: i['title'] as String? ?? ''};

    List<String> ids(Json shelf) => (shelf['item_ids'] as List? ?? const []).cast<String>();
    void setIds(int index, List<String> next) =>
        controller.update((c) => ((c['shelves'] as List)[index] as Json)['item_ids'] = next);
    void move(int from, int to) => controller.update((c) {
      final shelves = c['shelves'] as List;
      shelves.insert(to, shelves.removeAt(from));
    });

    Future<void> add() async {
      final name = await askName(context, title: 'Nowa półka', label: 'Tytuł półki, np. Na długą podróż');
      if (name == null) return;
      final id = freeId(name, state.shelves.map((s) => '${s['id']}'), fallback: 'polka');
      controller.update((c) => (c['shelves'] as List).add({'id': id, 'title': name, 'item_ids': <String>[]}));
    }

    Future<void> remove(int index, Json shelf) async {
      if (!await confirmDelete(context, 'półkę „${shelf['title']}” (zabawy zostają w katalogu)')) return;
      controller.update((c) => (c['shelves'] as List).removeAt(index));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionHeader(
          tint: Tint.shelves,
          pose: 'nasluchuje',
          title: 'Półki',
          text:
              'Półki to rzędy zabaw na ekranie Start w aplikacji, np. „Zabawa dnia”, „Na drogę”, „Jesienne wieczory”. '
              'Tu decydujesz, które zabawy są w którym rzędzie i w jakiej kolejności. Zabawa dnia to pierwsza zabawa z jej półki.',
          actions: [
            FilledButton.icon(onPressed: add, icon: const Icon(Icons.add), label: const Text('Dodaj półkę')),
          ],
        ),
        for (final (i, shelf) in state.shelves.indexed)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SyncedTextField(
                          label: 'Tytuł półki',
                          value: shelf['title'] as String? ?? '',
                          onChanged: (v) =>
                              controller.update((c) => ((c['shelves'] as List)[i] as Json)['title'] = v),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Wyżej na ekranie Start',
                        onPressed: i == 0 ? null : () => move(i, i - 1),
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
                      IconButton(
                        tooltip: 'Niżej na ekranie Start',
                        onPressed: i == state.shelves.length - 1 ? null : () => move(i, i + 1),
                        icon: const Icon(Icons.arrow_downward_rounded),
                      ),
                      if (narrow)
                        IconButton(
                          tooltip: 'Usuń półkę',
                          color: Colors.red.shade700,
                          onPressed: () => remove(i, shelf),
                          icon: const Icon(Icons.delete_outline),
                        )
                      else
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                          onPressed: () => remove(i, shelf),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Usuń półkę'),
                        ),
                    ],
                  ),
                  if (ids(shelf).isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Pusta półka. Dodaj zabawy poniżej.'),
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
                          leading: ReorderableDragStartListener(
                            index: j,
                            child: const Icon(Icons.drag_indicator, color: Brand.tealDeep),
                          ),
                          title: Text(titles[id] ?? '⚠ brak zabawy „$id”'),
                          trailing: IconButton(
                            tooltip: 'Zdejmij z półki',
                            icon: const Icon(Icons.close),
                            onPressed: () => setIds(i, ids(shelf)..remove(id)),
                          ),
                        ),
                    ],
                  ),
                  LabeledDropdown<String>(
                    key: ValueKey('add-$i-${ids(shelf).length}'),
                    label: '+ Dodaj zabawę na tę półkę',
                    value: '',
                    options: {
                      '': 'Wybierz zabawę…',
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
