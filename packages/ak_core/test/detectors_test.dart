import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ak_core/ak_core.dart';
import 'package:test/test.dart';

const rate = 16000;

List<double> silence(double seconds, {double noise = 0, int seed = 1}) {
  final r = math.Random(seed);
  return List.generate((rate * seconds).round(), (_) => noise * (r.nextDouble() * 2 - 1));
}

/// Broadband burst decaying in ~20 ms, like a hand clap.
List<double> clap({double volume = 0.8, int seed = 2}) {
  final r = math.Random(seed);
  return List.generate(
    (rate * 0.08).round(),
    (i) => volume * (r.nextDouble() * 2 - 1) * math.exp(-60 * i / rate),
  );
}

/// Sustained harmonic sound, like a child saying "muuu".
List<double> voice(double seconds, {double volume = 0.3}) => List.generate(
  (rate * seconds).round(),
  (i) => volume * (math.sin(2 * math.pi * 220 * i / rate) + 0.5 * math.sin(2 * math.pi * 440 * i / rate)),
);

SoundDetector run(List<List<double>> parts) {
  final d = SoundDetector(sampleRate: rate);
  for (final p in parts) {
    d.add(p);
  }
  return d;
}

void main() {
  test('short game answer is heard but a clap is not counted as speech', () {
    final speech = SoundDetector(voiceMinDuration: const Duration(milliseconds: 120));
    speech.add(silence(.3));
    speech.add(voice(.15));
    expect(speech.voiceDetected, isTrue);
    final transient = SoundDetector(voiceMinDuration: const Duration(milliseconds: 120));
    transient.add(silence(.3));
    transient.add(clap());
    transient.add(silence(.3));
    expect(transient.voiceDetected, isFalse);
  });
  test('counts separate claps in a quiet room', () {
    final d = run([silence(0.5), clap(), silence(0.4), clap(), silence(0.4), clap(), silence(0.5)]);
    expect(d.claps, 3);
    expect(d.voiceDetected, isFalse);
  });

  test('claps are still counted over background noise (car)', () {
    final d = run([
      silence(1, noise: 0.03),
      clap(),
      silence(0.5, noise: 0.03, seed: 3),
      clap(seed: 4),
      silence(0.5, noise: 0.03, seed: 5),
    ]);
    expect(d.claps, 2);
  });

  test('speech is voice activity, not claps', () {
    final d = run([silence(0.5), voice(0.8), silence(0.5)]);
    expect(d.claps, 0);
    expect(d.voiceDetected, isTrue);
  });

  test('short sound is not voice activity', () {
    final d = run([silence(0.5), voice(0.1), silence(0.5)]);
    expect(d.voiceDetected, isFalse);
  });

  test('silence and faint noise trigger nothing', () {
    final d = run([silence(2, noise: 0.005)]);
    expect(d.claps, 0);
    expect(d.voiceDetected, isFalse);
  });

  test('two claps closer than the refractory time count once', () {
    final d = run([silence(0.5), clap(), silence(0.02), clap(seed: 9), silence(0.5)]);
    expect(d.claps, 1);
  });

  test('resetting a window keeps the noise floor', () {
    final d = run([silence(1, noise: 0.03), clap(), silence(0.5, noise: 0.03)]);
    d.resetCounts();
    d.add(silence(0.3, noise: 0.03, seed: 7));
    expect(d.claps, 0);
    d.add(clap(seed: 8));
    d.add(silence(0.3, noise: 0.03, seed: 9));
    expect(d.claps, 1);
  });

  group('real recordings (placeholder game audio)', () {
    SoundDetector file(String name) {
      final bytes = File('test/fixtures/audio/$name.f32').readAsBytesSync();
      return SoundDetector(sampleRate: rate)..add(Float32List.view(bytes.buffer, 0, bytes.length ~/ 4));
    }

    test('clap rhythms are counted exactly', () {
      expect(file('claps_3').claps, 3);
      expect(file('claps_4').claps, 4);
    });

    test('narrator speech is voice, never claps', () {
      for (final name in ['speech_intro', 'speech_intro2']) {
        final d = file(name);
        expect(d.claps, 0, reason: name);
        expect(d.voiceDetected, isTrue, reason: name);
      }
    });
  });
}
