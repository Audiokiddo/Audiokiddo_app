import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../server/studio_server.dart';
import 'ads_screen.dart';
import 'crm_insights.dart';
import 'crm_widgets.dart';

/// The CRM: Dawid's daily workspace for growing AudioKiddo. The AI director (COO) reports and
/// proposes; nothing it proposes happens before Dawid approves it under "Decyzje".
class CrmScreen extends ConsumerStatefulWidget {
  const CrmScreen({super.key});

  @override
  ConsumerState<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends ConsumerState<CrmScreen> {
  @override
  Widget build(BuildContext context) {
    final server = ref.watch(studioServerProvider);
    if (!server.signedIn) return AdminSignIn(onSignedIn: () => setState(() {}));
    final pending = ref.watch(crmPendingProvider).value?.length ?? 0;
    final adsPending = ref.watch(adsPendingProvider);
    return DefaultTabController(
      length: 11,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(icon: Icon(Icons.dashboard_outlined), text: 'Pulpit'),
              Tab(
                icon: Badge(
                  isLabelVisible: pending > 0,
                  label: Text('$pending'),
                  child: const Icon(Icons.how_to_vote_outlined),
                ),
                text: 'Decyzje',
              ),
              const Tab(icon: Icon(Icons.view_kanban_outlined), text: 'Zadania'),
              const Tab(icon: Icon(Icons.lightbulb_outline), text: 'Pomysły'),
              const Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Kalendarz'),
              const Tab(icon: Icon(Icons.campaign_outlined), text: 'Reklamy'),
              Tab(
                icon: Badge(
                  isLabelVisible: adsPending > 0,
                  label: Text('$adsPending'),
                  child: const Icon(Icons.insights_outlined),
                ),
                text: 'Kampanie',
              ),
              const Tab(icon: Icon(Icons.mail_outline), text: 'Mailing'),
              const Tab(icon: Icon(Icons.people_outline), text: 'Użytkownicy'),
              const Tab(icon: Icon(Icons.update), text: 'Aktualizacje'),
              const Tab(icon: Icon(Icons.tune), text: 'Ustawienia'),
            ],
          ),
          const Divider(height: 1),
          const Expanded(
            child: TabBarView(
              children: [
                _Dashboard(),
                _Decisions(),
                _Tasks(),
                _Ideas(),
                _Calendar(),
                _Ads(),
                CampaignsTab(),
                _Mailing(),
                _Users(),
                _Updates(),
                _Settings(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sign-in with an e-mail code (admins only); the session is kept in this browser.
class AdminSignIn extends ConsumerStatefulWidget {
  const AdminSignIn({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  ConsumerState<AdminSignIn> createState() => _AdminSignInState();
}

class _AdminSignInState extends ConsumerState<AdminSignIn> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final server = ref.read(studioServerProvider);
    setState(() => _busy = true);
    final ok = await crmRun(context, () async {
      if (!_sent) {
        await server.sendCode(_email.text);
      } else {
        await server.verify(_email.text, _code.text);
      }
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok && !_sent) _sent = true;
    });
    if (ok && server.signedIn) widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CRM AudioKiddo', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Wyślemy kod na Twój e-mail. Wejdzie tylko konto z listy administratorów.'),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_sent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Kod z maila', border: OutlineInputBorder()),
                onSubmitted: (_) => _go(),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : _go, child: Text(_sent ? 'Zaloguj' : 'Wyślij kod')),
          ],
        ),
      ),
    ),
  );
}

// Pulpit ---------------------------------------------------------------------------------------

