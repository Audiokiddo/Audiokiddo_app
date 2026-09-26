import '../content.dart' show AssetRef;
import '../json.dart';

/// Highest script engine version this build of the app understands.
const int engineVersion = 1;

/// Supported `schema_version` of the game script format.
const int scriptSchemaVersion = 1;

/// Child input a script may wait for. [speechKeywords] is reserved and rejected in v1.
enum InputKind { tapAnywhere, clap, voiceActivity, motionShake, speechKeywords }

/// Why an input step falls back to its non-input variant.
enum FallbackReason { noMicrophone, screenLocked, inputError }

enum SetOp { set, inc, dec }

enum CompareOp { eq, lt, gt }

sealed class ScriptStep {
  const ScriptStep(this.id);

  final String id;

  /// All step ids this step can jump to (used by validation and graph analysis).
  List<String> get targets;

  /// Visits after which this step stops looping; only branch/goto may set it.
  int? get maxVisits => null;

  static ScriptStep fromJson(String id, JsonReader r) {
    return switch (r.string('type')) {
      'play' => PlayStep(id, asset: r.string('asset'), next: r.string('next')),
      'wait' => WaitStep(
        id,
        durationMs: r.integer('duration_ms', min: 1),
        loopAsset: r.optString('loop_asset'),
        next: r.string('next'),
      ),
      'input' => InputStep.fromJson(id, r),
      'branch' => BranchStep(
        id,
        condition: Condition.fromJson(r.object('if')),
        then: r.string('then'),
        otherwise: r.string('else'),
        maxVisits: r.optInteger('max_visits', min: 1),
      ),
      'set' => SetStep(
        id,
        variable: r.string('var'),
        op: r.enumValue('op', SetOp.values),
        value: r.optInteger('value') ?? 1,
        next: r.string('next'),
      ),
      'goto' => GotoStep(id, target: r.string('target'), maxVisits: r.optInteger('max_visits', min: 1)),
      'end' => EndStep(id, asset: r.optString('asset')),
      final other => throw FormatError('${r.path}.type', 'unknown step type "$other"'),
    };
  }
}

class PlayStep extends ScriptStep {
  const PlayStep(super.id, {required this.asset, required this.next});

  final String asset;
  final String next;

  @override
  List<String> get targets => [next];
}

/// Silence (or a looped bed) giving the child time to answer.
class WaitStep extends ScriptStep {
  const WaitStep(super.id, {required this.durationMs, required this.next, this.loopAsset});

  final int durationMs;
  final String? loopAsset;
  final String next;

  @override
  List<String> get targets => [next];
}

class InputStep extends ScriptStep {
  const InputStep(
    super.id, {
    required this.input,
    required this.windowMs,
    required this.onDetected,
    required this.onTimeout,
    required this.fallbacks,
    this.minCount,
  });

  factory InputStep.fromJson(String id, JsonReader r) {
    final fallbackJson = r.optObject('fallback');
    final fallbacks = <FallbackReason, ScriptStep>{};
    if (fallbackJson != null) {
      // First pass: inline steps; second pass: "same_as_<reason>" aliases.
      final aliases = <FallbackReason, FallbackReason>{};
      for (final reason in FallbackReason.values) {
        final key = wireName(reason);
        final value = fallbackJson.json[key];
        if (value == null) continue;
        if (value is String && value.startsWith('same_as_')) {
          final target = value.substring('same_as_'.length);
          final targetReason = FallbackReason.values.where((f) => wireName(f) == target).firstOrNull;
          if (targetReason == null) {
            throw FormatError('${fallbackJson.path}.$key', 'unknown alias "$value"');
          }
          aliases[reason] = targetReason;
        } else {
          final step = ScriptStep.fromJson('$id#$key', JsonReader.of(value, '${fallbackJson.path}.$key'));
          if (step is! WaitStep && step is! PlayStep && step is! GotoStep) {
            throw FormatError('${fallbackJson.path}.$key', 'fallback must be wait, play or goto');
          }
          fallbacks[reason] = step;
        }
      }
      for (final MapEntry(key: reason, value: target) in aliases.entries) {
        final step = fallbacks[target];
        if (step == null) {
          throw FormatError('${fallbackJson.path}.${wireName(reason)}', 'alias points to a missing fallback');
        }
        fallbacks[reason] = step;
      }
    }
    return InputStep(
      id,
      input: r.enumValue('input', InputKind.values),
      windowMs: r.integer('window_ms', min: 1),
      onDetected: r.string('on_detected'),
      onTimeout: r.string('on_timeout'),
      minCount: r.optInteger('min_count', min: 1),
      fallbacks: Map.unmodifiable(fallbacks),
    );
  }

