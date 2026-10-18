import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/kiddo_voice.dart';
import '../catalog/catalog_providers.dart' show clockProvider;
import '../family/family.dart';
import '../parent_voice/parent_voice.dart';
import '../player/playback_controller.dart';
import '../player/player_providers.dart';
import 'plan.dart';

/// One step of a guided session (trip, bedtime).
sealed class SessionStep {
  const SessionStep();
}

/// A recording from the catalog, played in the normal player (lock screen, headphones).
class ItemStep extends SessionStep {
  const ItemStep(this.item, {this.fadeOut = Duration.zero});

  final ContentItem item;

  /// Fades out over the end of the item (the last lullaby of the evening).
  final Duration fadeOut;
}

/// One of Kiddo's bundled lines, then [pauseAfter] of quiet (time to look out of the window).
class LineStep extends SessionStep {
  const LineStep(this.line, {this.pauseAfter = Duration.zero});

  final String line;
  final Duration pauseAfter;
}

/// A parent's recorded message, when there is one ([fallbackLine] otherwise).
class ParentStep extends SessionStep {
  const ParentStep(this.clip, {this.fallbackLine});

  final ParentClip clip;
  final String? fallbackLine;
}

enum SessionKind { trip, bedtime, dinner }

/// Lines Szop’en opens with the child's name (when he knows it).
const namedLines = ['trip_start', 'trip_end', 'bedtime_start', 'goodnight'];

/// His hello opening a moment of the day (Mój dzień plans), with the child's name.
bool isMomentHello(String line) =>
    line.contains('_start_') || (line.startsWith('c_') && !line.startsWith('c_rano_buty'));

/// Szop'en's lines at the start of a ride; one per trip, so he does not repeat himself.
const tripStartLines = [
  'trip_start',
  'trip_start_2',
  'trip_start_3',
  'trip_start_4',
  'trip_start_5',
  'trip_start_6',
];

/// Kiddo lines between trip activities, in turn.
const windowLines = ['window_1', 'window_2', 'window_3', 'window_4', 'window_5', 'window_6'];

/// Szop'en's goodbye when the ride ends.
const tripEndLines = ['trip_end', 'trip_end_2', 'trip_end_3'];

