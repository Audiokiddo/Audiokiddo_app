import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:test/test.dart';

GameScript fixture([void Function(Map<String, Object?> steps)? edit]) {
  final json =
      jsonDecode(File('test/fixtures/zgadnij_dzwiek.json').readAsStringSync()) as Map<String, Object?>;
  edit?.call(json['steps'] as Map<String, Object?>);
  return parseGameScript(json);
}

/// Drives the runner like the app would, answering each command with [answer].
List<String> play(ScriptRunner runner, EngineEvent Function(EngineCommand) answer, {int max = 200}) {
  final log = <String>[];
  var command = runner.start();
  for (var i = 0; i < max; i++) {
    log.add(switch (command) {
      PlaySegment(:final asset) => 'play:$asset',
      WaitFor(:final duration, :final loopAsset) => 'wait:${duration.inMilliseconds}:${loopAsset ?? '-'}',
      Listen(:final input) => 'listen:${input.name}',
      ListenForChoice(:final inputs) => 'choice:${inputs.map((i) => i.name).join('|')}',
      Finish(:final asset, :final reason) => 'finish:${asset ?? '-'}:${reason.name}',
    });
    if (command is Finish) return log;
    command = runner.next(answer(command));
  }
  fail('did not finish');
}

EngineEvent normal(EngineCommand c) => switch (c) {
  PlaySegment() => const SegmentFinished(),
  WaitFor() => const WaitElapsed(),
  Listen() || ListenForChoice() => const InputTimedOut(),
  Finish() => const SegmentFinished(),
};

/// Yes/no question: clap = yes, speak = no, touch = yes; asked at most twice.
GameScript quiz() {
  const asset = {'path': 'x.m4a', 'bytes': 1, 'sha256': '00'};
  return parseGameScript({
    'schema_version': 1,
    'id': 'quiz',
    'version': 1,
    'min_engine_version': 2,
    'timing_sensitive': false,
    'assets': {for (final a in ['question', 'yes', 'no', 'hint']) a: asset},
    'start': 'question',
    'steps': {
      'question': {'type': 'play', 'asset': 'question', 'next': 'answer'},
      'answer': {
        'type': 'choice',
        'window_ms': 8000,
        'options': {'clap': 'yes', 'voice_activity': 'no', 'tap_anywhere': 'yes'},
        'on_timeout': 'again',
        'fallback': {
          'no_microphone': {'type': 'play', 'asset': 'hint', 'next': 'yes'},
          'screen_locked': 'same_as_no_microphone',
          'input_error': 'same_as_no_microphone',
        },
      },
      'again': {'type': 'goto', 'target': 'question', 'max_visits': 1},
      'yes': {'type': 'play', 'asset': 'yes', 'next': 'end'},
      'no': {'type': 'play', 'asset': 'no', 'next': 'end'},
      'end': {'type': 'end'},
    },
  });
}

