import 'dart:async';
import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';
import '../downloads/download_providers.dart';
import '../player/playback_controller.dart';
import '../player/player_providers.dart';

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
  const GameUiState({this.phase = GamePhase.idle, this.itemId, this.title, this.listeningFor});

  final GamePhase phase;
  final String? itemId;
  final String? title;
  final InputKind? listeningFor;

  bool get active => phase != GamePhase.idle && phase != GamePhase.finished && phase != GamePhase.failed;
}

/// Inputs available on this device right now. The microphone arrives after the Etap 4
/// device tests; until then games run their no-microphone variant (ARCHITECTURE §10.5).
const microphoneInputs = {InputKind.clap, InputKind.voiceActivity, InputKind.speechKeywords};

/// Runs one interactive game: turns [ScriptRunner] commands into audio, timers and input.
class GameController extends Notifier<GameUiState> with WidgetsBindingObserver {
  ScriptRunner? _runner;
  ContentItem? _item;
  int _generation = 0;
  Completer<EngineEvent>? _input;
  bool _foreground = true;

  GameAudio get _audio => ref.read(gameAudioProvider);

  @override
  GameUiState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _generation++;
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
    final saved = resume ? await loadGameSnapshot(ref.read(databaseProvider), item) : null;
    if (!resume) await clearGameSnapshot(ref.read(databaseProvider), item.id);
    final runner = _runner = ScriptRunner(
      script,
      resumeFrom: saved,
      unavailable: {
        FallbackReason.noMicrophone, // until the microphone is enabled after device tests
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
          await clearGameSnapshot(ref.read(databaseProvider), item.id);
          ref.invalidate(gameResumeProvider(item));
          state = GameUiState(phase: GamePhase.finished, itemId: item.id, title: item.title);
          return;
        }
        command = runner.next(event);
      }
    } on Exception catch (e) {
      debugPrint('game ${item.id} failed: $e');
      if (generation == _generation) {
        state = GameUiState(phase: GamePhase.failed, itemId: item.id, title: item.title);
      }
    }
  }

  /// Leaves the game (long press on the game screen).
  Future<void> stop() async {
    _generation++;
    _input?.complete(const InputTimedOut());
    _input = null;
    await _audio.stop();
    state = const GameUiState();
  }

  /// Touch anywhere while a tap input is open.
  void tap() {
    if (state.listeningFor == InputKind.tapAnywhere) _completeInput(const InputDetected());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _runner?.setAvailability(FallbackReason.screenLocked, available: _foreground);
    // Touch cannot reach a locked phone: switch the open input to its fallback at once.
    if (!_foreground && this.state.listeningFor == InputKind.tapAnywhere) {
      _completeInput(const InputFailed(FallbackReason.screenLocked));
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
      case Listen(:final input, :final window):
        if (microphoneInputs.contains(input)) return const InputFailed(FallbackReason.noMicrophone);
        if (input != InputKind.tapAnywhere || !_foreground) {
          return const InputFailed(FallbackReason.screenLocked);
        }
        _set(GamePhase.listening, listeningFor: input);
        await _audio.startLoop(media, silenceUri);
        final completer = _input = Completer<EngineEvent>();
        unawaited(
          _pausableDelay(window, generation).then((done) {
            if (done) _completeInput(const InputTimedOut());
          }),
        );
        final event = await completer.future;
        await _audio.stopLoop();
        return generation == _generation ? event : null;
      case Finish(:final asset):
        if (asset != null) await _audio.playSegment(media, await _uri(asset));
        return const SegmentFinished();
    }
  }

  void _completeInput(EngineEvent event) {
    final input = _input;
    _input = null;
    if (input != null && !input.isCompleted) input.complete(event);
  }

  void _set(GamePhase phase, {InputKind? listeningFor}) =>
      state = GameUiState(phase: phase, itemId: _item?.id, title: _item?.title, listeningFor: listeningFor);

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