class _Dashboard extends ConsumerWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(crmOverviewProvider);
    final briefings = ref.watch(crmItemsProvider('briefing'));
    final tasks = ref.watch(crmItemsProvider('task'));
    final calendar = ref.watch(crmItemsProvider('calendar'));
    final text = Theme.of(context).textTheme;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    String zl(Object? v) => v == null ? '–' : '${(v as num).toStringAsFixed(0)} zł';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        crmAsync(
          overview,
          (o) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              KpiTile(
                'Zysk w tym miesiącu (szac.)',
                zl(o['profit_month_estimate']),
                hint: 'MRR netto minus koszty',
                color: Colors.green.shade50,
              ),
              KpiTile('MRR brutto', zl(o['mrr_gross']), hint: 'netto ${zl(o['mrr_net'])}'),
              KpiTile('Płacące rodziny', '${o['paying_families']}'),
              KpiTile(
                'Abonamenty',
                '${o['subs_yearly']} roczne · ${o['subs_monthly']} mies.',
                hint: o['subs_multi_child'] == null ? null : 'w tym dla 2+ dzieci: ${o['subs_multi_child']}',
              ),
              KpiTile('Użytkownicy', '${o['users_total']}', hint: '+${o['users_7d']} w 7 dni'),
              KpiTile('Przychód 30 dni (brutto)', zl(o['revenue_30d_gross'])),
              KpiTile('Otwarte zadania', '${o['open_tasks']}'),
              KpiTile('Czeka na decyzję', '${o['pending_decisions']}', color: Colors.amber.shade50),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const TrendCard(),
        const SizedBox(height: 24),
        const _CooBox(),
        const SizedBox(height: 16),
        crmAsync(briefings, (list) {
          final last = list.where((b) => b['area'] == 'brief').firstOrNull;
          if (last == null) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nie ma jeszcze raportu COO. Kliknij „Raport COO”, żeby dostać pierwszy.'),
              ),
            );
          }
          return Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${last['title']}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SelectableText('${last['body']}'),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        Text('Na dziś i zaległe', style: text.titleMedium),
        crmAsync(tasks, (list) {
          final now = [
            for (final t in list)
              if (!['done', 'archived'].contains(t['status']) &&
                  t['decision'] != 'pending' &&
                  t['decision'] != 'rejected' &&
                  (t['due'] == null ? t['priority'] == 1 : (t['due'] as String).compareTo(today) <= 0))
                t,
          ];
          if (now.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('Nic pilnego.'));
          return Column(children: [for (final t in now) CrmCard(item: t, dense: true)]);
        }),
        const SizedBox(height: 24),
        Text('W kalendarzu (14 dni)', style: text.titleMedium),
        crmAsync(calendar, (list) {
          final soon = DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10);
          final next = [
            for (final c in list)
              if (c['due'] != null &&
                  (c['due'] as String).compareTo(today) >= 0 &&
                  (c['due'] as String).compareTo(soon) <= 0)
                c,
          ]..sort((a, b) => (a['due'] as String).compareTo(b['due'] as String));
          if (next.isEmpty) return const Padding(padding: EdgeInsets.all(8), child: Text('Pusto.'));
          return Column(children: [for (final c in next) CrmCard(item: c, dense: true)]);
        }),
      ],
    );
  }
}

/// The generators of the AI director, with an optional instruction.
class _CooBox extends ConsumerStatefulWidget {
  const _CooBox();

  @override
  ConsumerState<_CooBox> createState() => _CooBoxState();
}

class _CooBoxState extends ConsumerState<_CooBox> {
  final _note = TextEditingController();
  String? _busy;

