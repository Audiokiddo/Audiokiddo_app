import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../server/studio_server.dart';
import '../state/studio_controller.dart';

typedef KpiLoader = Future<Map<String, dynamic>> Function(int days, String? age);

/// The four dashboards of the analytics annex (docs/ANEKS-ANALITYCZNY.md): CEO (is the
/// business working), Produkt (what children love), Growth (where good families come from)
/// and Tech i dane (can we trust the numbers). Every view should lead to keep, change or scale.
class KpiScreen extends ConsumerStatefulWidget {
  const KpiScreen({super.key, this.loader});

  /// Swapped in tests; the admin function otherwise.
  final KpiLoader? loader;

  @override
  ConsumerState<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends ConsumerState<KpiScreen> {
  int _days = 30;
  String? _age;
  late Future<Map<String, dynamic>> _kpi = _load();

  Future<Map<String, dynamic>> _load() =>
      (widget.loader ?? ref.read(studioServerProvider).kpi)(_days, _age);

  void _set({int? days, String? age, bool clearAge = false}) => setState(() {
    _days = days ?? _days;
    _age = clearAge ? null : (age ?? _age);
    _kpi = _load();
  });

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final d in [7, 30, 90, 365])
                ChoiceChip(label: Text('$d dni'), selected: _days == d, onSelected: (_) => _set(days: d)),
              const SizedBox(width: 16),
              ChoiceChip(label: const Text('Każdy wiek'), selected: _age == null, onSelected: (_) => _set(clearAge: true)),
              for (final a in ['3-5', '5-7', '7-9'])
                ChoiceChip(label: Text(a.replaceAll('-', '–')), selected: _age == a, onSelected: (_) => _set(age: a)),
            ],
          ),
        ),
        const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'CEO'),
            Tab(text: 'Produkt'),
            Tab(text: 'Growth'),
            Tab(text: 'Tech i dane'),
          ],
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _kpi,
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('${snap.error}'));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final k = snap.data!;
              return TabBarView(
                children: [
                  _Ceo(k: _map(k['ceo'])),
                  _Product(p: _map(k['product'])),
                  _Growth(rows: _list(k['growth']), money: _map(k['monetization'])),
                  _Tech(h: _map(k['data_health']), money: _map(k['monetization'])),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

Map<String, dynamic> _map(Object? v) => Map<String, dynamic>.from(v as Map? ?? const {});
List<Map<String, dynamic>> _list(Object? v) => [for (final e in v as List? ?? const []) _map(e)];
String _pct(Object? v) => v == null ? '–' : '$v%';
String _num(Object? v) => v == null ? '–' : '$v';

/// Business health in five minutes: the eight numbers, the funnel and the cohorts.
class _Ceo extends StatelessWidget {
  const _Ceo({required this.k});

  final Map<String, dynamic> k;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final trend = _list(k['wrf_trend']);
    final funnel = _map(k['funnel']);
    final cohorts = _list(k['cohorts']);
    final subs = (k['active_subscribers'] as num?) ?? 0;
    final mrr = (k['mrr'] as num?) ?? 0;
    final trendText = trend.length < 2
        ? 'Za mało tygodni na trend'
        : trend.map((t) => '${t['families']}').join(' → ');
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _Lead('Czy AudioKiddo działa jako biznes?'),
        _Tiles([
          KpiTile('Weekly Returning Families', _num(k['weekly_returning_families']),
              hint: 'North Star: zabawa ukończona w 2+ dni w ostatnich 7 dniach. Tygodnie: $trendText'),
          KpiTile('Nowe aktywowane rodziny', _num(k['new_activated']),
              hint: 'Ukończyły pierwszą zabawę i włączyły kolejną albo powtórkę'),
          KpiTile('True Activation', _pct(k['true_activation']), hint: 'Aktywowane / nowe rodziny'),
          KpiTile('D7', _pct(k['d7']), hint: 'Ukończona zabawa w dniach 7–13 od aktywacji'),
          KpiTile('D30', _pct(k['d30']), hint: 'Ukończona zabawa w dniach 28–34 od aktywacji'),
          KpiTile('Aktywni abonenci', '$subs',
              hint: 'Miesięczni ${_num(k['subs_monthly'])} · roczni ${_num(k['subs_annual'])}'),
          KpiTile('MRR', '$mrr zł', hint: 'Roczne liczone jako 1/12 miesięcznie, brutto'),
          KpiTile('Churn w tym miesiącu', _pct(k['churn_month']), hint: 'Dostęp faktycznie wygasł, nie kliknięcie „anuluj”'),
        ]),
        const SizedBox(height: 16),
        Text('Zdrowie biznesu', style: text.titleMedium),
        _Tiles([
          KpiTile('ARPU', subs == 0 ? '–' : '${(mrr / subs).toStringAsFixed(2)} zł', hint: 'MRR / abonenci'),
          const KpiTile('CAC', '–', hint: 'Potrzebne wydatki na reklamę według kanału (do dodania w CRM)'),
          const KpiTile('LTV i payback', '–', hint: 'Po kilku miesiącach danych: ARPU × miesiące × marża'),
          KpiTile('Technical Activation', _pct(k['technical_activation']), hint: 'Pierwsza zabawa / nowe rodziny'),
          KpiTile('Pierwsza zabawa ukończona', _pct(k['first_game_completion'])),
          KpiTile('Do pierwszej zabawy', '${_num(k['minutes_to_first_play_median'])} min', hint: 'Mediana'),
          KpiTile('Aktywne dni w tygodniu', _num(k['active_days_per_family_week']), hint: 'Na aktywną rodzinę'),
          KpiTile('Zabawy na aktywną rodzinę', _num(k['games_per_active_family_week']), hint: 'Ostatnie 7 dni'),
          KpiTile('M2 / M3', '${_pct(k['m2'])} / ${_pct(k['m3'])}'),
        ]),
        const SizedBox(height: 16),
        Text('Lejek nowych rodzin', style: text.titleMedium),
        const SizedBox(height: 8),
        _Funnel([
          ('Nowe rodziny', funnel['new_families']),
          ('Pierwsza zabawa', funnel['first_play']),
          ('Ukończona pierwsza', funnel['first_done']),
          ('Aktywowane', funnel['activated']),
          ('Zobaczyły ofertę', funnel['paywall']),
          ('Zapłaciły', funnel['paid']),
        ]),
        const SizedBox(height: 16),
        Text('Retencja kohortowa (tydzień aktywacji)', style: text.titleMedium),
        if (cohorts.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Za mało danych.')),
        if (cohorts.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Kohorta')),
                DataColumn(label: Text('Aktywowane'), numeric: true),
                DataColumn(label: Text('D7'), numeric: true),
                DataColumn(label: Text('D30'), numeric: true),
                DataColumn(label: Text('M2'), numeric: true),
                DataColumn(label: Text('M3'), numeric: true),
              ],
              rows: [
                for (final c in cohorts)
                  DataRow(
                    cells: [
                      DataCell(Text('${c['week']}')),
                      DataCell(Text('${c['activated']}')),
                      for (final key in ['d7', 'd30', 'm2', 'm3']) DataCell(Text(_pct(c[key]))),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// What children love: one row per play, the top and problem lists, the drop-off map.
class _Product extends ConsumerStatefulWidget {
  const _Product({required this.p});

  final Map<String, dynamic> p;

  @override
  ConsumerState<_Product> createState() => _ProductState();
}

class _ProductState extends ConsumerState<_Product> {
  String? _dropoffItem;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final games = _list(widget.p['games']);
    final dropoff = _map(widget.p['dropoff']);
    final studio = ref.watch(studioProvider);
    String title(Object? id) => '${studio.item('$id')?['title'] ?? id}';
    // Plays with too few starts would top every list by chance.
    final enough = games.where((g) => ((g['starts'] as num?) ?? 0) >= 5).toList();
    List<Map<String, dynamic>> top(String key, {bool asc = false}) {
      final list = enough.where((g) => g[key] != null).toList()
        ..sort((a, b) => (asc ? 1 : -1) * ((a[key] as num).compareTo(b[key] as num)));
      return list.take(5).toList();
    }

    final selected = _dropoffItem ?? (dropoff.keys.isEmpty ? null : dropoff.keys.first);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _Lead('Co kochają dzieci?'),
        if (enough.isEmpty)
          const Text('Listy „Top” pojawią się, gdy zabawy będą miały co najmniej 5 startów.')
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _TopList('Największy replay', [for (final g in top('replay7')) (title(g['item']), _pct(g['replay7']))]),
              _TopList('Najwyższy completion', [
                for (final g in top('completion')) (title(g['item']), _pct(g['completion'])),
              ]),
              _TopList('Najlepszy Next Game', [for (final g in top('next_game')) (title(g['item']), _pct(g['next_game']))]),
              _TopList('Problemy: najwięcej wyjść', [for (final g in top('exits')) (title(g['item']), '${g['exits']} wyjść')]),
            ],
          ),
        const SizedBox(height: 16),
        Text('Wszystkie zabawy', style: text.titleMedium),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Zabawa')),
              DataColumn(label: Text('Starty'), numeric: true),
              DataColumn(label: Text('Rodziny'), numeric: true),
              DataColumn(label: Text('Completion'), numeric: true),
              DataColumn(label: Text('Replay 7d'), numeric: true),
              DataColumn(label: Text('Next game'), numeric: true),
              DataColumn(label: Text('Wyjścia'), numeric: true),
              DataColumn(label: Text('Mediana wyjścia'), numeric: true),
              DataColumn(label: Text('Odtworzeń/rodzinę'), numeric: true),
            ],
            rows: [
              for (final g in games)
                DataRow(
                  cells: [
                    DataCell(Text(title(g['item']))),
                    DataCell(Text(_num(g['starts']))),
                    DataCell(Text(_num(g['families']))),
                    DataCell(Text(_pct(g['completion']))),
                    DataCell(Text(_pct(g['replay7']))),
                    DataCell(Text(_pct(g['next_game']))),
                    DataCell(Text(_num(g['exits']))),
                    DataCell(Text(_pct(g['median_exit_pct']))),
                    DataCell(Text(_num(g['plays_per_family']))),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Mapa wyjść: w której minucie dzieci kończą słuchanie', style: text.titleMedium),
        if (selected == null)
          const Padding(padding: EdgeInsets.all(8), child: Text('Brak wyjść w tym okresie.'))
        else ...[
          DropdownButton<String>(
            value: selected,
            items: [for (final id in dropoff.keys) DropdownMenuItem(value: id, child: Text(title(id)))],
            onChanged: (v) => setState(() => _dropoffItem = v),
          ),
          DropoffChart(buckets: [for (final b in dropoff[selected] as List) (b[0] as int, b[1] as int)]),
        ],
        const SizedBox(height: 16),
        Text('Czego szukają rodzice', style: text.titleMedium),
        for (final s in _list(widget.p['searches']))
          ListTile(
            dense: true,
            title: Text('${s['query']}'),
            subtitle: (s['no_results'] as num? ?? 0) > 0 ? Text('Bez wyników: ${s['no_results']}') : null,
            trailing: Text('${s['count']}'),
          ),
        const SizedBox(height: 16),
        Text('Otwierają kartę, ale nie włączają', style: text.titleMedium),
        for (final v in _list(widget.p['viewed_not_started']))
          ListTile(
            dense: true,
            title: Text(title(v['item'])),
            trailing: Text('${v['started']} z ${v['viewers']} włączyło'),
          ),
        const SizedBox(height: 16),
        Text('Najczęściej dodawane do ulubionych', style: text.titleMedium),
        for (final f in _list(widget.p['favorites']))
          ListTile(dense: true, title: Text(title(f['item'])), trailing: Text('${f['added']}')),
      ],
    );
  }
}

/// Where good families come from: by the parent's answer "Skąd o nas wiecie?".
class _Growth extends StatelessWidget {
  const _Growth({required this.rows, required this.money});

  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> money;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const _Lead('Skąd przychodzą dobrzy klienci?'),
      const Text(
        'Źródło to odpowiedź rodzica na pytanie „Skąd o nas wiecie?” po powitaniu. Liczą się aktywacje i '
        'płacące rodziny, nie same instalacje. CAC według kanału pojawi się po dopisaniu wydatków na reklamę.',
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Źródło')),
            DataColumn(label: Text('Nowe rodziny'), numeric: true),
            DataColumn(label: Text('Aktywowane'), numeric: true),
            DataColumn(label: Text('Płacące'), numeric: true),
            DataColumn(label: Text('Aktywacja'), numeric: true),
            DataColumn(label: Text('Płacące / nowe'), numeric: true),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                cells: [
                  DataCell(Text(_sourceName('${r['source']}'))),
                  DataCell(Text(_num(r['new_families']))),
                  DataCell(Text(_num(r['activated']))),
                  DataCell(Text(_num(r['paid']))),
                  DataCell(Text(_pct(r['activation']))),
                  DataCell(Text(_pct(r['paid_rate']))),
                ],
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text('Monetyzacja', style: Theme.of(context).textTheme.titleMedium),
      _Tiles([
        KpiTile('Darmowa zabawa → oferta', _pct(money['free_to_paywall'])),
        KpiTile('Oferta → zakup', _pct(money['paywall_to_purchase'])),
        KpiTile('Free → Paid 24 h', _pct(money['free_to_paid_24h'])),
        KpiTile('Free → Paid 7 dni', _pct(money['free_to_paid_7d'])),
        KpiTile('Free → Paid 30 dni', _pct(money['free_to_paid_30d'])),
      ]),
      for (final e in _map(money['paywall_from']).entries)
        ListTile(dense: true, title: Text('Oferta otwarta z: ${_entryName(e.key)}'), trailing: Text('${e.value} rodzin')),
    ],
  );
}

/// Can we trust the numbers, and does the app work: data health, versions, checkout errors.
class _Tech extends StatelessWidget {
  const _Tech({required this.h, required this.money});

  final Map<String, dynamic> h;
  final Map<String, dynamic> money;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final checkout = _map(money['checkout']);
    final purchases = _map(h['purchases_app_vs_store']);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _Lead('Czy produkt i pomiar działają?'),
        _Tiles([
          KpiTile('Zdarzenia w okresie', _num(h['events'])),
          KpiTile('Z grupą wieku', _pct(h['with_age_group'])),
          KpiTile('Z sesją', _pct(h['with_session'])),
          KpiTile('Z kontem', _pct(h['with_user'])),
          KpiTile('Nowe rodziny ze źródłem', _pct(h['families_with_source'])),
          KpiTile('Podejrzane duplikaty', _num(h['suspect_duplicates']), hint: 'To samo zdarzenie w 2 s'),
          KpiTile('Starty bez końca i wyjścia', _pct(h['starts_without_end']),
              hint: 'Aplikacja zamknięta w trakcie albo zgubione zdarzenie'),
          KpiTile('Zakupy: aplikacja / sklep', '${_num(purchases['app_events'])} / ${_num(purchases['store_entitlements'])}',
              hint: 'Powinny być zbliżone'),
        ]),
        const SizedBox(height: 16),
        Text('Płatności', style: text.titleMedium),
        ListTile(dense: true, title: const Text('Rozpoczęte'), trailing: Text(_num(checkout['started']))),
        ListTile(dense: true, title: const Text('Zakończone'), trailing: Text(_num(checkout['done']))),
        for (final e in _map(checkout['failed']).entries)
          ListTile(dense: true, title: Text('Nieudane: ${_errorName(e.key)}'), trailing: Text('${e.value}')),
        const SizedBox(height: 16),
        Text('Wersje aplikacji (rodziny)', style: text.titleMedium),
        for (final e in _map(h['versions']).entries)
          ListTile(dense: true, title: Text(e.key), trailing: Text('${e.value}')),
      ],
    );
  }
}

