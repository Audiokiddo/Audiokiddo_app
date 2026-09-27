import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/games/game_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Records what the game asked the player to do; segments finish immediately.
class FakeGameAudio implements GameAudio {
  final log = <String>[];
  bool playing = true;

  String _name(Uri u) => u.pathSegments.last.replaceAll('.m4a', '');

  @override
  Future<bool> playSegment(MediaItem media, Uri source) async {
    log.add('play:${_name(source)}');
    return true;
  }

  @override
  Future<void> startLoop(MediaItem media, Uri source) async => log.add('loop:${_name(source)}');

  @override
  Future<void> stopLoop() async => log.add('stopLoop');

  @override
  Future<void> stop() async => log.add('stop');

  @override
  bool get isPlaying => playing;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGameAudio audio;
  late ProviderContainer container;

  setUp(() {
    audio = FakeGameAudio();
    final db = memoryDatabase();
    addTearDown(db.close);
    container = ProviderContainer(
      overrides: [
        ...testOverrides(db),
        gameAudioProvider.overrideWithValue(audio),
        gameTimeScaleProvider.overrideWithValue(0.05),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<ContentItem> game(String id) async => (await container.read(catalogProvider.future)).item(id)!;

  test('Zgadnij dźwięk runs to the end on its no-microphone variant', () async {
    final item = await game('zgadnij-dzwiek');
    await container.read(gameControllerProvider.notifier).start(item);
    expect(container.read(gameControllerProvider).phase, GamePhase.finished);
    expect(audio.log.first, 'play:intro');
    // Each question: sound, a looped "thinking" bed while the child answers, then the answer.
    expect(audio.log.where((l) => l == 'loop:thinking'), hasLength(3));
    expect(audio.log.where((l) => l.startsWith('play:a_')), hasLength(3));
    expect(audio.log.where((l) => l == 'play:heard_you'), isEmpty, reason: 'no microphone, no "I heard you"');
    expect(audio.log.last, 'play:outro');
  });

  test('freeze dance keeps the audio session alive with silence while the child freezes', () async {
    final item = await game('zamrozony-taniec');
    await container.read(gameControllerProvider.notifier).start(item);
    expect(audio.log.where((l) => l == 'loop:silence_1s'), hasLength(3));
    expect(container.read(gameControllerProvider).phase, GamePhase.finished);
  });

  test('pausing from the lock screen pauses the wait', () async {
    audio.playing = false;
    final item = await game('zamrozony-taniec');
    final running = container.read(gameControllerProvider.notifier).start(item);
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(container.read(gameControllerProvider).phase, GamePhase.waiting, reason: 'frozen while paused');
    audio.playing = true;
    await running;
    expect(container.read(gameControllerProvider).phase, GamePhase.finished);
  });

  test('leaving mid-game stops everything', () async {
    audio.playing = false; // hold the game in its first wait
    final item = await game('zamrozony-taniec');
    unawaited(container.read(gameControllerProvider.notifier).start(item));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await container.read(gameControllerProvider.notifier).stop();
    expect(container.read(gameControllerProvider).phase, GamePhase.idle);
    expect(audio.log.last, 'stop');
  });

  test('an interrupted game resumes by replaying the last instruction', () async {
    final item = await game('zamrozony-taniec');
    audio.playing = false; // hold the game in the first freeze
    unawaited(container.read(gameControllerProvider.notifier).start(item));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await container.read(gameControllerProvider.notifier).stop();
    expect(audio.log.where((l) => l.startsWith('play:')), ['play:intro', 'play:music_1', 'play:stop']);
    expect(await container.read(gameResumeProvider(item).future), isTrue);

    audio
      ..log.clear()
      ..playing = true;
    await container.read(gameControllerProvider.notifier).start(item, resume: true);
    expect(audio.log.first, 'play:stop', reason: '"Stop!" is heard again');
    expect(audio.log.where((l) => l == 'play:intro'), isEmpty);
    expect(
      audio.log.where((l) => l == 'loop:silence_1s'),
      hasLength(3),
      reason: 'all three freezes still happen',
    );
    expect(await container.read(gameResumeProvider(item).future), isFalse, reason: 'cleared when finished');
  });

  test('"from the start" discards the saved position', () async {
    final item = await game('zamrozony-taniec');
    audio.playing = false;
    unawaited(container.read(gameControllerProvider.notifier).start(item));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await container.read(gameControllerProvider.notifier).stop();
    audio
      ..log.clear()
      ..playing = true;
    await container.read(gameControllerProvider.notifier).start(item);
    expect(audio.log.first, 'play:intro');
  });
}
