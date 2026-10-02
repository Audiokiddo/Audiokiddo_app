import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audiokiddo/features/discovery/queue_controller.dart';
import 'package:audiokiddo/features/player/audio_handler.dart';
import 'package:audiokiddo/features/player/player_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';
import 'discovery_test.dart' show sample;

class QueueAudio extends BaseAudioHandler implements AkAudioHandler {
  final played = <String>[];
  @override
  SleepTimer? get sleepTimer => null;
  @override
  Duration? get duration => const Duration(seconds: 600);
  @override
  Duration get position => Duration.zero;
  @override
  Future<void> playItem(MediaItem media, Uri source, {Duration start = Duration.zero}) async {
    played.add(media.id);
    mediaItem.add(media);
    playbackState.add(PlaybackState(playing: true, processingState: AudioProcessingState.ready));
  }

  @override
  Future<void> stop() async {
    playbackState.add(PlaybackState(processingState: AudioProcessingState.idle));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  void complete() => playbackState.add(PlaybackState(processingState: AudioProcessingState.completed));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final stopAtEnd in [false, true]) {
    test('queue advances only when completed; end timer=$stopAtEnd', () async {
      final db = memoryDatabase();
      addTearDown(db.close);
      final audio = QueueAudio();
      final container = ProviderContainer(
        overrides: [...testOverrides(db), audioHandlerProvider.overrideWithValue(audio)],
      );
      addTearDown(container.dispose);
      final runner = container.read(queueRunnerProvider.notifier);
      await runner.start(<ContentItem>[sample('one'), sample('two')]);
      runner.stopAfterCurrent = stopAtEnd;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      audio.playbackState.add(PlaybackState(playing: false, processingState: AudioProcessingState.ready));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(audio.played, ['one']);
      audio.complete();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(audio.played, stopAtEnd ? ['one'] : ['one', 'two']);
      if (!stopAtEnd) {
        audio.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(container.read(queueRunnerProvider).running, isFalse);
    });
  }
}
