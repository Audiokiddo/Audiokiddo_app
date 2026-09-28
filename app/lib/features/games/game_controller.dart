import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';
import '../downloads/download_providers.dart';
import '../player/playback_controller.dart';
import '../player/player_providers.dart';
import 'microphone.dart';
import '../family/family.dart';
import '../parent_voice/parent_voice.dart';

/// Audio operations a game needs; implemented by AkAudioHandler, faked in tests.
abstract interface class GameAudio {
  Future<bool> playSegment(MediaItem media, Uri source);
  Future<void> startLoop(MediaItem media, Uri source);
  Future<void> stopLoop();
  Future<void> stop();
  bool get isPlaying;
}

/// Tests shrink game waits; 1.0 in the app.
final gameTimeScaleProvider = Provider<double>((ref) => 1.0);

final gameAudioProvider = Provider<GameAudio>((ref) => ref.watch(audioHandlerProvider));

/// Kept alive during waits when a step has no looped bed (see AkAudioHandler.startLoop).
final silenceUri = Uri.parse('asset:///assets/audio/silence_1s.m4a');

enum GamePhase { idle, playing, waiting, listening, finished, failed }

@immutable
class GameUiState {
  const GameUiState({
    this.phase = GamePhase.idle,
    this.itemId,
    this.title,
    this.listening = const {},
    this.answers = 0,
  });

  final GamePhase phase;

  /// Answers heard or touched so far; the screen celebrates each new one.
  final int answers;
  final String? itemId;
  final String? title;

  /// Inputs the game is waiting for right now (empty unless [phase] is listening).
  final Set<InputKind> listening;

  bool get tapToAnswer => listening.contains(InputKind.tapAnywhere);
  bool get listensToSound =>
      listening.contains(InputKind.clap) || listening.contains(InputKind.voiceActivity);

  bool get active => phase != GamePhase.idle && phase != GamePhase.finished && phase != GamePhase.failed;
}

const _soundInputs = {InputKind.clap, InputKind.voiceActivity};

/// Runs one interactive game: turns [ScriptRunner] commands into audio, timers and input.
class GameController extends Notifier<GameUiState> with WidgetsBindingObserver {
  ScriptRunner? _runner;
  ContentItem? _item;
  int _generation = 0;
  Completer<EngineEvent>? _input;
  bool _foreground = true;

  // Microphone: open for the whole game when the parent enabled it (iOS may not start it
  // from the background), but samples are looked at only while the child may answer.
  StreamSubscription<List<double>>? _mic;
  SoundDetector? _detector;
  Set<InputKind> _listening = const {};
  int _minClaps = 1;

  GameAudio get _audio => ref.read(gameAudioProvider);

  bool get _micOn => _mic != null;

  /// Android stops delivering microphone audio to backgrounded apps without a microphone
  /// foreground service (to be decided after device tests), so answers by sound pause there.
  bool get _micUsable => _micOn && (_foreground || !Platform.isAndroid);