String _sourceName(String s) => switch (s) {
  'instagram' => 'Instagram',
  'tiktok' => 'TikTok',
  'facebook' => 'Facebook',
  'ad' => 'Reklama',
  'influencer' => 'Influencer lub blog',
  'referral' => 'Od znajomych',
  'search' => 'Wyszukiwarka / sklep',
  'other' => 'Inaczej',
  _ => s,
};

String _entryName(String s) => switch (s) {
  'locked_game' => 'zablokowana zabawa',
  'after_free_play' => 'po darmowej zabawie',
  _ => s,
};

String _errorName(String s) => switch (s) {
  'canceled' => 'anulowane przez rodzica',
  'store_error' => 'błąd sklepu',
  'store_not_ready' => 'sklep niedostępny',
  'verify_failed' => 'nie potwierdzone przez serwer',
  _ => s,
};

class _Lead extends StatelessWidget {
  const _Lead(this.question);

  final String question;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(question, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _Tiles extends StatelessWidget {
  const _Tiles(this.tiles);

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 16, runSpacing: 16, children: tiles);
}

class KpiTile extends StatelessWidget {
  const KpiTile(this.label, this.value, {super.key, this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          if (hint != null) ...[const SizedBox(height: 4), Text(hint!, style: text.bodySmall)],
        ],
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  const _TopList(this.title, this.rows);

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            for (final (name, value) in rows)
              Row(
                children: [
                  Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(value),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

/// One bar per step, from the widest: where the funnel loses families.
class _Funnel extends StatelessWidget {
  const _Funnel(this.steps);

  final List<(String, Object?)> steps;

  @override
  Widget build(BuildContext context) {
    final first = ((steps.first.$2 as num?) ?? 0).toDouble();
    return Column(
      children: [
        for (final (label, value) in steps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 170, child: Text(label)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: first == 0 ? 0 : (((value as num?) ?? 0) / first).clamp(0, 1).toDouble(),
                    minHeight: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                SizedBox(width: 60, child: Text(_num(value), textAlign: TextAlign.end)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Exits per half minute of one play: a sudden bar is a moment worth listening to.
class DropoffChart extends StatelessWidget {
  const DropoffChart({super.key, required this.buckets});

  /// (second the half minute starts at, exits in it).
  final List<(int, int)> buckets;

  @override
  Widget build(BuildContext context) {
    final most = buckets.fold(0, (m, b) => b.$2 > m ? b.$2 : m);
    String clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    return Column(
      children: [
        for (final (second, exits) in buckets)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text(clock(second))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: most == 0 ? 0 : exits / most,
                    minHeight: 14,
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(width: 40, child: Text('$exits', textAlign: TextAlign.end)),
              ],
            ),
          ),
      ],
    );
  }
}
