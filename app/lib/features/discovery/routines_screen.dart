import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import 'discovery_model.dart';
import 'queue_controller.dart';
import 'reference_widgets.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});
  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  bool mine = false;
  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(discoveryProvider).value?.routines ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Tryby i rutyny')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Gotowe tryby')),
              ButtonSegment(value: true, label: Text('Moje rutyny')),
            ],
            selected: {mine},
            onSelectionChanged: (v) => setState(() => mine = v.single),
          ),
          const SizedBox(height: 24),
          if (!mine)
            for (final row in [
              (
                'Samochód',
                'Zabawy idealne w podróży. Bez ekranu.',
                Icons.directions_car_rounded,
                AkBrand.sun,
                '/podroz',
              ),
              (
                'Podczas obiadu',
                'Bez materiałów i dodatkowego przygotowania.',
                Icons.restaurant_rounded,
                referenceLilac,
                '/ratunku?tryb=obiad',
              ),
              (
                'Na dobry dzień',
                'Pobudzające zabawy i piosenki.',
                Icons.wb_sunny_outlined,
                referenceMint,
                '/biblioteka?kategoria=movement',
              ),
              (
                'Rutyna przed snem',
                'Spokój, oddech i wyciszenie.',
                Icons.bedtime_rounded,
                referencePurple,
                '/dobranoc',
              ),
              (
                'Razem z rodzicem',
                'Wspólna wyobraźnia i rozmowa.',
                Icons.people_alt_outlined,
                referenceMint,
                '/biblioteka?kategoria=adventure',
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: row.$4,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => context.push(row.$5),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(row.$3, size: 36, color: row.$4 == referencePurple ? Colors.white : referencePurple),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.$1,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: row.$4 == referencePurple ? Colors.white : referencePurple),
                                ),
                                Text(
                                  row.$2,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: row.$4 == referencePurple ? Colors.white : referencePurple),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: row.$4 == referencePurple ? Colors.white : referencePurple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          if (mine) ...[
            if (saved.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Ułóż kolejkę i zapisz ją jako rutynę. Będzie czekać na następny obiad, podróż albo spokojny wieczór.',
                ),
              ),
            for (final routine in saved)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(routine.name),
                subtitle: Text('${routine.items.length} nagrań'),
                leading: const Icon(Icons.queue_music_rounded),
                onTap: () async {
                  if (ref.read(queueRunnerProvider).running) {
                    await ref.read(queueRunnerProvider.notifier).stop();
                  }
                  await ref.read(discoveryProvider.notifier).setQueue(routine.items);
                  if (context.mounted) context.push('/kolejka');
                },
                trailing: IconButton(
                  tooltip: 'Usuń rutynę',
                  onPressed: () => ref.read(discoveryProvider.notifier).removeRoutine(routine.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            FilledButton.icon(
              onPressed: () => context.push('/kolejka'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ułóż własną rutynę'),
            ),
          ],
        ],
      ),
    );
  }
}