  static const modes = [
    ('brief', Icons.assignment_outlined, 'Raport COO'),
    ('packs', Icons.inventory_2_outlined, 'Pomysły na pakiety'),
    ('ads', Icons.campaign_outlined, 'Reklamy i rolki'),
    ('newsletter', Icons.mail_outline, 'Newsletter'),
    ('improve', Icons.trending_up, 'Propozycje zmian'),
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _ask(String mode) async {
    setState(() => _busy = mode);
    await crmRun(
      context,
      () async {
        await ref.read(studioServerProvider).coo(mode, note: _note.text.trim().isEmpty ? null : _note.text.trim());
        ref.read(crmRefreshProvider.notifier).bump();
      },
      done: mode == 'brief'
          ? 'Raport gotowy. Propozycje zadań czekają w „Decyzje”.'
          : 'Propozycje czekają w „Decyzje”.',
    );
    if (mounted) setState(() => _busy = null);
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_outlined),
              const SizedBox(width: 8),
              Text('Agent COO', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Zna liczby, zadania, pomysły, kalendarz i Twoje wcześniejsze decyzje. Każda propozycja '
            'trafia do „Decyzje”: Ty wybierasz, co robimy dalej.',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Wskazówka dla agenta (opcjonalnie), np. „skup się na święta”',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (mode, icon, label) in modes)
                FilledButton.tonalIcon(
                  onPressed: _busy != null ? null : () => _ask(mode),
                  icon: _busy == mode
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(icon),
                  label: Text(label),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

// Decyzje --------------------------------------------------------------------------------------

class _Decisions extends ConsumerWidget {
  const _Decisions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.read(studioServerProvider);
    void refresh() => ref.read(crmRefreshProvider.notifier).bump();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _CooBox(),
        const SizedBox(height: 16),
        crmAsync(ref.watch(crmPendingProvider), (list) {
          if (list.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nic nie czeka na decyzję. Poproś agenta o propozycje powyżej.'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do decyzji: ${list.length}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final item in list)
                CrmCard(
                  item: item,
                  actions: [
                    FilledButton.icon(
                      onPressed: () async {
                        if (await crmRun(context, () => server.decide(item, approve: true))) refresh();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Zatwierdzam'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        if (await crmRun(context, () => server.decide(item, approve: false))) refresh();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Odrzucam'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final edited = await editCrmItem(
                          context,
                          kind: item['kind'] as String,
                          item: item,
                          areas: [item['area'] as String? ?? 'other'],
                          statuses: [item['status'] as String? ?? 'todo'],
                        );
                        if (edited == null || !context.mounted) return;
                        if (await crmRun(context, () => server.saveCrmItem(edited))) refresh();
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Popraw'),
                    ),
                  ],
                ),
            ],
          );
        }),
      ],
    );
  }
}

/// Items Dawid decided on or wrote himself (rejected and pending ones stay out).
List<Map<String, dynamic>> decided(List<Map<String, dynamic>> list) => [
  for (final i in list)
    if (i['decision'] != 'pending' && i['decision'] != 'rejected') i,
];

// Zadania --------------------------------------------------------------------------------------

class _Tasks extends ConsumerWidget {
  const _Tasks();