/// Activities for a car ride of [minutes]: travel-friendly first, what is downloaded first
/// (tunnels, no signal), songs every few games, a "look out of the window" break about
/// every quarter of an hour. Interactive games are left out: nobody should reach for the
/// phone while driving. [variant] picks which of Szop'en's lines this ride gets (start, the
/// first window break, goodbye); the same variant always gives the same ride.
List<SessionStep> buildTrip(
  Catalog catalog, {
  required int minutes,
  required int age,
  required bool Function(ContentItem) canPlay,
  Set<String> downloaded = const {},
  int variant = 0,
  String? startLine,
}) {
  final candidates = [
    for (final i in catalog.items)
      if (i.kind != ContentKind.interactiveGame && i.ageMin <= age && canPlay(i) && i.audio.isNotEmpty) i,
  ];
  double score(ContentItem i) =>
      // On the road what is on the phone comes first (tunnels), then plays made for the car.
      (downloaded.contains(i.id) ? 7 : 0) +
      (i.moments.contains('auto') ? 6 : 0) +
      (i.situations.contains(Situation.podroz) ? 4 : 0) +
      (i.durationSec <= 10 * 60 ? 1 : 0);
  final games = [
    for (final i in candidates)
      if (i.kind != ContentKind.song) i,
  ]..sort((a, b) => score(b).compareTo(score(a)));
  final songs = [
    for (final i in candidates)
      if (i.kind == ContentKind.song) i,
  ]..sort((a, b) => score(b).compareTo(score(a)));

  final steps = <SessionStep>[LineStep(startLine ?? tripStartLines[variant % tripStartLines.length])];
  final target = minutes * 60;
  var total = 0;
  var sinceBreak = 0;
  var breaks = variant;
  var gi = 0;
  var si = 0;
  var sinceSong = 0;
  while (total < target - 120 && (gi < games.length || si < songs.length)) {
    final wantSong = sinceSong >= 2 && si < songs.length;
    final ContentItem item;
    if (wantSong || gi >= games.length) {
      item = songs[si++];
      sinceSong = 0;
    } else {
      item = games[gi++];
      sinceSong++;
    }
    steps.add(ItemStep(item));
    total += item.durationSec;
    sinceBreak += item.durationSec;
    if (sinceBreak >= 15 * 60 && total < target - 300) {
      steps.add(
        LineStep(windowLines[breaks++ % windowLines.length], pauseAfter: const Duration(seconds: 40)),
      );
      total += 50;
      sinceBreak = 0;
    }
  }
  // Use the time fully: what is still missing is filled with the play that fits it best.
  final used = {
    for (final s in steps)
      if (s is ItemStep) s.item.id,
  };
  var gap = target - total;
  for (var k = 0; k < 4 && gap > 60; k++) {
    final pool = [
      for (final i in [...games, ...songs])
        if (!used.contains(i.id) && i.durationSec <= gap + 60) i,
    ];
    if (pool.isEmpty) break;
    final best = pool.reduce((a, b) => (gap - a.durationSec).abs() <= (gap - b.durationSec).abs() ? a : b);
    steps.add(ItemStep(best));
    used.add(best.id);
    total += best.durationSec;
    gap = target - total;
  }
  // Too few plays for the whole ride (a family without the subscription): the ones already in
  // the plan play again, each after a window break, at most twice more. Children like "jeszcze raz".
  final firstPass = [
    for (final s in steps)
      if (s is ItemStep) s.item,
  ];
  for (var round = 0; round < 2 && gap > 5 * 60 && firstPass.isNotEmpty; round++) {
    for (final item in firstPass) {
      if (gap <= 120) break;
      if (item.durationSec > gap + 180) continue;
      steps
        ..add(LineStep(windowLines[breaks++ % windowLines.length], pauseAfter: const Duration(seconds: 40)))
        ..add(ItemStep(item));
      total += 50 + item.durationSec;
      gap = target - total;
    }
  }
  steps
    ..add(LineStep(tripEndLines[variant % tripEndLines.length]))
    ..add(const ParentStep(ParentClip.praise));
  return steps;
}

/// How long the evening lullaby takes to fade away.
const bedtimeFade = Duration(seconds: 25);

/// The evening ritual behind one "Dobranoc" button: three calm breaths, one quiet
/// activity, one lullaby, goodnight in the parent's voice (or Kiddo's).
List<SessionStep> buildBedtime(
  Catalog catalog, {
  required int age,
  required bool Function(ContentItem) canPlay,
}) {
  final playable = [
    for (final i in catalog.items)
      if (i.ageMin <= age && canPlay(i) && i.audio.isNotEmpty && i.kind != ContentKind.interactiveGame) i,
  ];
  int calmness(ContentItem i) => (i.situations.contains(Situation.przedSnem) ? 10 : 0) - i.durationSec ~/ 120;
  final quiet = [
    for (final i in playable)
      if (i.kind != ContentKind.song) i,
  ]..sort((a, b) => calmness(b).compareTo(calmness(a)));
  final lullabies =
      [
        for (final i in playable)
          if (i.kind == ContentKind.song) i,
      ]..sort((a, b) {
        int lull(ContentItem i) => (i.title.toLowerCase().contains('kołys') ? 5 : 0) + calmness(i);
        return lull(b).compareTo(lull(a));
      });
  return [
    const LineStep('bedtime_start'),
    if (quiet.isNotEmpty) ItemStep(quiet.first),
    if (lullabies.isNotEmpty) ItemStep(lullabies.first, fadeOut: bedtimeFade),
    const ParentStep(ParentClip.goodnight, fallbackLine: 'goodnight'),
  ];
}

/// Plays the steps; separated so the sequence logic is testable without audio.
abstract interface class SessionAudio {
  /// Plays [item] from the start, fading out over its last [fadeOut]; completes when it
  /// ends or is stopped.
  /// [album]: what the lock screen says it is part of ("Poranek z Szop’enem · 2 z 4").
  Future<void> playItem(ContentItem item, {Duration fadeOut = Duration.zero, String? album});