  final InputKind input;
  final int windowMs;
  final String onDetected;
  final String onTimeout;

  /// For counted inputs such as claps.
  final int? minCount;
  final Map<FallbackReason, ScriptStep> fallbacks;

  @override
  List<String> get targets => [onDetected, onTimeout, for (final f in fallbacks.values) ...f.targets];
}

class Condition {
  const Condition({required this.variable, required this.op, required this.value});

  factory Condition.fromJson(JsonReader r) {
    for (final op in CompareOp.values) {
      if (r.has(op.name)) {
        return Condition(variable: r.string('var'), op: op, value: r.integer(op.name));
      }
    }
    throw FormatError(r.path, 'condition needs one of: eq, lt, gt');
  }

  final String variable;
  final CompareOp op;
  final int value;

  bool evaluate(Map<String, int> variables) {
    final current = variables[variable] ?? 0;
    return switch (op) {
      CompareOp.eq => current == value,
      CompareOp.lt => current < value,
      CompareOp.gt => current > value,
    };
  }
}

class BranchStep extends ScriptStep {
  const BranchStep(
    super.id, {
    required this.condition,
    required this.then,
    required this.otherwise,
    this.maxVisits,
  });

  final Condition condition;
  final String then;
  final String otherwise;
  @override
  final int? maxVisits;

  @override
  List<String> get targets => [then, otherwise];
}

class SetStep extends ScriptStep {
  const SetStep(
    super.id, {
    required this.variable,
    required this.op,
    required this.value,
    required this.next,
  });

  final String variable;
  final SetOp op;
  final int value;
  final String next;

  @override
  List<String> get targets => [next];
}

class GotoStep extends ScriptStep {
  const GotoStep(super.id, {required this.target, this.maxVisits});

  final String target;
  @override
  final int? maxVisits;

  @override
  List<String> get targets => [target];
}

class EndStep extends ScriptStep {
  const EndStep(super.id, {this.asset});

  final String? asset;

  @override
  List<String> get targets => const [];
}

class GameScript {
  const GameScript({
    required this.schemaVersion,
    required this.id,
    required this.version,
    required this.minEngineVersion,
    required this.assets,
    required this.variables,
    required this.start,
    required this.steps,
    this.timingSensitive = false,
  });

  factory GameScript.fromJson(JsonReader r) {
    final assetsJson = r.optObject('assets');
    final stepsJson = r.object('steps');
    final variablesJson = r.optObject('variables');
    return GameScript(
      schemaVersion: r.integer('schema_version', min: 1),
      id: r.string('id'),
      version: r.integer('version', min: 1),
      minEngineVersion: r.optInteger('min_engine_version', min: 1) ?? 1,
      timingSensitive: r.boolean('timing_sensitive'),
      assets: {
        if (assetsJson != null)
          for (final key in assetsJson.json.keys) key: AssetRef.fromJson(assetsJson.object(key)),
      },
      variables: {
        if (variablesJson != null)
          for (final key in variablesJson.json.keys) key: variablesJson.integer(key),
      },
      start: r.string('start'),
      steps: {for (final key in stepsJson.json.keys) key: ScriptStep.fromJson(key, stepsJson.object(key))},
    );
  }

  final int schemaVersion;
  final String id;
  final int version;
  final int minEngineVersion;
  final bool timingSensitive;
  final Map<String, AssetRef> assets;

  /// Declared variables with their initial values.
  final Map<String, int> variables;
  final String start;
  final Map<String, ScriptStep> steps;
}
