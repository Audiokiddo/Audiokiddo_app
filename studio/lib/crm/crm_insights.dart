import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../server/studio_server.dart';
import 'crm_widgets.dart';

// Trend 12 tygodni ------------------------------------------------------------------------------

final crmTrendProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  ref.watch(crmRefreshProvider);
  return ref.watch(studioServerProvider).crmTrend();
});

num _n(Object? v) => v is num ? v : num.tryParse('$v') ?? 0;

/// Pulpit: twelve weeks side by side, one measure at a time, with the change against last week.
class TrendCard extends ConsumerStatefulWidget {
  const TrendCard({super.key});

  @override
  ConsumerState<TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends ConsumerState<TrendCard> {
  String _measure = 'active';

  static const measures = [
    ('active', 'Aktywne rodziny'),
    ('accounts', 'Nowe konta'),
    ('plays', 'Zabawy'),
    ('paywall_views', 'Oferta wyświetlona'),
    ('purchases', 'Zakupy w aplikacji'),
    ('revenue', 'Przychód (szac.)'),
  ];

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: crmAsync(ref.watch(crmTrendProvider), (weeks) {
        final values = [for (final w in weeks) _n(w[_measure]).toDouble()];
        final last = values.isEmpty ? 0.0 : values.last;
        final before = values.length < 2 ? 0.0 : values[values.length - 2];
        final change = before == 0 ? null : ((last - before) / before * 100).round();
        String fmt(double v) => _measure == 'revenue' ? '${v.toStringAsFixed(0)} zł' : v.toStringAsFixed(0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Trend: 12 tygodni',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  'ten tydzień: ${fmt(last)}${change == null ? '' : ' (${change >= 0 ? '+' : ''}$change%)'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: change == null
                        ? null
                        : change >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (key, label) in measures)
                  ChoiceChip(
                    label: Text(label),
                    selected: _measure == key,
                    onSelected: (_) => setState(() => _measure = key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, w) in weeks.indexed)
                    Expanded(
                      child: Tooltip(
                        message: 'Tydzień od ${w['week']}: ${fmt(values[i])}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(fmt(values[i]), style: const TextStyle(fontSize: 10)),
                              const SizedBox(height: 2),
                              Container(
                                height: _barHeight(values, i, 100),
                                decoration: BoxDecoration(
                                  color: i == weeks.length - 1
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.primary.withValues(alpha: .45),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('${w['week']}'.substring(5), style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Zakupy i przychód liczone z aplikacji (sklep internetowy jest w „Przychód 30 dni”). '
              'Aktywne rodziny: urządzenia i konta, które otworzyły aplikację albo zabawę.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }),
    ),
  );

  static double _barHeight(List<double> values, int i, double max) {
    final top = values.fold(0.0, (a, b) => a > b ? a : b);
    if (top <= 0) return 2;
    return (values[i] / top * max).clamp(2, max);
  }
}

// Klienci -----------------------------------------------------------------------------------------

String _date(Object? v) => v == null ? '–' : '$v'.replaceFirst('T', ' ').substring(0, 16);

const _sourceLabels = {
  'app_store': 'App Store',
  'google_play': 'Google Play',
  'woocommerce': 'Sklep www',
  'manual': 'Ręcznie',
};

const _statusLabels = {
  'active': 'aktywny',
  'grace': 'okres karencji',
  'billing_retry': 'problem z płatnością',
  'expired': 'wygasł',
  'revoked': 'cofnięty',
  'refunded': 'zwrot',
};

String scopeLabel(String scope) => switch (scope) {
  'all_content' => 'Abonament: wszystko',
  final s when s.startsWith('children:') =>
    'Plan: ${s.substring(9)} ${s.endsWith(':1') ? 'dziecko' : 'dzieci'}',
  final s when s.startsWith('pack:') => 'Pakiet ${s.substring(5)}',
  final s when s.startsWith('item:') => 'Zabawa ${s.substring(5)}',
  final s => s,
};

/// Użytkownicy: find a parent by e-mail and help them (what they bought, whether they play,
/// access by hand for a gift or a complaint).
class CustomerLookup extends ConsumerStatefulWidget {
  const CustomerLookup({super.key});

  @override
  ConsumerState<CustomerLookup> createState() => _CustomerLookupState();
}

class _CustomerLookupState extends ConsumerState<CustomerLookup> {
  final _email = TextEditingController();
  Map<String, dynamic>? _customer;
  bool _searched = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!_email.text.contains('@')) return;
    setState(() => _busy = true);
    await crmRun(context, () async {
      final c = await ref.read(studioServerProvider).crmCustomer(_email.text);
      if (mounted) {
        setState(() {
          _customer = c;
          _searched = true;
        });
      }
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _grant() async {
    final c = _customer!;
    final result = await showDialog<(String, int, String)>(
      context: context,
      builder: (_) => const _GrantDialog(),
    );
    if (result == null || !mounted) return;
    final (scope, days, note) = result;
    final ok = await crmRun(
      context,
      () => ref.read(studioServerProvider).crmGrant(c['id'] as String, scope, days, note: note),
      done: 'Dostęp przyznany. Rodzic zobaczy go po odświeżeniu konta w aplikacji.',
    );
    if (ok) await _search();
  }

  @override
  Widget build(BuildContext context) {
    final c = _customer;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Obsługa klienta', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const Text('Wpisz e-mail rodzica: zobaczysz jego zakupy i to, czy korzysta z aplikacji.'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _email,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      labelText: 'E-mail rodzica',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(onPressed: _busy ? null : _search, child: const Text('Szukaj')),
              ],
            ),
            if (_searched && c == null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Nie ma takiego konta. Jeśli kupił w sklepie www, dostęp czeka na jego pierwsze logowanie tym adresem.',
                ),
              ),
            if (c != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  KpiTile('Konto od', _date(c['created_at']).substring(0, 10)),
                  KpiTile('Ostatnie logowanie', _date(c['last_sign_in_at'])),
                  KpiTile(
                    'Zabawy w 30 dni',
                    '${(c['activity'] as Map?)?['plays'] ?? 0}',
                    hint: 'ukończone ${(c['activity'] as Map?)?['completed'] ?? 0}',
                  ),
                  KpiTile(
                    'Ostatnio w aplikacji',
                    _date((c['activity'] as Map?)?['last_seen']),
                    hint: [
                      ?(c['activity'] as Map?)?['platform'],
                      if ((c['activity'] as Map?)?['app_version'] != null)
                        'wersja ${(c['activity'] as Map)['app_version']}',
                    ].join(' · '),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Zakupy i dostęp', style: text.titleSmall),
              if ((c['entitlements'] as List).isEmpty)
                const Text('Brak zakupów: korzysta z darmowych zabaw.'),
              for (final e in (c['entitlements'] as List).cast<Map>())
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    e['status'] == 'active' || e['status'] == 'grace'
                        ? Icons.check_circle
                        : Icons.cancel_outlined,
                    color: e['status'] == 'billing_retry' ? Colors.orange : null,
                  ),
                  title: Text(scopeLabel('${e['scope']}')),
                  subtitle: Text(
                    [
                      _sourceLabels[e['source']] ?? '${e['source']}',
                      _statusLabels[e['status']] ?? '${e['status']}',
                      if (e['valid_until'] != null) 'do ${_date(e['valid_until']).substring(0, 10)}',
                    ].join(' · '),
                  ),
                  trailing: e['source'] == 'manual' && e['status'] == 'active'
                      ? TextButton(
                          onPressed: () async {
                            final ok = await crmRun(
                              context,
                              () => ref
                                  .read(studioServerProvider)
                                  .crmRevoke(c['id'] as String, '${e['scope']}'),
                              done: 'Cofnięto dostęp ręczny.',
                            );
                            if (ok) await _search();
                          },
                          child: const Text('Cofnij'),
                        )
                      : null,
                ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _grant,
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Daj dostęp ręcznie'),
              ),
              const SizedBox(height: 4),
              Text(
                'Zwroty pieniędzy i anulowanie abonamentu robi rodzic w App Store / Google Play; '
                'zakupy ze sklepu www zwracasz w WooCommerce.',
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GrantDialog extends StatefulWidget {
  const _GrantDialog();

  @override
  State<_GrantDialog> createState() => _GrantDialogState();
}

class _GrantDialogState extends State<_GrantDialog> {
  String _scope = 'all_content';
  int _days = 30;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Dostęp ręczny'),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _scope,
            decoration: const InputDecoration(labelText: 'Co odblokować'),
            items: const [
              DropdownMenuItem(value: 'all_content', child: Text('Wszystkie zabawy (jak abonament)')),
              DropdownMenuItem(value: 'pack:wyobraznia', child: Text('Pakiet Wyobraźnia')),
              DropdownMenuItem(value: 'pack:slowa-i-wiedza', child: Text('Pakiet Słowa i Wiedza')),
              DropdownMenuItem(value: 'pack:detektyw', child: Text('Pakiet Detektyw')),
            ],
            onChanged: (v) => setState(() => _scope = v ?? _scope),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final d in const [7, 30, 90, 365])
                ChoiceChip(
                  label: Text(d == 365 ? 'rok' : '$d dni'),
                  selected: _days == d,
                  onSelected: (_) => setState(() => _days = d),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Powód (np. reklamacja, prezent, tester)'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
      FilledButton(
        onPressed: () => Navigator.pop(context, (_scope, _days, _note.text.trim())),
        child: const Text('Przyznaj'),
      ),
    ],
  );
}

// Rytm agenta -------------------------------------------------------------------------------------

/// Ustawienia: what the agent prepares by itself in the morning (all of it waits in "Decyzje").
class RhythmSettings extends ConsumerStatefulWidget {
  const RhythmSettings({super.key});

  @override
  ConsumerState<RhythmSettings> createState() => _RhythmSettingsState();
}

class _RhythmSettingsState extends ConsumerState<RhythmSettings> {
  Map<String, dynamic>? _value;

  static const switches = [
    (
      'brief_daily',
      'Raport COO codziennie rano',
      'Co zrobione, co utknęło, 3 priorytety i propozycje zadań.',
    ),
    (
      'ads_weekly',
      'Pomysły na reklamy i rolki w poniedziałki',
      '5 koncepcji z haczykiem, tekstem i budżetem testu.',
    ),
    (
      'newsletter_biweekly',
      'Newsletter co drugi czwartek',
      'Gotowy numer do zatwierdzenia; potem „Zaplanuj wysyłkę” w Mailing.',
    ),
    (
      'release_newsletter',
      'Newsletter o premierze 2 dni przed nią',
      'Dla każdej premiery w Kalendarzu: numer i rolki zapowiadające, z datą wysyłki w dniu premiery.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    ref.read(studioServerProvider).crmSetting('coo_rhythm').then((v) {
      if (mounted) setState(() => _value = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    if (value == null) return const LinearProgressIndicator();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rytm agenta', style: Theme.of(context).textTheme.titleMedium),
        const Text('Agent przygotowuje to sam około 6:30. Wszystko czeka na Twoją decyzję w „Decyzje”.'),
        for (final (key, title, subtitle) in switches)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title),
            subtitle: Text(subtitle),
            value: value[key] != false,
            onChanged: (v) async {
              final next = {...value, key: v};
              setState(() => _value = next);
              await crmRun(context, () => ref.read(studioServerProvider).saveCrmSetting('coo_rhythm', next));
            },
          ),
      ],
    );
  }
}

// Planowanie newslettera --------------------------------------------------------------------------

/// Group, day and hour for an approved newsletter; returns (groupId, date, time).
Future<(String, String, String)?> askNewsletterSchedule(
  BuildContext context,
  StudioServer server, {
  DateTime? day,
}) => showDialog<(String, String, String)>(
  context: context,
  builder: (_) => _ScheduleDialog(server: server, day: day),
);

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({required this.server, this.day});

  final StudioServer server;

  /// The premiere's day for a premiere newsletter.
  final DateTime? day;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late final Future<Map<String, dynamic>> _overview = widget.server.mailerLite();
  String? _group;
  late DateTime _day = widget.day != null && widget.day!.isAfter(DateTime.now())
      ? widget.day!
      : DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 30);

  String get _date => '${_day.year}-${'${_day.month}'.padLeft(2, '0')}-${'${_day.day}'.padLeft(2, '0')}';
  String get _hhmm => '${'${_time.hour}'.padLeft(2, '0')}:${'${_time.minute}'.padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Zaplanuj wysyłkę'),
    content: SizedBox(
      width: 440,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _overview,
        builder: (context, snap) {
          if (snap.hasError) return Text('${snap.error}');
          if (!snap.hasData) return const LinearProgressIndicator();
          final groups = (snap.data!['groups'] as List? ?? const []).cast<Map>();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _group,
                decoration: const InputDecoration(labelText: 'Do kogo (grupa w MailerLite)'),
                items: [
                  for (final g in groups)
                    DropdownMenuItem(value: '${g['id']}', child: Text('${g['name']} (${g['active']} osób)')),
                ],
                onChanged: (v) => setState(() => _group = v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text(_date),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        initialDate: _day,
                      );
                      if (d != null) setState(() => _day = d);
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(_hhmm),
                    onPressed: () async {
                      final t = await showTimePicker(context: context, initialTime: _time);
                      if (t != null) setState(() => _time = t);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rodzice najczęściej otwierają maile wieczorem (19–21) i w weekendowe poranki.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
      FilledButton(
        onPressed: _group == null ? null : () => Navigator.pop(context, (_group!, _date, _hhmm)),
        child: const Text('Zaplanuj'),
      ),
    ],
  );
}

// Poczta ----------------------------------------------------------------------------------------

/// Ustawienia: the morning e-mail to Dawid and the letters to parents, tried by hand.
class MailTools extends ConsumerWidget {
  const MailTools({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.read(studioServerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Poczta', style: Theme.of(context).textTheme.titleMedium),
        const Text(
          'Co rano o 7:30 przychodzi do Ciebie mail: alarmy, raport COO, liczby i to, co czeka na decyzję. '
          'Rodzice, którzy włączyli „Listy od Szop’ena”, dostają list w niedzielę o 18:00.',
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => crmRun(context, server.digestNow, done: 'Wysłano poranny raport.'),
              icon: const Icon(Icons.wb_sunny_outlined),
              label: const Text('Wyślij poranny raport teraz'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  crmRun(context, server.letterPreview, done: 'Wysłano przykładowy list na Twój adres.'),
              icon: const Icon(Icons.drafts_outlined),
              label: const Text('Przykładowy list do mnie'),
            ),
          ],
        ),
      ],
    );
  }
}
