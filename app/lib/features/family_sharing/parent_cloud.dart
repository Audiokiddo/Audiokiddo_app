import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Who shares the family's access (supabase/migrations/…_family_letters_orders.sql).
enum FamilyRole { none, owner, member }

@immutable
class FamilyStatus {
  const FamilyStatus({this.role = FamilyRole.none, this.partner, this.canInvite = false, this.code, this.shared = true});

  factory FamilyStatus.fromJson(Map<String, dynamic> json) => FamilyStatus(
    role: switch (json['role']) {
      'owner' => FamilyRole.owner,
      'member' => FamilyRole.member,
      _ => FamilyRole.none,
    },
    partner: json['partner'] as String?,
    canInvite: json['can_invite'] == true,
    code: json['code'] as String?,
    shared: json['shared'] != false,
  );

  final FamilyRole role;

  /// The other parent's e-mail, half hidden ("ma•••@gmail.com").
  final String? partner;
  final bool canInvite;

  /// A code made earlier and still valid.
  final String? code;

  /// Whether the owner's plan covers a second parent right now.
  final bool shared;
}

/// Why the server refused, said for a parent.
class FamilyException implements Exception {
  const FamilyException(this.message);
  final String message;

  static FamilyException from(Object e) {
    final text = e is PostgrestException ? e.message : '$e';
    return FamilyException(switch (text) {
      'plan' => 'Drugi rodzic jest w planach dla 2 dzieci i dla 3–5 dzieci.',
      'code' => 'Ten kod nie działa albo wygasł. Poproś o nowy.',
      'full' => 'W tej rodzinie jest już drugi rodzic.',
      'self' => 'To Twój własny kod. Przekaż go drugiemu rodzicowi.',
      'linked' => 'To konto jest już połączone z inną rodziną. Najpierw się odłącz.',
      'member' => 'Korzystasz z abonamentu innego rodzica, więc nie możesz zapraszać.',
      _ => 'Nie udało się połączyć z serwerem. Spróbuj za chwilę.',
    });
  }
}

/// The parent's things kept on the server: the second parent, the letters from Szop’en and
/// which A/B tests are running.
abstract interface class ParentCloud {
  Future<FamilyStatus> familyStatus();
  Future<String> familyInvite();
  Future<void> familyJoin(String code);
  Future<void> familyLeave();
  Future<bool> lettersOn();
  Future<void> setLetters(bool on);

  /// Running tests: key → variants.
  Future<Map<String, List<String>>> experiments();
}

/// Tests and builds without a server: nothing shared, no letters, no tests.
class OfflineParentCloud implements ParentCloud {
  const OfflineParentCloud();

  @override
  Future<FamilyStatus> familyStatus() async => const FamilyStatus();
  @override
  Future<String> familyInvite() async => throw const FamilyException('Brak połączenia z serwerem.');
  @override
  Future<void> familyJoin(String code) async => throw const FamilyException('Brak połączenia z serwerem.');
  @override
  Future<void> familyLeave() async {}
  @override
  Future<bool> lettersOn() async => false;
  @override
  Future<void> setLetters(bool on) async {}
  @override
  Future<Map<String, List<String>>> experiments() async => const {};
}

class SupabaseParentCloud implements ParentCloud {
  SupabaseParentCloud(this._client);

  final SupabaseClient _client;

  Future<T> _call<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (e) {
      throw FamilyException.from(e);
    } on Object catch (e) {
      throw FamilyException.from(e);
    }
  }

  @override
  Future<FamilyStatus> familyStatus() => _call(() async {
    final data = await _client.rpc('family_status');
    return data is Map ? FamilyStatus.fromJson(Map<String, dynamic>.from(data)) : const FamilyStatus();
  });

  @override
  Future<String> familyInvite() =>
      _call(() async => '${(Map<String, dynamic>.from(await _client.rpc('family_invite') as Map))['code']}');

  @override
  Future<void> familyJoin(String code) => _call(() => _client.rpc('family_join', params: {'p_code': code.trim()}));

  @override
  Future<void> familyLeave() => _call(() => _client.rpc('family_leave'));

  @override
  Future<bool> lettersOn() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      final row = await _client.from('parent_letters').select('weekly').eq('user_id', user.id).maybeSingle();
      return row?['weekly'] == true;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> setLetters(bool on) => _call(() async {
    final user = _client.auth.currentUser;
    if (user == null) throw const FamilyException('Zaloguj się, żeby dostawać listy.');
    // Both kinds together: the weekly letter and the short one after a longer break.
    await _client.from('parent_letters').upsert({
      'user_id': user.id,
      'weekly': on,
      'missed': on,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  });

  @override
  Future<Map<String, List<String>>> experiments() async {
    final data = await _client.rpc('app_experiments');
    return parseExperiments(data);
  }
}

Map<String, List<String>> parseExperiments(Object? data) => {
  if (data is Map)
    for (final MapEntry(:key, :value) in data.entries)
      if (value is List && value.length >= 2) '$key': [for (final v in value) '$v'],
};

final parentCloudProvider = Provider<ParentCloud>((ref) => const OfflineParentCloud());

// A/B tests ---------------------------------------------------------------------------------

/// The variant this install sees in each running test: the same every time (a hash of the
/// install id and the test), spread evenly over the variants.
Map<String, String> assignVariants(String installId, Map<String, List<String>> tests) => {
  for (final MapEntry(:key, :value) in tests.entries) key: value[_fnv('$installId|$key') % value.length],
};

int _fnv(String text) {
  var hash = 0x811c9dc5;
  for (final unit in utf8.encode(text)) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// The running tests, fetched at start (at most [wait]; the last known ones otherwise, saved
/// on the phone), and this install's variants.
Future<Map<String, String>> loadVariants(
  ParentCloud cloud,
  String installId,
  Future<String?> Function() readCache,
  Future<void> Function(String) writeCache, {
  Duration wait = const Duration(milliseconds: 1500),
}) async {
  Map<String, List<String>> tests;
  try {
    tests = await cloud.experiments().timeout(wait);
    await writeCache(jsonEncode(tests));
  } on Object {
    try {
      tests = parseExperiments(jsonDecode(await readCache() ?? '{}'));
    } on Object {
      tests = const {};
    }
  }
  return assignVariants(installId, tests);
}

/// Variants of the running tests for this install (empty: everyone sees the usual).
final experimentsProvider = Provider<Map<String, String>>((ref) => const {});
