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
}