  Future<void> sayLine(String line);

  Future<void> playClip(String path);

  /// Ends only what plays now so the session moves on to its next step. Unlike [stop] it
  /// leaves the audio service running: the next recording takes over the same player.
  Future<void> skipCurrent();

  Future<void> stop();
}

class AppSessionAudio implements SessionAudio {
  AppSessionAudio(this._ref);

  final Ref _ref;

  /// Completed by [skipCurrent] while an item plays.
  Completer<void>? _skipItem;

  @override
  Future<void> playItem(ContentItem item, {Duration fadeOut = Duration.zero, String? album}) async {
    final handler = _ref.read(audioHandlerProvider);
    final skip = _skipItem = Completer<void>();
    await _ref
        .read(playbackControllerProvider)
        .start(item, album: album ?? 'audiokiddo', fromStart: true, greet: false);
    if (fadeOut > Duration.zero) handler.fadeOutAtEnd(fadeOut);
    // Wait until this item actually runs, then until it is over (or stopped, or skipped).
    final over = handler.playbackState
        .firstWhere((s) => s.processingState == AudioProcessingState.ready)
        .timeout(const Duration(seconds: 30), onTimeout: () => handler.playbackState.value)
        .then(
          (_) => handler.playbackState.firstWhere(
            (s) =>
                s.processingState == AudioProcessingState.completed ||
                s.processingState == AudioProcessingState.idle,
          ),
        );
    await Future.any<Object?>([over, skip.future]);
    if (identical(_skipItem, skip)) _skipItem = null;
    // Paused here, before this call returns, so it can never land on the next recording.
    if (skip.isCompleted) await handler.pause();
  }

  @override
  Future<void> skipCurrent() async {
    // Both voices are asked to stop before anything else can start (the next step may be a line).
    await Future.wait([
      _ref.read(kiddoVoiceProvider).stop(),
      _ref.read(parentVoiceStoreProvider).stopPlayback(),
    ]);
    final skip = _skipItem;
    if (skip != null && !skip.isCompleted) skip.complete();
  }

  @override
  Future<void> sayLine(String line) async {
    final voice = _ref.read(kiddoVoiceProvider);
    // Szop’en greets the child by name at the start and end of a ride, at bedtime and when he
    // opens a moment of the day.
    if (namedLines.any(line.startsWith) || isMomentHello(line)) {
      await voice.sayName(_ref.read(familyProvider).value?.active?.name);
    }
    await voice.say(line);
  }

  @override
  Future<void> playClip(String path) => _ref.read(parentVoiceStoreProvider).play(path);

  @override
  Future<void> stop() async {
    await _ref.read(kiddoVoiceProvider).stop();
    await _ref.read(parentVoiceStoreProvider).stopPlayback();
    await _ref.read(audioHandlerProvider).stop();
  }
}

final sessionAudioProvider = Provider<SessionAudio>((ref) => AppSessionAudio(ref));

/// Tests shrink pauses; 1.0 in the app.
final sessionTimeScaleProvider = Provider<double>((ref) => 1.0);

/// Quiet before the next recording of a session starts by itself, so a parent can hold it.
const autoNextDelay = Duration(seconds: 5);

@immutable
class SessionState {
  const SessionState({
    this.kind,
    this.steps = const [],
    this.index = 0,
    this.running = false,
    this.childId,
    this.countdown,
    this.held = false,
    this.startedAt,
    this.endedAt,
    this.error,
    this.label,
  });

  /// The moment it is for ("Poranek z Szop’enem"), on the screen and the lock screen.
  final String? label;

  /// The same state with another list of steps (the parent edited the plan).
  SessionState withSteps(List<SessionStep> next) => SessionState(
    kind: kind,
    steps: next,
    index: index,
    running: running,
    childId: childId,
    countdown: countdown,
    held: held,
    startedAt: startedAt,
    endedAt: endedAt,
    error: error,
    label: label,
  );

  final SessionKind? kind;
  final List<SessionStep> steps;
  final int index;
  final bool running;
  final String? childId;

  /// Seconds until [current] starts by itself; null while something plays.
  final int? countdown;

  /// The parent held the countdown; [current] waits until they resume.
  final bool held;

