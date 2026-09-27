import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in parent. Only the e-mail is kept; there is no child data on the server.
class AccountUser {
  const AccountUser({required this.id, required this.email});

  final String id;
  final String email;
}

/// Why an account action failed, mapped to a message for the parent.
enum AccountError { invalidEmail, tooManyRequests, wrongCode, offline, server }

class AccountException implements Exception {
  const AccountException(this.error);

  final AccountError error;

  @override
  String toString() => 'AccountException($error)';
}

/// Parent account on the AudioKiddo server (ARCHITECTURE §4, §7a). Optional: the app works
/// without it; it is needed to unlock packs bought on the shop and to move access between
/// phones.
abstract interface class AccountService {
  AccountUser? get current;

  /// Emits whenever the parent signs in or out.
  Stream<AccountUser?> get changes;

  /// Sends a one-time code to [email]. Creates the account on first use.
  Future<void> sendCode(String email);

  Future<void> verifyCode(String email, String code);

  /// Pulls the parent's shop orders into their account; returns how many products were
  /// assigned.
  Future<int> syncWebPurchases();

  /// Entitlements of the signed-in parent (empty when signed out). Throws when offline.
  Future<List<Entitlement>> entitlements();

  Future<void> signOut();

  /// Deletes the account and its entitlements on the server, then signs out locally.
  Future<void> deleteAccount();
}

class SupabaseAccountService implements AccountService {
  SupabaseAccountService(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  static AccountUser? _user(User? user) =>
      user == null ? null : AccountUser(id: user.id, email: user.email ?? '');

  @override
  AccountUser? get current => _user(_auth.currentUser);

  @override
  Stream<AccountUser?> get changes => _auth.onAuthStateChange.map((s) => _user(s.session?.user));

  @override
  Future<void> sendCode(String email) =>
      _guard(() => _auth.signInWithOtp(email: email.trim().toLowerCase(), shouldCreateUser: true));

  @override
  Future<void> verifyCode(String email, String code) => _guard(
    () => _auth.verifyOTP(type: OtpType.email, email: email.trim().toLowerCase(), token: code.trim()),
  );

  @override
  Future<int> syncWebPurchases() => _guard(() async {
    final response = await _client.functions.invoke('sync-web-purchases');
    final data = response.data;
    return data is Map && data['claimed'] is int ? data['claimed'] as int : 0;
  });

  @override
  Future<List<Entitlement>> entitlements() async {
    if (_auth.currentUser == null) return const [];
    final rows = await _guard<List<Map<String, dynamic>>>(
      () async => await _client.from('entitlements').select('scope, status, source, valid_until'),
    );
    return [for (final row in rows) ?entitlementFromRow(row)];
  }

  @override
  Future<void> signOut() => _auth.signOut(scope: SignOutScope.local);

  @override
  Future<void> deleteAccount() async {
    await _guard(() => _client.functions.invoke('delete-account'));
    await signOut();
  }

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthRetryableFetchException {
      throw const AccountException(AccountError.offline);
    } on AuthException catch (e) {
      throw AccountException(_authError(e));
    } on FunctionException catch (e) {
      throw AccountException(e.status == 429 ? AccountError.tooManyRequests : AccountError.server);
    } on PostgrestException {
      throw const AccountException(AccountError.server);
    } on AccountException {
      rethrow;
    } on Exception {
      // Socket and TLS errors surface as plain exceptions from the HTTP client.
      throw const AccountException(AccountError.offline);
    }
  }

  static AccountError _authError(AuthException e) => switch (e.code) {
    'email_address_invalid' || 'validation_failed' => AccountError.invalidEmail,
    'over_email_send_rate_limit' || 'over_request_rate_limit' => AccountError.tooManyRequests,
    'otp_expired' || 'otp_disabled' => AccountError.wrongCode,
    _ when e.statusCode == '429' => AccountError.tooManyRequests,
    _ when e.statusCode == '403' || e.statusCode == '401' => AccountError.wrongCode,
    _ => AccountError.server,
  };
}

/// Used until main() connects the server, and in tests: nobody is signed in.
class SignedOutAccountService implements AccountService {
  const SignedOutAccountService();

  @override
  AccountUser? get current => null;

  @override
  Stream<AccountUser?> get changes => const Stream.empty();

  @override
  Future<void> sendCode(String email) async => throw const AccountException(AccountError.server);

  @override
  Future<void> verifyCode(String email, String code) async =>
      throw const AccountException(AccountError.server);

  @override
  Future<int> syncWebPurchases() async => 0;

  @override
  Future<List<Entitlement>> entitlements() async => const [];

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

/// Overridden in main() with [SupabaseAccountService].
final accountServiceProvider = Provider<AccountService>((ref) => const SignedOutAccountService());

/// The signed-in parent, or null.
final accountUserProvider = StreamProvider<AccountUser?>((ref) async* {
  final service = ref.watch(accountServiceProvider);
  yield service.current;
  yield* service.changes;
});

/// Server row (public.entitlements) → core model; unknown values are skipped, not fatal.
Entitlement? entitlementFromRow(Map<String, dynamic> row) {
  final status = switch (row['status']) {
    'active' => EntitlementStatus.active,
    'grace' => EntitlementStatus.grace,
    'billing_retry' => EntitlementStatus.billingRetry,
    'expired' => EntitlementStatus.expired,
    'revoked' => EntitlementStatus.revoked,
    'refunded' => EntitlementStatus.refunded,
    _ => null,
  };
  final source = switch (row['source']) {
    'app_store' => EntitlementSource.appStore,
    'google_play' => EntitlementSource.googlePlay,
    'woocommerce' => EntitlementSource.woocommerce,
    'manual' => EntitlementSource.manual,
    _ => null,
  };
  final scope = row['scope'];
  final validUntil = row['valid_until'];
  if (status == null || source == null || scope is! String) return null;
  return Entitlement(
    scope: scope,
    status: status,
    source: source,
    validUntil: validUntil is String ? DateTime.parse(validUntil) : null,
  );
}
