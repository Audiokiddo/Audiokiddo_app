import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../server/studio_server.dart';
import 'ads_screen.dart' show zl;
import 'crm_widgets.dart';

/// CRM → Kampanie → Kreacje, Konkurencja, Słowa kluczowe: what makes the ads pay off. Every
/// Monday the server scans competitors' ads (Meta Ad Library) and keyword ideas (Google), and the
/// agent writes creatives; each one waits here for approval before anything reaches a platform.
final adsGrowthProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  ref.watch(crmRefreshProvider);
  return ref.watch(studioServerProvider).adsGrowth();
});

/// Drafts waiting for a decision (for the tab's badge).
final creativesPendingProvider = Provider.autoDispose<int>(
  (ref) => _list(ref.watch(adsGrowthProvider).value?['creatives']).where((c) => c['status'] == 'draft').length,
);

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : {};
List<Map<String, dynamic>> _list(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map) Map<String, dynamic>.from(e),
];
List<String> _strings(Object? v) => [
  if (v is List)
    for (final e in v) '$e',
];
num _num(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;
String _int(Object? v) => v == null ? '–' : _num(v).round().toString();

class _Box extends StatelessWidget {
  const _Box(this.title, {required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          if (subtitle != null) Text(subtitle!),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}

Future<void> _report(BuildContext context, WidgetRef ref, Future<Map<String, dynamic>> Function() action) async {
  final ok = await crmRun(context, () async {
    final result = await action();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result['message'] ?? 'Gotowe.'}')));
    }
  });
  if (ok) ref.read(crmRefreshProvider.notifier).bump();
}

// Kreacje ----------------------------------------------------------------------------------

class CreativesView extends ConsumerWidget {
  const CreativesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => crmAsync(ref.watch(adsGrowthProvider), (data) {
    final creatives = _list(data['creatives']);
    final groups = _list(data['groups']);
    final drafts = creatives.where((c) => c['status'] == 'draft').toList();
    final approvedGoogle = creatives.where((c) => c['status'] == 'approved' && c['platform'] == 'google_ads').toList();
    final done = creatives.where((c) => c['status'] != 'draft' && !approvedGoogle.contains(c)).take(20).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Research(research: _list(data['research']), moments: _list(data['moments'])),
        const SizedBox(height: 16),
        _Box(
          'Kreacje do zatwierdzenia (${drafts.length})',
          subtitle:
              'Google: po zatwierdzeniu reklama powstaje w wybranej grupie jako wstrzymana. '
              'Meta: tekst i brief trafiają do zadania (grafikę albo wideo robicie Wy).',
          child: drafts.isEmpty
              ? const Text('Nic nie czeka. Nowe kreacje agent pisze w poniedziałki albo po „Zrób badanie teraz”.')
              : Column(
                  children: [for (final c in drafts) CreativeCard(creative: c, groups: groups)],
                ),
        ),
        if (approvedGoogle.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Box(
            'Zatwierdzone, czekają na grupę reklam',
            child: Column(
              children: [for (final c in approvedGoogle) _PlaceInGroup(creative: c, groups: groups)],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _Verdicts(verdicts: _list(data['verdicts'])),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Box(
            'Ostatnie decyzje',
            child: Column(
              children: [
                for (final c in done)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_statusIcon('${c['status']}')),
                    title: Text('${c['angle']}'.isEmpty ? 'Kreacja' : '${c['angle']}'),
                    subtitle: Text(
                      '${c['platform'] == 'google_ads' ? 'Google' : 'Meta'} · ${_statusLabel('${c['status']}')}'
                      '${c['feedback'] != null ? ' · uwaga: ${c['feedback']}' : ''}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  });
}

IconData _statusIcon(String s) => switch (s) {
  'live' => Icons.rocket_launch_outlined,
  'approved' => Icons.check_circle_outline,
  'rejected' => Icons.block,
  _ => Icons.archive_outlined,
};

String _statusLabel(String s) => switch (s) {
  'live' => 'utworzona na platformie (wstrzymana do włączenia)',
  'approved' => 'zatwierdzona',
  'rejected' => 'odrzucona',
  'retired' => 'wycofana',
  _ => s,
};

class _Research extends ConsumerStatefulWidget {
  const _Research({required this.research, required this.moments});

  final List<Map<String, dynamic>> research;
  final List<Map<String, dynamic>> moments;

  @override
  ConsumerState<_Research> createState() => _ResearchState();
}

class _ResearchState extends ConsumerState<_Research> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    final ok = await crmRun(
      context,
      () => ref.read(studioServerProvider).adsResearch(note: _note.text.trim().isEmpty ? null : _note.text.trim()),
      done: 'Badanie gotowe: nowe kreacje czekają niżej.',
    );
    if (mounted) setState(() => _busy = false);
    if (ok) ref.read(crmRefreshProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.research.isEmpty ? null : widget.research.first;
    return _Box(
      'Badanie tygodniowe',
      subtitle:
          'Co poniedziałek: reklamy konkurencji z Biblioteki reklam Meta, słowa kluczowe z Google, '
          'wyniki Waszych kreacji i okazje z kalendarza. Agent pisze z tego nowe kreacje.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.moments.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in widget.moments)
                  Chip(
                    avatar: const Icon(Icons.event, size: 16),
                    label: Text(
                      _num(m['days_to_start']) == 0
                          ? '${m['name']}: trwa'
                          : '${m['name']}: za ${_int(m['days_to_start'])} dni',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (last != null) ...[
            Text(
              'Ostatnie badanie: ${'${last['created_at']}'.substring(0, 10)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            SelectableText('${last['summary']}'),
            const SizedBox(height: 12),
          ] else
            const Text('Pierwsze badanie jeszcze się nie odbyło.'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'Wskazówka (opcjonalnie), np. „skup się na Mikołajkach”',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _run,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.travel_explore),
                label: Text(_busy ? 'Trwa (do 2 min)…' : 'Zrób badanie teraz'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One creative to approve: editable copy, the limits checked as you type.
class CreativeCard extends ConsumerStatefulWidget {
  const CreativeCard({super.key, required this.creative, required this.groups});

  final Map<String, dynamic> creative;
  final List<Map<String, dynamic>> groups;

  @override
  ConsumerState<CreativeCard> createState() => _CreativeCardState();
}

class _CreativeCardState extends ConsumerState<CreativeCard> {
  late final Map<String, dynamic> _content = _map(widget.creative['content']);
  late final bool _google = widget.creative['platform'] == 'google_ads';
  late final _headlines = TextEditingController(text: _strings(_content['headlines']).join('\n'));
  late final _descriptions = TextEditingController(text: _strings(_content['descriptions']).join('\n'));
  late final _fields = {
    for (final k in [
      'primary_text',
      'headline',
      'description',
      'cta',
      'visual_brief',
      'hook_script',
      'path1',
      'path2',
      'final_url',
    ])
      k: TextEditingController(text: '${_content[k] ?? ''}'),
  };
  String? _group;

  @override
  void dispose() {
    _headlines.dispose();
    _descriptions.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lines(TextEditingController c) =>
      c.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  Map<String, Object?> _edited() => _google
      ? {
          'headlines': _lines(_headlines),
          'descriptions': _lines(_descriptions),
          'path1': _fields['path1']!.text,
          'path2': _fields['path2']!.text,
          'final_url': _fields['final_url']!.text,
        }
      : {for (final e in _fields.entries) e.key: e.value.text, 'format': widget.creative['format']};

  Future<void> _approve() => _report(
    context,
    ref,
    () => ref
        .read(studioServerProvider)
        .adsCreative('${widget.creative['id']}', approve: true, content: _edited(), groupId: _google ? _group : null),
  );

  Future<void> _reject() async {
    final feedback = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odrzucić kreację?'),
        content: TextField(
          controller: feedback,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Dlaczego? (agent weźmie to pod uwagę)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Anuluj')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Odrzuć')),
        ],
      ),
    );
    final text = feedback.text.trim();
    feedback.dispose();
    if (go != true || !mounted) return;
    await _report(
      context,
      ref,
      () => ref
          .read(studioServerProvider)
          .adsCreative('${widget.creative['id']}', approve: false, feedback: text.isEmpty ? null : text),
    );
  }

  Widget _counted(String label, TextEditingController c, int max, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ValueListenableBuilder(
      valueListenable: c,
      builder: (context, value, _) {
        final over = lines == 1
            ? (value.text.length > max ? 1 : 0)
            : value.text.split('\n').where((l) => l.trim().length > max).length;
        return TextField(
          controller: c,
          minLines: lines == 1 ? 1 : 3,
          maxLines: lines == 1 ? 3 : 16,
          decoration: InputDecoration(
            labelText: label,
            helperText: lines == 1 ? '${value.text.length}/$max znaków' : 'Każdy w osobnej linii, do $max znaków',
            errorText: over > 0 ? (lines == 1 ? 'Za długie' : '$over za długie: Google je pominie') : null,
            border: const OutlineInputBorder(),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.creative;
    final problems = _strings(c['problems']);
    final googleGroups = widget.groups;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(
                    _google
                        ? 'Google: reklama tekstowa'
                        : c['format'] == 'meta_video'
                        ? 'Meta: wideo'
                        : 'Meta: grafika',
                  ),
                ),
                if (c['moment'] != null) Chip(avatar: const Icon(Icons.event, size: 16), label: Text('${c['moment']}')),
                Text('${c['angle']}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            if ('${c['why']}'.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6, bottom: 10), child: Text('Dlaczego: ${c['why']}')),
            for (final p in problems)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('⚠ $p', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_google) ...[
              _counted('Nagłówki (3–15)', _headlines, 30, lines: 15),
              _counted('Opisy (2–4)', _descriptions, 90, lines: 4),
              Wrap(
                spacing: 12,
                children: [
                  SizedBox(width: 180, child: _counted('Ścieżka 1', _fields['path1']!, 15)),
                  SizedBox(width: 180, child: _counted('Ścieżka 2', _fields['path2']!, 15)),
                  SizedBox(width: 320, child: _counted('Adres strony', _fields['final_url']!, 300)),
                ],
              ),
              DropdownButtonFormField<String>(
                initialValue: _group,
                decoration: const InputDecoration(labelText: 'Grupa reklam w Google Ads', border: OutlineInputBorder()),
                items: [
                  for (final g in googleGroups)
                    DropdownMenuItem(value: '${g['group_id']}', child: Text('${g['campaign_name']} › ${g['name']}')),
                ],
                onChanged: (v) => setState(() => _group = v),
              ),
              if (googleGroups.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Brak grup reklam w kampaniach w sieci wyszukiwania: zatwierdź teraz, dodasz ją później.',
                  ),
                ),
            ] else ...[
              _counted('Tekst główny', _fields['primary_text']!, 600),
              _counted('Nagłówek', _fields['headline']!, 40),
              _counted('Opis', _fields['description']!, 60),
              _counted('Przycisk', _fields['cta']!, 30),
              _counted('Grafika / kadr (brief)', _fields['visual_brief']!, 3000),
              if (c['format'] == 'meta_video') _counted('Scenariusz wideo', _fields['hook_script']!, 3000),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _approve,
                  icon: const Icon(Icons.check),
                  label: Text(
                    !_google
                        ? 'Zatwierdzam (zadanie z briefem)'
                        : _group == null
                        ? 'Zatwierdzam bez tworzenia'
                        : 'Zatwierdzam i utwórz w Google Ads (wstrzymana)',
                  ),
                ),
                OutlinedButton.icon(onPressed: _reject, icon: const Icon(Icons.close), label: const Text('Odrzucam')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceInGroup extends ConsumerStatefulWidget {
  const _PlaceInGroup({required this.creative, required this.groups});

  final Map<String, dynamic> creative;
  final List<Map<String, dynamic>> groups;

  @override
  ConsumerState<_PlaceInGroup> createState() => _PlaceInGroupState();
}

class _PlaceInGroupState extends ConsumerState<_PlaceInGroup> {
  String? _group;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text('${widget.creative['angle']}'),
    subtitle: DropdownButton<String>(
      value: _group,
      hint: const Text('Wybierz grupę reklam'),
      isExpanded: true,
      items: [
        for (final g in widget.groups)
          DropdownMenuItem(value: '${g['group_id']}', child: Text('${g['campaign_name']} › ${g['name']}')),
      ],
      onChanged: (v) => setState(() => _group = v),
    ),
    trailing: FilledButton(
      onPressed: _group == null
          ? null
          : () => _report(
              context,
              ref,
              () => ref.read(studioServerProvider).adsCreativeLive('${widget.creative['id']}', _group!),
            ),
      child: const Text('Utwórz'),
    ),
  );
}

class _Verdicts extends StatelessWidget {
  const _Verdicts({required this.verdicts});

  final List<Map<String, dynamic>> verdicts;

  static const _labels = {
    'zwyciezca': ('Zwycięzca', Colors.green),
    'przegrywa': ('Przegrywa', Colors.red),
    'jedyna': ('Bez porównania', Colors.orange),
    'w_normie': ('W normie', Colors.blueGrey),
    'za_malo_danych': ('Za mało danych', Colors.grey),
  };

  @override
  Widget build(BuildContext context) {
    final rows = [...verdicts]..sort((a, b) => _num(b['impressions']).compareTo(_num(a['impressions'])));
    return _Box(
      'Wyniki kreacji (14 dni)',
      subtitle:
          'Werdykt porównuje reklamy w tej samej grupie. „Zwycięzca”: co najmniej 95% szans na najlepszy CTR. '
          'Poniżej 1000 wyświetleń nie oceniamy.',
      child: rows.isEmpty
          ? const Text('Brak danych o reklamach. Pojawią się po pierwszym pobraniu z Meta lub Google Ads.')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                columns: const [
                  DataColumn(label: Text('Reklama')),
                  DataColumn(label: Text('Platforma')),
                  DataColumn(label: Text('Wyświetlenia'), numeric: true),
                  DataColumn(label: Text('CTR'), numeric: true),
                  DataColumn(label: Text('Wydatki'), numeric: true),
                  DataColumn(label: Text('Zakupy'), numeric: true),
                  DataColumn(label: Text('Koszt zakupu'), numeric: true),
                  DataColumn(label: Text('Werdykt')),
                ],
                rows: [
                  for (final v in rows.take(60))
                    DataRow(
                      cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text('${v['name']}', overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        DataCell(Text(v['platform'] == 'meta' ? 'Meta' : 'Google')),
                        DataCell(Text(_int(v['impressions']))),
                        DataCell(Text(v['ctr'] == null ? '–' : '${v['ctr']}%')),
                        DataCell(Text(zl(v['spend']))),
                        DataCell(Text('${v['conversions']}')),
                        DataCell(Text(zl(v['cpa']))),
                        DataCell(
                          Tooltip(
                            message: '${v['note']}',
                            child: Chip(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: (_labels[v['verdict']]?.$2 ?? Colors.grey).withValues(alpha: .15),
                              label: Text(_labels[v['verdict']]?.$1 ?? '${v['verdict']}'),
                            ),
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

// Konkurencja ------------------------------------------------------------------------------

class CompetitorsView extends ConsumerWidget {
  const CompetitorsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => crmAsync(ref.watch(adsGrowthProvider), (data) {
    final digest = _list(data['competitors']);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ResearchSettings(settings: _map(data['settings'])),
        const SizedBox(height: 16),
        _Box(
          'Reklamy konkurencji w Polsce (${_int(data['competitor_ads'])} z ostatnich 45 dni)',
          subtitle:
              'Z Biblioteki reklam Meta. Najdłużej emitowane zwykle się opłacają: patrz na ich kąty i oferty, '
              'nie kopiuj tekstów.',
          child: digest.isEmpty
              ? const Text('Brak danych. Ustaw token Biblioteki reklam (docs/REKLAMY.md) i zrób badanie.')
              : Column(
                  children: [
                    for (final page in digest)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text('${page['page']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('Aktywne reklamy: ${_int(page['active_ads'])} · id strony ${page['page_id']}'),
                        children: [
                          for (final ad in _list(page['longest']))
                            ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                child: Text(_int(ad['days']), style: const TextStyle(fontSize: 12)),
                              ),
                              title: Text('${ad['title']}'.isEmpty ? '(bez nagłówka)' : '${ad['title']}'),
                              subtitle: SelectableText(
                                '${ad['text']}\n${_int(ad['days'])} dni emisji'
                                '${ad['reach'] != null ? ' · zasięg w UE ${_int(ad['reach'])}' : ''}',
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  });
}

class _ResearchSettings extends ConsumerStatefulWidget {
  const _ResearchSettings({required this.settings});

  final Map<String, dynamic> settings;

  @override
  ConsumerState<_ResearchSettings> createState() => _ResearchSettingsState();
}

class _ResearchSettingsState extends ConsumerState<_ResearchSettings> {
  late bool _enabled = widget.settings['enabled'] != false;
  late final _fields = {
    for (final k in ['search_terms', 'competitor_pages', 'competitor_sites', 'keyword_seeds'])
      k: TextEditingController(text: _strings(widget.settings[k]).join('\n')),
  };

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lines(String key) =>
      _fields[key]!.text.split(RegExp(r'[\n,]')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    Widget field(String key, String label, String help) => SizedBox(
      width: 340,
      child: TextField(
        controller: _fields[key],
        minLines: 3,
        maxLines: 8,
        decoration: InputDecoration(
          labelText: label,
          helperText: help,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
      ),
    );
    return _Box(
      'Co obserwujemy',
      subtitle: 'Każda pozycja w osobnej linii. Zmiany działają od następnego badania.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            title: const Text('Agent pisze kreacje w poniedziałki'),
            subtitle: const Text('Wyłączony: konkurencja i słowa kluczowe nadal się pobierają.'),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              field('search_terms', 'Frazy w Bibliotece reklam', 'Np. bajki dla dzieci, audiobooki dla dzieci.'),
              field(
                'competitor_pages',
                'Strony konkurencji na Facebooku (id)',
                'Numer strony z adresu w Bibliotece reklam.',
              ),
              field('competitor_sites', 'Witryny konkurencji', 'https://… Google podpowie frazy, na które celują.'),
              field('keyword_seeds', 'Nasze frazy wyjściowe', 'Z nich Google proponuje podobne.'),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final ok = await crmRun(
                context,
                () => ref.read(studioServerProvider).saveCrmSetting('ads_research', {
                  'enabled': _enabled,
                  for (final k in _fields.keys) k: _lines(k),
                }),
                done: 'Zapisano.',
              );
              if (ok) ref.read(crmRefreshProvider.notifier).bump();
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}

// Słowa kluczowe ---------------------------------------------------------------------------

class KeywordsView extends ConsumerStatefulWidget {
  const KeywordsView({super.key});

  @override
  ConsumerState<KeywordsView> createState() => _KeywordsViewState();
}

class _KeywordsViewState extends ConsumerState<KeywordsView> {
  final _filter = TextEditingController();
  final _new = TextEditingController();
  String _use = 'both';

  @override
  void dispose() {
    _filter.dispose();
    _new.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => crmAsync(ref.watch(adsGrowthProvider), (data) {
    final wasted = _list(data['wasted']);
    final terms = _list(data['terms']);
    final q = _filter.text.trim().toLowerCase();
    final keywords = _list(data['keywords']).where((k) => q.isEmpty || '${k['keyword']}'.contains(q)).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Box(
          'Frazy, które kosztują i nie sprzedają (${wasted.length})',
          subtitle: '30 dni, Google Ads. „Wyklucz” dodaje wykluczenie (dopasowanie do wyrażenia) w tej kampanii.',
          child: wasted.isEmpty
              ? const Text('Brak takich fraz albo Google Ads nie jest jeszcze połączone.')
              : Column(
                  children: [
                    for (final t in wasted)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${t['term']}'),
                        subtitle: Text(
                          '${t['campaign_name']} · ${_int(t['clicks'])} kliknięć · ${zl(t['cost'])} · 0 zakupów',
                        ),
                        trailing: OutlinedButton(
                          onPressed: () => _report(
                            context,
                            ref,
                            () => ref.read(studioServerProvider).adsExclude('${t['campaign_id']}', '${t['term']}'),
                          ),
                          child: const Text('Wyklucz'),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Box(
          'Słowa kluczowe (${keywords.length})',
          subtitle:
              'Popyt i konkurencja z Google (odświeżane w poniedziałki). Z tej listy korzysta agent bloga i reklam.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _filter,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Szukaj',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _new,
                      decoration: const InputDecoration(labelText: 'Nowa fraza', border: OutlineInputBorder()),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _use,
                    items: const [
                      DropdownMenuItem(value: 'both', child: Text('blog i reklamy')),
                      DropdownMenuItem(value: 'blog', child: Text('blog')),
                      DropdownMenuItem(value: 'ads', child: Text('reklamy')),
                    ],
                    onChanged: (v) => setState(() => _use = v ?? 'both'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (_new.text.trim().length < 2) return;
                      final ok = await crmRun(
                        context,
                        () => ref.read(studioServerProvider).addKeyword(_new.text, _use),
                        done: 'Dodano.',
                      );
                      if (ok) {
                        _new.clear();
                        ref.read(crmRefreshProvider.notifier).bump();
                      }
                    },
                    child: const Text('Dodaj'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 18,
                  columns: const [
                    DataColumn(label: Text('Fraza')),
                    DataColumn(label: Text('Wyszukiwań / mies.'), numeric: true),
                    DataColumn(label: Text('Konkurencja')),
                    DataColumn(label: Text('CPC')),
                    DataColumn(label: Text('Szczyt')),
                    DataColumn(label: Text('Do czego')),
                    DataColumn(label: Text('Skąd')),
                    DataColumn(label: Text('Wpis')),
                  ],
                  rows: [
                    for (final k in keywords.take(200))
                      DataRow(
                        cells: [
                          DataCell(Text('${k['keyword']}')),
                          DataCell(Text(_int(k['monthly_searches']))),
                          DataCell(
                            Text(switch ('${k['competition']}') {
                              'LOW' => 'niska',
                              'MEDIUM' => 'średnia',
                              'HIGH' => 'wysoka',
                              _ => '–',
                            }),
                          ),
                          DataCell(Text(k['cpc_low'] == null ? '–' : '${zl(k['cpc_low'])}–${zl(k['cpc_high'])}')),
                          DataCell(Text(_peak(k['trend']))),
                          DataCell(
                            Text(switch ('${k['use_for']}') {
                              'blog' => 'blog',
                              'ads' => 'reklamy',
                              _ => 'oba',
                            }),
                          ),
                          DataCell(
                            Tooltip(
                              message: '${k['seed'] ?? k['note'] ?? ''}',
                              child: Text(switch ('${k['source']}') {
                                'google_ads' => 'Google',
                                'agent' => 'agent',
                                _ => 'ręcznie',
                              }),
                            ),
                          ),
                          DataCell(Icon(k['used_by'] != null ? Icons.check : Icons.remove, size: 18)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Box(
          'Co wpisują ludzie przed kliknięciem (Google Ads, 30 dni)',
          child: terms.isEmpty
              ? const Text('Brak danych.')
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 18,
                    columns: const [
                      DataColumn(label: Text('Fraza')),
                      DataColumn(label: Text('Kampania')),
                      DataColumn(label: Text('Kliknięcia'), numeric: true),
                      DataColumn(label: Text('Koszt'), numeric: true),
                      DataColumn(label: Text('Zakupy'), numeric: true),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      for (final t in terms.take(80))
                        DataRow(
                          cells: [
                            DataCell(Text('${t['term']}')),
                            DataCell(Text('${t['campaign_name']}')),
                            DataCell(Text(_int(t['clicks']))),
                            DataCell(Text(zl(t['cost']))),
                            DataCell(Text('${t['conversions']}')),
                            DataCell(
                              Text(switch ('${t['google_status']}') {
                                'added' => 'dodana',
                                'excluded' => 'wykluczona',
                                _ => '–',
                              }),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  });
}

/// The month with the most searches, e.g. "lip" for July.
String _peak(Object? trend) {
  final rows = _list(trend);
  if (rows.isEmpty) return '–';
  rows.sort((a, b) => _num(b['searches']).compareTo(_num(a['searches'])));
  const months = ['sty', 'lut', 'mar', 'kwi', 'maj', 'cze', 'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'];
  final m = int.tryParse('${rows.first['month']}'.split('-').last) ?? 0;
  return m >= 1 && m <= 12 ? months[m - 1] : '–';
}
