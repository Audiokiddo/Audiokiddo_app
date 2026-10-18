import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session.dart';
import '../discovery/queue_controller.dart';
import '../../core/audio/kiddo_voice.dart';
import '../insights/sitting.dart';
import '../catalog/widgets/item_art.dart';
import '../../core/storage/storage_providers.dart';
import '../downloads/download_providers.dart';
import '../personal/personal_repository.dart';
import 'audio_handler.dart';
import '../insights/events.dart';
import 'player_providers.dart';
import '../family/family.dart';
import '../catalog/catalog_providers.dart';

/// Thrown when an item is neither downloaded nor reachable.
class PlaybackAccessUnavailable implements Exception {
  const PlaybackAccessUnavailable();
}

class PlaybackSourceUnavailable implements Exception {
  const PlaybackSourceUnavailable();
}

/// Starts items (local file first, stream as fallback) and records listening progress.
class PlaybackController {
  PlaybackController(this._ref) {
    final handler = _ref.read(audioHandlerProvider);
    _subscriptions.addAll([
      handler.playbackState
          .map((s) => (s.playing, s.processingState))
          .distinct()
          .listen((s) => unawaited(_save(completed: s.$2 == AudioProcessingState.completed))),
      // Real listening time: the clock runs only while sound is actually playing.
      handler.playbackState.map((s) => s.playing).distinct().listen((playing) {
        final open = _open;
        if (open == null) return;
        if (playing) {
          open.active.start();
        } else {
          open.active.stop();
          _ref.read(sittingClockProvider).touch();
        }
      }),
      // A looped play went round once: heard to the end, then it starts again.
      handler.loopedToStart.listen((_) => unawaited(_save(completed: true))),
      // The play was left for another one or the session ended: where the family stopped.
      handler.mediaItem.map((m) => m?.id).distinct().listen((id) {
        if (_open != null && _open!.id != id) _closeOpen();
      }),
    ]);
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!handler.playbackState.value.playing) return;
      unawaited(_save());
      _showTimeLeft();
    });
  }

  /// The lock screen, Control Center and the notification say how long is left
  /// ("Do końca 12 min"), refreshed when the minute changes.
  void _showTimeLeft() {
    final media = _handler.mediaItem.value;
    final duration = _handler.duration;
    if (media == null || duration == null || media.id.startsWith(gameMediaPrefix)) return;
    final minutes = ((duration - _handler.position).inSeconds / 60).ceil().clamp(0, 999);
    final line = minutes <= 1 ? 'Zaraz koniec' : 'Do końca $minutes min';
    if (media.artist == line) return;
    _handler.mediaItem.add(media.copyWith(artist: line));
  }

  final Ref _ref;
  final _subscriptions = <StreamSubscription<void>>[];
  late final Timer _ticker;

  /// The play heard to the end most recently, and when.
  (String, DateTime)? _lastCompleted;

  /// The play now on, until it ends or is left (for play_exit).
  _OpenPlay? _open;

  /// One sitting = plays and games close together (see [SittingClock]).
  static const sittingGap = SittingClock.gap;

  /// Props every play event carries for the real-minutes measurement. No data about the child
  /// (not even the age): the store declarations say the app collects none.
  Map<String, Object?> _measure([_OpenPlay? open]) => {
    'sitting': ?_ref.read(sittingClockProvider).id,
    if (open != null) 'active_seconds': open.active.elapsed.inSeconds,
  };

  /// Reports a play left before its end: the second and share heard (the drop-off map).
  void _closeOpen() {
    final open = _open;
    _open = null;
    open?.active.stop();
    if (open != null) _ref.read(sittingClockProvider).touch();
    if (open == null || open.completed) return;
    final total = open.duration?.inSeconds ?? 0;
    _ref
        .read(eventSinkProvider)
        .track(
          AppEvent.playExit,
          itemId: open.id,
          props: {
            'exit_second': open.position.inSeconds,
            if (total > 0) 'pct': (100 * open.position.inSeconds / total).clamp(0, 100).round(),
            'play_number': open.playNumber,
            ..._measure(open),
          },
        );
  }

  AkAudioHandler get _handler => _ref.read(audioHandlerProvider);

  Future<void> start(ContentItem item, {required String album, bool fromStart = false}) async {
    _checkAccess(item);
    await _save(); // keep progress of whatever was playing before
    final local = await _ref.read(downloadManagerProvider).localAudioPath(item);
    final Uri source;
    if (local != null) {
      source = Uri.file(local);
    } else if (item.audio.isNotEmpty) {
      source = await _ref.read(contentUrlResolverProvider).urlFor(item.audio.first);
    } else {
      throw const PlaybackSourceUnavailable();
    }
    final progress = await _ref.read(personalRepositoryProvider).progress(item.id);
    // For the statistics: a replay (heard to the end before) and moving straight on to the next
    // play after finishing one.
    final last = _lastCompleted;
    final next = last != null && last.$1 != item.id && DateTime.now().difference(last.$2).inMinutes < 10;
    final count = await countPlayStart(_ref.read(databaseProvider), item.id);
    _closeOpen();
    _ref.read(sittingClockProvider).begin();
    _ref
        .read(eventSinkProvider)
        .track(
          AppEvent.playStart,
          itemId: item.id,
          props: {
            'free': item.isFree,
            'pack': ?item.packId,
            'duration_total': item.durationSec,
            if (progress?.completed ?? false) 'replay': true,
            if (next) 'next': true,
            if (next) 'previous_item': last.$1,
            ...count.props,
            ..._measure(),
          },
        );
    _checkAccess(item); // Resolving the source may have crossed the access deadline.
    _open = _OpenPlay(item.id, count.number);
    await _handler.playItem(
      MediaItem(
        id: item.id,
        title: item.title,
        album: album,
        artUri: await coverArtUri(item),
        extras: {timingSensitiveExtra: item.timingSensitive},
      ),
      source,
      start: fromStart ? Duration.zero : resumePosition(progress),
    );
  }

  void _checkAccess(ContentItem item) {
    _ref.invalidate(currentTimeProvider);
    _ref.invalidate(leaseStateProvider);
    if (!_ref.read(canPlayProvider(item))) throw const PlaybackAccessUnavailable();
  }

  Future<void> _save({bool completed = false}) async {
    final media = _handler.mediaItem.value;
    final duration = _handler.duration;
    if (media == null || duration == null || duration == Duration.zero) return;
    if (media.id.startsWith(gameMediaPrefix)) return; // games have no resume point
    final position = completed ? duration : _handler.position;
    final open = _open;
    if (open != null && open.id == media.id) {
      open
        ..position = position
        ..duration = duration;
    }
    if (completed) {
      _lastCompleted = (media.id, DateTime.now());
      _ref.read(sittingClockProvider).touch();
      if (open != null && open.id == media.id) {
        open.completed = true;
        open.active.stop();
      }
      _ref
          .read(eventSinkProvider)
          .track(
            AppEvent.playComplete,
            itemId: media.id,
            props: {
              'duration_listened': duration.inSeconds,
              'play_number': ?open?.playNumber,
              ..._measure(open != null && open.id == media.id ? open : null),
            },
          );
      // Counts towards the listening child's plan and progress.
      unawaited(_ref.read(familyProvider.notifier).record(itemId: media.id, seconds: duration.inSeconds));
      // The play ends so everyone hears it (report 2026-10-17: a play that ends by itself):
      // a short chime, unless a queue or a trip or bedtime plan carries on, or it loops.
      if (!_handler.looping && !_ref.read(queueRunnerProvider).running && !_ref.read(sessionProvider).running) {
        _ref.read(kiddoVoiceProvider).effect('chime');
      }
    }
    await _ref
        .read(personalRepositoryProvider)
        .saveProgress(
          media.id,
          position: position,
          duration: duration,
          completed: completed || duration - position < const Duration(seconds: 2),
        );
  }

  void dispose() {
    _ticker.cancel();
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
  }
}

class _OpenPlay {
  _OpenPlay(this.id, this.playNumber);

  final String id;
  final int playNumber;
  Duration position = Duration.zero;
  Duration? duration;
  bool completed = false;

  /// Time the sound was really on (pauses and stops excluded).
  final active = Stopwatch();
}

/// Media ids of game sessions start with this, so their segments are not saved as progress.
const gameMediaPrefix = 'game:';

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final controller = PlaybackController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

final sleepTimerProvider = StreamProvider<SleepTimer?>((ref) async* {
  final handler = ref.watch(audioHandlerProvider);
  yield handler.sleepTimer;
  yield* handler.sleepTimerStream;
});
