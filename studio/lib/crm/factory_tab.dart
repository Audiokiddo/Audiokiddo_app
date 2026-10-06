import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../io/studio_io.dart';
import '../server/studio_server.dart';
import '../state/studio_controller.dart';
import 'crm_widgets.dart';

const stageLabels = {
  'topic': 'Temat',
  'article': 'Artykuł',
  'publish': 'Publikacja',
  'idea': 'Pomysł',
  'script': 'Scenariusze',
  'voice': 'Próbne nagranie',
  'recording': 'Nagranie Neli',
  'listing': 'Opisy i okładka',
  'catalog': 'Do katalogu',
  'done': 'Gotowe',
};

const stageOrder = {
  'blog': ['topic', 'article', 'publish', 'done'],
  'pack': ['idea', 'script', 'voice', 'recording', 'listing', 'catalog', 'done'],
};

final factoryJobsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  ref.watch(crmRefreshProvider);
  return ref.watch(studioServerProvider).factoryJobs();
});

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : {};
List<dynamic> _list(Object? v) => v is List ? v : const [];

/// CRM → Fabryka: blog articles and new packs, made by the agent step by step. Every step
/// waits for you; only "Zatwierdzam" starts the next one.
class FactoryTab extends ConsumerStatefulWidget {
  const FactoryTab({super.key});

  @override
  ConsumerState<FactoryTab> createState() => _FactoryTabState();
}

class _FactoryTabState extends ConsumerState<FactoryTab> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // While the agent works, look again every 10 seconds.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) {
      final jobs = ref.read(factoryJobsProvider).value ?? const [];
      if (jobs.any((j) => j['status'] == 'working')) ref.invalidate(factoryJobsProvider);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _newPack() async {
    final title = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nowy pakiet'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Roboczy tytuł (opcjonalnie)'),
              ),
              TextField(
                controller: note,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pomysł albo wskazówki (opcjonalnie), np. „kosmos dla 4–6 lat, dużo ruchu”',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Agent: zaproponuj pakiet')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await crmRun(
        context,
        () => ref
            .read(studioServerProvider)
            .factoryCreate(
              'pack',
              title: title.text.trim().isEmpty ? null : title.text.trim(),
              note: note.text.trim().isEmpty ? null : note.text.trim(),
            ),
        done: 'Agent pracuje nad pomysłem. Za chwilę pojawi się w „Czeka na Was”.',
      );
      ref.invalidate(factoryJobsProvider);
    }
    title.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.read(studioServerProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Agent przygotowuje artykuły na blog i nowe pakiety krok po kroku. Każdy krok czeka na Waszą decyzję: '
          '„Zatwierdzam” uruchamia następny, „Popraw” każe agentowi zrobić krok jeszcze raz z Waszymi uwagami.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () async {
                await crmRun(context, () => server.factoryProposeTopics(3), done: 'Agent szuka 3 tematów na blog.');
                ref.invalidate(factoryJobsProvider);
              },
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('3 tematy na blog'),
            ),
            FilledButton.tonalIcon(
              onPressed: _newPack,
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Nowy pakiet'),
            ),
            IconButton(
              tooltip: 'Odśwież',
              onPressed: () => ref.invalidate(factoryJobsProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 16),
        crmAsync(ref.watch(factoryJobsProvider), (jobs) {
          final groups = [
            ('Czeka na Was', jobs.where((j) => j['status'] == 'waiting').toList()),
            ('Agent pracuje', jobs.where((j) => j['status'] == 'working').toList()),
            ('Wymaga uwagi', jobs.where((j) => j['status'] == 'failed').toList()),
            ('Gotowe', jobs.where((j) => j['status'] == 'done').take(20).toList()),
          ];
          if (jobs.isEmpty) return const Text('Pusto. Zacznij od „3 tematy na blog” albo „Nowy pakiet”.');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, list) in groups)
                if (list.isNotEmpty) ...[
                  Text('$label (${list.length})', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  for (final j in list) JobCard(job: j),
                  const SizedBox(height: 12),
                ],
            ],
          );
        }),
      ],
    );
  }
}

class JobCard extends ConsumerStatefulWidget {
  const JobCard({super.key, required this.job});

  final Map<String, dynamic> job;

  @override
  ConsumerState<JobCard> createState() => _JobCardState();
}

class _JobCardState extends ConsumerState<JobCard> {
  final _feedback = TextEditingController();
  final _edits = <String, TextEditingController>{};
  bool _busy = false;

