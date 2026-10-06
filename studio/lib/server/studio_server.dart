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

/// Studio's connection to the server: sign-in with an e-mail code and the admin function
/// (only accounts listed in public.admins may use it).
class StudioServer {
  StudioServer([SupabaseClient? client]) : client = client ?? SupabaseClient(_url, _key);

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
        400 => 'Serwer odrzucił dane: ${e.details}',
        409 => 'Ta propozycja jest już rozstrzygnięta. Odśwież widok.',
        412 =>
          function == 'coo' || function == 'ads'
              ? 'Brak klucza Claude API. Wpisz ANTHROPIC_API_KEY w Supabase → Edge Functions → Secrets.'
              : 'Brak klucza MailerLite. Wpisz MAILERLITE_API_KEY i MAILERLITE_FROM w Supabase → Edge Functions → Secrets.',
        502 =>
          function == 'coo' || function == 'ads'
              ? 'Agent nie odpowiedział poprawnie. Spróbuj ponownie za chwilę.'
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
        })
        as Map,
  );

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
