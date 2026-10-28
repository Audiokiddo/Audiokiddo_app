import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/widgets/item_art.dart';
import '../../core/storage/storage_providers.dart';
import '../downloads/download_providers.dart';
import '../personal/personal_repository.dart';
import 'audio_handler.dart';
import '../insights/events.dart';
import 'player_providers.dart';
import '../family/family.dart';

/// Thrown when an item is neither downloaded nor reachable.
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
      // The play was left for another one or the session ended: where the family stopped.
      handler.mediaItem.map((m) => m?.id).distinct().listen((id) {
        if (_open != null && _open!.id != id) _closeOpen();
      }),
    ]);
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (handler.playbackState.value.playing) unawaited(_save());
    });
  }

  final Ref _ref;
  final _subscriptions = <StreamSubscription<void>>[];
  late final Timer _ticker;

  /// The play heard to the end most recently, and when.
  (String, DateTime)? _lastCompleted;

  /// The play now on, until it ends or is left (for play_exit).
  _OpenPlay? _open;

  /// Reports a play left before its end: the second and share heard (the drop-off map).
  void _closeOpen() {
    final open = _open;
    _open = null;
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
          },
        );
  }

  AkAudioHandler get _handler => _ref.read(audioHandlerProvider);

  Future<void> start(ContentItem item, {required String album, bool fromStart = false}) async {
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
          },
        );
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
      if (open != null && open.id == media.id) open.completed = true;
      _ref
          .read(eventSinkProvider)
          .track(
            AppEvent.playComplete,
            itemId: media.id,
            props: {'duration_listened': duration.inSeconds, 'play_number': ?open?.playNumber},
          );
      // Counts towards the listening child's plan and progress.
      unawaited(_ref.read(familyProvider.notifier).record(itemId: media.id, seconds: duration.inSeconds));
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
