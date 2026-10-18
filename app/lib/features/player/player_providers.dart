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

/// The play being started right now, until its sound is ready. The player opens at once on a
/// tap and shows it ("Za chwilę zaczynamy") instead of waiting for the file, the address and
/// Szop’en's hello (2026-10-18: a few seconds of nothing looked like a frozen app).
class StartingItem extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) => state = id;
}

final startingItemProvider = NotifierProvider<StartingItem, String?>(StartingItem.new);
