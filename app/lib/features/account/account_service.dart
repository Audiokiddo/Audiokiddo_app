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

/// The server's answer about a store purchase (verify-purchase).
enum ServerVerdict { verified, pending, rejected, retry }

/// The server's answer to an access code or an order number (redeem-code, claim-order).
enum ClaimStatus {
  /// Added to the account.
  ok,

  /// This account already has it.
  already,

  /// Code: unknown. Order: the number and e-mail do not belong together (never says which).
  notFound,
  expired,
  usedUp,

  /// The order is not paid (refunded, cancelled, still processing).
  notPaid,

  /// Another account already holds this order.
  taken,

  /// The order has nothing the app can unlock.
  nothing,
  rateLimited,

  /// The text cannot be a code or an order number.
  format,
}

/// The parent's referral code ("POLEC-7K3M9Q"), friends who used it and rewards earned.
class ReferralInfo {
  const ReferralInfo({required this.code, this.friends = 0, this.rewards = 0});

  final String code;
  final int friends;
  final int rewards;

  static ReferralInfo? fromJson(Object? json) {
    if (json is! Map || json['code'] is! String) return null;
    int count(Object? v) => v is int ? v : int.tryParse('$v') ?? 0;
    return ReferralInfo(
      code: json['code'] as String,
      friends: count(json['friends']),
      rewards: count(json['rewards']),
    );
  }
}

class ClaimResult {
  const ClaimResult(this.status, [this.scopes = const []]);

  final ClaimStatus status;

  /// What was added (`pack:detektyw`, `all_content`…); empty unless [status] is ok or already.
  final List<String> scopes;

  bool get granted => status == ClaimStatus.ok || status == ClaimStatus.already;

  /// Reads the Edge Function's `{status, scopes}`.
  factory ClaimResult.fromJson(Object? json) {
    if (json is! Map) return const ClaimResult(ClaimStatus.format);
    final status = switch (json['status']) {
      'ok' => ClaimStatus.ok,
      'already' => ClaimStatus.already,
      'invalid' || 'not_found' => ClaimStatus.notFound,
      'expired' => ClaimStatus.expired,
      'used_up' => ClaimStatus.usedUp,
      'not_paid' => ClaimStatus.notPaid,
      'taken' => ClaimStatus.taken,
      'nothing' => ClaimStatus.nothing,
      'rate_limited' => ClaimStatus.rateLimited,
      _ => ClaimStatus.format,
    };
    final scopes = json['scopes'];
    return ClaimResult(status, [if (scopes is List) ...scopes.whereType<String>()]);
  }
}

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

  /// Adds what an access code unlocks (gift, tester, promotion) to the account; a guest
  /// account is created when nobody is signed in.
  Future<ClaimResult> redeemCode(String code);

  /// The parent's referral code and how many friends used it (referral-code); a guest account
  /// is created when nobody is signed in.
  Future<ReferralInfo> referralInfo();

  /// Adds the packs of one shop order, proven by its number and billing e-mail, for buyers
  /// whose shop e-mail differs from the one they sign in with.
  Future<ClaimResult> claimOrder(String order, String email);

  /// Entitlements of the signed-in parent (empty when signed out). Throws when offline.
  Future<List<Entitlement>> entitlements();

  Future<void> signOut();

  /// Deletes the account and its entitlements on the server, then signs out locally.
  Future<void> deleteAccount();

  /// The server user a store purchase is tied to (appAccountToken / obfuscatedAccountId).
  /// Without a parent account an anonymous user is created: a random id, no personal data
  /// (ARCHITECTURE D4). Null when the server cannot be reached.
  Future<String?> purchaseAccountId();

  /// Sends a store purchase to verify-purchase ({platform, signedTransaction} on iOS,
  /// {platform, productId, purchaseToken} on Android).
  Future<ServerVerdict> verifyStorePurchase(Map<String, Object?> body);

  /// A short-lived link to one catalog file, or null (no access, offline).
  Future<Uri?> signedFileUrl(String path);
}

class SupabaseAccountService implements AccountService {
  SupabaseAccountService(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  // The anonymous purchase holder is not a parent account: the app shows "signed out".
  static AccountUser? _user(User? user) =>
      user == null || user.isAnonymous ? null : AccountUser(id: user.id, email: user.email ?? '');

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
  Future<ClaimResult> redeemCode(String code) => _claim('redeem-code', {'code': code});

  @override
  Future<ClaimResult> claimOrder(String order, String email) =>
      _claim('claim-order', {'order': order, 'email': email});

  @override
  Future<ReferralInfo> referralInfo() => _guard(() async {
    if (await purchaseAccountId() == null) throw const AccountException(AccountError.offline);
    final response = await _client.functions.invoke('referral-code');
    final info = ReferralInfo.fromJson(response.data);
    if (info == null) throw const AccountException(AccountError.server);
    return info;
  });

  Future<ClaimResult> _claim(String function, Map<String, Object?> body) => _guard(() async {
    // Anonymous guest account when nobody is signed in: access waits there until sign-in.
    if (await purchaseAccountId() == null) throw const AccountException(AccountError.offline);
    final response = await _client.functions.invoke(function, body: body);
    return ClaimResult.fromJson(response.data);
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

  @override
  Future<String?> purchaseAccountId() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.id;
    try {
      return (await _auth.signInAnonymously()).user?.id;
    } on Exception {
      return null; // offline, or anonymous sign-ins not enabled yet: the purchase waits
    }
  }

  @override
  Future<ServerVerdict> verifyStorePurchase(Map<String, Object?> body) async {
    if (await purchaseAccountId() == null) return ServerVerdict.retry;
    try {
      final response = await _client.functions.invoke('verify-purchase', body: body);
      final data = response.data;
      return data is Map && data['status'] == 'pending' ? ServerVerdict.pending : ServerVerdict.verified;
    } on FunctionException catch (e) {
      // 422: the store says this purchase is not valid for us; anything else: try again later.
      return e.status == 422 ? ServerVerdict.rejected : ServerVerdict.retry;
    } on Exception {
      return ServerVerdict.retry;
    }
  }

  @override
  Future<Uri?> signedFileUrl(String path) async {
    try {
      final response = await _client.functions.invoke('download-url', body: {'path': path});
      final url = response.data is Map ? (response.data as Map)['url'] : null;
      return url is String ? Uri.tryParse(url) : null;
    } on Exception {
      return null;
    }
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
  Future<ClaimResult> redeemCode(String code) async => throw const AccountException(AccountError.server);

  @override
  Future<ClaimResult> claimOrder(String order, String email) async =>
      throw const AccountException(AccountError.server);

  @override
  Future<ReferralInfo> referralInfo() async => throw const AccountException(AccountError.notConfigured);

  @override
  Future<List<Entitlement>> entitlements() async => const [];

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<String?> purchaseAccountId() async => null;

  @override
  Future<ServerVerdict> verifyStorePurchase(Map<String, Object?> body) async => ServerVerdict.retry;

  @override
  Future<Uri?> signedFileUrl(String path) async => null;
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
