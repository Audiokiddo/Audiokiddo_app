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

  /// What the recogniser did lately (status, errors, what it heard), for the check screen.
  final log = ValueNotifier<List<String>>(const []);

  void _note(String line) {
    debugPrint('speech: $line');
    log.value = [...log.value.length > 40 ? log.value.sublist(log.value.length - 40) : log.value, line];
  }

  /// The language the recogniser uses, once ready.
  String? get locale => _locale;

  Future<bool> _init() async {
    if (_initialised) return _locale != null;
    final ok = await _speech.initialize(
      onStatus: (status) {
        _note('status: $status');
        if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
          // An error (no offline Polish, recogniser failure) arrives just after "done"; wait for
          // it so the game can switch to claps instead of hearing silence.
          final session = _session;
          Future<void>.delayed(const Duration(milliseconds: 400), () {
            if (_session == session) _finish();
          });
        }
      },
      onError: (SpeechRecognitionError e) {
        _note('błąd: ${e.errorMsg}${e.permanent ? ' (trwały)' : ''}');
        // "No match" and "speech timeout" only mean the child said nothing we know.
        _finish(e.permanent && !_quiet.contains(e.errorMsg) ? SpeechUnavailable(e.errorMsg) : null);
      },
    );
    _initialised = ok;
    _note(ok ? 'gotowy' : 'brak zgody albo rozpoznawania mowy');
    if (!ok) return false;
    final locales = await _speech.locales();
    _locale = locales
        .map((l) => l.localeId)
        .where((id) => id.toLowerCase().replaceAll('-', '_').startsWith('pl'))
        .firstOrNull;
    _note('język: ${_locale ?? 'brak polskiego'}');
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

  bool _stopRequested = false;

  @override
  Future<void> listen({
    required Duration window,
    required List<String> vocabulary,
    required void Function(List<String> transcripts) onHeard,
  }) async {
    if (!await ready()) throw const SpeechUnavailable('not ready');
    _stopRequested = false;
    final deadline = DateTime.now().add(window);
    // The recogniser ends a session after a pause; a child who is still thinking gets a new
    // one, until the whole answer window is used up.
    while (!_stopRequested) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining < const Duration(milliseconds: 800)) break;
      final session = _session = Completer<void>();
      final started = DateTime.now();
      var heardAnything = false;
      try {
        await _speech.listen(
          onResult: (r) {
            final heard = {r.recognizedWords, for (final a in r.alternates) a.recognizedWords}.toList();
            heardAnything = heardAnything || heard.any((h) => h.trim().isNotEmpty);
            _note('słyszę: ${heard.join(' | ')}${r.finalResult ? ' (koniec)' : ''}');
            onHeard(heard);
          },
          listenOptions: SpeechListenOptions(
            localeId: _locale,
            listenFor: remaining,
            // Short: a final result comes soon after the child stops talking.
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            // Never leaves the phone; a phone without offline Polish fails and the game falls back.
            onDevice: true,
            listenMode: ListenMode.confirmation,
            cancelOnError: true,
            autoPunctuation: false,
            contextualPhrases: vocabulary,
          ),
        );
      } on SpeechUnavailable {
        rethrow;
      } on Object catch (e) {
        _note('nie udało się zacząć słuchać: $e');
        _finish();
        throw SpeechUnavailable('listen_failed: $e');
      }
      await session.future;
      if (_stopRequested) break;
      // A recogniser that stops at once without hearing anything is not working (seen with
      // error 300 when offline recognition cannot start): let the game ask for claps.
      if (!heardAnything && DateTime.now().difference(started) < const Duration(milliseconds: 1200)) {
        _note('rozpoznawanie skończyło się od razu, bez słów');
        throw const SpeechUnavailable('stopped_at_once');
      }
      _note('słucham dalej');
    }
  }

  void _finish([SpeechUnavailable? error]) {
    final session = _session;
    _session = null;
    if (session == null || session.isCompleted) return;
    error == null ? session.complete() : session.completeError(error);
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;
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
