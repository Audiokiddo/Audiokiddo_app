import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../server/studio_server.dart';
import '../state/studio_controller.dart';
import 'kpi_screen.dart';

/// "Serwer": sign in as an admin, see how the app sells, publish the catalog to the app and
/// manage promotions. Everything goes through the admin function.
class ServerScreen extends ConsumerStatefulWidget {
  const ServerScreen({super.key});

  @override
  ConsumerState<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends ConsumerState<ServerScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  StudioServer get _server => ref.read(studioServerProvider);

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_server.signedIn) return _signIn(context);
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          ListTile(
            title: Text('Zalogowano: ${_server.email ?? ''}'),
            trailing: TextButton(
              onPressed: () => _run(() async {
                await _server.signOut();
                setState(() {});
              }),
              child: const Text('Wyloguj'),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Statystyki'),
              Tab(text: 'KPI'),
              Tab(text: 'Katalog w aplikacji'),
              Tab(text: 'Promocje'),
            ],
          ),
          const Expanded(child: TabBarView(children: [_StatsTab(), KpiScreen(), _CatalogTab(), _PromotionsTab()])),
        ],
      ),
    );
  }

  Widget _signIn(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Logowanie administratora', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Wyślemy kod na Twój e-mail. Konto musi być na liście administratorów (tabela admins).',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_codeSent) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _code,
                decoration: const InputDecoration(labelText: 'Kod z maila', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      if (!_codeSent) {
                        await _server.sendCode(_email.text);
                        setState(() => _codeSent = true);
                      } else {
                        await _server.verify(_email.text, _code.text);
                        setState(() {});
                      }
                    }),
              child: Text(_codeSent ? 'Zaloguj' : 'Wyślij kod'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Numbers from the admin function: paying families, purchases and the app's own events.
class _StatsTab extends ConsumerStatefulWidget {
  const _StatsTab();

  @override
  ConsumerState<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<_StatsTab> {
  int _days = 30;
  late Future<Map<String, dynamic>> _stats = ref.read(studioServerProvider).stats(_days);

  static const _eventNames = {
    'first_open': 'Pierwsze uruchomienie',
    'app_open': 'Otwarcia aplikacji',
    'play_start': 'Start zabawy',
    'play_complete': 'Ukończone zabawy',
    'paywall_view': 'Wejście w ofertę',
    'purchase_start': 'Rozpoczęty zakup',
    'purchase_done': 'Zakup w aplikacji',
    'referral_share': 'Wysłane polecenia',
    'promo_tap': 'Kliknięcia promocji',
    'download_pack': 'Pobrane pakiety',
    'welcome_done': 'Przeszli powitanie',
    'tour_done': 'Samouczek Szop’ena',
    'quick_pick': 'Wybór „Co teraz?”',
    'news_alerts_on': 'Włączone powiadomienia',
  };

  void _reload(int days) => setState(() {
    _days = days;
    _stats = ref.read(studioServerProvider).stats(days);
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _stats,
    builder: (context, snap) {
      if (snap.hasError) return Center(child: Text('${snap.error}'));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final s = snap.data!;
      final events = Map<String, dynamic>.from(s['events'] as Map? ?? {});
      final purchases = (s['purchases'] as List? ?? const []).cast<Map>();
      final referrals = Map<String, dynamic>.from(s['referrals'] as Map? ?? {});
      final text = Theme.of(context).textTheme;
      int installs(String e) => ((events[e] as Map?)?['installs'] as int?) ?? 0;
      int count(String e) => ((events[e] as Map?)?['count'] as int?) ?? 0;
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final d in [7, 30, 90, 365])
                ChoiceChip(label: Text('$d dni'), selected: _days == d, onSelected: (_) => _reload(d)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Tile('Płacące rodziny (teraz)', '${s['paying_families'] ?? 0}'),
              _Tile('Aktywne abonamenty', '${s['active_subscriptions'] ?? 0}'),
              _Tile('Nowe instalacje', '${installs('first_open')}'),
              _Tile(
                'Polecenia: użyte / nagrodzone',
                '${referrals['redeemed'] ?? 0} / ${referrals['rewarded'] ?? 0}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Lejek ($_days dni, liczone urządzenia)', style: text.titleMedium),
          const SizedBox(height: 8),
          for (final (label, value) in [
            ('Pierwsze uruchomienie', installs('first_open')),
            ('Zaczęli zabawę', installs('play_start')),
            ('Ukończyli zabawę', installs('play_complete')),
            ('Weszli w ofertę', installs('paywall_view')),
            ('Kupili w aplikacji', installs('purchase_done')),
          ])
            ListTile(
              dense: true,
              title: Text(label),
              trailing: Text('$value', style: text.titleMedium),
            ),
          if (s['analytics'] case final Map a) ...[
            const Divider(height: 32),
            _Analytics(a: Map<String, dynamic>.from(a), days: _days),
          ],
          const Divider(height: 32),
          Text('Zakupy według produktu ($_days dni)', style: text.titleMedium),
          if (purchases.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('Brak zakupów w tym okresie.')),
          for (final p in purchases)
            ListTile(
              dense: true,
              title: Text('${p['product']}'),
              subtitle: Text(switch (p['source']) {
                'app_store' => 'App Store',
                'google_play' => 'Google Play',
                'woocommerce' => 'Sklep audiokiddo.pl',
                _ => '${p['source']}',
              }),
              trailing: Text('${p['count']}', style: text.titleMedium),
            ),
          const Divider(height: 32),
          Text('Zdarzenia w aplikacji ($_days dni)', style: text.titleMedium),
          for (final e in _eventNames.entries)
            ListTile(
              dense: true,
              title: Text(e.value),
              trailing: Text('${count(e.key)} (${installs(e.key)} urządzeń)'),
            ),
        ],
      );
    },
  );
}

/// Completions, replays, next plays, how often and how long families come back, conversion
/// from a free play and how long subscriptions last (admin_analytics on the server).
class _Analytics extends StatelessWidget {
  const _Analytics({required this.a, required this.days});

  final Map<String, dynamic> a;
  final int days;

  static String pct(Object? v) => v == null ? '–' : '$v%';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Map<String, dynamic> part(String k) => Map<String, dynamic>.from(a[k] as Map? ?? {});
    final plays = part('plays');
    final freq = part('frequency');
    final ret = part('retention');
    final conv = part('conversion');
    final subs = part('subscriptions');
    final onb = part('onboarding');
    final top = (a['top_items'] as List? ?? const []).cast<Map>();
    final cohorts = (a['cohorts'] as List? ?? const []).cast<Map>();
    Widget row(String label, String value, [String? hint]) => ListTile(
      dense: true,
      title: Text(label),
      subtitle: hint == null ? null : Text(hint),
      trailing: Text(value, style: text.titleMedium),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analityka zaawansowana ($days dni)', style: text.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _Tile('Ukończenia zabaw', pct(plays['completion_rate'])),
            _Tile('Powtórki', pct(plays['replay_rate'])),
            _Tile('Kolejna zabawa po ukończeniu', pct(plays['next_rate'])),
            _Tile('Powrót następnego dnia (D1)', pct(ret['d1'])),
            _Tile('Powrót w 1. tygodniu', pct(ret['week1'])),
            _Tile('Aktywni w 2. tygodniu', pct(ret['week2'])),
            _Tile('Aktywni po miesiącu', pct(ret['month1'])),
            _Tile('Darmowa zabawa → zakup', pct(conv['rate'])),
            _Tile('Utrzymanie abonamentu', pct(subs['retention'])),
          ],
        ),
        const SizedBox(height: 16),
        Text('Zabawy', style: text.titleMedium),
        row('Rozpoczęte / ukończone', '${plays['starts'] ?? 0} / ${plays['completes'] ?? 0}'),
        row('Powtórki (zabawa znana do końca)', '${plays['replays'] ?? 0}'),
        row(
          'Od razu następna zabawa',
          '${plays['next_plays'] ?? 0}',
          'Do 10 minut po ukończeniu poprzedniej',
        ),
        const SizedBox(height: 12),
        Text('Częstotliwość', style: text.titleMedium),
        row('Aktywne urządzenia', '${freq['active_installs'] ?? 0}'),
        row('Średnio dni z aplikacją', '${freq['avg_active_days'] ?? '–'}'),
        row('Średnio zabaw na urządzenie', '${freq['avg_plays'] ?? '–'}'),
        row(
          'Dni aktywności: 1 / 2–3 / 4–7 / 8+',
          '${freq['days_1'] ?? 0} / ${freq['days_2_3'] ?? 0} / ${freq['days_4_7'] ?? 0} / ${freq['days_8_plus'] ?? 0}',
        ),
        const SizedBox(height: 12),
        Text('Powroty tygodniowe (kohorty według tygodnia instalacji)', style: text.titleMedium),
        if (cohorts.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Za mało danych.')),
        if (cohorts.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Tydzień')),
                DataColumn(label: Text('Instalacje'), numeric: true),
                DataColumn(label: Text('Tydz. 1'), numeric: true),
                DataColumn(label: Text('Tydz. 2'), numeric: true),
                DataColumn(label: Text('Tydz. 3'), numeric: true),
                DataColumn(label: Text('Tydz. 4'), numeric: true),
              ],
              rows: [
                for (final c in cohorts)
                  DataRow(
                    cells: [
                      DataCell(Text('${c['week']}')),
                      DataCell(Text('${c['installs']}')),
                      for (final k in ['week1', 'week2', 'week3', 'week4']) DataCell(Text(pct(c[k]))),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text('Konwersja', style: text.titleMedium),
        row('Grali za darmo', '${conv['free_players'] ?? 0}'),
        row('Potem kupili w aplikacji', '${conv['paid_after_free'] ?? 0}'),
        row(
          'Oferta → kasa → zakup (urządzenia)',
          '${conv['paywall_installs'] ?? 0} → ${conv['checkout_installs'] ?? 0} → ${conv['buyer_installs'] ?? 0}',
        ),
        for (final e in Map<String, dynamic>.from(conv['paywall_from'] as Map? ?? {}).entries)
          row('Oferta otwarta z: ${e.key}', '${e.value}'),
        const SizedBox(height: 12),
        Text('Abonamenty (od początku)', style: text.titleMedium),
        row(
          'Kiedykolwiek / aktywne / zakończone',
          '${subs['ever'] ?? 0} / ${subs['active'] ?? 0} / ${subs['ended'] ?? 0}',
        ),
        row('Aktywne roczne / miesięczne', '${subs['active_yearly'] ?? 0} / ${subs['active_monthly'] ?? 0}'),
        const SizedBox(height: 12),
        Text('Pierwsze kroki', style: text.titleMedium),
        row('Przeszli powitanie', '${onb['welcome_done'] ?? 0}'),
        row('Obejrzeli samouczek Szop’ena', '${onb['tour_done'] ?? 0}'),
        row('Użycia „Co teraz?”', '${onb['quick_picks'] ?? 0}'),
        if (top.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Najczęściej włączane zabawy', style: text.titleMedium),
          for (final t in top)
            row(
              '${t['item']}',
              '${t['starts']}',
              'Ukończenia ${pct(t['completion_rate'])} · powtórki ${pct(t['replay_rate'])}',
            ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

/// Publish the draft to the app, or load what the app shows into the draft.
class _CatalogTab extends ConsumerStatefulWidget {
  const _CatalogTab();

  @override
  ConsumerState<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends ConsumerState<_CatalogTab> {
  final _note = TextEditingController();
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final validation = ref.read(validationProvider);
    if (!validation.canPublish) {
      setState(() => _status = 'Katalog ma błędy (${validation.errorCount}). Popraw je w zakładce Treści.');
      return;
    }
    setState(() => _busy = true);
    try {
      final raw = ref.read(studioProvider.notifier).exportForPublishing();
      final version = await ref.read(studioServerProvider).publish(jsonDecode(raw) as Json, _note.text);
      setState(
        () => _status =
            'Opublikowano wersję $version. Rodziny zobaczą zmiany przy następnym otwarciu aplikacji.',
      );
    } on Object catch (e) {
      setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadPublished() async {
    setState(() => _busy = true);
    try {
      final data = await ref.read(studioServerProvider).publishedCatalog();
      final manifest = data['manifest'];
      if (manifest is! Map) {
        setState(() => _status = 'Na serwerze nie ma jeszcze katalogu. Aplikacja używa wbudowanego.');
        return;
      }
      ref.read(studioProvider.notifier).importCatalog(jsonEncode(manifest));
      setState(() => _status = 'Wczytano wersję ${data['version']} z serwera do edycji.');
    } on Object catch (e) {
      setState(() => _status = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final validation = ref.watch(validationProvider);
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Jak dodać nową audiozabawę', style: text.titleMedium),
        const SizedBox(height: 8),
        const Text(
          '1. Wgraj plik nagrania (i okładkę) na serwer plików przez FileZillę, do nagrania/audio/<pakiet>/.\n'
          '2. W zakładce Treści dodaj zabawę i wybierz ten sam plik z dysku: Studio wpisze ścieżkę, rozmiar i sumę SHA-256.\n'
          '3. Opcjonalnie ustaw datę premiery w przyszłości: zabawa pojawi się w „Wkrótce”, a w dniu premiery zagra.\n'
          '4. Tutaj kliknij „Publikuj w aplikacji”. Serwer zapisze nową wersję i pozwoli pobierać plik.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _note,
          decoration: const InputDecoration(
            labelText: 'Notatka do wersji (np. „Nowa zabawa: Mistrz kuchni”)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _publish,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(
                validation.canPublish ? 'Publikuj w aplikacji' : 'Publikuj (błędy: ${validation.errorCount})',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _loadPublished,
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('Wczytaj katalog z serwera'),
            ),
          ],
        ),
        if (_status != null) ...[const SizedBox(height: 16), Text(_status!, style: text.bodyLarge)],
      ],
    );
  }
}

/// Promotions shown in the app while they run.
class _PromotionsTab extends ConsumerStatefulWidget {
  const _PromotionsTab();

  @override
  ConsumerState<_PromotionsTab> createState() => _PromotionsTabState();
}

class _PromotionsTabState extends ConsumerState<_PromotionsTab> {
  late Future<List<Map<String, dynamic>>> _list = ref.read(studioServerProvider).promotions();

  void _reload() => setState(() => _list = ref.read(studioServerProvider).promotions());

  Future<void> _edit([Map<String, dynamic>? existing]) async {
    final saved = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _PromotionDialog(existing: existing),
    );
    if (saved == null) return;
    try {
      await ref.read(studioServerProvider).savePromotion(saved);
      _reload();
    } on Object catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _list,
    builder: (context, snap) {
      if (snap.hasError) return Center(child: Text('${snap.error}'));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final now = DateTime.now();
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Promocja to komunikat w aplikacji z prawdziwą datą końca. Samą cenę zmieniasz w App Store Connect, '
            'Google Play i w sklepie WooCommerce.',
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Nowa promocja'),
            ),
          ),
          const SizedBox(height: 12),
          if (snap.data!.isEmpty) const Text('Brak promocji.'),
          for (final p in snap.data!)
            Card(
              child: ListTile(
                title: Text('${p['title']}'),
                subtitle: Text(
                  '${_fmt(p['starts_at'])} – ${_fmt(p['ends_at'])}'
                  '${p['target'] == null ? '' : ' · dotyczy: ${p['target']}'}'
                  '${_running(p, now) ? ' · TRWA' : ''}${p['active'] == false ? ' · wyłączona' : ''}',
                ),
                onTap: () => _edit(p),
                trailing: IconButton(
                  tooltip: 'Usuń',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref.read(studioServerProvider).deletePromotion(p['id'] as String);
                    _reload();
                  },
                ),
              ),
            ),
        ],
      );
    },
  );

  static String _fmt(Object? iso) {
    final d = DateTime.tryParse('$iso')?.toLocal();
    return d == null ? '?' : '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  static bool _running(Map<String, dynamic> p, DateTime now) {
    final s = DateTime.tryParse('${p['starts_at']}');
    final e = DateTime.tryParse('${p['ends_at']}');
    return p['active'] != false && s != null && e != null && now.isAfter(s) && now.isBefore(e);
  }
}

class _PromotionDialog extends StatefulWidget {
  const _PromotionDialog({this.existing});

  final Map<String, dynamic>? existing;

  @override
  State<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<_PromotionDialog> {
  late final _title = TextEditingController(text: widget.existing?['title'] as String? ?? '');
  late final _body = TextEditingController(text: widget.existing?['body'] as String? ?? '');
  late final _badge = TextEditingController(text: widget.existing?['badge'] as String? ?? '');
  late final _target = TextEditingController(text: widget.existing?['target'] as String? ?? '');
  late DateTime _start = DateTime.tryParse('${widget.existing?['starts_at']}')?.toLocal() ?? DateTime.now();
  late DateTime _end =
      DateTime.tryParse('${widget.existing?['ends_at']}')?.toLocal() ??
      DateTime.now().add(const Duration(days: 7));
  late bool _active = widget.existing?['active'] as bool? ?? true;

  Future<void> _pick(bool start) async {
    final initial = start ? _start : _end;
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2026),
      lastDate: DateTime(2030),
    );
    if (day == null) return;
    setState(() {
      final at = DateTime(day.year, day.month, day.day, start ? 0 : 23, start ? 0 : 59);
      start ? _start = at : _end = at;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'Nowa promocja' : 'Promocja'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tytuł (np. Mikołajki: zestaw 3 pakietów taniej)'),
          ),
          TextField(
            controller: _body,
            decoration: const InputDecoration(labelText: 'Opis (krótko)'),
          ),
          TextField(
            controller: _badge,
            decoration: const InputDecoration(labelText: 'Etykieta (np. −20%)'),
          ),
          TextField(
            controller: _target,
            decoration: const InputDecoration(
              labelText: 'Dotyczy: id pakietu, subscription, bundle albo puste',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(true),
                  child: Text('Od ${_start.day}.${_start.month}.${_start.year}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pick(false),
                  child: Text('Do ${_end.day}.${_end.month}.${_end.year}'),
                ),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Włączona'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
      FilledButton(
        onPressed: () => Navigator.pop(context, {
          if (widget.existing?['id'] case final String id) 'id': id,
          'title': _title.text.trim(),
          'body': _body.text.trim(),
          'badge': _badge.text.trim(),
          'target': _target.text.trim(),
          'starts_at': _start.toUtc().toIso8601String(),
          'ends_at': _end.toUtc().toIso8601String(),
          'active': _active,
        }),
        child: const Text('Zapisz'),
      ),
    ],
  );
}
