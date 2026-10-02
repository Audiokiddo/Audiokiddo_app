import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/golden_hello.dart';
import '../catalog/catalog_providers.dart';
import '../downloads/download_providers.dart';
import '../downloads/download_manager.dart';
import '../downloads/download_button.dart';
import '../family/family.dart';
import '../personal/personal_repository.dart';
import '../parental_gate/parental_gate.dart';
import '../kids_mode/kids_mode_setup.dart';
import 'discovery_model.dart';
import 'reference_widgets.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Więcej')),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        for (final item in [
          (Icons.face_rounded, 'Profil dziecka', '/profil'),
          (Icons.auto_awesome_rounded, 'Tryby i rutyny', '/rutyny'),
          (Icons.queue_music_rounded, 'Kolejka', '/kolejka'),
          (Icons.download_done_rounded, 'Pobrane', '/pobrane'),
          (Icons.history_rounded, 'Historia słuchania', '/historia'),
          (Icons.route_rounded, 'Plan rozwoju', '/plan'),
        ])
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(item.$1, color: AkBrand.tealDeep),
            title: Text(item.$2),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(item.$3),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.child_care_rounded),
          title: const Text('Tryb dziecka'),
          onTap: () => showKidsModeSetup(context, ref),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: const Text('Konto i zakupy'),
          onTap: () async {
            if (await showParentalGate(context) && context.mounted) context.push('/konto');
          },
        ),
        const RefSection('Szop’en — kolega na dyżurze'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Drobne żarty na Start'),
          subtitle: const Text('Najwyżej jeden dziennie, bez dźwięku. W trakcie słuchania ma przerwę.'),
          value: !(ref.watch(discoveryProvider).value?.quiet ?? false),
          onChanged: (v) => ref.read(discoveryProvider.notifier).quiet(!v),
        ),
        OutlinedButton.icon(
          onPressed: () => showGoldenHello(context),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Zawołaj Szop’ena'),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key, this.history = false});
  final bool history;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final ids = ref.watch(history ? recentProvider : favoritesOrderedProvider);
    return Scaffold(
      appBar: AppBar(title: Text(history ? 'Ostatnio słuchane' : 'Ulubione')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (catalog.isLoading || ids.isLoading) const LinearProgressIndicator(),
          if (catalog.hasError || ids.hasError)
            TextButton(
              onPressed: () {
                ref.invalidate(catalogProvider);
                ref.invalidate(history ? recentProvider : favoritesOrderedProvider);
              },
              child: const Text('Spróbuj ponownie'),
            ),
          if (ids.value?.isEmpty ?? false)
            Text(
              history
                  ? 'Tutaj wrócicie do rozpoczętych przygód.'
                  : 'Dotknij serduszka przy zabawie, żeby mieć ją zawsze pod ręką.',
            ),
          for (final id in ids.value ?? <String>[])
            if (catalog.value?.item(id) case final item?) AudioRow(item: item),
        ],
      ),
    );
  }
}

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});
  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  bool pending = false;
  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final summary = ref.watch(downloadSummaryProvider).value;
    final free = ref.watch(freeBytesProvider).value;
    final entries = [
      for (final i in catalog.value?.items ?? <ContentItem>[])
        (i, ref.watch(downloadStatusProvider(i)).value ?? ItemDownloadStatus.none),
    ];
    final shown = entries
        .where(
          (e) => pending
              ? e.$2.isActive || e.$2.phase == DownloadPhase.failed
              : e.$2.phase == DownloadPhase.ready,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Pobrane')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('W urządzeniu')),
                ButtonSegment(value: true, label: Text('Pobieranie')),
              ],
              selected: {pending},
              onSelectionChanged: (s) => setState(() => pending = s.single),
            ),
            const SizedBox(height: 20),
            if (catalog.isLoading) const LinearProgressIndicator(),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  pending
                      ? 'Brak trwających pobrań.'
                      : 'Jeszcze nic nie pobrano. Wybierz zabawę w bibliotece i dotknij „Pobierz”.',
                ),
              ),
            for (final (item, _) in shown) ...[
              AudioRow(item: item),
              DownloadControl(item: item),
              const SizedBox(height: 18),
            ],
            const SizedBox(height: 24),
            Text(
              'Zajęte miejsce: ${formatBytes(summary?.bytes ?? 0)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (free != null) Text('Wolne na urządzeniu: ${formatBytes(free)}'),
            if (free != null && (summary?.bytes ?? 0) + free > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(
                  value: (summary?.bytes ?? 0) / ((summary?.bytes ?? 0) + free),
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyProvider);
    final family = state.value;
    final child = family?.active;
    final results = child == null ? <ActivityResult>[] : family!.resultsOf(child.id);
    final favorites = ref.watch(favoritesProvider).value ?? {};
    final catalog = ref.watch(catalogProvider).value;
    final counts = <String, int>{};
    for (final r in results) {
      counts.update(r.itemId, (n) => n + 1, ifAbsent: () => 1);
    }
    final recent = results.reversed.map((r) => r.itemId).toSet().take(5);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil dziecka'),
        actions: [
          IconButton(
            tooltip: 'Dodaj dziecko',
            onPressed: () => context.push('/plan/dziecko'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (state.isLoading) const LinearProgressIndicator(),
          if (child == null) ...[
            const Text('Dodaj profil, żeby dobierać zabawy do wieku i zapisywać wspólne postępy.'),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => context.push('/plan/dziecko'), child: const Text('Dodaj dziecko')),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: referenceMint, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.face_rounded, size: 42, color: AkBrand.tealDeep),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name.isEmpty ? 'Twoje dziecko' : child.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text('${child.age} lat'),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edytuj profil',
                    onPressed: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => _EditProfile(child: child))),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            if (family!.children.length > 1)
              Wrap(
                spacing: 8,
                children: [
                  for (final c in family.children)
                    ChoiceChip(
                      label: Text(c.name.isEmpty ? 'Dziecko ${family.children.indexOf(c) + 1}' : c.name),
                      selected: c.id == child.id,
                      onSelected: (_) => ref.read(familyProvider.notifier).setActive(c.id),
                    ),
                ],
              ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Stat(
                  Icons.favorite_rounded,
                  '${favorites.length}',
                  'Ulubione rodziny',
                  const Color(0xFFD45365),
                ),
                _Stat(
                  Icons.star_rounded,
                  '${results.where((r) => r.completed).length}',
                  'Ukończone',
                  AkBrand.sunDeep,
                ),
                _Stat(
                  Icons.bar_chart_rounded,
                  '${results.fold<int>(0, (s, r) => s + r.seconds) ~/ 60} min',
                  'Czas zabaw',
                  AkBrand.tealDeep,
                ),
              ],
            ),
            const RefSection('To lubi najbardziej'),
            if (counts.isEmpty)
              const Text('Po kilku zabawach pojawią się tutaj ulubione tematy dziecka.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c
                      in (PlayCategory.values.toList()..sort((a, b) {
                            int score(PlayCategory c) => results
                                .where(
                                  (r) =>
                                      catalog?.item(r.itemId) != null && c.matches(catalog!.item(r.itemId)!),
                                )
                                .length;
                            return score(b).compareTo(score(a));
                          }))
                          .take(3))
                    ActionChip(
                      avatar: Icon(categoryIcon(c), size: 18),
                      label: Text(c.label.replaceAll('\n', ' ')),
                      onPressed: () => context.push('/biblioteka?kategoria=${c.name}'),
                    ),
                ],
              ),
            const RefSection('Ostatnio słuchane'),
            for (final id in recent)
              if (catalog?.item(id) case final item?)
                AudioRow(item: item, subtitle: '${counts[id]} razy · ${(item.durationSec / 60).ceil()} min'),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final String value, label;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 100,
    child: Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _EditProfile extends ConsumerStatefulWidget {
  const _EditProfile({required this.child});
  final ChildProfile child;
  @override
  ConsumerState<_EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<_EditProfile> {
  late final name = TextEditingController(text: widget.child.name);
  late int age = widget.child.age;
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edytuj profil')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: name,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Imię lub pseudonim'),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          initialValue: age,
          decoration: const InputDecoration(labelText: 'Wiek'),
          items: [for (var a = 1; a <= 18; a++) DropdownMenuItem(value: a, child: Text('$a lat'))],
          onChanged: (v) => age = v ?? age,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: saving
              ? null
              : () async {
                  setState(() => saving = true);
                  final c = widget.child;
                  await ref
                      .read(familyProvider.notifier)
                      .saveChild(
                        ChildProfile(
                          id: c.id,
                          name: name.text.trim(),
                          age: age,
                          startedOn: c.startedOn,
                          goals: c.goals,
                          situations: c.situations,
                          dailyMinutes: c.dailyMinutes,
                        ),
                      );
                  if (context.mounted) context.pop();
                },
          child: const Text('Zapisz'),
        ),
      ],
    ),
  );
}
