import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/studio_controller.dart';
import '../widgets/fields.dart';
import 'script_editor.dart';

final _idPattern = RegExp(r'^[a-z0-9-]+$');

/// Edits one catalog item. Every change is applied immediately and validated.
class ItemEditor extends ConsumerWidget {
  const ItemEditor({super.key, required this.itemId, required this.onRenamed, required this.onDeleted});

  final String itemId;
  final ValueChanged<String> onRenamed;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studioProvider);
    final item = state.item(itemId);
    if (item == null) return const Center(child: Text('Wybierz pozycję z listy.'));
    final controller = ref.read(studioProvider.notifier);
    final validation = ref.watch(validationProvider);
    final error = validation.itemErrors[itemId];
    final warnings = validation.scriptWarnings[itemId] ?? const [];
    final kind = item['kind'] as String? ?? 'audio_game';

    void set(String key, Object? value) => controller.updateItem(itemId, (i) {
      if (value == null || (value is String && value.isEmpty)) {
        i.remove(key);
      } else {
        i[key] = value;
      }
    });

    List<String> list(String key) => (item[key] as List? ?? const []).cast<String>();
    void toggle(String key, String value, bool on) {
      final values = list(key).toSet();
      on ? values.add(value) : values.remove(value);
      set(key, values.isEmpty ? null : values.toList());
    }

    Future<void> pickAudio() async {
      final picked = await ref.read(studioIoProvider).pickAsset(extensions: const ['m4a', 'mp3', 'aac', 'wav']);
      if (picked == null) return;
      final folder = item['pack_id'] as String? ?? (kind == 'song' ? 'piosenki' : 'inne');
      set('audio', [
        {'path': 'audio/$folder/$itemId${picked.extension}', 'bytes': picked.bytes, 'sha256': picked.sha256},
      ]);
    }

    Future<void> pickPdf() async {
      final picked = await ref.read(studioIoProvider).pickAsset(extensions: const ['pdf']);
      if (picked == null) return;
      set('pdf', [
        {'path': 'pdf/${item['pack_id'] ?? 'inne'}/$itemId.pdf', 'bytes': picked.bytes, 'sha256': picked.sha256},
      ]);
    }

    final duration = item['duration_sec'] as int? ?? 0;
    final audio = (item['audio'] as List? ?? const []).cast<Json>();
    final pdf = (item['pdf'] as List? ?? const []).cast<Json>();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(child: Text(item['title'] as String? ?? itemId, style: Theme.of(context).textTheme.headlineSmall)),
            IconButton(
              tooltip: 'Usuń pozycję',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Usunąć pozycję?'),
                    content: Text('„${item['title']}” zniknie z katalogu i z półek.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Anuluj')),
                      FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Usuń')),
                    ],
                  ),
                );
                if (ok ?? false) {
                  controller.deleteItem(itemId);
                  onDeleted();
                }
              },
            ),
          ],
        ),
        if (error != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Aplikacja ukryje tę pozycję'),
              subtitle: Text(error),
            ),
          ),
        for (final w in warnings) ListTile(dense: true, leading: const Icon(Icons.info_outline), title: Text(w)),
        const SectionTitle('Podstawowe'),
        _IdField(
          itemId: itemId,
          onRename: (to) {
            controller.renameItem(itemId, to);
            onRenamed(to);
          },
          taken: {for (final i in state.items) i['id'] as String?},
        ),
        LabeledDropdown<String>(label: 'Rodzaj', value: kind, options: kindLabels, onChanged: (v) => set('kind', v)),
        LabeledDropdown<String>(
          label: 'Pakiet',
          value: item['pack_id'] as String? ?? '',
          options: {
            '': '(brak)',
            for (final p in state.packs) p['id'] as String: p['title'] as String? ?? p['id'] as String,
          },
          onChanged: (v) => set('pack_id', v.isEmpty ? null : v),
        ),
        SyncedTextField(label: 'Tytuł', value: item['title'] as String? ?? '', onChanged: (v) => set('title', v)),
        SyncedTextField(
          label: 'Podtytuł (opcjonalnie)',
          value: item['subtitle'] as String? ?? '',
          onChanged: (v) => set('subtitle', v),
        ),
        SyncedTextField(
          label: 'Opis dla rodzica',
          helper: 'Co to za zabawa i co ćwiczy. Bez obietnic efektów.',
          maxLines: 4,
          value: item['parent_description'] as String? ?? '',
          onChanged: (v) => set('parent_description', v),
        ),
        Row(
          children: [
            Expanded(
              child: SyncedTextField(
                label: 'Wiek od',
                digitsOnly: true,
                value: '${item['age_min'] ?? ''}',
                onChanged: (v) => set('age_min', int.tryParse(v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SyncedTextField(
                label: 'Czas (minuty)',
                digitsOnly: true,
                value: duration == 0 ? '' : '${(duration / 60).round()}',
                onChanged: (v) => set('duration_sec', (int.tryParse(v) ?? 0) * 60),
              ),
            ),
          ],
        ),
        const SectionTitle('Kiedy się sprawdza'),
        Wrap(
          spacing: 8,
          children: [
            for (final MapEntry(:key, :value) in situationLabels.entries)
              FilterChip(
                label: Text(value),
                selected: list('situations').contains(key),
                onSelected: (on) => toggle('situations', key, on),
              ),
          ],
        ),
        const SectionTitle('Co będzie potrzebne'),
        Wrap(
          spacing: 8,
          children: [
            for (final MapEntry(:key, :value) in requirementLabels.entries)
              FilterChip(
                label: Text(value),
                selected: list('requirements').contains(key),
                onSelected: (on) => toggle('requirements', key, on),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SyncedTextField(
          label: 'Co ćwiczy (po przecinku)',
          value: list('skills').join(', '),
          onChanged: (v) => set('skills', [
            for (final s in v.split(','))
              if (s.trim().isNotEmpty) s.trim(),
          ]),
        ),
        const SectionTitle('Dostęp i sklep'),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'free', label: Text('Za darmo (próbka)')),
            ButtonSegment(value: 'paid', label: Text('Płatna')),
          ],
          selected: {item['access'] as String? ?? 'paid'},
          onSelectionChanged: (s) => set('access', s.single),
        ),
        const SizedBox(height: 12),
        SyncedTextField(
          label: 'ID produktu w sklepach (pojedyncza zabawa)',
          helper: 'Musi być identyczny w App Store Connect i Google Play Console.',
          value: item['store_product_id'] as String? ?? '',
          onChanged: (v) => set('store_product_id', v),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => set('store_product_id', 'pl.audiokiddo.item.${itemId.replaceAll('-', '_')}'),
            child: const Text('Wygeneruj ID produktu'),
          ),
        ),
        if (kind != 'interactive_game') ...[
          const SectionTitle('Nagranie'),
          _AssetRow(
            asset: audio.firstOrNull,
            empty: 'Brak nagrania',
            buttonLabel: 'Wybierz plik audio…',
            onPick: pickAudio,
          ),
        ],
        const SectionTitle('Karta do druku (PDF, opcjonalnie)'),
        _AssetRow(
          asset: pdf.firstOrNull,
          empty: 'Brak',
          buttonLabel: 'Wybierz PDF…',
          onPick: pickPdf,
          onRemove: pdf.isEmpty ? null : () => set('pdf', null),
        ),
        if (kind == 'interactive_game') ...[
          const SectionTitle('Skrypt zabawy'),
          FilledButton.icon(
            icon: const Icon(Icons.account_tree_outlined),
            label: const Text('Edytuj skrypt'),
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ScriptEditorScreen(itemId: itemId))),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Zależna od tempa (blokuje zmianę prędkości)'),
            value: item['timing_sensitive'] == true,
            onChanged: (v) => set('timing_sensitive', v ? true : null),
          ),
        ],
      ],
    );
  }
}

