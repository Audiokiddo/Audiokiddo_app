import 'model.dart';

/// Hard limits enforced by the engine (ARCHITECTURE §10.3).
abstract final class ScriptLimits {
  static const maxInputWindowMs = 30000;
  static const maxWaitMs = 120000;
  static const maxStepsPerSession = 500;
  static const maxSessionMinutes = 60;
}

const _inputsSupportedInV1 = {
  InputKind.tapAnywhere,
  InputKind.clap,
  InputKind.voiceActivity,
  InputKind.motionShake,
};

enum IssueSeverity { error, warning }

class ScriptIssue {
  const ScriptIssue(this.severity, this.stepId, this.message);

  final IssueSeverity severity;

  /// Step the issue refers to, or null for script-level issues.
  final String? stepId;
  final String message;

  @override
  String toString() => '${severity.name}${stepId == null ? '' : ' [$stepId]'}: $message';
}

class ScriptValidation {
  const ScriptValidation(this.issues);

  final List<ScriptIssue> issues;

  List<ScriptIssue> get errors => issues.where((i) => i.severity == IssueSeverity.error).toList();
  List<ScriptIssue> get warnings => issues.where((i) => i.severity == IssueSeverity.warning).toList();

  /// A script with errors must not start; warnings are shown only in Studio.
  bool get isValid => errors.isEmpty;
}

/// Checks a parsed script so broken content can never hang or crash the app.
ScriptValidation validateScript(GameScript script, {int engine = engineVersion}) {
  final issues = <ScriptIssue>[];
  void error(String? step, String msg) => issues.add(ScriptIssue(IssueSeverity.error, step, msg));
  void warn(String? step, String msg) => issues.add(ScriptIssue(IssueSeverity.warning, step, msg));

  if (script.schemaVersion != scriptSchemaVersion) {
    error(null, 'unsupported schema_version ${script.schemaVersion}');
  }
  if (script.minEngineVersion > engine) {
    error(null, 'requires engine ${script.minEngineVersion}, this app has $engine');
  }
  if (!script.steps.containsKey(script.start)) {
    error(null, 'start step "${script.start}" does not exist');
  }
  if (!script.steps.values.any((s) => s is EndStep)) {
    error(null, 'script has no end step');
  }

  void checkAsset(String stepId, String? asset) {
    if (asset != null && !script.assets.containsKey(asset)) {
      error(stepId, 'unknown asset "$asset"');
    }
  }

  void checkStep(ScriptStep step, {required String reportAs}) {
    for (final target in step.targets) {
      if (!script.steps.containsKey(target)) error(reportAs, 'jumps to missing step "$target"');
    }
    switch (step) {
      case PlayStep(:final asset):
        checkAsset(reportAs, asset);
      case WaitStep(:final durationMs, :final loopAsset):
        checkAsset(reportAs, loopAsset);
        if (durationMs > ScriptLimits.maxWaitMs) {
          error(reportAs, 'wait longer than ${ScriptLimits.maxWaitMs} ms');
        }
      case EndStep(:final asset):
        checkAsset(reportAs, asset);
      case InputStep():
        if (!_inputsSupportedInV1.contains(step.input)) {
          error(reportAs, 'input "${step.input.name}" is not supported by this engine');
        }
        if (step.windowMs > ScriptLimits.maxInputWindowMs) {
          error(reportAs, 'input window longer than ${ScriptLimits.maxInputWindowMs} ms');
        }
        for (final reason in FallbackReason.values) {
          if (!step.fallbacks.containsKey(reason)) error(reportAs, 'missing fallback for "${reason.name}"');
        }
        // Aliased reasons share one step object; check each distinct fallback once.
        final checked = Set<ScriptStep>.identity();
        for (final MapEntry(key: reason, value: fallback) in step.fallbacks.entries) {
          if (checked.add(fallback)) checkStep(fallback, reportAs: '$reportAs (fallback ${reason.name})');
        }
      case BranchStep(:final condition):
        if (!script.variables.containsKey(condition.variable)) {
          error(reportAs, 'undeclared variable "${condition.variable}"');
        }
      case SetStep(:final variable):
        if (!script.variables.containsKey(variable)) {
          error(reportAs, 'undeclared variable "$variable"');
        }
      case GotoStep():
        break;
    }
  }

  for (final step in script.steps.values) {
    checkStep(step, reportAs: step.id);
  }

  // Graph checks only make sense when every reference resolves.
  if (issues.any((i) => i.severity == IssueSeverity.error)) return ScriptValidation(issues);

  final reachable = _reachableFrom(script.start, script);
  for (final id in script.steps.keys) {
    if (!reachable.contains(id)) warn(id, 'step is never reached');
  }

  // Every reachable step must be able to finish.
  final canFinish = _stepsThatReachEnd(script);
  for (final id in reachable) {
    if (!canFinish.contains(id)) error(id, 'no path from this step to an end step');
  }

  // Every loop must pass through a step with max_visits, otherwise it can run forever.
  final unbounded = {
    for (final id in reachable)
      if (script.steps[id]!.maxVisits == null) id,
  };
  final cycle = _findCycle(unbounded, script);
  if (cycle != null) {
    error(cycle.first, 'loop without max_visits: ${cycle.join(' → ')}');
  }

  return ScriptValidation(issues);
}

Set<String> _reachableFrom(String start, GameScript script) {
  final seen = <String>{};
  final stack = [start];
  while (stack.isNotEmpty) {
    final id = stack.removeLast();
    if (!seen.add(id)) continue;
    stack.addAll(script.steps[id]!.targets);
  }
  return seen;
}

Set<String> _stepsThatReachEnd(GameScript script) {
  final incoming = <String, List<String>>{};
  for (final step in script.steps.values) {
    for (final t in step.targets) {
      (incoming[t] ??= []).add(step.id);
    }
  }
  final result = <String>{};
  final stack = [
    for (final s in script.steps.values)
      if (s is EndStep) s.id,
  ];
  while (stack.isNotEmpty) {
    final id = stack.removeLast();
    if (!result.add(id)) continue;
    stack.addAll(incoming[id] ?? const []);
  }
  return result;
}

/// Returns one cycle made only of [nodes], or null when that subgraph is acyclic.
List<String>? _findCycle(Set<String> nodes, GameScript script) {
  const white = 0, grey = 1, black = 2;
  final colour = {for (final n in nodes) n: white};
  final path = <String>[];

  List<String>? visit(String id) {
    colour[id] = grey;
    path.add(id);
    for (final t in script.steps[id]!.targets) {
      if (!nodes.contains(t)) continue;
      if (colour[t] == grey) return [...path.sublist(path.indexOf(t)), t];
      if (colour[t] == white) {
        final found = visit(t);
        if (found != null) return found;
      }
    }
    path.removeLast();
    colour[id] = black;
    return null;
  }

  for (final n in nodes) {
    if (colour[n] == white) {
      final found = visit(n);
      if (found != null) return found;
    }
  }
  return null;
}