  static const columns = [('todo', 'Do zrobienia'), ('doing', 'W toku'), ('done', 'Zrobione')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.read(studioServerProvider);
    void refresh() => ref.read(crmRefreshProvider.notifier).bump();
    Future<void> edit([Map<String, dynamic>? item]) async {
      final saved = await editCrmItem(
        context,
        kind: 'task',
        item: item,
        areas: const ['launch', 'marketing', 'feature', 'crm', 'server', 'release'],
      );
      if (saved == null || !context.mounted) return;
      if (await crmRun(context, () => server.saveCrmItem(saved))) refresh();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: edit,
        icon: const Icon(Icons.add),
        label: const Text('Zadanie'),
      ),
      body: crmAsync(ref.watch(crmItemsProvider('task')), (all) {
        final list = decided(all)..sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (status, label) in columns)
                Container(
                  width: 340,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$label (${list.where((t) => t['status'] == status).length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final t in list.where((t) => t['status'] == status))
                        CrmCard(
                          item: t,
                          dense: true,
                          onTap: () => edit(t),
                          actions: [
                            for (final (next, nextLabel) in columns)
                              if (next != status)
                                TextButton(
                                  onPressed: () async {
                                    if (await crmRun(
                                      context,
                                      () => server.saveCrmItem({'id': t['id'], 'status': next}),
                                    )) {
                                      refresh();
                                    }
                                  },
                                  child: Text('→ $nextLabel'),
                                ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// Pomysły --------------------------------------------------------------------------------------

class _Ideas extends ConsumerStatefulWidget {
  const _Ideas();

  @override
  ConsumerState<_Ideas> createState() => _IdeasState();
}

class _IdeasState extends ConsumerState<_Ideas> {
  String? _area;
  String? _writing;

  static const areas = ['pack', 'scenario', 'feature', 'post', 'reel'];
  static const statuses = ['new', 'chosen', 'in_production', 'published', 'archived'];

  @override
  Widget build(BuildContext context) {
    final server = ref.read(studioServerProvider);
    void refresh() => ref.read(crmRefreshProvider.notifier).bump();
    Future<void> edit([Map<String, dynamic>? item]) async {
      final saved = await editCrmItem(context, kind: 'idea', item: item, areas: areas, statuses: statuses);
      if (saved == null || !context.mounted) return;
      if (await crmRun(context, () => server.saveCrmItem(saved))) refresh();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: edit,
        icon: const Icon(Icons.add),
        label: const Text('Pomysł'),
      ),
      body: crmAsync(ref.watch(crmItemsProvider('idea')), (all) {
        final list = [
          for (final i in decided(all))
            if (i['area'] != 'ad' && (_area == null || i['area'] == _area)) i,
        ];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Wszystkie'),
                  selected: _area == null,
                  onSelected: (_) => setState(() => _area = null),
                ),
                for (final a in areas)
                  ChoiceChip(
                    label: Text(areaLabel(a)),
                    selected: _area == a,
                    onSelected: (_) => setState(() => _area = a),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty) const Text('Brak pomysłów. Dodaj własny albo poproś agenta w „Decyzje”.'),
            for (final item in list)
              CrmCard(
                item: item,
                actions: [
                  Chip(label: Text(statusLabels[item['status']] ?? '${item['status']}')),
                  TextButton(onPressed: () => edit(item), child: const Text('Edytuj')),
                  if (item['area'] == 'pack' || item['area'] == 'feature')
                    TextButton.icon(
                      onPressed: _writing != null
                          ? null
                          : () async {
                              setState(() => _writing = item['id'] as String);
                              await crmRun(context, () async {
                                await server.coo('scenario', focusId: item['id'] as String);
                                refresh();
                              }, done: 'Scenariusz gotowy: czeka w „Decyzje”.');
                              if (mounted) setState(() => _writing = null);
                            },
                      icon: _writing == item['id']
                          ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_stories_outlined),
                      label: const Text('Agent: napisz scenariusz zabawy'),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await crmRun(
                        context,
                        () => server.saveCrmItem({
                          'kind': 'calendar',
                          'area': item['area'] == 'pack' ? 'release' : 'post',
                          'title': '${item['title']}',
                          'body': '${item['body']}',
                          'status': 'todo',
                          'data': {'idea_id': item['id']},
                        }),
                        done: 'Dodano do kalendarza. Ustaw datę w zakładce Kalendarz.',
                      );
                      if (ok) refresh();
                    },
                    icon: const Icon(Icons.event_available),
                    label: const Text('Do kalendarza'),
                  ),
                ],
              ),
          ],
        );
      }),
    );
  }
}

// Kalendarz ------------------------------------------------------------------------------------

class _Calendar extends ConsumerWidget {
  const _Calendar();

  static const areas = ['release', 'post', 'reel', 'newsletter', 'promotion', 'update'];
  static const months = [
    'Styczeń',
    'Luty',
    'Marzec',
    'Kwiecień',
    'Maj',
    'Czerwiec',
    'Lipiec',
    'Sierpień',
    'Wrzesień',
    'Październik',
    'Listopad',
    'Grudzień',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.read(studioServerProvider);
    void refresh() => ref.read(crmRefreshProvider.notifier).bump();
    Future<void> edit([Map<String, dynamic>? item]) async {
      final saved = await editCrmItem(context, kind: 'calendar', item: item, areas: areas);
      if (saved == null || !context.mounted) return;
      if (await crmRun(context, () => server.saveCrmItem(saved))) refresh();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: edit,
        icon: const Icon(Icons.add),
        label: const Text('Publikacja'),
      ),
      body: crmAsync(ref.watch(crmItemsProvider('calendar')), (all) {
        final list = decided(all)
          ..sort((a, b) => ((a['due'] as String?) ?? '9999').compareTo((b['due'] as String?) ?? '9999'));
        final byMonth = <String, List<Map<String, dynamic>>>{};
        for (final c in list) {
          final due = DateTime.tryParse(c['due'] as String? ?? '');
          final key = due == null ? 'Bez daty' : '${months[due.month - 1]} ${due.year}';
          byMonth.putIfAbsent(key, () => []).add(c);
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Plan: jeden nowy pakiet w miesiącu, 3 rolki w tygodniu, newsletter co 2 tygodnie.'),
            const SizedBox(height: 12),
            if (byMonth.isEmpty) const Text('Kalendarz jest pusty.'),
            for (final MapEntry(key: month, value: items) in byMonth.entries) ...[
              Text(month, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              for (final c in items)
                CrmCard(
                  item: c,
                  dense: true,
                  onTap: () => edit(c),
                  actions: [Chip(label: Text(statusLabels[c['status']] ?? '${c['status']}'))],
                ),
              const SizedBox(height: 12),
            ],
          ],
        );
      }),
    );
  }
}

// Reklamy --------------------------------------------------------------------------------------

/// Ad ideas as previews of a social post (hook, text on screen, caption, CTA).
class _Ads extends ConsumerWidget {
  const _Ads();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.read(studioServerProvider);
    void refresh() => ref.read(crmRefreshProvider.notifier).bump();
    Future<void> edit([Map<String, dynamic>? item]) async {
      final saved = await editCrmItem(
        context,
        kind: 'idea',
        item: item ?? {'area': 'ad'},
        areas: const ['ad'],
        statuses: const ['new', 'chosen', 'in_production', 'published', 'archived'],
      );
      if (saved == null || !context.mounted) return;
      if (await crmRun(context, () => server.saveCrmItem(saved))) refresh();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: edit,
        icon: const Icon(Icons.add),
        label: const Text('Reklama'),
      ),
      body: crmAsync(ref.watch(crmItemsProvider('idea')), (all) {
        final ads = [
          for (final i in decided(all))
            if (i['area'] == 'ad') i,
        ];
        if (ads.isEmpty) {
          return const Center(child: Text('Brak reklam. Poproś agenta o „Reklamy i rolki” w „Decyzje”.'));
        }
        return GridView.extent(
          maxCrossAxisExtent: 340,
          padding: const EdgeInsets.all(20),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: .52,
          children: [for (final ad in ads) _AdPreview(ad: ad, onTap: () => edit(ad))],
        );
      }),
    );
  }
}