  @override
  GameUiState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _generation++;
      unawaited(_stopMicrophone());
    });
    return const GameUiState();
  }

  /// Starts [item]; with [resume] it continues from the last saved instruction when the
  /// saved state belongs to the same version of the game.
  Future<void> start(ContentItem item, {bool resume = false}) async {
    final script = item.script;
    if (script == null) return;
    final generation = ++_generation;
    _item = item;
    _answers = 0;
    final startedAt = DateTime.now();
    final saved = resume ? await loadGameSnapshot(ref.read(databaseProvider), item) : null;
    if (!resume) await clearGameSnapshot(ref.read(databaseProvider), item.id);
    await _startMicrophone();
    final runner = _runner = ScriptRunner(
      script,
      resumeFrom: saved,
      unavailable: {
        if (!_micUsable) FallbackReason.noMicrophone,
        if (!_foreground) FallbackReason.screenLocked,
      },
    );
    state = GameUiState(phase: GamePhase.playing, itemId: item.id, title: item.title);
    try {
      var command = runner.start();
      while (generation == _generation) {
        final event = await _execute(command, generation);
        if (event == null || generation != _generation) return; // stopped or replaced
        if (command is Finish) {
          await _stopMicrophone();
          // Games that keep a `score` variable report correct answers to the parent.
          await ref
              .read(familyProvider.notifier)
              .record(
                itemId: item.id,
                seconds: DateTime.now().difference(startedAt).inSeconds,
                answers: _answers,
                correct: script.variables.containsKey('score') ? runner.variables['score'] : null,
              );
          await clearGameSnapshot(ref.read(databaseProvider), item.id);
          ref.invalidate(gameResumeProvider(item));
          state = GameUiState(phase: GamePhase.finished, itemId: item.id, title: item.title);
          await _praise(generation);
          return;
        }
        command = runner.next(event);
      }
    } on Exception catch (e) {
      debugPrint('game ${item.id} failed: $e');
      await _stopMicrophone();
      if (generation == _generation) {
        state = GameUiState(phase: GamePhase.failed, itemId: item.id, title: item.title);
      }
    }
  }

  /// "Brawo!" in the parent's own voice after a finished game, when they recorded one.
  Future<void> _praise(int generation) async {
    final child = ref.read(familyProvider).value?.active;
    if (child == null) return;
    final store = ref.read(parentVoiceStoreProvider);
    final clip = (await store.clips(child.id))[ParentClip.praise];
    if (clip != null && generation == _generation) await store.play(clip);
  }

  /// Leaves the game (long press on the game screen).
  Future<void> stop() async {
    _generation++;
    await ref.read(parentVoiceStoreProvider).stopPlayback();
    _input?.complete(const InputTimedOut());
    _input = null;
    await _stopMicrophone();
    await _audio.stop();
    state = const GameUiState();
  }

  /// Touch anywhere while a tap answer is possible.
  void tap() {
    if (_listening.contains(InputKind.tapAnywhere)) {
      _completeInput(const InputDetected(kind: InputKind.tapAnywhere));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _runner?.setAvailability(FallbackReason.screenLocked, available: _foreground);
    _runner?.setAvailability(FallbackReason.noMicrophone, available: _micUsable);
    if (_listening.isEmpty || _foreground) return;
    // Touch cannot reach a locked phone (nor sound a backgrounded Android app): keep what
    // still works, or switch the open input to its fallback at once.
    final still = _usable(_listening);
    if (still.isEmpty) {
      _completeInput(InputFailed(_whyUnusable(_listening)));
    } else {
      _listening = still;
      _set(GamePhase.listening, listening: still);
    }
  }

  Future<EngineEvent?> _execute(EngineCommand command, int generation) async {
    final item = _item!;
    final media = MediaItem(id: '$gameMediaPrefix${item.id}', title: item.title, album: 'AudioKiddo');
    switch (command) {
      case PlaySegment(:final asset):
        _set(GamePhase.playing);
        // Save at every instruction: after any interruption the child hears it again.
        await ref
            .read(databaseProvider)
            .writeValue(_snapshotKey(item.id), jsonEncode(_runner!.snapshot().toJson()));
        final completed = await _audio.playSegment(media, await _uri(asset));
        return completed ? const SegmentFinished() : null;
      case WaitFor(:final duration, :final loopAsset):
        _set(GamePhase.waiting);
        await _audio.startLoop(media, loopAsset == null ? silenceUri : await _uri(loopAsset));
        final done = await _pausableDelay(duration, generation);
        await _audio.stopLoop();
        return done ? const WaitElapsed() : null;
      case Listen(:final input, :final window, :final minCount):
        return _listen({input}, window, generation, media, minClaps: minCount ?? 1);
      case ListenForChoice(:final inputs, :final window):
        return _listen(inputs, window, generation, media);
      case Finish(:final asset):
        if (asset != null) await _audio.playSegment(media, await _uri(asset));
        return const SegmentFinished();
    }
  }

  Set<InputKind> _usable(Set<InputKind> inputs) => {
    for (final kind in inputs)
      if ((kind == InputKind.tapAnywhere && _foreground) || (_soundInputs.contains(kind) && _micUsable)) kind,
  };

  FallbackReason _whyUnusable(Set<InputKind> inputs) => inputs.any(_soundInputs.contains) && !_micUsable
      ? FallbackReason.noMicrophone
      : FallbackReason.screenLocked;

  Future<EngineEvent?> _listen(
    Set<InputKind> inputs,
    Duration window,
    int generation,
    MediaItem media, {
    int minClaps = 1,
  }) async {
    final usable = _usable(inputs);
    if (usable.isEmpty) return InputFailed(_whyUnusable(inputs));
    // Ready for an answer before anyone can hear the prompt to give one.
    final completer = _input = Completer<EngineEvent>();
    _detector?.resetCounts();
    _minClaps = minClaps;
    _listening = usable;
    _set(GamePhase.listening, listening: usable);
    await _audio.startLoop(media, silenceUri);
    unawaited(
      _pausableDelay(window, generation).then((done) {
        if (!done) return;
        // Counted claps short of the target still reach the script (e.g. "you clapped twice").
        final claps = _detector?.claps ?? 0;
        _completeInput(
          claps > 0 && _listening.contains(InputKind.clap)
              ? InputDetected(count: claps, kind: InputKind.clap)
              : const InputTimedOut(),
        );
      }),
    );
    final event = await completer.future;
    await _audio.stopLoop();
    return generation == _generation ? event : null;
  }

  Future<void> _startMicrophone() async {
    await _stopMicrophone();
    final bool enabled;
    try {
      enabled = await ref.read(microphoneSettingsProvider.future);
    } on Exception {
      return;
    }
    if (!enabled) return;
    try {
      final samples = await ref.read(microphoneInputProvider).start();
      _detector = SoundDetector(sampleRate: micSampleRate);
      _mic = samples.listen(_onSamples, onError: (Object _) => _onMicrophoneLost());
    } on Exception catch (e) {
      debugPrint('microphone unavailable: $e');
    }
  }

  Future<void> _stopMicrophone() async {
    final mic = _mic;
    _mic = null;
    _detector = null;
    _listening = const {};
    if (mic == null) return;
    await mic.cancel();
    await ref.read(microphoneInputProvider).stop();
  }

  void _onMicrophoneLost() {
    unawaited(_stopMicrophone());
    _runner?.setAvailability(FallbackReason.noMicrophone, available: false);
    _completeInput(const InputFailed(FallbackReason.inputError));
  }

  /// Samples outside an answer window are dropped unread.
  void _onSamples(List<double> samples) {
    final detector = _detector;
    if (detector == null || _listening.isEmpty) return;
    detector.add(samples);
    if (_listening.contains(InputKind.clap) && detector.claps >= _minClaps) {
      _completeInput(InputDetected(count: detector.claps, kind: InputKind.clap));
    } else if (_listening.contains(InputKind.voiceActivity) && detector.voiceDetected) {
      _completeInput(const InputDetected(kind: InputKind.voiceActivity));
    }
  }

  void _completeInput(EngineEvent event) {
    _listening = const {};
    final input = _input;
    _input = null;
    if (input != null && !input.isCompleted) {
      input.complete(event);
      if (event is InputDetected) {
        _answers++;
        _set(state.phase);
      }
    }
  }

  int _answers = 0;

  void _set(GamePhase phase, {Set<InputKind> listening = const {}}) => state = GameUiState(
    phase: phase,
    itemId: _item?.id,
    title: _item?.title,
    listening: listening,
    answers: _answers,
  );

  /// Counts only while audio plays, so pausing from the lock screen pauses the game too.
  Future<bool> _pausableDelay(Duration duration, int generation) async {
    const tick = Duration(milliseconds: 100);
    final scaled = duration * ref.read(gameTimeScaleProvider);
    var elapsed = Duration.zero;
    while (elapsed < scaled) {
      await Future<void>.delayed(tick);
      if (generation != _generation) return false;
      if (_audio.isPlaying) elapsed += tick;
    }
    return true;
  }

  Future<Uri> _uri(String assetKey) async {
    final asset = _item!.script!.assets[assetKey]!;
    final local = await ref.read(downloadManagerProvider).localFilePath(asset);
    return local != null ? Uri.file(local) : ref.read(contentUrlResolverProvider).urlFor(asset);
  }
}

String _snapshotKey(String itemId) => 'game_resume:$itemId';

/// Saved position of an interrupted game, if it matches the current version of the script.
Future<RunnerSnapshot?> loadGameSnapshot(AppDatabase db, ContentItem item) async {
  final raw = await db.readValue(_snapshotKey(item.id));
  final script = item.script;
  if (raw == null || script == null) return null;
  try {
    final snapshot = RunnerSnapshot.fromJson(jsonDecode(raw) as Map<String, Object?>);
    return snapshot.matches(script) && script.steps.containsKey(snapshot.stepId) ? snapshot : null;
  } on Object {
    return null; // corrupt or from an older format: start fresh
  }
}

Future<void> clearGameSnapshot(AppDatabase db, String itemId) => db.deleteValue(_snapshotKey(itemId));

final gameResumeProvider = FutureProvider.autoDispose.family<bool, ContentItem>(
  (ref, item) async => await loadGameSnapshot(ref.watch(databaseProvider), item) != null,
);

final gameControllerProvider = NotifierProvider<GameController, GameUiState>(GameController.new);
