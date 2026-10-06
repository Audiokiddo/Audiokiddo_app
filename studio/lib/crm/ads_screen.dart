import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../server/studio_server.dart';
import 'crm_widgets.dart';

/// CRM → Kampanie: Meta Ads, Meta Pixel, Google Ads and Google Analytics in one place. The ads
/// agent reviews them every morning and proposes changes; a change reaches a platform only
/// after "Zatwierdzam i wprowadź" (or when made here by hand), always within the limits below.
class CampaignsTab extends ConsumerWidget {
  const CampaignsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => crmAsync(
    ref.watch(adsOverviewProvider),
    (data) => ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Sources(data: data),
        const SizedBox(height: 16),
        _Totals(summary: _map(data['summary'])),
        const SizedBox(height: 16),
        const _AgentBox(),
        const SizedBox(height: 16),
        _Proposals(actions: _list(data['actions'])),
        const SizedBox(height: 16),
        _Campaigns(data: data),
        const SizedBox(height: 16),
        _Sites(summary: _map(data['summary'])),
        const SizedBox(height: 16),
        _Limits(settings: _map(data['settings'])),
        const SizedBox(height: 16),
        _History(actions: _list(data['actions'])),
      ],
    ),
  );
}

final adsOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  ref.watch(crmRefreshProvider);
  return ref.watch(studioServerProvider).adsOverview();
});

/// How many proposals wait (for the tab's badge); 0 while loading or offline.
final adsPendingProvider = Provider.autoDispose<int>(
  (ref) => _list(ref.watch(adsOverviewProvider).value?['actions']).where((a) => a['status'] == 'pending').length,
);

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : {};
List<Map<String, dynamic>> _list(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];
num _num(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;

String zl(Object? v) => v == null ? '–' : '${_num(v).toStringAsFixed(2).replaceAll('.', ',')} zł';

const platformLabels = {
  'meta': 'Meta Ads',
  'meta_pixel': 'Meta Pixel',
  'google_ads': 'Google Ads',
  'ga4': 'Google Analytics',
  'agent': 'Agent reklam',
  'site': 'Strona i kreacje',
};

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              ?trailing,
            ],
          ),
          if (subtitle != null) Text(subtitle!),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

// Połączenia ---------------------------------------------------------------------------------

/// What each source needs in Supabase → Edge Functions → Secrets (names only, never values).
const _secretsHint = {
  'meta': 'META_ACCESS_TOKEN, META_AD_ACCOUNT_ID',
  'meta_pixel': 'META_PIXEL_ID (oraz token Meta)',
  'google_ads':
      'GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_REFRESH_TOKEN, GOOGLE_ADS_DEVELOPER_TOKEN, GOOGLE_ADS_CUSTOMER_ID',
  'ga4': 'GA4_PROPERTY_ID (oraz klucze Google)',
  'agent': 'ANTHROPIC_API_KEY',
};

class _Sources extends ConsumerStatefulWidget {
  const _Sources({required this.data});

  final Map<String, dynamic> data;

  @override
  ConsumerState<_Sources> createState() => _SourcesState();
}

class _SourcesState extends ConsumerState<_Sources> {
  bool _busy = false;

