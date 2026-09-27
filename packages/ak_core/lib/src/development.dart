import 'catalog.dart';
import 'content.dart';

/// What the parent wants to develop (the short parent quiz). Mapped to catalog skills.
enum DevGoal {
  imagination({'wyobraźnia', 'opowiadanie'}),
  language({'słownictwo'}),
  logic({'logiczne myślenie'}),
  listening({'słuchanie', 'koncentracja'}),
  movement({'ruch', 'rytm'}),
  calm({'wyciszenie'});

  const DevGoal(this.skills);

  final Set<String> skills;
}

/// A child, kept only on this device (ARCHITECTURE §4: no child data on the server).
/// [name] is an optional nickname the parent may leave empty.
class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.startedOn,
    this.goals = const {},
    this.situations = const {},
    this.dailyMinutes = 10,
  });

  factory ChildProfile.fromJson(Map<String, Object?> json) => ChildProfile(
    id: json['id']! as String,
    name: json['name'] as String? ?? '',
    age: json['age']! as int,
    startedOn: DateTime.parse(json['started_on']! as String),
    goals: {
      for (final g in (json['goals'] as List? ?? const []).cast<String>()) ?DevGoal.values.asNameMap()[g],
    },
    situations: {
      for (final s in (json['situations'] as List? ?? const []).cast<String>())
        ?Situation.values.asNameMap()[s],
    },
    dailyMinutes: json['daily_minutes'] as int? ?? 10,
  );

  final String id;
  final String name;
  final int age;
  final DateTime startedOn;
  final Set<DevGoal> goals;
  final Set<Situation> situations;
  final int dailyMinutes;

  ChildProfile copyWith({
    String? name,
    int? age,
    Set<DevGoal>? goals,
    Set<Situation>? situations,
    int? dailyMinutes,
  }) => ChildProfile(
    id: id,
    name: name ?? this.name,
    age: age ?? this.age,
    startedOn: startedOn,
    goals: goals ?? this.goals,
    situations: situations ?? this.situations,
    dailyMinutes: dailyMinutes ?? this.dailyMinutes,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'started_on': _day(startedOn).toIso8601String(),
    'goals': [for (final g in goals) g.name],
    'situations': [for (final s in situations) s.name],
    'daily_minutes': dailyMinutes,
  };
}

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// Features the plan introduces one at a time, so a new parent is not flooded on day one.
enum PlanTip { phoneDown, kidsMode, download, favorites, microphone, sleepTimer, printables, account }

/// Levels of the development path: short and familiar first, more demanding later.
class PlanLevel {
  const PlanLevel(this.number, this.firstDay, this.lastDay);

  final int number;
  final int firstDay;
  final int lastDay;

  static const all = [PlanLevel(1, 1, 7), PlanLevel(2, 8, 14), PlanLevel(3, 15, 21), PlanLevel(4, 22, 30)];

  static PlanLevel of(int day) => all.firstWhere((l) => day <= l.lastDay, orElse: () => all.last);
}

class PlanDay {
  const PlanDay({required this.day, required this.itemIds, this.tip, this.chest = false});

  final int day;
  final List<String> itemIds;
  final PlanTip? tip;

  /// A little reward at the end of each week.
  final bool chest;

  PlanLevel get level => PlanLevel.of(day);
}

const _tips = {
  1: PlanTip.phoneDown,
  2: PlanTip.kidsMode,
  3: PlanTip.download,
  5: PlanTip.favorites,
  8: PlanTip.microphone,
  10: PlanTip.sleepTimer,
  15: PlanTip.printables,
  17: PlanTip.account,
};

