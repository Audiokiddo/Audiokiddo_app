import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../catalog/catalog_providers.dart';
import '../catalog/widgets/content_cover.dart';
import 'discovery_model.dart';
import 'reference_widgets.dart';
import 'queue_controller.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryProvider);
    final catalog = ref.watch(catalogProvider).value;
    final run = ref.watch(queueRunnerProvider);
    final items = [for (final id in state.value?.queue ?? <String>[]) ?catalog?.item(id)];
    final controller = ref.read(discoveryProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kolejka'),
        actions: [
          IconButton(
            tooltip: 'Dodaj nagrania',
            onPressed: run.running ? null : () => showQueuePicker(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.isLoading) const LinearProgressIndicator(),
            if (items.isEmpty)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Ułóż własną kolejkę. Dodaj nagrania przyciskiem +.'),
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  buildDefaultDragHandles: false,
                  itemCount: items.length,
                  onReorderItem: (old, next) {
                    if (run.running) return;
                    final ids = items.map((i) => i.id).toList();
                    ids.insert(next, ids.removeAt(old));
                    controller.setQueue(ids);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      key: ValueKey(item.id),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          SizedBox(width: 23, child: Text('${index + 1}')),
                          ContentCover(item: item, size: 56),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                                Text(
                                  '${(item.durationSec / 60).ceil()} min',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (run.running && run.index == index) const Icon(Icons.equalizer_rounded),
                          if (!run.running) ...[
                            IconButton(
                              tooltip: 'Usuń ${item.title}',
                              onPressed: () => controller.setQueue(
                                items.where((i) => i.id != item.id).map((i) => i.id).toList(),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 20),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.drag_handle_rounded),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (run.error != null) Padding(padding: const EdgeInsets.all(16), child: Text(run.error!)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (items.isNotEmpty)
                    Text(
                      '${items.length} nagrań · ${(items.fold<int>(0, (s, i) => s + i.durationSec) / 60).ceil()} min',
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: items.isEmpty
                        ? () => showQueuePicker(context)
                        : run.running
                        ? () => ref.read(queueRunnerProvider.notifier).stop()
                        : () async {
                            await ref.read(queueRunnerProvider.notifier).start(items);
                            if (context.mounted && ref.read(queueRunnerProvider).running) {
                              context.push('/odtwarzacz');
                            }
                          },
                    icon: Icon(run.running ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(
                      items.isEmpty
                          ? 'Dodaj nagrania'
                          : run.running
                          ? 'Zatrzymaj kolejkę'
                          : 'Start kolejki',
                    ),
                  ),
                  if (items.isNotEmpty)
                    TextButton(
                      onPressed: () => saveRoutineDialog(context, ref),
                      child: const Text('Zapisz jako moją rutynę'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> saveRoutineDialog(BuildContext context, WidgetRef ref) async {
  final name = await showDialog<String>(context: context, builder: (_) => const _RoutineNameDialog());
  if (name != null && name.isNotEmpty) {
    await ref.read(discoveryProvider.notifier).saveRoutine(name);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Rutyna zapisana w „Moich rutynach”.')));
    }
  }
}

Future<void> showQueuePicker(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => const _QueuePicker(),
);

class _QueuePicker extends ConsumerWidget {
  const _QueuePicker();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final ids = ref.watch(discoveryProvider).value?.queue ?? [];
    final items =
        catalog.value?.items
            .where(
              (i) =>
                  i.kind != ContentKind.interactiveGame &&
                  i.audio.isNotEmpty &&
                  ref.watch(canPlayProvider(i)),
            )
            .toList() ??
        [];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            Text('Dodaj do kolejki', style: Theme.of(context).textTheme.titleLarge),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Nagrania, które mogą odtwarzać się kolejno.'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (catalog.isLoading) const LinearProgressIndicator(),
                  if (items.isEmpty && !catalog.isLoading)
                    const Text('Brak dostępnych nagrań. Sprawdź bibliotekę.'),
                  for (final item in items)
                    AudioRow(
                      item: item,
                      trailing: IconButton(
                        tooltip: ids.contains(item.id) ? 'Dodano' : 'Dodaj ${item.title}',
                        onPressed: ids.contains(item.id)
                            ? null
                            : () => ref.read(discoveryProvider.notifier).add(item.id),
                        icon: Icon(
                          ids.contains(item.id)
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Gotowe')),
          ],
        ),
      ),
    );
  }
}

class _RoutineNameDialog extends StatefulWidget {
  const _RoutineNameDialog();
  @override
  State<_RoutineNameDialog> createState() => _RoutineNameDialogState();
}

class _RoutineNameDialogState extends State<_RoutineNameDialog> {
  final input = TextEditingController();
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nazwa rutyny'),
    content: TextField(
      controller: input,
      autofocus: true,
      maxLength: 50,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(hintText: 'Na przykład: Obiad bez negocjacji'),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
      FilledButton(
        onPressed: input.text.trim().isEmpty ? null : () => Navigator.pop(context, input.text.trim()),
        child: const Text('Zapisz'),
      ),
    ],
  );
}