  /// When the session began and ended (the trip's dry summary: real minutes only).
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? error;

  /// Whole minutes from start to end, once finished.
  int? get minutesTaken =>
      startedAt == null || endedAt == null ? null : endedAt!.difference(startedAt!).inMinutes;

  SessionStep? get current => index < steps.length ? steps[index] : null;
  SessionStep? get next => index + 1 < steps.length ? steps[index + 1] : null;
  bool get finished => kind != null && !running && index >= steps.length;

  /// Seconds of catalog audio still ahead (for "about 25 min left").
  int get secondsLeft => [
    for (final s in steps.skip(index))
      if (s is ItemStep) s.item.durationSec,
  ].fold(0, (a, b) => a + b);
}

class SessionController extends Notifier<SessionState> {
  int _generation = 0;
  bool _skip = false;
  bool _held = false;

  String? _label;

  /// The steps being played. The parent may edit the ones ahead while it runs, so the loop
  /// reads this list again at every step instead of keeping its own copy.
  List<SessionStep> _steps = const [];

  @override
  SessionState build() {
    ref.onDispose(() => _generation++);
    return const SessionState();
  }

  Future<void> start(SessionKind kind, List<SessionStep> steps, {String? childId, String? label}) async {
    _label = label;
    final generation = ++_generation;
    _held = false;
    await ref.read(sessionAudioProvider).stop();
    final startedAt = ref.read(clockProvider)();
    _steps = List.of(steps);
    state = SessionState(kind: kind, steps: List.of(_steps), running: true, childId: childId, label: _label);
    final clips = childId == null
        ? const <ParentClip, String>{}
        : await ref.read(parentVoiceStoreProvider).clips(childId);
    var playedItem = false;
    for (var i = 0; i < _steps.length; i++) {
      if (generation != _generation) return;
      final playing = SessionState(
        kind: kind,
        steps: List.of(_steps),
        index: i,
        running: true,
        childId: childId,
        label: _label,
      );
      // The parent tapped "next" during the last step: they chose to move on, so no countdown.
      final chosen = _skip;
      _skip = false;
      // After the first recording, each next one that comes by itself waits a moment so a
      // parent can hold it (in the car nobody wants a recording to start unannounced).
      if (_steps[i] is ItemStep && playedItem && !chosen) {
        await _countdown(playing, generation);
        if (generation != _generation) return;
        _skip = false;
        // The parent may have dropped the waiting play meanwhile; what is now at [i] plays.
        if (i >= _steps.length) break;
      }
      final step = _steps[i];
      state = SessionState(kind: kind, steps: List.of(_steps), index: i, running: true, childId: childId, label: _label);
      if (step is ItemStep) playedItem = true;
      try {
        await _play(step, clips, generation);
      } on Exception {
        if (generation != _generation || !ref.mounted) return;
        // A network/access failure ends the run visibly, never as an unhandled future
        // with a screen that still claims to be playing.
        state = SessionState(
          kind: kind,
          steps: List.of(_steps),
          index: i,
          childId: childId,
          label: _label,
          error:
              'Nie udało się odtworzyć zabawy. Sprawdź połączenie i dostęp, a potem uruchom plan ponownie.',
        );
        return;
      }
    }
    if (generation == _generation) {
      state = SessionState(
        kind: kind,
        steps: List.of(_steps),
        index: _steps.length,
        childId: childId,
        label: _label,
        startedAt: startedAt,
        endedAt: ref.read(clockProvider)(),
      );
    }
  }

  Future<void> _play(SessionStep step, Map<ParentClip, String> clips, int generation) async {
    final audio = ref.read(sessionAudioProvider);
    switch (step) {
      case ItemStep(:final item, :final fadeOut):
        final plays = [for (final s in _steps) if (s is ItemStep) s];
        final k = plays.indexWhere((s) => identical(s, step)) + 1;
        await audio.playItem(
          item,
          fadeOut: fadeOut,
          album: _label == null || k == 0 ? null : '$_label · $k z ${plays.length}',
        );
      case LineStep(:final line, :final pauseAfter):
        await audio.sayLine(line);
        await _pause(pauseAfter, generation);
      case ParentStep(:final clip, :final fallbackLine):
        final path = clips[clip];
        if (path != null) {
          await audio.playClip(path);
        } else if (fallbackLine != null) {
          await audio.sayLine(fallbackLine);
        }
    }
  }

