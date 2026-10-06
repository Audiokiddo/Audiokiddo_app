import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_handler.dart';

/// Overridden in `main` with the handler created by `initAudio()`.
final audioHandlerProvider = Provider<AkAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider must be overridden'),
);

final playbackStateProvider = StreamProvider<PlaybackState>((ref) => ref.watch(audioHandlerProvider).playbackState);

final currentMediaProvider = StreamProvider<MediaItem?>((ref) => ref.watch(audioHandlerProvider).mediaItem);

final positionProvider = StreamProvider<Duration>((ref) => ref.watch(audioHandlerProvider).positionStream);