class _AdPreview extends StatelessWidget {
  const _AdPreview({required this.ad, required this.onTap});

  final Map<String, dynamic> ad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = Map<String, dynamic>.from(ad['data'] as Map? ?? {});
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black, width: 6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3EADB2), Color(0xFFFAC119)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(radius: 14, child: Text('A', style: TextStyle(fontSize: 12))),
                        const SizedBox(width: 6),
                        Text('audiokiddo', style: text.labelMedium?.copyWith(color: Colors.white)),
                        const Spacer(),
                        Text('${data['format'] ?? 'rolka'}', style: text.labelSmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${ad['title']}',
                      style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: Text('${ad['body']}', style: text.bodySmall?.copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        if (data['audience'] != null) 'Dla: ${data['audience']}',
                        if (data['budget_test_pln'] != null) 'Test: ${data['budget_test_pln']} zł',
                        statusLabels[ad['status']] ?? '${ad['status']}',
                      ].join(' · '),
                      style: text.labelSmall,
                    ),
                  ),
                  FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Sprawdź'),
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

// Mailing --------------------------------------------------------------------------------------

class _Mailing extends ConsumerStatefulWidget {
  const _Mailing();

  @override
  ConsumerState<_Mailing> createState() => _MailingState();
}

class _MailingState extends ConsumerState<_Mailing> {
  Future<Map<String, dynamic>>? _overview;
  String? _busy;