  Future<void> _pause(Duration d, int generation) async {
    final scaled = d * ref.read(sessionTimeScaleProvider);
    var waited = Duration.zero;
    const tick = Duration(milliseconds: 100);
    while (waited < scaled && generation == _generation && !_skip) {
      await Future<void>.delayed(tick);
      waited += tick;
    }
  }

  /// Counts [autoNextDelay] down before [playing] starts; waits while held, ends early on skip.
  Future<void> _countdown(SessionState playing, int generation) async {
    const step = Duration(milliseconds: 100);
    final tick = step * ref.read(sessionTimeScaleProvider);
    var left = autoNextDelay;
    while (generation == _generation && !_skip && (_held || left > Duration.zero)) {
      final seconds = (left.inMilliseconds / 1000).ceil();
      if (state.countdown != seconds || state.held != _held || state.index != playing.index) {
        state = SessionState(
          kind: playing.kind,
          steps: List.of(_steps),
          index: playing.index,
          running: true,
          childId: playing.childId,
          countdown: seconds,
          held: _held,
        );
      }
      await Future<void>.delayed(tick);
      if (!_held) left -= step;
    }
    _held = false;
  }

  /// Keeps the next recording from starting by itself until [resume].
  void hold() {
    if (state.countdown == null) return;
    _held = true;
    state = SessionState(
      kind: state.kind,
      steps: List.of(_steps),
      index: state.index,
      running: true,
      childId: state.childId,
      countdown: state.countdown,
      held: true,
    );
  }

  /// Starts the held recording now.
  void resume() {
    _held = false;
    _skip = true;
  }

  /// Moves on to the next step; during the countdown, starts the next recording now.
  Future<void> skip() async {
    _skip = true;
    // Ending what plays ends the current step; the loop then starts the next one. Not stop():
    // that shuts the audio service down just as the next recording starts on it.
    if (state.current != null && state.countdown == null) await ref.read(sessionAudioProvider).skipCurrent();
  }

  /// First step the parent may still change: the one about to start (while its countdown
  /// runs) or the one after the one that plays now.
  int get editFrom => state.countdown != null ? state.index : state.index + 1;

  void _edited(List<SessionStep> next) {
    if (!state.running) return;
    _steps = next;
    state = state.withSteps(List.of(next));
  }

  /// Plan edits while a ride or dinner runs; positions count the plays still ahead.
  void removePlay(int pos) => _edited(planRemove(_steps, pos, from: editFrom));
  void reorderPlays(int oldPos, int newPos) => _edited(planReorder(_steps, oldPos, newPos, from: editFrom));

  /// Resolve the original play after the chooser closes; playback may have advanced.
  /// [nth] tells apart a play that comes again later in a ride (0 = its first time ahead).
  bool replacePlay(String itemId, ContentItem item, {int nth = 0}) {
    if (!state.running) return false;
    final pos = nthPlayPos(playsFrom(_steps, editFrom), itemId, nth);
    if (pos < 0) return false;
    _edited(planReplace(_steps, pos, item, from: editFrom));
    return true;
  }

  void addPlays(List<ContentItem> items) {
    if (!state.running || items.isEmpty) return;
    // During a closing line the last play is behind the cursor. Insert ahead of
    // that cursor, otherwise the added audio is skipped and the line repeats.
    final last = _steps.lastIndexWhere((s) => s is ItemStep);
    final at = (last + 1).clamp(editFrom, _steps.length);
    _edited([..._steps]..insertAll(at, [for (final i in items) ItemStep(i)]));
  }

  Future<void> stop() async {
    _generation++;
    _held = false;
    await ref.read(sessionAudioProvider).stop();
    state = const SessionState();
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);

/// "Obiad bez wołania": [items] one after another, nothing else.
List<SessionStep> buildDinner(List<ContentItem> items) => [for (final i in items) ItemStep(i)];
