import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/widgets/item_art.dart';
import '../downloads/download_providers.dart';
import '../personal/personal_repository.dart';
import 'audio_handler.dart';
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
    ]);
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (handler.playbackState.value.playing) unawaited(_save());
    });
  }

  final Ref _ref;
  final _subscriptions = <StreamSubscription<void>>[];
  late final Timer _ticker;

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
    if (completed) {
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