  Future<void> _sync() async {
    setState(() => _busy = true);
    await crmRun(context, () async {
      final report = await ref.read(studioServerProvider).adsSync();
      ref.read(crmRefreshProvider.notifier).bump();
      if (report.isEmpty) throw const StudioServerException('Żadne źródło nie jest jeszcze połączone.');
    }, done: 'Dane pobrane.');
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final configured = _map(widget.data['configured']);
    final statuses = {for (final s in _list(widget.data['sources'])) s['source'] as String: s};
    final scheme = Theme.of(context).colorScheme;
    return _Section(
      'Połączenia',
      subtitle: 'Dane pobierają się same codziennie rano, razem z przeglądem agenta.',
      trailing: FilledButton.tonalIcon(
        onPressed: _busy ? null : _sync,
        icon: _busy
            ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.sync),
        label: const Text('Pobierz dane teraz'),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final source in const ['meta', 'meta_pixel', 'google_ads', 'ga4', 'agent'])
            Builder(
              builder: (context) {
                final on = configured[source] == true;
                final status = statuses[source];
                final ok = on && (status == null || status['ok'] == true);
                final color = !on
                    ? scheme.surfaceContainerHighest
                    : ok
                    ? Colors.green.withValues(alpha: .14)
                    : scheme.errorContainer;
                return Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            !on
                                ? Icons.link_off
                                : ok
                                ? Icons.check_circle
                                : Icons.error_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              platformLabels[source]!,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !on
                            ? 'Niepołączone. Sekrety: ${_secretsHint[source]}'
                            : status == null
                            ? 'Połączone, jeszcze bez danych.'
                            : '${status['message']}'.split('\n').first,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Wyniki -------------------------------------------------------------------------------------

class _Totals extends StatelessWidget {
  const _Totals({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final totals = _map(summary['totals']);
    return _Section(
      'Ostatnie 7 dni',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final platform in const ['meta', 'google_ads']) ...[
            KpiTile('${platformLabels[platform]}: wydatki', zl(_map(totals[platform])['spend'])),
            KpiTile(
              '${platformLabels[platform]}: zakupy',
              '${_map(totals[platform])['conversions'] ?? 0}',
              hint: 'koszt zakupu ${zl(_map(totals[platform])['cpa'])}',
            ),
            KpiTile(
              '${platformLabels[platform]}: ROAS',
              _map(totals[platform])['roas'] == null ? '–' : '${_map(totals[platform])['roas']}×',
              hint: 'przychód ${zl(_map(totals[platform])['revenue'])}',
            ),
          ],
        ],
      ),
    );
  }
}

// Agent --------------------------------------------------------------------------------------

class _AgentBox extends ConsumerStatefulWidget {
  const _AgentBox();

  @override
  ConsumerState<_AgentBox> createState() => _AgentBoxState();
}

class _AgentBoxState extends ConsumerState<_AgentBox> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    setState(() => _busy = true);
    await crmRun(context, () async {
      await ref.read(studioServerProvider).adsPropose(note: _note.text.trim().isEmpty ? null : _note.text.trim());
      ref.read(crmRefreshProvider.notifier).bump();
    }, done: 'Agent skończył przegląd. Propozycje czekają poniżej.');
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(adsOverviewProvider).value ?? {};
    final agent = _list(overview['sources']).where((s) => s['source'] == 'agent').firstOrNull;
    return _Section(
      'Agent reklam',
      subtitle:
          'Codziennie rano przegląda kampanie, Pixel i ruch na stronie. Proponuje zmiany budżetów, '
          'wstrzymanie lub wznowienie kampanii i zadania. Nic nie zmienia bez Twojej zgody.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (agent != null) ...[
            Text(
              'Ostatni przegląd: ${'${agent['updated_at']}'.replaceFirst('T', ' ').substring(0, 16)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4),
            SelectableText('${agent['message']}'),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Wskazówka dla agenta (opcjonalnie), np. „przed świętami stawiamy na pakiety”',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : _ask,
            icon: _busy
                ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.smart_toy_outlined),
            label: const Text('Przejrzyj kampanie teraz'),
          ),
        ],
      ),
    );
  }
}

// Propozycje ---------------------------------------------------------------------------------

String actionLabel(Map<String, dynamic> a) => switch (a['action']) {
  'set_budget' => 'Budżet: ${zl(_map(a['params'])['daily_budget'])} dziennie',
  'pause' => 'Wstrzymać kampanię',
  'enable' => 'Wznowić kampanię',
  _ => 'Zadanie na tablicę',
};

class _Proposals extends ConsumerWidget {
  const _Proposals({required this.actions});

  final List<Map<String, dynamic>> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = [
      for (final a in actions)
        if (a['status'] == 'pending') a,
    ];
    return _Section(
      'Do decyzji: ${pending.length}',
      subtitle: pending.isEmpty ? 'Nic nie czeka. Agent zajrzy jutro rano albo poproś go powyżej.' : null,
      child: Column(children: [for (final a in pending) ProposalCard(action: a)]),
    );
  }
}

/// One proposal: what, why, what we expect; approve (applies it now), change the budget, reject.
class ProposalCard extends ConsumerStatefulWidget {
  const ProposalCard({super.key, required this.action});

  final Map<String, dynamic> action;