/// A day-by-day path for [child]: one portion a day within the parent's daily minutes,
/// matched to the goals, age and situations, never the same activity two days running.
///
/// Level 1 keeps to short recordings and songs; interactive games join at level 2; long
/// adventures (over 10 minutes) at level 3. [canPlay] prefers what the family can already
/// play; locked items still appear (the parent decides whether to unlock them).
List<PlanDay> buildPlan(
  Catalog catalog,
  ChildProfile child, {
  int days = 30,
  bool Function(ContentItem item)? canPlay,
}) {
  final goalSkills = {for (final g in child.goals) ...g.skills};
  final eligible = [
    for (final i in catalog.items)
      if (i.ageMin <= child.age) i,
  ];
  final lastUsed = <String, int>{};
  final plan = <PlanDay>[];

  bool allowed(ContentItem item, int level) => switch (level) {
    1 => item.kind != ContentKind.interactiveGame && item.durationSec <= 8 * 60,
    2 => item.durationSec <= 10 * 60,
    _ => true,
  };

  double score(ContentItem item, int day) {
    var s = 0.0;
    s += 3 * item.skills.where(goalSkills.contains).length;
    s += item.situations.where(child.situations.contains).length.toDouble();
    if (child.goals.contains(DevGoal.calm) && item.situations.contains(Situation.przedSnem)) s += 3;
    if (child.goals.contains(DevGoal.movement) && item.kind == ContentKind.song) s += 2;
    if (canPlay?.call(item) ?? true) s += 4;
    final used = lastUsed[item.id];
    if (used != null) s -= used >= day - 2 ? 100 : 6 / (day - used);
    // Stable variety between items with the same score.
    s += ((item.id.hashCode ^ (day * 7919)) & 0xff) / 2560;
    return s;
  }

  for (var day = 1; day <= days; day++) {
    final level = PlanLevel.of(day).number;
    final budget = child.dailyMinutes * 60 + 90; // a little slack: games vary in length
    final ranked = [
      for (final i in eligible)
        if (allowed(i, level)) i,
    ]..sort((a, b) => score(b, day).compareTo(score(a, day)));
    final picked = <ContentItem>[];
    var seconds = 0;
    final packsToday = <String?>{};
    for (final item in ranked) {
      if (picked.length == 3) break;
      if (lastUsed[item.id] != null && lastUsed[item.id]! >= day - 1) continue;
      if (picked.isNotEmpty && seconds + item.durationSec > budget) continue;
      // Mix packs within a day when there is a choice.
      if (picked.isNotEmpty && item.packId != null && packsToday.contains(item.packId) && ranked.length > 6) {
        continue;
      }
      picked.add(item);
      packsToday.add(item.packId);
      seconds += item.durationSec;
    }
    if (picked.isEmpty && ranked.isNotEmpty) picked.add(ranked.first);
    for (final item in picked) {
      lastUsed[item.id] = day;
    }
    plan.add(
      PlanDay(day: day, itemIds: [for (final i in picked) i.id], tip: _tips[day], chest: day % 7 == 0),
    );
  }
  return plan;
}

/// One finished (or abandoned) activity of a child, recorded on this device.
class ActivityResult {
  const ActivityResult({
    required this.childId,
    required this.itemId,
    required this.at,
    required this.seconds,
    this.completed = true,
    this.answers = 0,
    this.correct,
  });

  factory ActivityResult.fromJson(Map<String, Object?> json) => ActivityResult(
    childId: json['child']! as String,
    itemId: json['item']! as String,
    at: DateTime.parse(json['at']! as String),
    seconds: json['seconds'] as int? ?? 0,
    completed: json['completed'] as bool? ?? true,
    answers: json['answers'] as int? ?? 0,
    correct: json['correct'] as int?,
  );

  final String childId;
  final String itemId;
  final DateTime at;
  final int seconds;
  final bool completed;

  /// Answers the game heard or got by touch.
  final int answers;

  /// Correct answers, when the game scores them (script variable `score`).
  final int? correct;

  Map<String, Object?> toJson() => {
    'child': childId,
    'item': itemId,
    'at': at.toIso8601String(),
    'seconds': seconds,
    'completed': completed,
    'answers': answers,
    if (correct != null) 'correct': correct,
  };
}

/// Where the child is on the path: [completedDays] done, [currentDay] open today (one new
/// portion per calendar day), and whether today's portion is already done.
class PlanPosition {
  const PlanPosition({required this.completedDays, required this.currentDay, required this.todayDone});

  final int completedDays;
  final int currentDay;
  final bool todayDone;
}

/// Plan days count as done in order: a day is done once all its activities were completed
/// on or after the calendar day it opened. At most one new day opens per calendar day.
PlanPosition planPosition(List<PlanDay> plan, List<ActivityResult> results, DateTime now) {
  final today = _day(now);
  var completed = 0;
  DateTime? lastDone;
  for (final day in plan) {
    // The day opens the calendar day after the previous one was finished (day 1: any time).
    final opensOn = lastDone?.add(const Duration(days: 1));
    final done = day.itemIds.every(
      (id) => results.any(
        (r) => r.itemId == id && r.completed && (opensOn == null || !_day(r.at).isBefore(opensOn)),
      ),
    );
    if (!done) break;
    final finishedAt = [
      for (final id in day.itemIds)
        results
            .where((r) => r.itemId == id && r.completed && (opensOn == null || !_day(r.at).isBefore(opensOn)))
            .map((r) => _day(r.at))
            .reduce((a, b) => a.isBefore(b) ? a : b),
    ].reduce((a, b) => a.isAfter(b) ? a : b);
    completed++;
    lastDone = finishedAt;
  }
  final todayDone = lastDone != null && !lastDone.isBefore(today);
  final current = todayDone ? completed : completed + 1;
  return PlanPosition(
    completedDays: completed,
    currentDay: current.clamp(1, plan.length),
    todayDone: todayDone,
  );
}