  @override
  Widget build(BuildContext context) {
    final server = ref.read(studioServerProvider);
    final text = Theme.of(context).textTheme;
    void refresh() => ref.read(crmRefreshProvider.notifier).bump();
    Future<void> edit([Map<String, dynamic>? item]) async {
      final saved = await editCrmItem(context, kind: 'mailing', item: item, areas: const ['newsletter', 'automation']);
      if (saved == null || !context.mounted) return;
      if (await crmRun(context, () => server.saveCrmItem(saved))) refresh();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: edit,
        icon: const Icon(Icons.add),
        label: const Text('Mail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _overview == null
                  ? Row(
                      children: [
                        const Expanded(child: Text('MailerLite: subskrybenci, wyniki kampanii i automatyzacje.')),
                        FilledButton.tonal(
                          onPressed: () => setState(() => _overview = server.mailerLite()),
                          child: const Text('Wczytaj z MailerLite'),
                        ),
                      ],
                    )
                  : FutureBuilder<Map<String, dynamic>>(
                      future: _overview,
                      builder: (context, snap) {
                        if (snap.hasError) return Text('${snap.error}');
                        if (!snap.hasData) return const LinearProgressIndicator();
                        final o = snap.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Subskrybenci: ${o['subscribers'] ?? '–'}', style: text.titleMedium),
                            const SizedBox(height: 8),
                            Text('Grupy', style: text.labelLarge),
                            for (final g in (o['groups'] as List? ?? const []).cast<Map>())
                              Text('• ${g['name']}: ${g['active']} aktywnych, otwarcia ${g['open_rate'] ?? '–'}'),
                            const SizedBox(height: 8),
                            Text('Ostatnie kampanie', style: text.labelLarge),
                            for (final c in (o['campaigns'] as List? ?? const []).cast<Map>())
                              Text(
                                '• ${c['subject'] ?? c['name']}: wysłano ${c['sent'] ?? '–'}, otwarcia ${c['open_rate'] ?? '–'}, kliknięcia ${c['click_rate'] ?? '–'}',
                              ),
                            const SizedBox(height: 8),
                            Text('Automatyzacje', style: text.labelLarge),
                            for (final a in (o['automations'] as List? ?? const []).cast<Map>())
                              Text(
                                '• ${a['name']}: ${a['enabled'] == true ? 'włączona' : 'wyłączona'}, ukończyło ${a['completed'] ?? '–'}',
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          crmAsync(ref.watch(crmItemsProvider('mailing')), (all) {
            final list = decided(all);
            if (list.isEmpty) return const Text('Brak maili. Poproś agenta o newsletter w „Decyzje”.');
            return Column(
              children: [
                for (final m in list)
                  CrmCard(
                    item: m,
                    actions: [
                      Chip(label: Text(statusLabels[m['status']] ?? '${m['status']}')),
                      TextButton(onPressed: () => edit(m), child: const Text('Edytuj')),
                      TextButton.icon(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text('${(m['data'] as Map?)?['subject'] ?? m['title']}'),
                            content: SizedBox(
                              width: 560,
                              child: SingleChildScrollView(child: SelectableText('${m['body']}')),
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Podgląd'),
                      ),
                      if (m['area'] == 'newsletter')
                        TextButton.icon(
                          onPressed: _busy != null
                              ? null
                              : () async {
                                  setState(() => _busy = m['id'] as String);
                                  final ok = await crmRun(
                                    context,
                                    () => server.mailerLiteDraft(m['id'] as String),
                                    done: 'Szkic jest w MailerLite. Sprawdź i wyślij go tam.',
                                  );
                                  if (ok) refresh();
                                  if (mounted) setState(() => _busy = null);
                                },
                          icon: const Icon(Icons.outbox_outlined),
                          label: const Text('Szkic w MailerLite'),
                        ),
                      if (m['area'] == 'newsletter' && (m['data'] as Map?)?['scheduled'] == null)
                        FilledButton.tonalIcon(
                          onPressed: _busy != null
                              ? null
                              : () async {
                                  final plan = await askNewsletterSchedule(context, server);
                                  if (plan == null || !context.mounted) return;
                                  final (group, date, time) = plan;
                                  setState(() => _busy = m['id'] as String);
                                  final ok = await crmRun(
                                    context,
                                    () => server.mailerLiteSchedule(m['id'] as String, group, date, time),
                                    done: 'Zaplanowano: $date o $time. Zmienisz to jeszcze w MailerLite.',
                                  );
                                  if (ok) refresh();
                                  if (mounted) setState(() => _busy = null);
                                },
                          icon: const Icon(Icons.schedule_send_outlined),
                          label: const Text('Zaplanuj wysyłkę'),
                        ),
                      if ((m['data'] as Map?)?['scheduled'] case final at?)
                        Chip(avatar: const Icon(Icons.schedule_send, size: 16), label: Text('Wysyłka $at')),
                    ],
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// Użytkownicy ----------------------------------------------------------------------------------

class _Users extends ConsumerWidget {
  const _Users();

  @override
  Widget build(BuildContext context, WidgetRef ref) => crmAsync(ref.watch(crmOverviewProvider), (o) {
    final users = (o['recent_users'] as List? ?? const []).cast<Map>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CustomerLookup(),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            KpiTile('Wszyscy', '${o['users_total']}'),
            KpiTile('Nowi w 7 dni', '${o['users_7d']}'),
            KpiTile('Nowi w 30 dni', '${o['users_30d']}'),
            KpiTile('Płacący', '${o['paying_families']}'),
            KpiTile('Sprzedane pakiety', '${o['packs_sold']}'),
          ],
        ),
        const SizedBox(height: 20),
        Text('Ostatnio założone konta', style: Theme.of(context).textTheme.titleMedium),
        DataTable(
          columns: const [
            DataColumn(label: Text('E-mail')),
            DataColumn(label: Text('Założone')),
            DataColumn(label: Text('Płaci')),
          ],
          rows: [
            for (final u in users)
              DataRow(
                cells: [
                  DataCell(Text('${u['email'] ?? 'gość'}')),
                  DataCell(Text('${u['created_at']}'.substring(0, 16).replaceFirst('T', ' '))),
                  DataCell(Icon(u['paying'] == true ? Icons.check_circle : Icons.remove, size: 18)),
                ],
              ),
          ],
        ),
      ],
    );
  });
}

// Aktualizacje ---------------------------------------------------------------------------------

class _Updates extends ConsumerWidget {
  const _Updates();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.read(studioServerProvider);
    void refresh() => ref.read(crmRefreshProvider.notifier).bump();
    Future<void> edit([Map<String, dynamic>? item]) async {
      final saved = await editCrmItem(context, kind: 'change', item: item, areas: const ['update', 'proposal']);
      if (saved == null || !context.mounted) return;
      if (await crmRun(context, () => server.saveCrmItem(saved))) refresh();
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: edit,
        icon: const Icon(Icons.add),
        label: const Text('Wpis'),
      ),
      body: crmAsync(ref.watch(crmItemsProvider('change')), (all) {
        final list = decided(all);
        final proposals = [
          for (final c in list)
            if (c['area'] == 'proposal') c,
        ];
        final updates = [
          for (final c in list)
            if (c['area'] != 'proposal') c,
        ];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Propozycje zmian w aplikacji', style: Theme.of(context).textTheme.titleMedium),
            const Text('Zatwierdzone tu zmiany przekaż Claude do zrobienia (albo dodaj jako zadanie).'),
            const SizedBox(height: 8),
            if (proposals.isEmpty) const Text('Brak. Poproś agenta o „Propozycje zmian”.'),
            for (final c in proposals)
              CrmCard(
                item: c,
                onTap: () => edit(c),
                actions: [
                  Chip(label: Text(statusLabels[c['status']] ?? '${c['status']}')),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await crmRun(
                        context,
                        () => server.saveCrmItem({
                          'kind': 'task',
                          'area': 'feature',
                          'title': '${c['title']}',
                          'body': '${c['body']}',
                          'owner': 'Claude',
                          'status': 'todo',
                          'priority': c['priority'],
                        }),
                        done: 'Dodano zadanie dla Claude.',
                      );
                      if (ok) refresh();
                    },
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Jako zadanie'),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Text('Historia aktualizacji', style: Theme.of(context).textTheme.titleMedium),
            if (updates.isEmpty) const Text('Brak wpisów.'),
            for (final c in updates) CrmCard(item: c, onTap: () => edit(c)),
          ],
        );
      }),
    );
  }
}

// Ustawienia -----------------------------------------------------------------------------------

class _Settings extends ConsumerStatefulWidget {
  const _Settings();

  @override
  ConsumerState<_Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<_Settings> {
  Map<String, TextEditingController>? _costs;
  final _newName = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(studioServerProvider).crmSetting('monthly_costs').then((v) {
      if (mounted) {
        setState(() => _costs = {for (final e in v.entries) e.key: TextEditingController(text: '${e.value}')});
      }
    });
  }

  @override
  void dispose() {
    for (final c in _costs?.values ?? const <TextEditingController>[]) {
      c.dispose();
    }
    _newName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final costs = _costs;
    if (costs == null) return const Center(child: CircularProgressIndicator());
    final total = costs.values.fold(0.0, (s, c) => s + (double.tryParse(c.text.replaceAll(',', '.')) ?? 0));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const RhythmSettings(),
        const Divider(height: 32),
        Text('Koszty miesięczne (zł)', style: Theme.of(context).textTheme.titleMedium),
        const Text('Odejmowane od przychodu w „Zysk w tym miesiącu”.'),
        const SizedBox(height: 8),
        for (final MapEntry(key: name, value: c) in costs.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 220, child: Text(name)),
                SizedBox(
                  width: 120,
                  child: TextField(controller: c, onChanged: (_) => setState(() {})),
                ),
                IconButton(
                  tooltip: 'Usuń',
                  onPressed: () => setState(() => costs.remove(name)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        Row(
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _newName,
                decoration: const InputDecoration(hintText: 'Nowy koszt'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                if (_newName.text.trim().isEmpty) return;
                costs[_newName.text.trim()] = TextEditingController(text: '0');
                _newName.clear();
              }),
              child: const Text('Dodaj'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Razem: ${total.toStringAsFixed(2)} zł miesięcznie'),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () async {
              final ok = await crmRun(
                context,
                () => ref.read(studioServerProvider).saveCrmSetting('monthly_costs', {
                  for (final MapEntry(key: name, value: c) in costs.entries)
                    name: double.tryParse(c.text.replaceAll(',', '.')) ?? 0,
                }),
                done: 'Zapisano koszty.',
              );
              if (ok) ref.read(crmRefreshProvider.notifier).bump();
            },
            child: const Text('Zapisz koszty'),
          ),
        ),
      ],
    );
  }
}
