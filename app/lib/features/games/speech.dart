import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Spoken answers in games ("w lewo", "do zamku"). Recognition runs on the phone itself:
/// audio is never recorded, stored or sent, and a phone that cannot recognise Polish
/// offline simply plays the clap version of the question.
abstract interface class SpeechInput {
  /// Whether this kind of phone may answer with words at all (see [DeviceSpeech.platformAllowed]).
  bool get supported;

  /// Whether answers by words can be heard now, without asking for anything.
  Future<bool> ready();

  /// Shows the system prompt for speech recognition. Only behind the parental gate.
  Future<bool> requestPermission();

  /// Listens up to [window], reporting every transcript (partial ones too, with the
  /// recogniser's alternatives) to [onHeard]. Completes when listening ended; a failure of
  /// the recogniser itself throws [SpeechUnavailable].
  Future<void> listen({
    required Duration window,
    required List<String> vocabulary,
    required void Function(List<String> transcripts) onHeard,
  });

  Future<void> stop();
}

class SpeechUnavailable implements Exception {
  const SpeechUnavailable(this.reason);
  final String reason;

  @override
  String toString() => 'SpeechUnavailable($reason)';
}

class DeviceSpeech implements SpeechInput {
  final _speech = SpeechToText();
  String? _locale;
  bool _initialised = false;
  Completer<void>? _session;

  Future<bool> _init() async {
    if (_initialised) return _locale != null;
    final ok = await _speech.initialize(
      onStatus: (status) {
        if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
          _finish();
        }
      },
      onError: (SpeechRecognitionError e) {
        // "No match" and "speech timeout" only mean the child said nothing we know.
        _finish(e.permanent && !_quiet.contains(e.errorMsg) ? SpeechUnavailable(e.errorMsg) : null);
      },
    );
    _initialised = true;
    if (!ok) return false;
    final locales = await _speech.locales();
    _locale = locales
        .map((l) => l.localeId)
        .where((id) => id.toLowerCase().replaceAll('-', '_').startsWith('pl'))
        .firstOrNull;
    return _locale != null;
  }

  static const _quiet = {'error_no_match', 'error_speech_timeout', 'error_busy'};

  /// Android's recogniser falls back to Google's servers when offline Polish is missing
  /// (speech_to_text 7.5 below Android 13 and without an on-device model), which a kids' app
  /// must not do. Until a strictly on-device check is tested on real phones, Android games
  /// ask for claps instead of words.
  static bool get platformAllowed => Platform.isIOS;

  @override
  bool get supported => platformAllowed;

  @override
  Future<bool> ready() async {
    if (!platformAllowed || !await _speech.hasPermission) return false;
    try {
      return await _init();
    } on Object catch (e) {
      debugPrint('speech unavailable: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!platformAllowed) return false;
    try {
      return await _init();
    } on Object {
      return false;
    }
  }

  @override
  Future<void> listen({
    required Duration window,
    required List<String> vocabulary,
    required void Function(List<String> transcripts) onHeard,
  }) async {
    if (!await ready()) throw const SpeechUnavailable('not ready');
    final session = _session = Completer<void>();
    await _speech.listen(
      onResult: (r) => onHeard([for (final a in r.alternates) a.recognizedWords]),
      listenOptions: SpeechListenOptions(
        localeId: _locale,
        listenFor: window,
        pauseFor: window,
        // Never leaves the phone; a phone without offline Polish fails and the game falls back.
        onDevice: true,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        autoPunctuation: false,
        contextualPhrases: vocabulary,
      ),
    );
    await session.future;
  }

  void _finish([SpeechUnavailable? error]) {
    final session = _session;
    _session = null;
    if (session == null || session.isCompleted) return;
    error == null ? session.complete() : session.completeError(error);
  }

  @override
  Future<void> stop() async {
    final wasListening = _session != null || _speech.isListening;
    _finish();
    if (!wasListening) return;
    await _speech.cancel();
    // The recogniser deactivates the audio session it borrowed; the game keeps playing.
    if (Platform.isIOS) {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    }
  }
}

final speechInputProvider = Provider<SpeechInput>((ref) => DeviceSpeech());
