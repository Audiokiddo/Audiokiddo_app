import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/kiddo_voice.dart';
import '../parent_voice/parent_voice.dart';
import '../player/playback_controller.dart';
import '../player/player_providers.dart';

/// One step of a guided session (trip, bedtime).
sealed class SessionStep {
  const SessionStep();
}

/// A recording from the catalog, played in the normal player (lock screen, headphones).
class ItemStep extends SessionStep {
  const ItemStep(this.item);

  final ContentItem item;
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

enum SessionKind { trip, bedtime }

/// Kiddo lines between trip activities, in turn.
const windowLines = ['window_1', 'window_2', 'window_3'];

/// Activities for a car ride of [minutes]: travel-friendly first, what is downloaded first
/// (tunnels, no signal), songs every few games, a "look out of the window" break about
/// every quarter of an hour. Interactive games are left out: nobody should reach for the
/// phone while driving.
List<SessionStep> buildTrip(
  Catalog catalog, {
  required int minutes,
  required int age,
  required bool Function(ContentItem) canPlay,
  Set<String> downloaded = const {},
}) {
  final candidates = [
    for (final i in catalog.items)
      if (i.kind != ContentKind.interactiveGame && i.ageMin <= age && canPlay(i) && i.audio.isNotEmpty) i,
  ];
  double score(ContentItem i) =>
      (i.situations.contains(Situation.podroz) ? 4 : 0) +
      (downloaded.contains(i.id) ? 3 : 0) +
      (i.durationSec <= 10 * 60 ? 1 : 0);
  final games = [
    for (final i in candidates)
      if (i.kind != ContentKind.song) i,
  ]..sort((a, b) => score(b).compareTo(score(a)));
  final songs = [
    for (final i in candidates)
      if (i.kind == ContentKind.song) i,
  ]..sort((a, b) => score(b).compareTo(score(a)));

  final steps = <SessionStep>[const LineStep('trip_start')];
  final target = minutes * 60;
  var total = 0;
  var sinceBreak = 0;
  var breaks = 0;
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
  steps
    ..add(const LineStep('trip_end'))
    ..add(const ParentStep(ParentClip.praise));
  return steps;
}

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
    if (lullabies.isNotEmpty) ItemStep(lullabies.first),
    const ParentStep(ParentClip.goodnight, fallbackLine: 'goodnight'),
  ];
}

/// Plays the steps; separated so the sequence logic is testable without audio.
abstract interface class SessionAudio {
  /// Plays [item] from the start; completes when it ends or is stopped.
  Future<void> playItem(ContentItem item);

  Future<void> sayLine(String line);

  Future<void> playClip(String path);

  Future<void> stop();
}

class AppSessionAudio implements SessionAudio {
  AppSessionAudio(this._ref);

  final Ref _ref;

  @override
  Future<void> playItem(ContentItem item) async {
    final handler = _ref.read(audioHandlerProvider);
    await _ref.read(playbackControllerProvider).start(item, album: 'AudioKiddo', fromStart: true);
    // Wait until this item actually runs, then until it is over (or stopped).
    await handler.playbackState
        .firstWhere((s) => s.processingState == AudioProcessingState.ready)
        .timeout(const Duration(seconds: 30), onTimeout: () => handler.playbackState.value);
    await handler.playbackState.firstWhere(
      (s) =>
          s.processingState == AudioProcessingState.completed ||
          s.processingState == AudioProcessingState.idle,
    );
  }

  @override
  Future<void> sayLine(String line) => _ref.read(kiddoVoiceProvider).say(line);

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

@immutable
class SessionState {
  const SessionState({this.kind, this.steps = const [], this.index = 0, this.running = false, this.childId});

  final SessionKind? kind;
  final List<SessionStep> steps;
  final int index;
  final bool running;
  final String? childId;

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

  @override
  SessionState build() {
    ref.onDispose(() => _generation++);
    return const SessionState();
  }

  Future<void> start(SessionKind kind, List<SessionStep> steps, {String? childId}) async {
    final generation = ++_generation;
    await ref.read(sessionAudioProvider).stop();
    state = SessionState(kind: kind, steps: steps, running: true, childId: childId);
    final clips = childId == null
        ? const <ParentClip, String>{}
        : await ref.read(parentVoiceStoreProvider).clips(childId);
    for (var i = 0; i < steps.length; i++) {
      if (generation != _generation) return;
      state = SessionState(kind: kind, steps: steps, index: i, running: true, childId: childId);
      _skip = false;
      await _play(steps[i], clips, generation);
    }
    if (generation == _generation) {
      state = SessionState(kind: kind, steps: steps, index: steps.length, childId: childId);
    }
  }

  Future<void> _play(SessionStep step, Map<ParentClip, String> clips, int generation) async {
    final audio = ref.read(sessionAudioProvider);
    switch (step) {
      case ItemStep(:final item):
        await audio.playItem(item);
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

  /// Moves on to the next step.
  Future<void> skip() async {
    _skip = true;
    // Stopping what plays ends the current step; the loop then starts the next one.
    if (state.current != null) await ref.read(sessionAudioProvider).stop();
  }

  Future<void> stop() async {
    _generation++;
    await ref.read(sessionAudioProvider).stop();
    state = const SessionState();
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);
