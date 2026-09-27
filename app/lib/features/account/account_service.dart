import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend/backend_config.dart';

/// The signed-in parent. Only the e-mail is kept; there is no child data on the server.
class AccountUser {
  const AccountUser({required this.id, required this.email});

  final String id;
  final String email;
}

/// Why an account action failed, mapped to a message for the parent.
/// [canceled]: the parent closed the Apple/Google sheet; nothing to show.
/// [notConfigured]: the sign-in method is not set up for this build yet.
enum AccountError { invalidEmail, tooManyRequests, wrongCode, offline, server, canceled, notConfigured }

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

  /// Sign in with Apple is offered on iOS (App Store guideline 4.8 when Google is offered).
  bool get appleAvailable;

  Future<void> signInWithApple();

  Future<void> signInWithGoogle();

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
  bool get appleAvailable => Platform.isIOS;

  @override
  Future<void> signInWithApple() => _guard(() async {
    // Apple gets the hash, Supabase the raw value, so a stolen token cannot be replayed.
    final rawNonce = _auth.generateRawNonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
    );
    final idToken = credential.identityToken;
    if (idToken == null) throw const AccountException(AccountError.server);
    await _auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: idToken, nonce: rawNonce);
  });

  bool _googleReady = false;

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    if (!BackendConfig.googleConfigured) throw const AccountException(AccountError.notConfigured);
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        clientId: Platform.isIOS ? BackendConfig.googleIosClientId : null,
        serverClientId: BackendConfig.googleWebClientId,
      );
      _googleReady = true;
    }
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AccountException(AccountError.server);
    await _auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);
  });

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
  Future<void> signOut() async {
    await _auth.signOut(scope: SignOutScope.local);
    // Next time the parent picks the Google account again instead of being signed in silently.
    if (_googleReady) await GoogleSignIn.instance.signOut();
  }

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
    } on SignInWithAppleAuthorizationException catch (e) {
      throw AccountException(
        e.code == AuthorizationErrorCode.canceled ? AccountError.canceled : AccountError.server,
      );
    } on SignInWithAppleNotSupportedException {
      throw const AccountException(AccountError.notConfigured);
    } on GoogleSignInException catch (e) {
      throw AccountException(switch (e.code) {
        GoogleSignInExceptionCode.canceled => AccountError.canceled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError => AccountError.notConfigured,
        _ => AccountError.server,
      });
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
  bool get appleAvailable => false;

  @override
  Future<void> signInWithApple() async => throw const AccountException(AccountError.notConfigured);

  @override
  Future<void> signInWithGoogle() async => throw const AccountException(AccountError.notConfigured);

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