/// Numbers for the parent's progress screen.
class ChildProgress {
  const ChildProgress({
    required this.streak,
    required this.activeDays,
    required this.minutes,
    required this.activities,
    required this.answers,
    required this.scored,
    required this.correct,
    required this.skillPractice,
    required this.skillCorrect,
  });

  /// Days in a row (ending today or yesterday) with at least one finished activity.
  final int streak;
  final int activeDays;
  final int minutes;
  final int activities;
  final int answers;

  /// Answers in games that score them, and how many of those were correct.
  final int scored;
  final int correct;

  /// Finished activities per catalog skill.
  final Map<String, int> skillPractice;

  /// Correct / scored answers per skill (games that score).
  final Map<String, ({int correct, int scored})> skillCorrect;

  double? get accuracy => scored == 0 ? null : correct / scored;
}

ChildProgress summarizeProgress(List<ActivityResult> results, Catalog catalog, DateTime now) {
  final days = {
    for (final r in results)
      if (r.completed) _day(r.at),
  };
  var streak = 0;
  var cursor = _day(now);
  if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  final practice = <String, int>{};
  final skillCorrect = <String, ({int correct, int scored})>{};
  var scored = 0;
  var correct = 0;
  for (final r in results) {
    final item = catalog.item(r.itemId);
    if (item == null) continue;
    if (r.completed) {
      for (final s in item.skills) {
        practice[s] = (practice[s] ?? 0) + 1;
      }
    }
    if (r.correct != null && r.answers > 0) {
      scored += r.answers;
      correct += r.correct!;
      for (final s in item.skills) {
        final prev = skillCorrect[s] ?? (correct: 0, scored: 0);
        skillCorrect[s] = (correct: prev.correct + r.correct!, scored: prev.scored + r.answers);
      }
    }
  }
  return ChildProgress(
    streak: streak,
    activeDays: days.length,
    minutes: results.fold(0, (sum, r) => sum + r.seconds) ~/ 60,
    activities: results.where((r) => r.completed).length,
    answers: results.fold(0, (sum, r) => sum + r.answers),
    scored: scored,
    correct: correct,
    skillPractice: practice,
    skillCorrect: skillCorrect,
  );
}

enum AdviceKind { excelling, needsPractice, untouchedGoal, comeBack, levelUp }

/// A suggestion for the parent, e.g. "logic goes great, try Detektyw".
class Advice {
  const Advice(this.kind, {this.skill, this.packId});

  final AdviceKind kind;
  final String? skill;
  final String? packId;
}

/// Plain rules the parent can follow: praise what goes well, suggest a pack for a goal not
/// practised yet, gently bring the family back after a break.
List<Advice> adviseParent(
  ChildProfile child,
  ChildProgress progress,
  Catalog catalog, {
  DateTime? lastActivity,
  required DateTime now,
}) {
  final advice = <Advice>[];
  if (lastActivity != null && now.difference(lastActivity).inDays >= 3) {
    advice.add(const Advice(AdviceKind.comeBack));
  }
  String? packFor(String skill) {
    for (final pack in catalog.packs) {
      if (pack.ageMin > child.age) continue;
      if (catalog.items.any((i) => i.packId == pack.id && i.skills.contains(skill))) return pack.id;
    }
    return null;
  }

  for (final MapEntry(key: skill, value: v) in progress.skillCorrect.entries) {
    if (v.scored < 5) continue;
    final rate = v.correct / v.scored;
    if (rate >= 0.8) {
      final harder = child.age >= 6 && catalog.pack('detektyw') != null ? 'detektyw' : null;
      advice.add(Advice(AdviceKind.excelling, skill: skill, packId: harder));
    } else if (rate < 0.5) {
      advice.add(Advice(AdviceKind.needsPractice, skill: skill, packId: packFor(skill)));
    }
  }
  for (final goal in child.goals) {
    final practised = goal.skills.any((s) => (progress.skillPractice[s] ?? 0) > 0);
    final available = goal.skills.any((s) => catalog.items.any((i) => i.skills.contains(s)));
    if (!practised && available && progress.activities >= 3) {
      advice.add(
        Advice(AdviceKind.untouchedGoal, skill: goal.skills.first, packId: packFor(goal.skills.first)),
      );
    }
  }
  if (progress.activeDays >= 7 && progress.streak >= 5) advice.add(const Advice(AdviceKind.levelUp));
  return advice;
}
