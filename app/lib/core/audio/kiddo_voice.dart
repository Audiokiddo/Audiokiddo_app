import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Kiddo's bundled voice lines and interface sounds (assets/audio/kiddo/). Separate from the
/// main player: they never show on the lock screen and never replace what the child listens to.
abstract interface class KiddoVoice {
  /// Plays a voice line; completes when it ends (or is stopped).
  Future<void> say(String line);

  /// "Hej, Zosia!" when Szop’en knows [name] (assets/audio/names/); false and silent when he
  /// does not, so the line that follows simply goes without a name.
  Future<bool> sayName(String? name);

  /// Plays a bundled recording by its full asset path (Szop’en's secrets); completes at its end.
  Future<void> sayAsset(String asset);

  /// Fire-and-forget effect over anything else (pop, chime, whoosh).
  void effect(String sound);

  Future<void> stop();
}

/// just_audio plays a bundled asset from a copy it extracts once into the temporary folder and
/// keeps reusing; that copy survives an app update, so a re-recorded line would still play the
/// old file. Called once at launch, before anything plays: the copies are made again from the
/// current bundle (a few small files).
Future<void> clearBundledAudioCopies() async {
  try {
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'just_audio_cache', 'assets'));
    if (dir.existsSync()) await dir.delete(recursive: true);
  } on Exception {
    // Worst case the old copy plays; never block the launch.
  }
}

class AssetKiddoVoice implements KiddoVoice {
  final _voice = AudioPlayer();
  final _effects = AudioPlayer();

  static String _asset(String name) => 'assets/audio/kiddo/$name.m4a';

  Future<Map<String, String>>? _names;

  /// Typed name ("zosia") → file ("zosia"), from tool/name_voice.py.
  Future<Map<String, String>> _nameIndex() => _names ??= () async {
    try {
      final json = jsonDecode(await rootBundle.loadString('assets/audio/names/index.json')) as Map<String, Object?>;
      return {for (final e in json.entries) e.key: e.value! as String};
    } on Exception {
      return const <String, String>{};
    }
  }();

  @override
  Future<void> sayAsset(String asset) async {
    try {
      await _playToEnd(asset);
    } on Exception {
      // decorative
    }
  }

  @override
  Future<bool> sayName(String? name) async {
    final file = nameClip(name, await _nameIndex());
    if (file == null) return false;
    try {
      await _playToEnd('assets/audio/names/$file.m4a');
      return true;
    } on Exception {
      return false;
    }
  }

  /// Plays [asset] and completes when it has ended. just_audio's play() returns at once while
  /// the player still counts as playing (it stays "playing" after the previous clip ended), so
  /// the player is stopped first; otherwise "Hej, Elena!" followed by a line let the next step
  /// (a play) start over Szop’en's voice.
  Future<void> _playToEnd(String asset) async {
    await _voice.stop();
    await _voice.setAsset(asset);
    await _voice.play();
  }

  @override
  Future<void> say(String line) async {
    try {
      await _playToEnd(_asset(line));
    } on Exception {
      // A missing voice must never block the app; the screen carries the same words.
    }
  }

  @override
  void effect(String sound) {
    unawaited(() async {
      try {
        await _effects.setAsset(_asset(sound));
        await _effects.play();
      } on Exception {
        // decorative only
      }
    }());
  }

  @override
  Future<void> stop() async {
    await _voice.stop();
    await _effects.stop();
  }

  Future<void> dispose() async {
    await _voice.dispose();
    await _effects.dispose();
  }
}

/// Tests (and anything that must stay quiet): lines "end" at once.
class SilentKiddoVoice implements KiddoVoice {
  const SilentKiddoVoice();

  @override
  Future<void> say(String line) async {}

  @override
  Future<bool> sayName(String? name) async => false;

  @override
  Future<void> sayAsset(String asset) async {}

  @override
  void effect(String sound) {}

  @override
  Future<void> stop() async {}
}

final kiddoVoiceProvider = Provider<KiddoVoice>((ref) {
  final voice = AssetKiddoVoice();
  ref.onDispose(voice.dispose);
  return voice;
});

/// The recorded greeting for a child's [name] as typed by the parent: the first word, trimmed,
/// in lower case ("Zosia", " zosia ", "Zosia Kowalska" all match "zosia"). Null when there is
/// no recording for it.
String? nameClip(String? name, Map<String, String> index) {
  final first = name?.trim().split(RegExp(r'\s+')).first.toLowerCase();
  if (first == null || first.isEmpty) return null;
  final exact = index[first];
  if (exact != null) return exact;
  // "Lucja" typed without Polish letters still finds "łucja".
  final plain = plainName(first);
  for (final e in index.entries) {
    if (plainName(e.key) == plain) return e.value;
  }
  return null;
}

/// The names Szop’en can say, as parents write them ("Zosia", "Łucja"), in Polish alphabetical
/// order, with the related forms of each ("zofia" → ["zosia"]): the list the child quiz offers.
typedef RecordedNames = ({List<String> names, Map<String, List<String>> related});

final recordedNamesProvider = FutureProvider<RecordedNames>((ref) async {
  try {
    final index = jsonDecode(await rootBundle.loadString('assets/audio/names/index.json')) as Map<String, Object?>;
    var related = const <String, List<String>>{};
    try {
      final groups = jsonDecode(await rootBundle.loadString('assets/audio/names/groups.json')) as Map<String, Object?>;
      related = {for (final e in groups.entries) e.key: (e.value! as List).cast<String>()};
    } on Exception {
      // Search works without the related forms.
    }
    return (names: [for (final n in index.keys.toList()..sort(comparePolish)) capitalizeName(n)], related: related);
  } on Exception {
    return (names: const <String>[], related: const <String, List<String>>{});
  }
});

String capitalizeName(String n) => n.isEmpty ? n : n[0].toUpperCase() + n.substring(1);

/// Polish alphabetical order (ą after a, ł after l…).
int comparePolish(String a, String b) {
  const order = 'aąbcćdeęfghijklłmnńoópqrsśtuvwxyzźż';
  for (var i = 0; i < a.length && i < b.length; i++) {
    final d = order.indexOf(a[i]) - order.indexOf(b[i]);
    if (d != 0) return d;
  }
  return a.length - b.length;
}

/// "Łucja" → "lucja": typing without Polish letters still finds the name.
String plainName(String s) {
  const from = 'ąćęłńóśźż';
  const to = 'acelnoszz';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i < 0 ? ch : to[i]);
  }
  return b.toString();
}

/// The names for what the parent typed: names starting with it first, then the usual short or
/// full forms of those ("Zofia" brings "Zosia"), then names that merely contain it.
List<String> searchNames(String query, RecordedNames recorded) {
  final q = plainName(query.trim());
  if (q.isEmpty) return recorded.names;
  final starts = [
    for (final n in recorded.names)
      if (plainName(n).startsWith(q)) n,
  ];
  final relatedLower = {for (final n in starts) ...?recorded.related[n.toLowerCase()]};
  final related = [
    for (final n in recorded.names)
      if (!starts.contains(n) && relatedLower.contains(n.toLowerCase())) n,
  ];
  final contains = [
    for (final n in recorded.names)
      if (q.length >= 2 && !starts.contains(n) && !related.contains(n) && plainName(n).contains(q)) n,
  ];
  return [...starts, ...related, ...contains];
}
