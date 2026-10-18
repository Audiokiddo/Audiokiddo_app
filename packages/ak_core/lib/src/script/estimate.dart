import 'model.dart';

/// About how many seconds a game still lasts from step [from]: the shortest way to an end
/// (a child who answers at once), with recordings timed by their size. Branching stories end
/// sooner on some paths, so the catalog's length alone said "7 min" when the play was over.
int estimatedSecondsLeft(GameScript script, String from, {double bytesPerSecond = 8400}) {
  double seconds(String? asset) {
    final ref = asset == null ? null : script.assets[asset];
    return ref == null ? 0 : ref.bytes / bytesPerSecond;
  }

  double cost(ScriptStep step) => switch (step) {
    PlayStep(:final asset) => seconds(asset),
    WaitStep(:final durationMs) => durationMs / 1000,
    EndStep(:final asset) => seconds(asset),
    InputStep() || ChoiceStep() => 3,
    _ => 0,
  };

  // Dijkstra over the steps; the cost of a step is paid when it is reached.
  final best = <String, double>{};
  final open = <String, double>{};
  final first = script.steps[from];
  if (first == null) return 0;
  open[from] = cost(first);
  while (open.isNotEmpty) {
    final id = open.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
    final here = open.remove(id)!;
    if (best.containsKey(id)) continue;
    best[id] = here;
    final step = script.steps[id];
    if (step == null) continue;
    if (step is EndStep) return here.round();
    for (final next in step.targets) {
      final target = script.steps[next];
      if (target == null || best.containsKey(next)) continue;
      final through = here + cost(target);
      if (through < (open[next] ?? double.infinity)) open[next] = through;
    }
  }
  return 0;
}