class _IdField extends StatefulWidget {
  const _IdField({required this.itemId, required this.onRename, required this.taken});

  final String itemId;
  final ValueChanged<String> onRename;
  final Set<String?> taken;

  @override
  State<_IdField> createState() => _IdFieldState();
}

class _IdFieldState extends State<_IdField> {
  late String _value = widget.itemId;

  String? get _error {
    if (!_idPattern.hasMatch(_value)) return 'Tylko małe litery, cyfry i myślniki';
    if (_value != widget.itemId && widget.taken.contains(_value)) return 'Takie ID już istnieje';
    return null;
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: SyncedTextField(
          label: 'ID (adres w aplikacji i nazwa pliku)',
          value: widget.itemId,
          errorText: _error,
          onChanged: (v) => setState(() => _value = v.trim()),
        ),
      ),
      const SizedBox(width: 8),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton(
          onPressed: _error == null && _value != widget.itemId ? () => widget.onRename(_value) : null,
          child: const Text('Zmień ID'),
        ),
      ),
    ],
  );
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.empty,
    required this.buttonLabel,
    required this.onPick,
    this.onRemove,
  });

  final Json? asset;
  final String empty;
  final String buttonLabel;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final a = asset;
    return Card(
      child: ListTile(
        title: Text(a == null ? empty : a['path'] as String),
        subtitle: a == null
            ? null
            : Text(
                '${((a['bytes'] as int) / 1000).toStringAsFixed(0)} KB · SHA-256 ${(a['sha256'] as String).substring(0, 12)}…',
              ),
        trailing: Wrap(
          spacing: 8,
          children: [
            if (onRemove != null) IconButton(tooltip: 'Usuń', onPressed: onRemove, icon: const Icon(Icons.close)),
            OutlinedButton(onPressed: onPick, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
