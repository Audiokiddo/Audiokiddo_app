import 'dart:async';
import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/core/storage/storage_providers.dart';
import 'package:audiokiddo/features/family/family.dart';
import 'package:audiokiddo/features/games/game_controller.dart';
import 'package:audiokiddo/features/games/microphone.dart';
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

/// Microphone fed with synthetic sound; records whether it is open.
class FakeMicrophone implements MicrophoneInput {
  StreamController<List<double>>? _stream;
  int starts = 0;
  bool get open => _stream != null;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Stream<List<double>>> start() async {
    starts++;
    return (_stream = StreamController<List<double>>()).stream;
  }

  @override
  Future<void> stop() async {
    await _stream?.close();
    _stream = null;
  }

  void feed(List<double> samples) => _stream?.add(samples);
}

final _rnd = math.Random(1);
List<double> quiet(int ms) => [for (var i = 0; i < ms * 16; i++) 0.001 * (_rnd.nextDouble() * 2 - 1)];

/// A hand clap: loud noise that dies away within ~20 ms.
List<double> clapSound() => [
  ...quiet(300),
  for (var i = 0; i < 1440; i++) 0.8 * (_rnd.nextDouble() * 2 - 1) * math.exp(-60 * i / 16000),
  ...quiet(300),
];

/// A short "nie!": voiced (harmonic, few zero crossings) and sustained.
List<double> voiceSound() => [
  ...quiet(300),
  for (var i = 0; i < 16 * 450; i++)
    math.min(1, i / 640) *
        0.25 *
        (math.sin(2 * math.pi * 180 * i / 16000) + 0.5 * math.sin(2 * math.pi * 360 * i / 16000)),
  ...quiet(300),
];

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

  group('answers by sound (Prawda czy nie?)', () {
    const truth = {'krowa': true, 'ryby': false, 'snieg': true, 'slon': false, 'lato': true, 'auta': false};

    Future<(FakeMicrophone, ProviderContainer)> withMicrophone({required bool enabled}) async {
      final mic = FakeMicrophone();
      final db = memoryDatabase();
      addTearDown(db.close);
      final c = ProviderContainer(
        overrides: [
          ...testOverrides(db),
          gameAudioProvider.overrideWithValue(audio),
          gameTimeScaleProvider.overrideWithValue(0.05),
          microphoneInputProvider.overrideWithValue(mic),
        ],
      );
      addTearDown(c.dispose);
      if (enabled) await c.read(databaseProvider).writeValue('games_microphone', '1');
      return (mic, c);
    }

    /// Answers every statement as soon as the game listens: right or deliberately wrong.
    void answer(ProviderContainer c, FakeMicrophone mic, {required bool correctly}) {
      c.listen(gameControllerProvider, (_, next) {
        if (next.phase != GamePhase.listening || !next.listensToSound) return;
        final question = audio.log.lastWhere((l) => l.startsWith('play:q_')).substring('play:q_'.length);
        final sayTrue = truth[question]! == correctly;
        mic.feed(sayTrue ? clapSound() : voiceSound());
      });
    }

    test('a clap means true, a spoken "nie" means false, and points add up', () async {
      final (mic, c) = await withMicrophone(enabled: true);
      await c.read(familyProvider.future);
      await c
          .read(familyProvider.notifier)
          .saveChild(ChildProfile(id: 'z', name: 'Zosia', age: 4, startedOn: DateTime(2026)));
      answer(c, mic, correctly: true);
      await c
          .read(gameControllerProvider.notifier)
          .start((await c.read(catalogProvider.future)).item('prawda-czy-nie')!);
      expect(c.read(gameControllerProvider).phase, GamePhase.finished);
      expect(audio.log.where((l) => l == 'play:correct'), hasLength(6));
      expect(audio.log.where((l) => l == 'play:oops'), isEmpty);
      expect(audio.log.last, 'play:outro_great');
      expect(mic.open, isFalse, reason: 'the microphone closes with the game');
      final result = c.read(familyProvider).value!.resultsOf('z').single;
      expect((result.itemId, result.answers, result.correct), ('prawda-czy-nie', 6, 6));
    });

    test('wrong answers get a gentle correction', () async {
      final (mic, c) = await withMicrophone(enabled: true);
      answer(c, mic, correctly: false);
      await c
          .read(gameControllerProvider.notifier)
          .start((await c.read(catalogProvider.future)).item('prawda-czy-nie')!);
      expect(audio.log.where((l) => l == 'play:oops'), hasLength(6));
      expect(audio.log.last, 'play:outro_good');
    });

    test('without the parent\'s consent the microphone never opens', () async {
      final (mic, c) = await withMicrophone(enabled: false);
      await c
          .read(gameControllerProvider.notifier)
          .start((await c.read(catalogProvider.future)).item('prawda-czy-nie')!);
      expect(mic.starts, 0);
      expect(audio.log.where((l) => l == 'play:think'), hasLength(6));
      expect(audio.log.where((l) => l.startsWith('play:a_')), hasLength(6));
      expect(audio.log.last, 'play:outro_good');
    });
  });
}
