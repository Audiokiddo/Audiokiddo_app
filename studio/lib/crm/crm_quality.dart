import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../server/studio_server.dart';
import 'crm_insights.dart' show scopeLabel;
import 'crm_widgets.dart';

num _n(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;
String _date(Object? v) => v == null ? '–' : '$v'.replaceFirst('T', ' ').substring(0, 16);

// Do uwagi (Pulpit) -------------------------------------------------------------------------------

final alertsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  ref.watch(crmRefreshProvider);
  return ref.watch(studioServerProvider).alerts();
});

/// The watchdog's open alerts, the most urgent first. "Przyjąłem" greys one out until it
/// changes or passes.
class AlertsCard extends ConsumerWidget {
  const AlertsCard({super.key});

  static const _icons = {
    'critical': (Icons.error, Colors.red),
    'warning': (Icons.warning_amber_rounded, Colors.orange),
    'info': (Icons.info_outline, Colors.blue),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) => crmAsync(ref.watch(alertsProvider), (alerts) {
    if (alerts.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        child: const ListTile(
          leading: Icon(Icons.verified_outlined, color: Colors.green),
          title: Text('Do uwagi: nic'),
          subtitle: Text('Strażnik sprawdza co godzinę płatności, błędy, zakupy, aktywność i źródła reklam.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do uwagi (${alerts.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            for (final a in alerts)
              Opacity(
                opacity: a['acknowledged_at'] == null ? 1 : .5,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_icons[a['level']]?.$1 ?? Icons.circle, color: _icons[a['level']]?.$2),
                  title: Text('${a['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${a['detail']}\nod ${_date(a['first_seen'])}'),
                  isThreeLine: true,
                  trailing: a['acknowledged_at'] == null
                      ? TextButton(
                          onPressed: () async {
                            if (await crmRun(context, () => ref.read(studioServerProvider).ackAlert('${a['id']}'))) {
                              ref.invalidate(alertsProvider);
                            }
                          },
                          child: const Text('Przyjąłem'),
                        )
                      : const Text('przyjęte'),
                ),
              ),
          ],
        ),
      ),
    );
  });
}

// Błędy -------------------------------------------------------------------------------------------

class ErrorsTab extends ConsumerStatefulWidget {
  const ErrorsTab({super.key});

  @override
  ConsumerState<ErrorsTab> createState() => _ErrorsTabState();
}

class _ErrorsTabState extends ConsumerState<ErrorsTab> {
  int _days = 7;
  late Future<List<Map<String, dynamic>>> _errors = _load();