  Map<String, dynamic> get job => widget.job;
  Map<String, dynamic> get output => _map(job['output']);

  @override
  void dispose() {
    _feedback.dispose();
    for (final c in _edits.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _edit(String key) =>
      _edits.putIfAbsent(key, () => TextEditingController(text: '${output[key] ?? ''}'));

  Future<void> _act(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    final ok = await crmRun(context, action, done: done);
    if (mounted) setState(() => _busy = false);
    if (ok) ref.invalidate(factoryJobsProvider);
  }

  Map<String, dynamic> _approvedOutput() {
    final out = Map<String, dynamic>.from(output);
    for (final MapEntry(:key, :value) in _edits.entries) {
      out[key] = value.text;
    }
    return out;
  }

  /// Pack listing → Studio's catalog draft: the pack and its plays (recordings and covers are
  /// added in Treści, then Serwer → Katalog publishes it).
  void _toCatalog() {
    final data = _map(job['data']);
    final listing = _map(data['listing']);
    final pack = _map(listing['pack']);
    final items = _list(listing['items']).map(_map).toList();
    final idea = _map(data['idea']);
    ref.read(studioProvider.notifier).update((c) {
      final packs = (c['packs'] as List);
      if (!packs.any((p) => (p as Map)['id'] == pack['id'])) {
        packs.add({
          'id': pack['id'],
          'title': pack['title'],
          'age_min': idea['age_min'] ?? 3,
          'color': 'teal',
          'description': pack['description'] ?? '',
          'store_product_id': 'pl.audiokiddo.pack.${'${pack['id']}'.replaceAll('-', '_')}',
        });
      }
      final existing = {for (final i in (c['items'] as List)) (i as Map)['id']};
      for (final item in items) {
        if (existing.contains(item['id'])) continue;
        (c['items'] as List).add({
          'id': item['id'],
          'kind': 'audio_game',
          'pack_id': pack['id'],
          'title': item['title'],
          'parent_description': item['parent_description'] ?? '',
          'age_min': item['age_min'] ?? 3,
          if (item['age_max'] != null) 'age_max': item['age_max'],
          'duration_sec': item['duration_sec'] ?? 360,
          'situations': item['situations'] ?? const [],
          'skills': item['skills'] ?? const [],
          'requirements': item['requirements'] ?? const [],
          'access': item['access'] == 'free' ? 'free' : 'paid',
          'audio': const [],
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.read(studioServerProvider);
    final kind = '${job['kind']}';
    final stage = '${job['stage']}';
    final status = '${job['status']}';
    final steps = stageOrder[kind] ?? const [];
    final text = Theme.of(context).textTheme;
    final scriptCount = _list(_map(_map(job['data'])['idea'])['plays']).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(kind == 'blog' ? Icons.article_outlined : Icons.inventory_2_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${job['title']}'.isEmpty ? (kind == 'blog' ? 'Nowy artykuł' : 'Nowy pakiet') : '${job['title']}',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                if (status == 'working')
                  const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                for (final s in steps)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: s == stage ? Theme.of(context).colorScheme.primaryContainer : null,
                    label: Text(
                      s == 'script' && stage == 'script'
                          ? 'Scenariusz ${(job['step_index'] as int? ?? 0) + 1}/$scriptCount'
                          : stageLabels[s] ?? s,
                      style: TextStyle(fontWeight: s == stage ? FontWeight.w800 : FontWeight.normal, fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (status == 'failed') Text('Nie wyszło: ${job['error']}', style: const TextStyle(color: Colors.red)),
            if (status == 'working') const Text('Agent pracuje nad tym krokiem…'),
            if (status == 'done' && _map(_map(job['data'])['wp'])['url'] != null)
              TextButton.icon(
                onPressed: () => openInBrowser('${_map(_map(job['data'])['wp'])['url']}'),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Zobacz na stronie'),
              ),
            if (status == 'waiting') ...[
              const SizedBox(height: 8),
              _StageView(stage: stage, output: output, edit: _edit, server: server),
              const SizedBox(height: 10),
              TextField(
                controller: _feedback,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Uwagi dla agenta (do „Popraw”)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (stage == 'catalog')
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              _toCatalog();
                              _act(
                                () => server.factoryApprove('${job['id']}'),
                                'Pakiet jest w Treści jako szkic. Dodaj nagrania i okładki.',
                              );
                            },
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Dodaj do katalogu w Studio'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _act(
                              () => server.factoryApprove(
                                '${job['id']}',
                                output: _edits.isEmpty ? null : _approvedOutput(),
                              ),
                              stage == 'article'
                                  ? 'Zatwierdzone. Publikuję na stronie…'
                                  : stage == 'recording'
                                  ? 'Super! Agent przygotowuje opisy.'
                                  : 'Zatwierdzone. Agent robi następny krok.',
                            ),
                      icon: const Icon(Icons.check),
                      label: Text(stage == 'recording' ? 'Nagrane' : 'Zatwierdzam'),
                    ),
                  if (stage != 'recording' && stage != 'catalog')
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _act(() => server.factoryRevise('${job['id']}', _feedback.text), 'Agent poprawia.'),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Popraw'),
                    ),
                  TextButton(
                    onPressed: _busy ? null : () => _act(() => server.factoryReject('${job['id']}'), 'Odrzucone.'),
                    child: const Text('Odrzuć'),
                  ),
                ],
              ),
            ],
            if (status == 'failed')
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _act(() => server.factoryRevise('${job['id']}', _feedback.text), 'Ponawiam.'),
                child: const Text('Spróbuj jeszcze raz'),
              ),
          ],
        ),
      ),
    );
  }
}

