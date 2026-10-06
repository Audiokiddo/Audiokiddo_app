import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/studio_controller.dart';
import '../theme.dart';

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
        SectionHeader(
          tint: Tint.publish,
          pose: v.canPublish ? 'klaszcze' : 'zdziwiony',
          title: 'Sprawdzenie przed publikacją',
          text:
              'Katalog w wersji ${state.catalog['version']}: ${state.items.length} zabaw (w tym $free za darmo), '
              '${state.packs.length} pakiety, ${state.shelves.length} półek. Publikujesz w zakładce Serwer.',
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Wczytaj katalog z aplikacji'),
              onPressed: () async {
                final sure = await confirmDelete(
                  context,
                  'obecny szkic i wczytać katalog wbudowany w aplikację',
                );
                if (!sure) return;
                final ok = await ref.read(studioProvider.notifier).loadStarter();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Wczytano katalog z aplikacji.' : 'Nie udało się wczytać katalogu.'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
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
                  Text(
                    'Do poprawienia: ${v.errorCount} (popraw w „Treści”)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
          'Plik catalog.json to kopia na dysk (np. do wbudowania w aplikację). '
          'Rodzinom katalog publikujesz w zakładce Serwer → „Publikuj w aplikacji”.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
