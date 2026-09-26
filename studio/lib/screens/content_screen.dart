import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/studio_controller.dart';
import '../widgets/fields.dart';
import 'item_editor.dart';

/// List of items on the left, editor on the right.
class ContentScreen extends ConsumerStatefulWidget {
  const ContentScreen({super.key});

  @override
  ConsumerState<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends ConsumerState<ContentScreen> {
  String? _selected;
  String _query = '';
  String _pack = '';

  void _add() {
    final state = ref.read(studioProvider);
    var n = 1;
    while (state.item('nowa-pozycja-$n') != null) {
      n++;
    }
    final id = 'nowa-pozycja-$n';
    ref.read(studioProvider.notifier).addItem({
      'id': id,
      'kind': 'audio_game',
      if (_pack.isNotEmpty) 'pack_id': _pack,
      'title': 'Nowa zabawa',
      'parent_description': '',
      'age_min': 3,
      'duration_sec': 300,
      'access': 'paid',
      'audio': <Object?>[],
    });
    setState(() => _selected = id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studioProvider);
    final validation = ref.watch(validationProvider);
    final items = [
      for (final i in state.items)
        if ((_pack.isEmpty || i['pack_id'] == _pack) &&
            '${i['title']} ${i['id']}'.toLowerCase().contains(_query.toLowerCase()))
          i,
    ];

    return Row(
      children: [
        SizedBox(
          width: 380,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Szukaj',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: LabeledDropdown<String>(
                  label: 'Pakiet',
                  value: _pack,
                  options: {
                    '': 'Wszystkie',
                    for (final p in state.packs) p['id'] as String: p['title'] as String? ?? '',
                  },
                  onChanged: (v) => setState(() => _pack = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final id = item['id'] as String? ?? '';
                    final error = validation.itemErrors[id];
                    return ListTile(
                      selected: id == _selected,
                      leading: Icon(
                        error != null ? Icons.error : Icons.check_circle_outline,
                        color: error != null ? Theme.of(context).colorScheme.error : null,
                      ),
                      title: Text(item['title'] as String? ?? id),
                      subtitle: Text(
                        '${kindLabels[item['kind']] ?? item['kind']} · ${item['access'] == 'free' ? 'za darmo' : 'płatna'} · $id',
                      ),
                      onTap: () => setState(() => _selected = id),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj pozycję'),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selected == null
              ? const Center(child: Text('Wybierz pozycję z listy albo dodaj nową.'))
              : ItemEditor(
                  key: ValueKey(_selected),
                  itemId: _selected!,
                  onRenamed: (to) => setState(() => _selected = to),
                  onDeleted: () => setState(() => _selected = null),
                ),
        ),
      ],
    );
  }
}
