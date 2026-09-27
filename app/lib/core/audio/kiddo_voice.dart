import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Kiddo's bundled voice lines and interface sounds (assets/audio/kiddo/). Separate from the
/// main player: they never show on the lock screen and never replace what the child listens to.
abstract interface class KiddoVoice {
  /// Plays a voice line; completes when it ends (or is stopped).
  Future<void> say(String line);

  /// Fire-and-forget effect over anything else (pop, chime, whoosh).
  void effect(String sound);

  Future<void> stop();
}

class AssetKiddoVoice implements KiddoVoice {
  final _voice = AudioPlayer();
  final _effects = AudioPlayer();

  static String _asset(String name) => 'assets/audio/kiddo/$name.m4a';

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
  void effect(String sound) {}

  @override
  Future<void> stop() async {}
}

final kiddoVoiceProvider = Provider<KiddoVoice>((ref) {
  final voice = AssetKiddoVoice();
  ref.onDispose(voice.dispose);
  return voice;
});