  @override
  ConsumerState<ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends ConsumerState<ProposalCard> {
  bool _busy = false;

  Future<void> _decide(bool approve, {double? budget}) async {
    setState(() => _busy = true);
    await crmRun(context, () async {
      final result = await ref
          .read(studioServerProvider)
          .adsDecide(widget.action['id'] as String, approve: approve, dailyBudget: budget);
      ref.read(crmRefreshProvider.notifier).bump();
      if (result['ok'] == false) throw StudioServerException('${result['message']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message']}')));
      }
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _changeBudget() async {
    final budget = await askBudget(context, _num(_map(widget.action['params'])['daily_budget']).toDouble());
    if (budget != null) await _decide(true, budget: budget);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(platformLabels[a['platform']] ?? '${a['platform']}')),
                Chip(label: Text(actionLabel(a))),
                if (a['priority'] == 1) const Chip(label: Text('Pilne')),
              ],
            ),
            const SizedBox(height: 6),
            Text('${a['title']}', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            if ('${a['entity_name']}'.isNotEmpty) Text('Kampania: ${a['entity_name']}', style: text.bodySmall),
            if ('${a['reason']}'.isNotEmpty) ...[const SizedBox(height: 6), Text('${a['reason']}')],
            if ('${a['expected']}'.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Oczekiwany efekt: ${a['expected']}', style: text.bodySmall),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _busy ? null : () => _decide(true),
                  icon: const Icon(Icons.check),
                  label: Text(a['action'] == 'task' ? 'Zatwierdzam' : 'Zatwierdzam i wprowadź'),
                ),
                if (a['action'] == 'set_budget')
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _changeBudget,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Inna kwota'),
                  ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _decide(false),
                  icon: const Icon(Icons.close),
                  label: const Text('Odrzucam'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<double?> askBudget(BuildContext context, double current) async {
  final controller = TextEditingController(text: current > 0 ? current.toStringAsFixed(0) : '');
  final value = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Budżet dzienny (zł)'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(suffixText: 'zł dziennie'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
        FilledButton(
          onPressed: () => Navigator.pop(context, double.tryParse(controller.text.replaceAll(',', '.'))),
          child: const Text('Wprowadź'),
        ),
      ],
    ),
  );
  controller.dispose();
  return value;
}

// Kampanie -----------------------------------------------------------------------------------

class _Campaigns extends ConsumerWidget {
  const _Campaigns({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaigns = _list(_map(data['summary'])['campaigns']);
    Future<void> apply(Map<String, dynamic> c, String action, {double? budget}) => crmRun(context, () async {
      final result = await ref
          .read(studioServerProvider)
          .adsApply(c['platform'] as String, c['id'] as String, action, dailyBudget: budget);
      ref.read(crmRefreshProvider.notifier).bump();
      if (result['ok'] == false) throw StudioServerException('${result['message']}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message']}')));
      }
    });