  Future<List<Map<String, dynamic>>> _load() => ref.read(studioServerProvider).appErrors(days: _days);

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Błędy z telefonów rodziców, zgrupowane: ten sam błąd w tym samym miejscu kodu to jedna pozycja. '
              'Bez danych osobowych.',
            ),
          ),
          for (final d in const [1, 7, 30])
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChoiceChip(
                label: Text(d == 1 ? '24 h' : '$d dni'),
                selected: _days == d,
                onSelected: (_) => setState(() {
                  _days = d;
                  _errors = _load();
                }),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _errors,
        builder: (context, snap) {
          if (snap.hasError) return Text('${snap.error}');
          if (!snap.hasData) return const LinearProgressIndicator();
          if (snap.data!.isEmpty) return const Text('Brak błędów w tym czasie.');
          return Column(
            children: [
              for (final e in snap.data!)
                Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(child: Text('${e['count']}')),
                    title: Text('${e['error_type']}: ${e['message']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      'telefonów: ${e['installs']} · ostatnio ${_date(e['last_seen'])} · '
                      'wersje ${(e['versions'] as List? ?? const []).join(', ')} · ${(e['platforms'] as List? ?? const []).join(', ')}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: SelectableText(
                          '${e['stack']}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

// Analiza: ranking zabaw, LTV i kohorty, testy A/B -----------------------------------------------

class AnalysisTab extends ConsumerStatefulWidget {
  const AnalysisTab({super.key});

  @override
  ConsumerState<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends ConsumerState<AnalysisTab> {
  int _days = 30;
  String _sort = 'starts';
  late Future<List<Map<String, dynamic>>> _plays = ref.read(studioServerProvider).plays(days: _days);
  late final Future<Map<String, dynamic>> _ltv = ref.read(studioServerProvider).ltv();
  late Future<List<Map<String, dynamic>>> _experiments = ref.read(studioServerProvider).experiments();

  static const _sorts = [
    ('starts', 'Najczęściej włączane'),
    ('completion', 'Najlepiej kończone'),
    ('dropped', 'Najczęściej przerywane'),
    ('replays', 'Najczęściej powtarzane'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final server = ref.read(studioServerProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('LTV: ile wart jest płacący rodzic', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        FutureBuilder<Map<String, dynamic>>(
          future: _ltv,
          builder: (context, snap) {
            if (snap.hasError) return Text('${snap.error}');
            if (!snap.hasData) return const LinearProgressIndicator();
            final l = snap.data!;
            String zl(Object? v) => v == null ? '–' : '${_n(v).toStringAsFixed(0)} zł';
            final ltv = l['ltv_net'];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    KpiTile('Płacące rodziny', '${l['paying'] ?? 0}'),
                    KpiTile('Średnio miesięcznie (netto)', zl(l['arpu_net']), hint: 'brutto ${zl(l['arpu_gross'])}'),
                    KpiTile(
                      'Odchodzi w miesiąc',
                      l['churn_month'] == null ? '–' : '${l['churn_month']}%',
                      hint: l['lifetime_months'] == null ? null : 'zostaje średnio ${l['lifetime_months']} mies.',
                    ),
                    KpiTile('LTV (netto)', zl(ltv), color: Colors.green.shade50),
                    KpiTile(
                      'Maks. koszt pozyskania',
                      ltv == null ? '–' : zl(_n(ltv) / 3),
                      hint: '1/3 LTV, żeby reklama się zwracała',
                      color: Colors.amber.shade50,
                    ),
                    KpiTile(
                      'Pakiet na kupującego',
                      zl(l['pack_value_net']),
                      hint: '${l['pack_buyers'] ?? 0} kupujących',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Źródła abonamentów: ${(l['by_source'] as Map? ?? const {}).entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 12),
                Text('Kohorty: ilu nadal płaci po 1, 2, 3 i 6 miesiącach', style: text.titleSmall),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Pierwsza płatność')),
                      DataColumn(label: Text('Rodzin'), numeric: true),
                      DataColumn(label: Text('po 1 mies.'), numeric: true),
                      DataColumn(label: Text('po 2'), numeric: true),
                      DataColumn(label: Text('po 3'), numeric: true),
                      DataColumn(label: Text('po 6'), numeric: true),
                    ],
                    rows: [
                      for (final c in (l['cohorts'] as List? ?? const []).cast<Map>())
                        DataRow(
                          cells: [
                            DataCell(Text('${c['month']}')),
                            DataCell(Text('${c['families']}')),
                            for (final k in const ['m1', 'm2', 'm3', 'm6'])
                              DataCell(Text(c[k] == null ? '–' : '${c[k]}%')),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const Divider(height: 40),
        Row(
          children: [
            Expanded(
              child: Text('Ranking zabaw', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            for (final d in const [7, 30, 90])
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text('$d dni'),
                  selected: _days == d,
                  onSelected: (_) => setState(() {
                    _days = d;
                    _plays = server.plays(days: d);
                  }),
                ),
              ),
          ],
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final (key, label) in _sorts)
              ChoiceChip(label: Text(label), selected: _sort == key, onSelected: (_) => setState(() => _sort = key)),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _plays,
          builder: (context, snap) {
            if (snap.hasError) return Text('${snap.error}');
            if (!snap.hasData) return const LinearProgressIndicator();
            final rows = [...snap.data!]..sort((a, b) => _key(b).compareTo(_key(a)));
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 22,
                columns: const [
                  DataColumn(label: Text('Zabawa')),
                  DataColumn(label: Text('Włączona'), numeric: true),
                  DataColumn(label: Text('Ukończona'), numeric: true),
                  DataColumn(label: Text('Przerwana'), numeric: true),
                  DataColumn(label: Text('Powtórki'), numeric: true),
                  DataColumn(label: Text('Następna po niej'), numeric: true),
                  DataColumn(label: Text('Rodzin'), numeric: true),
                ],
                rows: [
                  for (final p in rows)
                    DataRow(
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${p['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                '${p['pack_id'] ?? 'bez pakietu'}${p['free'] == true ? ' · za darmo' : ''}',
                                style: text.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text('${p['starts']}')),
                        DataCell(Text(p['completion'] == null ? '–' : '${p['completion']}%')),
                        DataCell(Text('${_n(p['starts']) - _n(p['completes']).clamp(0, _n(p['starts']))}')),
                        DataCell(Text('${p['replays']}')),
                        DataCell(Text('${p['next_plays']}')),
                        DataCell(Text('${p['families']}')),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Mało ukończeń przy wielu włączeniach: za długi wstęp albo za trudna? Dużo powtórek: dobra kandydatka '
          'na darmową zabawę w reklamie.',
          style: text.bodySmall,
        ),
        const Divider(height: 40),
        Text('Testy A/B oferty', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Text(
          'Każdy telefon widzi stale jeden wariant. Wynik jest wiarygodny od ok. 100 wyświetleń oferty na wariant.',
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _experiments,
          builder: (context, snap) {
            if (snap.hasError) return Text('${snap.error}');
            if (!snap.hasData) return const LinearProgressIndicator();
            return Column(
              children: [
                for (final e in snap.data!)
                  _ExperimentCard(
                    experiment: e,
                    onToggle: (v) async {
                      if (await crmRun(context, () => server.setExperiment('${e['key']}', active: v))) {
                        setState(() => _experiments = server.experiments());
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  num _key(Map<String, dynamic> p) => switch (_sort) {
    'completion' => _n(p['completion'] ?? -1),
    'dropped' => _n(p['starts']) - _n(p['completes']),
    'replays' => _n(p['replays']),
    _ => _n(p['starts']),
  };
}

class _ExperimentCard extends ConsumerWidget {
  const _ExperimentCard({required this.experiment, required this.onToggle});

  final Map<String, dynamic> experiment;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = experiment;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${e['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${e['note']}'),
              value: e['active'] == true,
              onChanged: onToggle,
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ref.read(studioServerProvider).experimentResults('${e['key']}'),
              builder: (context, snap) {
                final rows = snap.data ?? const [];
                if (rows.isEmpty) return const Text('Jeszcze bez wyników.');
                final best = rows.reduce((a, b) => _n(a['conversion']) >= _n(b['conversion']) ? a : b);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final r in rows)
                      Text(
                        '${r['variant']}: zobaczyło ${r['saw']}, zaczęło zakup ${r['started']}, kupiło ${r['bought']} '
                        '(${r['conversion'] ?? '–'}%)${r == best && rows.length > 1 ? '  ← prowadzi' : ''}',
                        style: TextStyle(fontWeight: r == best ? FontWeight.w800 : FontWeight.normal),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Opinie --------------------------------------------------------------------------------------

class ReviewsTab extends ConsumerStatefulWidget {
  const ReviewsTab({super.key});

  @override
  ConsumerState<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<ReviewsTab> {
  late Future<List<Map<String, dynamic>>> _reviews = ref.read(studioServerProvider).reviews();
  bool _busy = false;

  void _reload() => setState(() => _reviews = ref.read(studioServerProvider).reviews());

  @override
  Widget build(BuildContext context) {
    final server = ref.read(studioServerProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Opinie z App Store i Google Play. Codziennie rano agent pisze propozycje odpowiedzi; '
                'publikujesz po poprawkach jednym kliknięciem.',
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await crmRun(context, server.reviewsSync, done: 'Opinie pobrane.');
                      if (mounted) setState(() => _busy = false);
                      _reload();
                    },
              icon: const Icon(Icons.sync),
              label: const Text('Pobierz teraz'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _reviews,
          builder: (context, snap) {
            if (snap.hasError) return Text('${snap.error}');
            if (!snap.hasData) return const LinearProgressIndicator();
            if (snap.data!.isEmpty) {
              return const Text('Brak opinii. Pojawią się po premierze i podłączeniu kluczy sklepów.');
            }
            final rows = snap.data!;
            final avg = rows.map((r) => _n(r['rating'])).reduce((a, b) => a + b) / rows.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Średnia: ${avg.toStringAsFixed(1)} ★ z ${rows.length} opinii'),
                const SizedBox(height: 8),
                for (final r in rows) _ReviewCard(review: r, onChanged: _reload),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends ConsumerStatefulWidget {
  const _ReviewCard({required this.review, required this.onChanged});

  final Map<String, dynamic> review;
  final VoidCallback onChanged;

  @override
  ConsumerState<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<_ReviewCard> {
  late final _reply = TextEditingController(text: '${widget.review['draft'] ?? ''}');
  bool _busy = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final server = ref.read(studioServerProvider);
    final store = '${r['store']}';
    final id = '${r['review_id']}';
    final done = r['status'] == 'published' || r['status'] == 'skipped';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('★' * _n(r['rating']).toInt(), style: const TextStyle(color: Colors.amber, fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${store == 'app_store' ? 'App Store' : 'Google Play'} · ${r['author']} · ${_date(r['created_at'])}'
                    '${r['app_version'] == null ? '' : ' · wersja ${r['app_version']}'}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
            if ('${r['title']}'.isNotEmpty) Text('${r['title']}', style: const TextStyle(fontWeight: FontWeight.w800)),
            Text('${r['body']}'),
            const SizedBox(height: 8),
            if (r['status'] == 'published')
              Text('Nasza odpowiedź: ${r['reply']}', style: TextStyle(color: Colors.green.shade800))
            else if (r['status'] == 'skipped')
              const Text('Bez odpowiedzi (pominięta).')
            else ...[
              TextField(
                controller: _reply,
                maxLines: 4,
                maxLength: 350,
                decoration: const InputDecoration(labelText: 'Odpowiedź', border: OutlineInputBorder()),
              ),
              if (r['status'] == 'failed') Text('Nie wyszło: ${r['error']}', style: const TextStyle(color: Colors.red)),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: _busy || _reply.text.trim().isEmpty
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            final ok = await crmRun(context, () async {
                              final res = await server.reviewPublish(store, id, _reply.text);
                              if (res['ok'] == false) throw StudioServerException('${res['message']}');
                            }, done: 'Odpowiedź opublikowana.');
                            if (mounted) setState(() => _busy = false);
                            if (ok) widget.onChanged();
                          },
                    child: const Text('Opublikuj'),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            await crmRun(context, () async => _reply.text = await server.reviewDraft(store, id));
                            if (mounted) setState(() => _busy = false);
                          },
                    child: Text(_reply.text.isEmpty ? 'Agent: napisz odpowiedź' : 'Agent: inna wersja'),
                  ),
                  TextButton(
                    onPressed: _busy || done
                        ? null
                        : () async {
                            if (await crmRun(context, () => server.reviewSkip(store, id))) widget.onChanged();
                          },
                    child: const Text('Pomiń'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Zamówienia (sklep www) ----------------------------------------------------------------------

class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});

  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  late final Future<List<Map<String, dynamic>>> _orders = ref.read(studioServerProvider).orders();
  final _sent = <int>{};

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Zamówienia z audiokiddo.pl z 60 dni. „Czeka” znaczy, że kupujący nie zalogował się jeszcze w aplikacji '
        'tym adresem: wyślij mu przypomnienie z instrukcją.',
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _orders,
        builder: (context, snap) {
          if (snap.hasError) return Text('${snap.error}');
          if (!snap.hasData) return const LinearProgressIndicator();
          final rows = snap.data!;
          if (rows.isEmpty) return const Text('Brak zamówień w tym czasie.');
          final waiting = rows.where((o) => o['claimed'] != true && o['status'] == 'completed').length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Zamówień: ${rows.length}, czeka na odebranie: $waiting'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Zamówienie')),
                    DataColumn(label: Text('Kiedy')),
                    DataColumn(label: Text('E-mail')),
                    DataColumn(label: Text('Co')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('W aplikacji')),
                  ],
                  rows: [
                    for (final o in rows)
                      DataRow(
                        cells: [
                          DataCell(Text('${o['order'] ?? '–'}')),
                          DataCell(Text(_date(o['at']))),
                          DataCell(Text('${o['email']}')),
                          DataCell(
                            Text(
                              ((o['scopes'] as List?) ?? const [])
                                  .map((s) => scopeLabel('$s'))
                                  .join(', ')
                                  .ifEmpty('${o['product']}'),
                            ),
                          ),
                          DataCell(Text('${o['status']}')),
                          DataCell(
                            o['claimed'] == true
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                                : o['status'] != 'completed' || o['order'] == null
                                ? const Text('–')
                                : _sent.contains(_n(o['order']).toInt())
                                ? const Text('wysłano')
                                : TextButton(
                                    onPressed: () async {
                                      final order = _n(o['order']).toInt();
                                      final ok = await crmRun(
                                        context,
                                        () => ref.read(studioServerProvider).orderReminder(order),
                                        done: 'Wysłano przypomnienie do ${o['email']}.',
                                      );
                                      if (ok) setState(() => _sent.add(order));
                                    },
                                    child: const Text('Czeka: przypomnij'),
                                  ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
