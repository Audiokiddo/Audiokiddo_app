import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/szop.dart';
import '../session/session.dart';
import 'day_routine.dart';

/// The moments of the day a plan is made for (parents, 2026-10-18: "the modes should feel like
/// more than the same plays"). Each has its own plays (the catalog's `moments`), its own colour
/// and Szop’en hosting it: a hello for the moment, short asides between plays and a goodbye.
enum PlayMoment {
  rano('Poranek z Szop’enem', Color(0xFFFFF0C2), SzopPose.zadowolony, starts: 3, links: 6, ends: 2),
  auto('W drogę z Szop’enem', Color(0xFFCDEDEA), SzopPose.chytry, starts: 0, links: 0, ends: 0),
  po('Po przedszkolu z Szop’enem', Color(0xFFE8DDF4), SzopPose.zmeczony, starts: 3, links: 6, ends: 2),
  dom('Dzień w domu z Szop’enem', Color(0xFFDDEFD9), SzopPose.klaszcze, starts: 3, links: 5, ends: 2),
  chory('Na leżąco z Szop’enem', Color(0xFFD9E6F5), SzopPose.nasluchuje, starts: 2, links: 4, ends: 2),
  czekamy('Czekamy z Szop’enem', Color(0xFFF3E0D2), SzopPose.znudzony, starts: 3, links: 3, ends: 2),
  kolacja('Kolacja z Szop’enem', Color(0xFFFFE3C2), SzopPose.prosi, starts: 3, links: 5, ends: 2);

  const PlayMoment(this.label, this.color, this.pose, {required this.starts, required this.links, required this.ends});

  /// "Poranek z Szop’enem": on the plan, the session screen and the lock screen.
  final String label;
  final Color color;
  final SzopPose pose;

  /// How many recorded lines of each kind he has (`assets/audio/kiddo/m_<name>_….m4a`).
  final int starts, links, ends;

  /// The plan screen's `pora` (rano, po, dom, chory, czekamy, kolacja); a meal by default.
  static PlayMoment of(String? pora) => switch (pora) {
    'rano' => rano,
    'po' => po,
    'dom' => dom,
    'chory' => chory,
    'czekamy' => czekamy,
    _ => kolacja,
  };
}

/// What Szop’en knows about today from Mój dzień.
@immutable
class DayContext {
  const DayContext({this.daycare = false, this.friday = false, this.sick = false, this.afternoon = false});

  factory DayContext.of(DayRoutine? routine, DateTime now) {
    if (routine == null || !routine.configured) return DayContext(afternoon: now.hour >= 12);
    final reason = homeReason(routine, now);
    return DayContext(
      daycare: reason == null,
      friday: reason == null && now.weekday == DateTime.friday,
      sick: reason == 'Dziecko choruje',
      afternoon: now.hour >= 12,
    );
  }

  /// A kindergarten day (not a weekend, holiday, day off or sick day).
  final bool daycare;
  final bool friday;
  final bool sick;
  final bool afternoon;
}

/// Szop’en's opening line for [moment] today; [variant] turns the lines day by day.
String momentStart(PlayMoment moment, DayContext day, int variant) {
  String pick(String base, int count) => '${base}_${variant % count + 1}';
  return switch (moment) {
    PlayMoment.rano when day.friday => 'c_piatek',
    PlayMoment.rano when day.daycare => pick('c_rano_przedszkole', 2),
    PlayMoment.rano => pick('c_rano_wolne', 2),
    PlayMoment.auto when day.daycare => pick(day.afternoon ? 'c_auto_powrot' : 'c_auto_przedszkole', 2),
    PlayMoment.auto => tripStartLines[variant % tripStartLines.length],
    _ => pick('m_${moment.name}_start', moment.starts),
  };
}

/// His goodbye: in the morning of a kindergarten day "Czas na buty!".
String momentEnd(PlayMoment moment, DayContext day, int variant) => switch (moment) {
  PlayMoment.rano when day.daycare => 'c_rano_buty_${variant % 2 + 1}',
  PlayMoment.auto => tripEndLines[variant % tripEndLines.length],
  _ => 'm_${moment.name}_end_${variant % moment.ends + 1}',
};

/// A plan for [moment]: Szop’en's hello, the plays with a short aside between them, his
/// goodbye. On a sick day the gentle lines of "Na leżąco" whatever the plan.
List<SessionStep> buildMomentPlan(List<ContentItem> items, PlayMoment moment, DayContext day, {int variant = 0}) {
  final host = day.sick && moment != PlayMoment.auto ? PlayMoment.chory : moment;
  if (items.isEmpty) return const [];
  return [
    LineStep(host == moment ? momentStart(moment, day, variant) : momentStart(host, day, variant)),
    for (final (k, item) in items.indexed) ...[
      if (k > 0 && host.links > 0) LineStep('m_${host.name}_link_${(variant + k) % host.links + 1}'),
      ItemStep(item),
    ],
    LineStep(momentEnd(host, day, variant)),
  ];
}

/// Plays for [moment] first (the catalog marks which suit it), then the rest as a fallback.
int momentScore(ContentItem i, PlayMoment moment) => i.moments.contains(moment.name) ? 6 : 0;
