import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';

/// The project Studio publishes to (same as the app; the key is the public one).
const _url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://ypdxofcwewwdyoelamgy.supabase.co');
const _key = String.fromEnvironment(
  'SUPABASE_KEY',
  defaultValue: 'sb_publishable_GfJcAHEtFYs5IvlKrNZBVw_0WeAneGQ',
);

/// Thrown with a message for the person at the keyboard.
class StudioServerException implements Exception {
  const StudioServerException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// What to do when the agent (Claude) failed, from the reason the function sends back.
String agentTrouble(Object? details) {
  final body = details is Map ? details : const {};
  return switch ('${body['reason'] ?? body['error'] ?? ''}') {
    'key' =>
      'Klucz Claude jest nieprawidłowy albo wyłączony. Utwórz nowy w console.anthropic.com → API Keys '
          'i wklej go w Supabase → Edge Functions → Secrets jako ANTHROPIC_API_KEY.',
    'credit' => 'Na koncie Anthropic skończyły się środki. Doładuj je: console.anthropic.com → Billing.',
    'model_missing' => 'Ten model Claude jest niedostępny dla Twojego klucza. Usuń sekret COO_MODEL w Supabase albo wpisz inny model.',
    'busy' => 'Claude jest teraz przeciążony. Spróbuj za minutę.',
    'too_long' =>
      'Odpowiedź agenta była za długa i się urwała. Spróbuj jeszcze raz albo dopisz węższą wskazówkę.',
    'answer' => 'Agent odpowiedział w złym formacie. Spróbuj jeszcze raz.',
    _ => 'Agent nie odpowiedział poprawnie. Spróbuj ponownie za chwilę.',
  };
}

/// Studio's connection to the server: sign-in with an e-mail code and the admin function
/// (only accounts listed in public.admins may use it).
class StudioServer {
  // The code from the e-mail is typed in Studio, so no redirect and no PKCE: PKCE would need a
  // storage for its verifier, which a bare SupabaseClient does not have (null check on send).
  StudioServer([SupabaseClient? client])
    : client =
          client ??
          SupabaseClient(
            _url,
            _key,
            authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
          );

  final SupabaseClient client;
  static const _sessionKey = 'studio_session';
  StreamSubscription<AuthState>? _saving;

