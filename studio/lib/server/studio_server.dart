import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  bool get signedIn => client.auth.currentUser != null;
  String? get email => client.auth.currentUser?.email;

  Future<void> sendCode(String email) =>
      client.auth.signInWithOtp(email: email.trim(), shouldCreateUser: false);

  Future<void> verify(String email, String code) =>
      client.auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.email);

  Future<void> signOut() => client.auth.signOut();

  Future<dynamic> _admin(Map<String, Object?> body) async {
    try {
      final response = await client.functions.invoke('admin', body: body);
      return response.data;
    } on FunctionException catch (e) {
      throw StudioServerException(switch (e.status) {
        401 => 'Zaloguj się ponownie.',
        403 => 'To konto nie jest administratorem (tabela admins).',
        400 => 'Serwer odrzucił dane: ${e.details}',
        _ => 'Serwer nie odpowiada. Spróbuj za chwilę.',
      });
    }
  }

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
