import 'model.dart';
import 'validator.dart';

/// What the app must do next. The runner never touches audio, timers or the microphone.
sealed class EngineCommand {
  const EngineCommand();
}

/// Play one recorded segment, then report [SegmentFinished].
class PlaySegment extends EngineCommand {
  const PlaySegment(this.asset);

  final String asset;
}

/// Give the child time (optionally over a looped bed), then report [WaitElapsed].
class WaitFor extends EngineCommand {
  const WaitFor(this.duration, {this.loopAsset});

  final Duration duration;
  final String? loopAsset;
}

/// Listen for [input] for [window]; report [InputDetected], [InputTimedOut] or [InputFailed].
class Listen extends EngineCommand {
  const Listen(this.input, this.window, {this.minCount});

  final InputKind input;
  final Duration window;
  final int? minCount;
}

/// The session is over; play [asset] if given, then close.
class Finish extends EngineCommand {
  const Finish({this.asset, this.reason = FinishReason.completed});

  final String? asset;
  final FinishReason reason;
}

enum FinishReason { completed, stepLimit, loopLimit }

sealed class EngineEvent {
  const EngineEvent();
}

class SegmentFinished extends EngineEvent {
  const SegmentFinished();
}

class WaitElapsed extends EngineEvent {
  const WaitElapsed();
}

class InputDetected extends EngineEvent {
  const InputDetected({this.count = 1});

  final int count;
}

class InputTimedOut extends EngineEvent {
  const InputTimedOut();
}

/// The input could not be used; the runner switches to the step's fallback.
class InputFailed extends EngineEvent {
  const InputFailed(this.reason);

  final FallbackReason reason;
}

/// State needed to resume after an interruption: the current step is replayed from its start.
class RunnerSnapshot {
  const RunnerSnapshot({
    required this.stepId,
    required this.variables,
    required this.visits,
    required this.executed,
  });

  final String stepId;
  final Map<String, int> variables;
  final Map<String, int> visits;
  final int executed;
}

/// Interprets a validated [GameScript] (ARCHITECTURE §10).
///
/// Loop limits: a `branch` over its `max_visits` takes its `else` exit; a `goto` over its
/// limit ends the session. More than [ScriptLimits.maxStepsPerSession] steps also end it,
/// so broken content can never loop forever.
class ScriptRunner {
  ScriptRunner(this.script, {Set<FallbackReason> unavailable = const {}, RunnerSnapshot? resumeFrom})
    : _unavailable = {...unavailable},
      _variables = {...(resumeFrom?.variables ?? script.variables)},
      _visits = {...?resumeFrom?.visits},
      _executed = resumeFrom?.executed ?? 0,
      _current = resumeFrom?.stepId ?? script.start;

  final GameScript script;
  final Set<FallbackReason> _unavailable;
  final Map<String, int> _variables;
  final Map<String, int> _visits;
  int _executed;
  String _current;

  /// The inline fallback step being executed instead of an input step, if any.
  ScriptStep? _activeFallback;
  bool _finished = false;

  Map<String, int> get variables => Map.unmodifiable(_variables);
  String get currentStepId => _current;
  bool get isFinished => _finished;

  RunnerSnapshot snapshot() =>
      RunnerSnapshot(stepId: _current, variables: {..._variables}, visits: {..._visits}, executed: _executed);

  /// Marks an input source as (un)available, e.g. the screen got locked or the parent
  /// denied the microphone. Affects the next input step.
  void setAvailability(FallbackReason reason, {required bool available}) =>
      available ? _unavailable.remove(reason) : _unavailable.add(reason);

  EngineCommand start() => _resolve(_current);

  EngineCommand next(EngineEvent event) {
    if (_finished) return const Finish();
    final fallback = _activeFallback;
    if (fallback != null) {
      _activeFallback = null;
      return _advanceFrom(fallback);
    }
    final step = script.steps[_current]!;
    return switch ((step, event)) {
      (PlayStep(:final next), SegmentFinished()) => _resolve(next),
      (WaitStep(:final next), WaitElapsed()) => _resolve(next),
      (final InputStep input, InputDetected(:final count)) =>
        count >= (input.minCount ?? 1) ? _resolve(input.onDetected) : _resolve(input.onTimeout),
      (final InputStep input, InputTimedOut()) => _resolve(input.onTimeout),
      (final InputStep input, InputFailed(:final reason)) => _runFallback(input, reason),
      (EndStep(), _) => _finish(const Finish()),
      // An event that does not match the step (e.g. a late timer) replays the current step.
      _ => _commandFor(step),
    };
  }

  EngineCommand _advanceFrom(ScriptStep fallback) => switch (fallback) {
    PlayStep(:final next) || WaitStep(:final next) => _resolve(next),
    GotoStep(:final target) => _resolve(target),
    _ => _resolve(script.steps[_current]!.targets.first),
  };

  EngineCommand _runFallback(InputStep step, FallbackReason reason) {
    final fallback = step.fallbacks[reason] ?? step.fallbacks[FallbackReason.noMicrophone]!;
    if (fallback is GotoStep) return _resolve(fallback.target);
    _activeFallback = fallback;
    return switch (fallback) {
      WaitStep(:final durationMs, :final loopAsset) => WaitFor(
        Duration(milliseconds: durationMs),
        loopAsset: loopAsset,
      ),
      PlayStep(:final asset) => PlaySegment(asset),
      _ => throw StateError('invalid fallback'),
    };
  }

  /// Follows branch/set/goto steps until one needs the app (audio, wait, input, end).
  EngineCommand _resolve(String stepId) {
    var id = stepId;
    while (true) {
      _executed++;
      if (_executed > ScriptLimits.maxStepsPerSession) {
        return _finish(const Finish(reason: FinishReason.stepLimit));
      }
      _current = id;
      final visits = _visits[id] = (_visits[id] ?? 0) + 1;
      final step = script.steps[id]!;
      switch (step) {
        case BranchStep(:final condition, :final then, :final otherwise, :final maxVisits):
          final overLimit = maxVisits != null && visits > maxVisits;
          id = !overLimit && condition.evaluate(_variables) ? then : otherwise;
        case SetStep(:final variable, :final op, :final value, :final next):
          final current = _variables[variable] ?? 0;
          _variables[variable] = switch (op) {
            SetOp.set => value,
            SetOp.inc => current + value,
            SetOp.dec => current - value,
          };
          id = next;
        case GotoStep(:final target, :final maxVisits):
          if (maxVisits != null && visits > maxVisits) {
            return _finish(const Finish(reason: FinishReason.loopLimit));
          }
          id = target;
        case InputStep() when _unavailable.isNotEmpty:
          final reason = _unavailable.contains(FallbackReason.screenLocked)
              ? FallbackReason.screenLocked
              : _unavailable.first;
          return _runFallback(step, reason);
        default:
          return _commandFor(step);
      }
    }
  }

  EngineCommand _commandFor(ScriptStep step) => switch (step) {
    PlayStep(:final asset) => PlaySegment(asset),
    WaitStep(:final durationMs, :final loopAsset) => WaitFor(
      Duration(milliseconds: durationMs),
      loopAsset: loopAsset,
    ),
    InputStep(:final input, :final windowMs, :final minCount) => Listen(
      input,
      Duration(milliseconds: windowMs),
      minCount: minCount,
    ),
    EndStep(:final asset) => _finish(Finish(asset: asset)),
    _ => throw StateError('not an audible step: ${step.id}'),
  };

  Finish _finish(Finish finish) {
    _finished = true;
    return finish;
  }
}
