import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/studio_controller.dart';

/// Validation summary and publishing. Local mode exports catalog.json; with the server
/// (Etap 3) this becomes "Publikuj" with version history and "Przywróć".
class PublishScreen extends ConsumerWidget {
  const PublishScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studioProvider);
    final v = ref.watch(validationProvider);
    final scheme = Theme.of(context).colorScheme;
    final free = state.items.where((i) => i['access'] == 'free').length;
    final missingAudio = [
      for (final i in state.items)
        if (i['kind'] != 'interactive_game' && (i['audio'] as List? ?? const []).isEmpty)
          i['title'] as String? ?? '${i['id']}',
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Katalog w wersji ${state.catalog['version']}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '${state.items.length} pozycji, w tym $free za darmo · ${state.packs.length} pakiety · ${state.shelves.length} półki',
        ),
        const SizedBox(height: 24),
        if (v.canPublish)
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: scheme.primary),
              title: const Text('Katalog jest poprawny'),
              subtitle: const Text('Aplikacja pokaże wszystkie pozycje.'),
            ),
          )
        else
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Do poprawienia: ${v.errorCount}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (v.fatal != null) Text('• Cały katalog: ${v.fatal}'),
                  for (final MapEntry(:key, :value) in v.itemErrors.entries) Text('• $key: $value'),
                  for (final e in v.otherErrors) Text('• $e'),
                ],
              ),
            ),
          ),
        if (missingAudio.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.music_off_outlined),
              title: Text('Bez nagrania: ${missingAudio.length}'),
              subtitle: Text(missingAudio.join(', ')),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Eksportuj catalog.json (nowa wersja)'),
          onPressed: v.canPublish
              ? () {
                  final json = ref.read(studioProvider.notifier).exportForPublishing();
                  ref.read(studioIoProvider).download('catalog.json', json);
                }
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          'Tryb lokalny: plik zastępuje app/assets/mock/catalog.json. '
          'Po podłączeniu serwera ten przycisk opublikuje katalog od razu dla wszystkich '
          'i pozwoli wrócić do poprzedniej wersji.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
