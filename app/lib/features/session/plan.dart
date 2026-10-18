import 'package:ak_core/ak_core.dart';

import 'session.dart';

/// A plan is the list of [SessionStep]s of a ride or a dinner. The parent edits only the plays
/// (not Szop'en's lines): they are addressed by their position among the plays ahead, counted
/// from the first step that may still change ([from]). All functions return a new list.

/// Indexes in [steps] of the plays from [from] on, in order.
List<int> playSlots(List<SessionStep> steps, int from) => [
  for (var i = from < 0 ? 0 : from; i < steps.length; i++)
    if (steps[i] is ItemStep) i,
];

/// The plays from [from] on.
List<ContentItem> playsFrom(List<SessionStep> steps, int from) => [
  for (final i in playSlots(steps, from)) (steps[i] as ItemStep).item,
];

/// Drops the play at [pos] (among the plays ahead).
List<SessionStep> planRemove(List<SessionStep> steps, int pos, {int from = 0}) {
  final slots = playSlots(steps, from);
  if (pos < 0 || pos >= slots.length) return steps;
  return [...steps]..removeAt(slots[pos]);
}

/// Moves the play at [oldPos] to [newPos] ("insert before", like ReorderableListView's
/// onReorderItem); Szop'en's lines stay where they are.
List<SessionStep> planReorder(List<SessionStep> steps, int oldPos, int newPos, {int from = 0}) {
  final slots = playSlots(steps, from);
  if (oldPos < 0 || oldPos >= slots.length || newPos < 0 || newPos >= slots.length || oldPos == newPos) {
    return steps;
  }
  final plays = [for (final i in slots) steps[i] as ItemStep];
  plays.insert(newPos, plays.removeAt(oldPos));
  final out = [...steps];
  for (var k = 0; k < slots.length; k++) {
    out[slots[k]] = plays[k];
  }
  return out;
}

/// Swaps the play at [pos] for [item] (the fade-out of the slot stays).
List<SessionStep> planReplace(List<SessionStep> steps, int pos, ContentItem item, {int from = 0}) {
  final slots = playSlots(steps, from);
  if (pos < 0 || pos >= slots.length) return steps;
  final old = steps[slots[pos]] as ItemStep;
  return [...steps]..[slots[pos]] = ItemStep(item, fadeOut: old.fadeOut);
}

/// Adds [items] after the last play, before the closing lines.
List<SessionStep> planAdd(List<SessionStep> steps, List<ContentItem> items) {
  if (items.isEmpty) return steps;
  final last = steps.lastIndexWhere((s) => s is ItemStep);
  final at = last < 0 ? steps.length : last + 1;
  return [...steps]..insertAll(at, [for (final i in items) ItemStep(i)]);
}

/// Seconds of the plan from step [index] on: the plays' own length (the one playing now only
/// what is left of it, as [position] of [current]) plus the quiet breaks. A rough "how long
/// still", not to the second; Szop'en's short lines are not counted.
int planSecondsLeft(
  List<SessionStep> steps, {
  required int index,
  Duration position = Duration.zero,
  bool started = true,
}) {
  var seconds = 0;
  for (var i = index < 0 ? 0 : index; i < steps.length; i++) {
    switch (steps[i]) {
      case ItemStep(:final item):
        final done = i == index && started ? position.inSeconds : 0;
        seconds += (item.durationSec - done).clamp(0, 1 << 30);
      case LineStep(:final pauseAfter):
        seconds += pauseAfter.inSeconds;
      case ParentStep():
        break;
    }
  }
  return seconds;
}

/// Plays a ride or a dinner may use, best first: what suits the road (or the table), what is
/// already on the phone, short ones. [exclude] are plays already in the plan.
List<ContentItem> planCandidates(
  Catalog catalog, {
  required int age,
  required bool Function(ContentItem) canPlay,
  Set<String> exclude = const {},
  Set<String> downloaded = const {},
  bool dinner = false,
  String? moment,
}) {
  bool ok(ContentItem i) =>
      !exclude.contains(i.id) &&
      i.audio.isNotEmpty &&
      i.ageMin <= age &&
      canPlay(i) &&
      (dinner
          ? i.kind == ContentKind.audioGame && i.requirements.isEmpty
          : i.kind != ContentKind.interactiveGame);
  double score(ContentItem i) =>
      (i.moments.contains(moment ?? (dinner ? 'kolacja' : 'auto')) ? 6 : 0) +
      (i.situations.contains(Situation.podroz) ? 4 : 0) +
      (downloaded.contains(i.id) ? 3 : 0) +
      (i.durationSec <= 10 * 60 ? 1 : 0);
  return [
    for (final i in catalog.items)
      if (ok(i)) i,
  ]..sort((a, b) => score(b).compareTo(score(a)));
}

/// The first of [candidates] that together last at least [minutes] (always at least one while
/// there is any): what "+10 min" adds.
List<ContentItem> playsForMinutes(List<ContentItem> candidates, int minutes) {
  final out = <ContentItem>[];
  var seconds = 0;
  for (final i in candidates) {
    if (seconds >= minutes * 60) break;
    out.add(i);
    seconds += i.durationSec;
  }
  return out;
}

/// "23 min", "1 h 5 min": the time left, rounded up to whole minutes.
String minutesLabel(int seconds) {
  final minutes = (seconds + 59) ~/ 60;
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}