    return _Section(
      'Kampanie',
      subtitle: 'Zmiany ręczne trafiają od razu na platformę (w granicach maksymalnego budżetu).',
      child: campaigns.isEmpty
          ? const Text('Brak kampanii. Połącz Meta Ads lub Google Ads i pobierz dane.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Kampania')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Budżet / dzień'), numeric: true),
                  DataColumn(label: Text('Wydatki 7 dni'), numeric: true),
                  DataColumn(label: Text('Zakupy 7 dni'), numeric: true),
                  DataColumn(label: Text('Koszt zakupu'), numeric: true),
                  DataColumn(label: Text('Tydzień wcześniej'), numeric: true),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final c in campaigns)
                    DataRow(
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${c['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                '${platformLabels[c['platform']]}${c['kind'] == 'adset' ? ' · zestaw reklam' : ''}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(switch (c['status']) {
                            'active' => 'Aktywna',
                            'paused' => 'Wstrzymana',
                            final s => '$s',
                          }),
                        ),
                        DataCell(Text(zl(c['daily_budget']))),
                        DataCell(Text(zl(_map(c['last_7'])['spend']))),
                        DataCell(Text('${_map(c['last_7'])['conversions'] ?? 0}')),
                        DataCell(Text(zl(_map(c['last_7'])['cpa']))),
                        DataCell(Text(zl(_map(c['prev_7'])['cpa']))),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (c['daily_budget'] != null)
                                IconButton(
                                  tooltip: 'Zmień budżet',
                                  icon: const Icon(Icons.payments_outlined),
                                  onPressed: () async {
                                    final budget = await askBudget(context, _num(c['daily_budget']).toDouble());
                                    if (budget != null && context.mounted) {
                                      await apply(c, 'set_budget', budget: budget);
                                    }
                                  },
                                ),
                              if (c['status'] == 'active')
                                IconButton(
                                  tooltip: 'Wstrzymaj',
                                  icon: const Icon(Icons.pause_circle_outline),
                                  onPressed: () => apply(c, 'pause'),
                                ),
                              if (c['status'] == 'paused')
                                IconButton(
                                  tooltip: 'Wznów',
                                  icon: const Icon(Icons.play_circle_outline),
                                  onPressed: () => apply(c, 'enable'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

// Strona (GA4) -------------------------------------------------------------------------------

class _Sites extends StatelessWidget {
  const _Sites({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final sources = _list(summary['site_sources_7d']);
    return _Section(
      'audiokiddo.pl: skąd przychodzą rodzice (7 dni)',
      subtitle: 'Z Google Analytics. Zakupy i przychód ze sklepu WooCommerce.',
      child: sources.isEmpty
          ? const Text('Brak danych. Połącz Google Analytics.')
          : DataTable(
              columns: const [
                DataColumn(label: Text('Źródło / medium')),
                DataColumn(label: Text('Wizyty'), numeric: true),
                DataColumn(label: Text('Zakupy'), numeric: true),
                DataColumn(label: Text('Przychód'), numeric: true),
              ],
              rows: [
                for (final s in sources)
                  DataRow(
                    cells: [
                      DataCell(Text('${s['source']}')),
                      DataCell(Text('${s['sessions']}')),
                      DataCell(Text('${s['purchases']}')),
                      DataCell(Text(zl(s['revenue']))),
                    ],
                  ),
              ],
            ),
    );
  }
}

// Limity -------------------------------------------------------------------------------------

class _Limits extends ConsumerStatefulWidget {
  const _Limits({required this.settings});

  final Map<String, dynamic> settings;

  @override
  ConsumerState<_Limits> createState() => _LimitsState();
}

class _LimitsState extends ConsumerState<_Limits> {
  late bool _enabled = widget.settings['enabled'] != false;
  late final _maxDaily = TextEditingController(text: '${widget.settings['max_daily'] ?? 150}');
  late final _maxChange = TextEditingController(
    text: '${(_num(widget.settings['max_change'] ?? .5) * 100).round()}',
  );
  late final _targetCpa = TextEditingController(text: '${widget.settings['target_cpa'] ?? ''}');

  @override
  void dispose() {
    _maxDaily.dispose();
    _maxChange.dispose();
    _targetCpa.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.').trim());

  @override
  Widget build(BuildContext context) {
    Widget field(String label, TextEditingController c, String suffix) => SizedBox(
      width: 200,
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder()),
      ),
    );
    return _Section(
      'Limity agenta',
      subtitle: 'Agent nie zaproponuje niczego poza nimi, a system sprawdza je jeszcze raz przed zmianą.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: const Text('Codzienny przegląd z propozycjami'),
            subtitle: const Text('Wyłączony: dane nadal się pobierają, agent działa tylko na Twoją prośbę.'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              field('Maks. budżet kampanii', _maxDaily, 'zł/dzień'),
              field('Maks. zmiana naraz', _maxChange, '%'),
              field('Docelowy koszt zakupu', _targetCpa, 'zł'),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final ok = await crmRun(
                context,
                () => ref.read(studioServerProvider).saveCrmSetting('ads', {
                  'enabled': _enabled,
                  'max_daily': _parse(_maxDaily) ?? 150,
                  'max_change': (_parse(_maxChange) ?? 50) / 100,
                  'target_cpa': _parse(_targetCpa),
                }),
                done: 'Zapisano limity.',
              );
              if (ok) ref.read(crmRefreshProvider.notifier).bump();
            },
            child: const Text('Zapisz limity'),
          ),
        ],
      ),
    );
  }
}

// Historia -----------------------------------------------------------------------------------

class _History extends StatelessWidget {
  const _History({required this.actions});

  final List<Map<String, dynamic>> actions;

  @override
  Widget build(BuildContext context) {
    final done = [
      for (final a in actions)
        if (a['status'] != 'pending') a,
    ].take(40).toList();
    return _Section(
      'Historia zmian',
      child: done.isEmpty
          ? const Text('Jeszcze nic nie zmieniono.')
          : Column(
              children: [
                for (final a in done)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(switch (a['status']) {
                      'applied' => Icons.check_circle_outline,
                      'failed' => Icons.error_outline,
                      'rejected' => Icons.block,
                      _ => Icons.schedule,
                    }),
                    title: Text('${a['title']}'),
                    subtitle: Text(
                      [
                        switch (a['status']) {
                          'applied' => 'wprowadzone',
                          'failed' => 'nie udało się: ${_map(a['result'])['error'] ?? ''}',
                          'rejected' => 'odrzucone',
                          _ => 'wygasło',
                        },
                        if (a['source'] == 'dawid') 'ręcznie' else 'od agenta',
                        '${a['decided_at'] ?? a['created_at']}'.replaceFirst('T', ' ').substring(0, 16),
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
    );
  }
}
