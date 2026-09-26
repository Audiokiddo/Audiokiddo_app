import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

const _skipInterval = Duration(seconds: 15);
const _sleepFade = Duration(seconds: 10);

/// Extra on [MediaItem] marking content whose timing matters (rhythm games): no speed change.
const timingSensitiveExtra = 'timing_sensitive';

Future<AkAudioHandler> initAudio() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  return AudioService.init(
    builder: () => AkAudioHandler(session),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'pl.audiokiddo.playback',
      androidNotificationChannelName: 'Odtwarzanie',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      fastForwardInterval: _skipInterval,
      rewindInterval: _skipInterval,
    ),
  );
}

/// Sleep timer: a fixed duration or "stop at the end of this item".
sealed class SleepTimer {
  const SleepTimer();
}

class SleepAfter extends SleepTimer {
  const SleepAfter(this.endsAt);

  final DateTime endsAt;
}

class SleepAtEndOfItem extends SleepTimer {
  const SleepAtEndOfItem();
}

/// Plays plain audio (audiozabawy, piosenki) in the background with lock-screen and
/// headset controls. Interactive games get their own session in Etap 4.
class AkAudioHandler extends BaseAudioHandler with SeekHandler {
  AkAudioHandler(AudioSession session) {
    _player.playbackEventStream.listen(_broadcast, onError: (Object e, StackTrace st) => _broadcastError(e));
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        unawaited(_player.pause());
        if (_sleep is SleepAtEndOfItem) cancelSleepTimer();
      }
    });
    _subscriptions.addAll([
      // A call or another app interrupts: pause and do NOT resume on our own —
      // the child may have walked away (ARCHITECTURE §9).
      session.interruptionEventStream.listen((event) {
        if (event.begin && event.type != AudioInterruptionType.duck) unawaited(pause());
      }),
      // Headphones unplugged or Bluetooth disconnected.
      session.becomingNoisyEventStream.listen((_) => unawaited(pause())),
    ]);
  }

  // just_audio's own interruption handling would resume playback after a call.
  final _player = AudioPlayer(handleInterruptions: false);
  final _subscriptions = <StreamSubscription<void>>[];
  final _sleepController = StreamController<SleepTimer?>.broadcast();
  SleepTimer? _sleep;
  Timer? _sleepTicker;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<SleepTimer?> get sleepTimerStream => _sleepController.stream;
  SleepTimer? get sleepTimer => _sleep;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  /// Plays a local file or a URL, starting at [start].
  Future<void> playItem(MediaItem media, Uri source, {Duration start = Duration.zero}) async {
    final timingSensitive = media.extras?[timingSensitiveExtra] == true;
    if (timingSensitive) await _player.setSpeed(1);
    await _player.setVolume(1);
    // Publish the item only once it loaded, so a failed start does not linger in the mini player.
    final duration = await _player.setAudioSource(
      AudioSource.uri(source, tag: media),
      initialPosition: start,
    );
    mediaItem.add(duration == null ? media : media.copyWith(duration: duration));
    // just_audio's play() completes only when playback stops, so it is not awaited.
    unawaited(_player.play());
  }

  @override
  Future<void> play() async {
    await _player.setVolume(1);
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) async {
    if (mediaItem.value?.extras?[timingSensitiveExtra] == true) return;
    await _player.setSpeed(speed);
  }

  @override
  Future<void> stop() async {
    cancelSleepTimer();
    await _player.stop();
    await super.stop();
  }

  void setSleepTimer(SleepTimer timer) {
    cancelSleepTimer();
    _sleep = timer;
    if (timer is SleepAfter) {
      _sleepTicker = Timer.periodic(const Duration(milliseconds: 500), (_) => _tickSleep(timer));
    }
    _sleepController.add(timer);
  }

  void cancelSleepTimer() {
    _sleepTicker?.cancel();
    _sleepTicker = null;
    if (_sleep != null) unawaited(_player.setVolume(1));
    _sleep = null;
    _sleepController.add(null);
  }

  void _tickSleep(SleepAfter timer) {
    final left = timer.endsAt.difference(DateTime.now());
    if (left <= Duration.zero) {
      unawaited(_player.pause());
      cancelSleepTimer();
    } else if (left < _sleepFade && _player.playing) {
      unawaited(_player.setVolume(left.inMilliseconds / _sleepFade.inMilliseconds));
    }
  }

  void _broadcast(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
        ],
        systemActions: const {MediaAction.seek, MediaAction.rewind, MediaAction.fastForward},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  void _broadcastError(Object error) {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        errorMessage: error.toString(),
        playing: false,
      ),
    );
  }

  Future<void> dispose() async {
    cancelSleepTimer();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _sleepController.close();
    await _player.dispose();
  }
}