  /// Keeps the admin signed in across page reloads (the session lives in this browser only).
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_sessionKey);
    if (saved != null && !signedIn) {
      try {
        await client.auth.recoverSession(saved);
      } on Object {
        await prefs.remove(_sessionKey);
      }
    }
    _saving ??= client.auth.onAuthStateChange.listen((state) async {
      final session = state.session;
      if (session == null) {
        await prefs.remove(_sessionKey);
      } else {
        await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
      }
    });
  }

  bool get signedIn => client.auth.currentUser != null;
  String? get email => client.auth.currentUser?.email;

  Future<void> sendCode(String email) =>
      client.auth.signInWithOtp(email: email.trim(), shouldCreateUser: false);

  Future<void> verify(String email, String code) =>
      client.auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.email);

  Future<void> signOut() => client.auth.signOut();

  Future<dynamic> _admin(Map<String, Object?> body) => _invoke('admin', body);

  Future<dynamic> _invoke(String function, Map<String, Object?> body) async {
    try {
      final response = await client.functions.invoke(function, body: body);
      return response.data;
    } on FunctionException catch (e) {
      throw StudioServerException(switch (e.status) {
        401 => 'Zaloguj się ponownie.',
        403 => 'To konto nie jest administratorem (tabela admins).',
        400 =>
          '${e.details}'.contains('past')
              ? 'Wybierz godzinę co najmniej 10 minut od teraz.'
              : 'Serwer odrzucił dane: ${e.details}',
        409 => 'Ta propozycja jest już rozstrzygnięta. Odśwież widok.',
        412 when function == 'mailer' => 'Brak ustawień poczty. Wpisz SMTP_HOST, SMTP_USER, SMTP_PASS (i REPORT_TO) w Supabase → Edge Functions → Secrets.',
        412 when function == 'reviews' =>
          'Brak kluczy sklepów: ASC_* (App Store) albo GOOGLE_SERVICE_ACCOUNT_JSON (Google Play).',
        404 when function == 'mailer' => 'To zamówienie jest już odebrane albo go nie ma.',
        412 =>
          function == 'coo' || function == 'ads'
              ? 'Brak klucza Claude API. Wpisz ANTHROPIC_API_KEY w Supabase → Edge Functions → Secrets.'
              : 'Brak klucza MailerLite. Wpisz MAILERLITE_API_KEY i MAILERLITE_FROM w Supabase → Edge Functions → Secrets.',
        502 =>
          function == 'coo' || function == 'ads'
              ? agentTrouble(e.details)
              : 'MailerLite odrzucił zapytanie. Sprawdź klucz i adres nadawcy.',
        _ => 'Serwer nie odpowiada. Spróbuj za chwilę.',
      });
    }
  }

  // CRM -------------------------------------------------------------------------------------

  Future<Map<String, dynamic>> crmOverview() async =>
      Map<String, dynamic>.from(await client.rpc('crm_overview') as Map);

  Future<List<Map<String, dynamic>>> crmItems({String? kind, String? decision}) async {
    var query = client.from('crm_items').select();
    if (kind != null) query = query.eq('kind', kind);
    if (decision != null) query = query.eq('decision', decision);
    final rows = await query.order('created_at', ascending: false).limit(500);
    return [for (final r in rows) Map<String, dynamic>.from(r)];
  }

  /// Adds (no id) or changes an item.
  Future<void> saveCrmItem(Map<String, Object?> item) async {
    final id = item['id'];
    final values = Map<String, Object?>.from(item)
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    if (id == null) {
      await client.from('crm_items').insert(values);
    } else {
      await client.from('crm_items').update(values).eq('id', id);
    }
  }

  Future<void> deleteCrmItem(String id) => client.from('crm_items').delete().eq('id', id);

  /// Dawid's decision on an AI proposal: approved ones join their board, rejected are archived.
  Future<void> decide(Map<String, dynamic> item, {required bool approve}) => client
      .from('crm_items')
      .update({
        'decision': approve ? 'approved' : 'rejected',
        'status': approve ? (item['kind'] == 'idea' ? 'chosen' : 'todo') : 'archived',
      })
      .eq('id', item['id'] as String);

  /// Asks the AI director. Returns { summary, proposals }.
  Future<Map<String, dynamic>> coo(String mode, {String? note, String? focusId}) async =>
      Map<String, dynamic>.from(
        await _invoke('coo', {'mode': mode, 'note': ?note, 'focus_id': ?focusId}) as Map,
      );

  Future<Map<String, dynamic>> mailerLite() async =>
      Map<String, dynamic>.from(await _invoke('mailerlite', {'action': 'overview'}) as Map);

  Future<void> mailerLiteDraft(String itemId, {String? groupId}) =>
      _invoke('mailerlite', {'action': 'draft', 'item_id': itemId, 'group_id': ?groupId});

  // Kampanie (Meta Ads, Pixel, Google Ads, GA4) ---------------------------------------------

  /// Everything the Kampanie tab shows: sources, campaigns, numbers, proposals, limits.
  Future<Map<String, dynamic>> adsOverview() async =>
      Map<String, dynamic>.from(await _invoke('ads', {'action': 'overview'}) as Map);

  /// Fetches campaigns and numbers from the platforms now. Returns a line per source.
  Future<Map<String, dynamic>> adsSync() async =>
      Map<String, dynamic>.from((await _invoke('ads', {'action': 'sync'}) as Map)['report'] as Map? ?? {});

  /// Asks the ads agent; its proposals wait for a decision. Returns { summary, proposed }.
  Future<Map<String, dynamic>> adsPropose({String? note}) async =>
      Map<String, dynamic>.from(await _invoke('ads', {'action': 'propose', 'note': ?note}) as Map);

  /// Approving applies the change on the platform right away. Returns { ok, message }.
  Future<Map<String, dynamic>> adsDecide(String id, {required bool approve, double? dailyBudget}) async =>
      Map<String, dynamic>.from(
        await _invoke('ads', {'action': 'decide', 'id': id, 'approve': approve, 'daily_budget': ?dailyBudget})
            as Map,
      );

  /// A change made by hand: pause, enable or a new daily budget.
  Future<Map<String, dynamic>> adsApply(
    String platform,
    String entityId,
    String action, {
    double? dailyBudget,
  }) async => Map<String, dynamic>.from(
    await _invoke('ads', {
      'action': 'apply',
      'platform': platform,
      'entity_id': entityId,
      'action_kind': action,
      'daily_budget': ?dailyBudget,
    }) as Map,
  );

  /// Kreacje, konkurencja, słowa kluczowe: verdicts, creatives, research, competitors, keywords.
  Future<Map<String, dynamic>> adsGrowth() async =>
      Map<String, dynamic>.from(await _invoke('ads', {'action': 'growth'}) as Map);

  /// The weekly research now: competitors, keywords, then the agent writes creatives.
  Future<Map<String, dynamic>> adsResearch({String? note}) async =>
      Map<String, dynamic>.from(await _invoke('ads', {'action': 'research', 'note': ?note}) as Map);

  /// Approve (optionally edited; a Google one straight into [groupId]) or reject a creative.
  Future<Map<String, dynamic>> adsCreative(
    String id, {
    required bool approve,
    Map<String, Object?>? content,
    String? feedback,
    String? groupId,
  }) async => Map<String, dynamic>.from(
    await _invoke('ads', {
      'action': 'creative',
      'id': id,
      'approve': approve,
      'content': ?content,
      'feedback': ?feedback,
      'group_id': ?groupId,
    }) as Map,
  );

  /// An approved Google creative created (paused) in an ad group.
  Future<Map<String, dynamic>> adsCreativeLive(String id, String groupId) async => Map<String, dynamic>.from(
    await _invoke('ads', {'action': 'creative_live', 'id': id, 'group_id': groupId}) as Map,
  );

  /// A search term excluded in a Google campaign (phrase match).
  Future<Map<String, dynamic>> adsExclude(String campaignId, String term) async => Map<String, dynamic>.from(
    await _invoke('ads', {'action': 'exclude', 'campaign_id': campaignId, 'term': term}) as Map,
  );

  /// Adds a keyword by hand (blog, ads or both).
  Future<void> addKeyword(String keyword, String useFor) => client.from('seo_keywords').upsert({
    'keyword': keyword.trim().toLowerCase(),
    'source': 'manual',
    'use_for': useFor,
  });

  // Klienci i trendy ----------------------------------------------------------------------

  /// A customer by e-mail: account, purchases, 30 days of activity; null when there is none.
  Future<Map<String, dynamic>?> crmCustomer(String email) async {
    final data = await client.rpc('crm_customer', params: {'p_email': email.trim()});
    return data == null ? null : Map<String, dynamic>.from(data as Map);
  }

  /// Access by hand for [days] (`all_content` or `pack:<id>`), noted in the CRM history.
  Future<void> crmGrant(String userId, String scope, int days, {String? note}) =>
      client.rpc('crm_grant', params: {'p_user': userId, 'p_scope': scope, 'p_days': days, 'p_note': note});

  Future<void> crmRevoke(String userId, String scope) =>
      client.rpc('crm_revoke', params: {'p_user': userId, 'p_scope': scope});

  /// Week by week: accounts, active families, plays, offers seen, purchases, revenue.
  Future<List<Map<String, dynamic>>> crmTrend({int weeks = 12}) async => [
    for (final w in (await client.rpc('crm_trend', params: {'p_weeks': weeks}) as List? ?? const []))
      Map<String, dynamic>.from(w as Map),
  ];

  /// Sends an approved newsletter to [groupId] on [date] at [time] ("HH:MM", Warsaw time).
  Future<void> mailerLiteSchedule(String itemId, String groupId, String date, String time) => _invoke(
    'mailerlite',
    {'action': 'schedule', 'item_id': itemId, 'group_id': groupId, 'date': date, 'time': time},
  );

  // Jakość, analiza, opinie, zamówienia, poczta ------------------------------------------

  List<Map<String, dynamic>> _rows(Object? data) => [
    for (final r in (data as List? ?? const [])) Map<String, dynamic>.from(r as Map),
  ];

  /// Open alerts, checked right now by the watchdog.
  Future<List<Map<String, dynamic>>> alerts() async => _rows(await client.rpc('crm_alerts_now'));

  Future<void> ackAlert(String id) => client.rpc('crm_ack', params: {'p_id': id});

  Future<List<Map<String, dynamic>>> appErrors({int days = 7}) async =>
      _rows(await client.rpc('crm_errors', params: {'p_days': days}));

  Future<List<Map<String, dynamic>>> plays({int days = 30}) async =>
      _rows(await client.rpc('crm_plays', params: {'p_days': days}));

  Future<Map<String, dynamic>> ltv() async => Map<String, dynamic>.from(await client.rpc('crm_ltv') as Map);

  Future<List<Map<String, dynamic>>> experiments() async =>
      _rows(await client.from('experiments').select().order('key'));

  Future<void> setExperiment(String key, {required bool active}) => client
      .from('experiments')
      .update({
        'active': active,
        if (active)
          'started_at': DateTime.now().toUtc().toIso8601String()
        else
          'ended_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('key', key);

  Future<List<Map<String, dynamic>>> experimentResults(String key) async =>
      _rows(await client.rpc('crm_experiment', params: {'p_key': key}));

  Future<List<Map<String, dynamic>>> reviews() async =>
      _rows(await client.from('store_reviews').select().order('created_at', ascending: false).limit(200));

  Future<Map<String, dynamic>> reviewsSync() async =>
      Map<String, dynamic>.from(await _invoke('reviews', {'action': 'sync'}) as Map);

  Future<String> reviewDraft(String store, String id) async =>
      '${(await _invoke('reviews', {'action': 'draft', 'store': store, 'review_id': id}) as Map)['draft']}';

  Future<Map<String, dynamic>> reviewPublish(String store, String id, String text) async =>
      Map<String, dynamic>.from(
        await _invoke('reviews', {'action': 'publish', 'store': store, 'review_id': id, 'text': text}) as Map,
      );

  Future<void> reviewSkip(String store, String id) =>
      _invoke('reviews', {'action': 'skip', 'store': store, 'review_id': id});

  Future<List<Map<String, dynamic>>> orders({int days = 60}) async =>
      _rows(await client.rpc('crm_orders', params: {'p_days': days}));

  Future<void> orderReminder(int order) => _invoke('mailer', {'action': 'order_reminder', 'order': order});

  Future<void> digestNow() => _invoke('mailer', {'action': 'digest'});

  Future<void> letterPreview() => _invoke('mailer', {'action': 'letter_preview'});

  // Fabryka ---------------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> factoryJobs() async => _rows(
    await client
        .from('factory_jobs')
        .select()
        .neq('status', 'rejected')
        .order('updated_at', ascending: false)
        .limit(100),
  );

  Future<void> factoryCreate(String kind, {String? title, String? note}) =>
      _invoke('factory', {'action': 'create', 'kind': kind, 'title': ?title, 'note': ?note});

  Future<void> factoryProposeTopics(int count) =>
      _invoke('factory', {'action': 'propose_topics', 'count': count});

  Future<void> factoryApprove(String id, {Map<String, dynamic>? output}) =>
      _invoke('factory', {'action': 'approve', 'id': id, 'output': ?output});

  Future<void> factoryRevise(String id, String feedback) =>
      _invoke('factory', {'action': 'revise', 'id': id, 'feedback': feedback});

  Future<void> factoryReject(String id) => _invoke('factory', {'action': 'reject', 'id': id});

  Future<String> factoryAudioUrl(String path) async =>
      '${(await _invoke('factory', {'action': 'audio_url', 'path': path}) as Map)['url']}';

  Future<Map<String, dynamic>> crmSetting(String key) async {
    final row = await client.from('crm_settings').select('value').eq('key', key).maybeSingle();
    return Map<String, dynamic>.from((row?['value'] as Map?) ?? {});
  }

  Future<void> saveCrmSetting(String key, Map<String, Object?> value) => client.from('crm_settings').upsert({
    'key': key,
    'value': value,
    'updated_at': DateTime.now().toIso8601String(),
  });

  Future<Map<String, dynamic>> stats(int days) async =>
      Map<String, dynamic>.from(await _admin({'action': 'stats', 'days': days}) as Map);

  /// The published catalog: { version, manifest } (empty map when nothing was published yet).
  Future<Map<String, dynamic>> publishedCatalog() async =>
      Map<String, dynamic>.from((await _admin({'action': 'catalog'})) as Map? ?? {});

  Future<int> publish(Map<String, Object?> manifest, String note) async {
    final data = await _admin({'action': 'publish', 'manifest': manifest, 'note': note}) as Map;
    return data['version'] as int;
  }

  Future<List<Map<String, dynamic>>> promotions() async => [
    for (final p in (await _admin({'action': 'promotions'})) as List) Map<String, dynamic>.from(p as Map),
  ];

  Future<void> savePromotion(Map<String, Object?> promotion) =>
      _admin({'action': 'promotion_save', 'promotion': promotion});

  Future<void> deletePromotion(String id) => _admin({'action': 'promotion_delete', 'id': id});
}

final studioServerProvider = Provider<StudioServer>((ref) => StudioServer());
