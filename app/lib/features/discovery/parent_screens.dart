import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/appearance.dart';
import '../../core/theme/tokens.dart';
import '../catalog/catalog_providers.dart';
import '../downloads/download_providers.dart';
import '../downloads/download_manager.dart';
import '../downloads/pack_download.dart';
import '../family/family.dart';
import '../personal/personal_repository.dart';
import '../kids_mode/kids_mode_setup.dart';
import '../alerts/alerts.dart';
import '../diploma/diploma.dart';
import '../rating/rating.dart';
import 'discovery_model.dart';
import 'reference_widgets.dart';
import '../about/about_screen.dart';
import '../family_sharing/family_screen.dart';
import '../purchases/plan_limit.dart';
import '../reminders/reminder_offer.dart';
import '../welcome/szop_tour.dart';
import '../welcome/welcome_controller.dart';
import '../../core/router.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  /// Szop’en's tour lights up the downloads.
  static Widget _tile(String route, Widget child) =>
      route == '/pobrane' ? TourTarget(id: 'downloads', child: child) : child;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Więcej')),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        for (final item in [
          (Icons.favorite_rounded, 'Ulubione', '/ulubione'),
          (Icons.face_rounded, 'Profil dziecka', '/profil'),
          (Icons.auto_awesome_rounded, 'Tryby i rutyny', '/rutyny'),
          (Icons.queue_music_rounded, 'Kolejka', '/kolejka'),
          (Icons.download_done_rounded, 'Pobrane', '/pobrane'),
          (Icons.history_rounded, 'Historia słuchania', '/historia'),
          (Icons.route_rounded, 'Plan rozwoju', '/plan'),
        ])
          _tile(
            item.$3,
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.$1, color: AkBrand.tealDeep),
              title: Text(item.$2),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(item.$3),
            ),
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
          onTap: () => context.push('/konto'),
        ),
        const ManageSubscriptionTile(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.family_restroom_rounded, color: AkBrand.tealDeep),
          title: const Text('Drugi rodzic'),
          subtitle: const Text('Ten sam abonament na drugim telefonie'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/rodzina'),
        ),
        const RefSection('Wygląd aplikacji'),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Jasny')),
            ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('Auto')),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Ciemny')),
          ],
          selected: {ref.watch(appearanceProvider).value ?? ThemeMode.light},
          onSelectionChanged: (s) => ref.read(appearanceProvider.notifier).set(s.single),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Auto: jasny w dzień, ciemny wieczorem od 20:00 do 6:00.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.emoji_emotions_outlined, color: AkBrand.tealDeep),
          title: const Text('Ikona aplikacji'),
          subtitle: const Text('Wybierz, w jakim humorze Szop’en czeka na ekranie telefonu'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/ikona'),
        ),
        const RefSection('Powiadomienia'),
        const ReminderTile(),
        const AlertsSwitch(),
        const LettersSwitch(),
        const RefSection('Szop’en — kolega na dyżurze'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Komentarze Szop’ena'),
          subtitle: const Text('Przy powrocie i osiągnięciach. Krótko, bez dźwięku.'),
          value: !(ref.watch(discoveryProvider).value?.quiet ?? false),
          onChanged: (v) => ref.read(discoveryProvider.notifier).quiet(!v),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.tour_rounded, color: AkBrand.tealDeep),
          title: const Text('Szop’en pokaże, gdzie co jest'),
          subtitle: const Text('Krótki samouczek po aplikacji, jeszcze raz'),
          onTap: () {
            context.go('/');
            ref.read(welcomeProvider).startTour();
          },
        ),
        const RefSection('Pomóż nam rosnąć'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const PolishFlag(width: 24),
          title: const Text('O nas: Nela i Dawid'),
          subtitle: const Text('Polska rodzinna marka. Sami piszemy i nagrywamy zabawy'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/o-nas'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.card_giftcard_rounded, color: AkBrand.tealDeep),
          title: const Text('Poleć znajomym'),
          subtitle: const Text('Znajomy 14 dni za darmo, Ty miesiąc gratis'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/polec'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.star_rounded, color: AkBrand.tealDeep),
          title: const Text('Oceń AudioKiddo'),
          subtitle: const Text('Kilka gwiazdek pomaga innym rodzicom nas znaleźć'),
          onTap: () => rateApp(context, fromList: true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.mail_outline_rounded, color: AkBrand.tealDeep),
          title: const Text('Napisz do nas'),
          subtitle: const Text(feedbackEmail),
          onTap: () => sendFeedback(context),
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

/// Downloads: the family's plays by pack, each with its own button and a "whole pack" one, then
/// what is on the phone and what is still coming.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});
  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

enum _DownloadsTab { yours, onPhone, pending }

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  _DownloadsTab tab = _DownloadsTab.yours;
  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider).value;
    final summary = ref.watch(downloadSummaryProvider).value;
    final free = ref.watch(freeBytesProvider).value;
    final text = Theme.of(context).textTheme;
    final items = [
      for (final i in catalog?.items ?? <ContentItem>[])
        if (i.downloadBytes > 0) i,
    ];
    final playable = [
      for (final i in items)
        if (ref.watch(canPlayProvider(i))) i,
    ];
    ItemDownloadStatus status(ContentItem i) => ref.watch(downloadStatusProvider(i)).value ?? ItemDownloadStatus.none;
    final listed = switch (tab) {
      _DownloadsTab.yours => playable,
      _DownloadsTab.onPhone => [
        for (final i in items)
          if (status(i).phase == DownloadPhase.ready) i,
      ],
      _DownloadsTab.pending => [
        for (final i in items)
          if (status(i).isActive || status(i).phase == DownloadPhase.failed) i,
      ],
    };
    final groups = <(String, List<ContentItem>)>[
      for (final pack in catalog?.packs ?? const <Pack>[])
        if (listed.where((i) => i.packId == pack.id).toList() case final g when g.isNotEmpty) (pack.title, g),
      if (listed.where((i) => i.packId == null).toList() case final g when g.isNotEmpty) ('Piosenki i gry', g),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Pobrane')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Pobrane zabawy działają bez internetu: w aucie, samolocie i na działce.',
              style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
            ),
            const SizedBox(height: 14),
            SegmentedButton<_DownloadsTab>(
              segments: const [
                ButtonSegment(value: _DownloadsTab.yours, label: Text('Wasze zabawy')),
                ButtonSegment(value: _DownloadsTab.onPhone, label: Text('W telefonie')),
                ButtonSegment(value: _DownloadsTab.pending, label: Text('W trakcie')),
              ],
              selected: {tab},
              onSelectionChanged: (s) => setState(() => tab = s.single),
            ),
            const SizedBox(height: 12),
            if (catalog == null) const LinearProgressIndicator(),
            if (catalog != null && groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(switch (tab) {
                  _DownloadsTab.yours => 'Nie macie jeszcze zabaw do pobrania.',
                  _DownloadsTab.onPhone => 'Jeszcze nic nie pobrano. Zacznij od „Wasze zabawy”.',
                  _DownloadsTab.pending => 'Nic się teraz nie pobiera.',
                }),
              ),
            for (final (title, group) in groups) ...[
              const SizedBox(height: 12),
              Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              if (tab == _DownloadsTab.yours) ...[
                const SizedBox(height: 8),
                PackDownloadButton(items: group, label: 'Pobierz wszystkie'),
              ],
              for (final item in group)
                AudioRow(
                  item: item,
                  trailing: ItemDownloadIcon(item: item),
                ),
            ],
            const SizedBox(height: 24),
            Text('Zajęte miejsce: ${formatBytes(summary?.bytes ?? 0)}', style: text.titleSmall),
            if (free != null) Text('Wolne w telefonie: ${formatBytes(free)}'),
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
            onPressed: () async {
              if (await mayAddChild(context, ref) && context.mounted) await context.push('/plan/dziecko');
            },
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
              child: LightSurface(
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
                          Navigator.of(context).push(swipeRoute<void>(builder: (_) => _EditProfile(child: child))),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
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
                _Stat(Icons.favorite_rounded, '${favorites.length}', 'Ulubione rodziny', const Color(0xFFD45365)),
                _Stat(Icons.star_rounded, '${results.where((r) => r.completed).length}', 'Ukończone', AkBrand.sunDeep),
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
              Row(
                children: [
                  for (final (i, c)
                      in (PlayCategory.values.toList()..sort((a, b) {
                            int score(PlayCategory c) => results
                                .where((r) => catalog?.item(r.itemId) != null && c.matches(catalog!.item(r.itemId)!))
                                .length;
                            return score(b).compareTo(score(a));
                          }))
                          .take(3)
                          .indexed) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: categoryColor(c) == referencePurple ? referenceLilac : categoryColor(c),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => context.push('/biblioteka?kategoria=${c.name}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                            child: Column(
                              children: [
                                Icon(categoryIcon(c), size: 30, color: const Color(0xFF211C35)),
                                const SizedBox(height: 6),
                                Text(
                                  c.label.split('\n').first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: const Color(0xFF211C35), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            if (ref.watch(diplomasProvider(child.id)).value case final diplomas? when diplomas.isNotEmpty) ...[
              const RefSection('Dyplomy'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in diplomas.entries)
                    if (catalog?.pack(e.key) case final pack?)
                      ActionChip(
                        avatar: const Icon(Icons.workspace_premium_rounded, size: 18, color: AkBrand.sunDeep),
                        label: Text(pack.title),
                        onPressed: () => context.push('/dyplom/${pack.id}'),
                      ),
                ],
              ),
            ],
            ...() {
              final weekAgo = DateTime.now().subtract(const Duration(days: 7));
              final week = <String, int>{};
              for (final r in results.where((r) => r.at.isAfter(weekAgo))) {
                week.update(r.itemId, (n) => n + 1, ifAbsent: () => 1);
              }
              if (week.isEmpty) return const <Widget>[];
              return [
                const RefSection('W tym tygodniu'),
                for (final e in (week.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5))
                  if (catalog?.item(e.key) case final item?)
                    AudioRow(item: item, subtitle: e.value == 1 ? '1 raz' : '${e.value} razy'),
              ];
            }(),
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