/// What the agent made at a step, readable (and the article editable before approval).
class _StageView extends StatelessWidget {
  const _StageView({required this.stage, required this.output, required this.edit, required this.server});

  final String stage;
  final Map<String, dynamic> output;
  final TextEditingController Function(String key) edit;
  final StudioServer server;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget field(String label, String key, {int lines = 1}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: edit(key),
        maxLines: lines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
    Widget kv(String label, Object? value) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value is List ? value.join(' · ') : '${value ?? '–'}'),
          ],
        ),
      ),
    );
    switch (stage) {
      case 'topic':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            field('Tytuł', 'title'),
            kv('Fraza główna', output['keyword']),
            kv('Frazy poboczne', output['secondary']),
            kv('Czego szuka rodzic', output['intent']),
            kv('Plan', output['outline']),
            kv('Pytania', output['faq']),
            kv('Dlaczego teraz', output['why']),
          ],
        );
      case 'article':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            field('Tytuł (do 60 znaków)', 'title'),
            field('Opis w Google (140–155 znaków)', 'meta_description', lines: 2),
            kv('Kategoria', output['category']),
            kv('Autor', output['author']),
            field('Treść (HTML)', 'content_html', lines: 14),
            Text('Pytania w artykule: ${(output['faq'] as List? ?? const []).length}', style: text.bodySmall),
          ],
        );
      case 'idea':
        final plays = (output['plays'] as List? ?? const []).map(_map).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            kv('Tytuł', output['title']),
            kv('Wiek', '${output['age_min']}–${output['age_max']}'),
            kv('Obietnica', output['promise']),
            kv('Dlaczego', output['why']),
            kv('Premiera', output['month']),
            for (final (i, p) in plays.indexed)
              Text(
                '${i + 1}. ${p['title']} (${p['minutes']} min${p['free'] == true ? ', za darmo' : ''}): ${p['summary']}',
              ),
          ],
        );
      case 'script':
      case 'listing':
        return Container(
          constraints: const BoxConstraints(maxHeight: 420),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              stage == 'script'
                  ? '${output['title']}\n\n${output['text']}\n\nDla Neli: ${output['notes_for_nela'] ?? ''}'
                        '${'${output['print_card'] ?? ''}'.isEmpty ? '' : '\n\nKarta do druku: ${output['print_card']}'}'
                  : const JsonEncoder.withIndent('  ').convert(output),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        );
      case 'voice':
        final files = (output['files'] as List? ?? const []).map(_map).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Próbne nagranie głosem z ElevenLabs (${output['chars']} znaków). Posłuchaj, czy scenariusze brzmią dobrze.',
            ),
            for (final f in files)
              TextButton.icon(
                onPressed: () async => openInBrowser(await server.factoryAudioUrl('${f['path']}')),
                icon: const Icon(Icons.play_circle_outline),
                label: Text('${f['title']}'),
              ),
            if (_n(output['skipped']) > 0) Text('Pominięto ${output['skipped']} (limit znaków na próbę).'),
          ],
        );
      case 'recording':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${output['note']}'),
            for (final line in output['checklist'] as List? ?? const []) Text('☐ $line'),
          ],
        );
      case 'publish':
        return Text('Opublikowano: ${output['url']}');
      default:
        return Text('${output['note'] ?? ''}');
    }
  }

  static num _n(Object? v) => v is num ? v : 0;
}