void main() {
  test('plays five rounds and finishes with the outro', () {
    final log = play(ScriptRunner(fixture()), normal);
    expect(log.first, 'play:intro');
    expect(log.where((l) => l == 'play:q_krowa'), hasLength(5));
    expect(log.where((l) => l == 'listen:voiceActivity'), hasLength(5));
    expect(log.last, 'finish:outro:completed');
  });

  test('a detected answer plays the acknowledgement first', () {
    final runner = ScriptRunner(fixture());
    expect(runner.start(), isA<PlaySegment>());
    expect(runner.next(const SegmentFinished()), isA<PlaySegment>()); // question
    expect(runner.next(const SegmentFinished()), isA<Listen>());
    final ack = runner.next(const InputDetected());
    expect((ack as PlaySegment).asset, 'heard_you');
  });

  test('without a microphone every question falls back to a timed wait', () {
    final log = play(ScriptRunner(fixture(), unavailable: {FallbackReason.noMicrophone}), normal);
    expect(log.where((l) => l.startsWith('listen')), isEmpty);
    expect(log.where((l) => l == 'wait:6000:thinking'), hasLength(5));
    expect(log.last, 'finish:outro:completed');
  });

  test('locking the screen mid-game switches the next input to its fallback', () {
    final runner = ScriptRunner(fixture());
    runner.start();
    runner.next(const SegmentFinished());
    final listen = runner.next(const SegmentFinished());
    expect(listen, isA<Listen>());
    // Screen locked while listening: the app reports the failure and marks the input unavailable.
    runner.setAvailability(FallbackReason.screenLocked, available: false);
    final wait = runner.next(const InputFailed(FallbackReason.screenLocked));
    expect(wait, isA<WaitFor>());
    final answer = runner.next(const WaitElapsed());
    expect((answer as PlaySegment).asset, 'a_krowa');
  });

  test('a loop past its limit takes the exit instead of spinning', () {
    final script = fixture((s) {
      (s['more'] as Map)['if'] = {'var': 'round', 'lt': 1000};
      (s['more'] as Map)['max_visits'] = 3;
    });
    final log = play(ScriptRunner(script), normal);
    // The first round plus one per allowed pass through the branch.
    expect(log.where((l) => l == 'play:q_krowa'), hasLength(4));
    expect(log.last, 'finish:outro:completed');
  });

  test('goto over its limit ends the session', () {
    final script = fixture((s) {
      s['more'] = {'type': 'goto', 'target': 'q1', 'max_visits': 2};
      s['orphan_end'] = {'type': 'end'};
    });
    final log = play(ScriptRunner(script), normal);
    expect(log.last, 'finish:-:loopLimit');
  });

  test('clap count below the minimum counts as no answer', () {
    final script = fixture((s) {
      (s['listen1'] as Map)['input'] = 'clap';
      (s['listen1'] as Map)['min_count'] = 3;
    });
    final runner = ScriptRunner(script)..start();
    runner.next(const SegmentFinished());
    runner.next(const SegmentFinished());
    final afterTwo = runner.next(const InputDetected(count: 2));
    expect((afterTwo as PlaySegment).asset, 'a_krowa', reason: 'on_timeout path, no acknowledgement');
  });

  test('resume from a snapshot replays the current step with the same variables', () {
    final runner = ScriptRunner(fixture());
    var c = runner.start();
    for (var i = 0; i < 6; i++) {
      c = runner.next(normal(c));
    }
    final snap = runner.snapshot();
    final resumed = ScriptRunner(fixture(), resumeFrom: snap);
    expect(resumed.variables, runner.variables);
    final replay = resumed.start();
    expect(replay.runtimeType, c.runtimeType);
  });

  test('a late, mismatched event replays the current step', () {
    final runner = ScriptRunner(fixture());
    runner.start();
    expect((runner.next(const WaitElapsed()) as PlaySegment).asset, 'intro');
  });

  test('snapshot round-trips through JSON and keeps loop counts exact', () {
    final runner = ScriptRunner(fixture());
    var c = runner.start();
    // Play until the second question starts.
    while (!(c is PlaySegment && c.asset == 'q_krowa' && runner.variables['round'] == 1)) {
      c = runner.next(normal(c));
    }
    final snap = RunnerSnapshot.fromJson(runner.snapshot().toJson());
    expect(snap.matches(fixture()), isTrue);
    final resumed = ScriptRunner(fixture(), resumeFrom: snap);
    final log = play(resumed, normal);
    expect(log.first, 'play:q_krowa', reason: 'the interrupted instruction is replayed');
    // Rounds 2..5 remain, exactly as without the interruption.
    expect(log.where((l) => l == 'play:q_krowa'), hasLength(4));
    expect(log.last, 'finish:outro:completed');
  });

  group('choice', () {
    test('clap and voice lead to different answers', () {
      for (final (kind, answer) in [(InputKind.clap, 'yes'), (InputKind.voiceActivity, 'no')]) {
        final runner = ScriptRunner(quiz());
        runner.start();
        final listen = runner.next(const SegmentFinished()) as ListenForChoice;
        expect(listen.inputs, {InputKind.clap, InputKind.voiceActivity, InputKind.tapAnywhere});
        expect(listen.window, const Duration(seconds: 8));
        expect((runner.next(InputDetected(kind: kind)) as PlaySegment).asset, answer);
      }
    });

    test('no answer asks again, then stops at the loop limit', () {
      final log = play(ScriptRunner(quiz()), normal);
      expect(log.where((l) => l == 'play:question'), hasLength(2));
      expect(log.last, 'finish:-:loopLimit');
    });

    test('without a microphone the child can still answer by touch', () {
      final log = play(ScriptRunner(quiz(), unavailable: {FallbackReason.noMicrophone}), normal);
      expect(log, contains('choice:tapAnywhere'));
    });

    test('with no usable input the fallback plays', () {
      final runner = ScriptRunner(
        quiz(),
        unavailable: {FallbackReason.noMicrophone, FallbackReason.screenLocked},
      );
      final log = play(runner, normal);
      expect(log, ['play:question', 'play:hint', 'play:yes', 'finish:-:completed']);
    });

    test('an input the choice does not offer counts as no answer', () {
      final runner = ScriptRunner(quiz());
      runner.start();
      runner.next(const SegmentFinished());
      final next = runner.next(const InputDetected(kind: InputKind.motionShake));
      expect((next as PlaySegment).asset, 'question');
    });

    test('a choice is valid only in scripts that require engine 2', () {
      expect(validateScript(quiz()).errors, isEmpty);
      final old = GameScript(
        schemaVersion: 1,
        id: 'quiz',
        version: 1,
        minEngineVersion: 1,
        assets: quiz().assets,
        variables: const {},
        start: 'question',
        steps: quiz().steps,
      );
      expect(validateScript(old).errors.map((e) => e.message), contains(contains('min_engine_version')));
    });
  });
}
