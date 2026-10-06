import 'dart:io';

/// Public connection settings of the AudioKiddo server (Supabase, region EU / Frankfurt).
///
/// The publishable key is meant to ship in apps: it only identifies the project, and every
/// table is protected by RLS (supabase/migrations). Secret keys live only in Edge Function
/// secrets. Another project (e.g. staging) can be used with
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...`.
abstract final class BackendConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ypdxofcwewwdyoelamgy.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_GfJcAHEtFYs5IvlKrNZBVw_0WeAneGQ',
  );

  /// Google Sign-In OAuth clients (Google Cloud → Credentials). Until they exist the Google
  /// button explains that it is not available yet: `--dart-define=GOOGLE_WEB_CLIENT_ID=...`
  /// and, for iOS, `GOOGLE_IOS_CLIENT_ID` (plus its reversed ID as a URL scheme in Info.plist).
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// Whether the access-code field is shown. Codes unlock content outside the stores, which Apple
  /// may not accept in an iOS release (guideline 3.1.1); the order number and e-mail ways stay
  /// either way (3.1.3(b)). Build such a release with `--dart-define=REDEEM_CODES=false`.
  static const redeemCodes = bool.fromEnvironment('REDEEM_CODES', defaultValue: true);

  /// The App Store build for the Kids Category (tool/release_build.sh ios): the number question
  /// also in the parent area, no access codes, no Google sign-in, no talk of other prices.
  static const kidsStoreBuild = bool.fromEnvironment('PARENT_GATE_EVERYWHERE');

  static bool get googleConfigured =>
      googleWebClientId.isNotEmpty && (!Platform.isIOS || googleIosClientId.isNotEmpty);
}
