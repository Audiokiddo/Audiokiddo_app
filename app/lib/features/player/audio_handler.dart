import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

const _skipInterval = Duration(seconds: 15);

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

/// Plays plain audio (audiozabawy, piosenki) in the background with lock-screen and
/// headset controls. Interactive games get their own session in Etap 4.
class AkAudioHandler extends BaseAudioHandler with SeekHandler {
  AkAudioHandler(AudioSession session) {
    _player.playbackEventStream.listen(_broadcast, onError: (Object e, StackTrace st) => _broadcastError(e));
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) unawaited(_player.pause());
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

  Future<void> playAsset(MediaItem media, String assetPath) async {
    mediaItem.add(media);
    final duration = await _player.setAudioSource(AudioSource.asset(assetPath, tag: media));
    if (duration != null) mediaItem.add(media.copyWith(duration: duration));
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  Stream<Duration> get positionStream => _player.positionStream;

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
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _player.dispose();
  }
}
