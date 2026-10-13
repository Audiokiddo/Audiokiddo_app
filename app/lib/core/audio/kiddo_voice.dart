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
  Future<bool> sayName(String? name) async {
    final file = nameClip(name, await _nameIndex());
    if (file == null) return false;
    try {
      await _voice.setAsset('assets/audio/names/$file.m4a');
      await _voice.play();
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> say(String line) async {
    try {
      await _voice.setAsset(_asset(line));
      await _voice.play();
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
  return index[first];
}
