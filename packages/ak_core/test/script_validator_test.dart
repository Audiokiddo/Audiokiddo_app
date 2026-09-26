import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:ak_core/src/json.dart';
import 'package:test/test.dart';

Map<String, Object?> loadFixture() =>
    jsonDecode(File('test/fixtures/zgadnij_dzwiek.json').readAsStringSync()) as Map<String, Object?>;

GameScript parse(Map<String, Object?> json) => GameScript.fromJson(JsonReader(json));

/// Deep-copies the fixture and applies [edit] to its `steps` map.
GameScript withSteps(void Function(Map<String, Object?> steps) edit) {
  final json = loadFixture();
  edit(json['steps'] as Map<String, Object?>);
  return parse(json);
}

void main() {
  test('example script from ARCHITECTURE is valid', () {
    final result = validateScript(parse(loadFixture()));
    expect(result.errors, isEmpty);
    expect(result.warnings, isEmpty);
  });

  test('same_as_ fallback aliases resolve to the same step', () {
    final listen = parse(loadFixture()).steps['listen1'] as InputStep;
    expect(listen.fallbacks.keys, containsAll(FallbackReason.values));
    expect(
      listen.fallbacks[FallbackReason.screenLocked],
      same(listen.fallbacks[FallbackReason.noMicrophone]),
    );
  });

  test('missing step reference is an error', () {
    final script = withSteps((s) => (s['q1'] as Map)['next'] = 'nowhere');
    expect(validateScript(script).errors.single.message, contains('"nowhere"'));
  });

  test('unknown asset is an error', () {
    final script = withSteps((s) => (s['q1'] as Map)['asset'] = 'missing_audio');
    expect(validateScript(script).isValid, isFalse);
  });

  test('loop without max_visits is rejected', () {
    final script = withSteps((s) => (s['more'] as Map).remove('max_visits'));
    final errors = validateScript(script).errors;
    expect(errors, hasLength(1));
    expect(errors.single.message, startsWith('loop without max_visits'));
  });

  test('input without all fallbacks is rejected', () {
    final script = withSteps((s) => ((s['listen1'] as Map)['fallback'] as Map).remove('input_error'));
    expect(validateScript(script).errors.single.message, contains('inputError'));
  });

  test('speech keywords are reserved in engine v1', () {
    final script = withSteps((s) => (s['listen1'] as Map)['input'] = 'speech_keywords');
    expect(validateScript(script).errors.single.message, contains('not supported'));
  });

  test('limits: too long input window and wait', () {
    final script = withSteps((s) {
      (s['listen1'] as Map)['window_ms'] = ScriptLimits.maxInputWindowMs + 1;
      ((s['listen1'] as Map)['fallback'] as Map)['no_microphone'] = {
        'type': 'wait',
        'duration_ms': ScriptLimits.maxWaitMs + 1,
        'next': 'answer1',
      };
    });
    expect(validateScript(script).errors, hasLength(2));
  });

  test('dead end without path to end is rejected', () {
    final script = withSteps((s) {
      s['trap'] = {'type': 'goto', 'target': 'trap', 'max_visits': 3};
      (s['ack1'] as Map)['next'] = 'trap';
    });
    expect(validateScript(script).errors.map((e) => e.stepId), contains('trap'));
  });

  test('unreachable step is only a warning', () {
    final script = withSteps((s) => s['orphan'] = {'type': 'end'});
    final result = validateScript(script);
    expect(result.isValid, isTrue);
    expect(result.warnings.single.stepId, 'orphan');
  });

  test('script for a newer engine is rejected', () {
    final json = loadFixture()..['min_engine_version'] = engineVersion + 1;
    expect(validateScript(parse(json)).isValid, isFalse);
  });

  test('undeclared variable is an error', () {
    final script = withSteps((s) => (s['count'] as Map)['var'] = 'rounds');
    expect(validateScript(script).errors.single.message, contains('undeclared'));
  });

  test('unknown step type fails parsing', () {
    expect(() => withSteps((s) => s['x'] = {'type': 'explode'}), throwsA(isA<FormatError>()));
  });

  test('condition evaluation', () {
    const c = Condition(variable: 'round', op: CompareOp.lt, value: 5);
    expect(c.evaluate({'round': 4}), isTrue);
    expect(c.evaluate({'round': 5}), isFalse);
    expect(c.evaluate({}), isTrue, reason: 'missing variable counts as 0');
  });
}
