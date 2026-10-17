import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/database.dart';
import '../../core/storage/storage_providers.dart';

/// The family's day as the parent describes it (Więcej → Mój dzień): which days the child goes
/// to kindergarten and the family drives, and the usual hours. The app reads it to say what
/// fits right now (the "teraz" card on Start and the day's notifications). Local only.
class DayRoutine {
  const DayRoutine({
    this.daycareDays = const {1, 2, 3, 4, 5},
    this.driveDays = const {1, 2, 3, 4, 5},
    this.wake = 7 * 60,
    this.leave = 7 * 60 + 45,
    this.back = 16 * 60,
    this.drive = 20,
    this.dinner = 18 * 60,
    this.bedtime = 20 * 60,
    this.morningMinutes = 15,
    this.homeDates = const {},
    this.sickUntil,
    this.notify = const {DayMomentKind.car, DayMomentKind.afterDaycare, DayMomentKind.bedtime},
    this.configured = false,
  });

  /// Weekdays (1 = Monday … 7 = Sunday) with kindergarten or school.
  final Set<int> daycareDays;

  /// Weekdays with a drive there and back.
  final Set<int> driveDays;

  /// Minutes after midnight.
  final int wake, leave, back, dinner, bedtime;

  /// How long a drive lasts, in minutes (the car plan's length).
  final int drive;

  /// The morning cycle the parent picked (10, 15, 20 or 30 minutes).
  final int morningMinutes;

  /// Extra days at home (holidays of the kindergarten, a day off), as yyyy-mm-dd.
  final Set<String> homeDates;

  /// The child is ill and stays at home up to and including this day.
  final DateTime? sickUntil;

  /// Which moments may send a notification (only when reminders are allowed).
  final Set<DayMomentKind> notify;

  /// The parent saved the routine at least once (until then the defaults guess a usual week).
  final bool configured;

  DayRoutine copyWith({
    Set<int>? daycareDays,
    Set<int>? driveDays,
    int? wake,
    int? leave,
    int? back,
    int? drive,
    int? dinner,
    int? bedtime,
    int? morningMinutes,
    Set<String>? homeDates,
    DateTime? sickUntil,
    bool clearSick = false,
    Set<DayMomentKind>? notify,
  }) => DayRoutine(
    daycareDays: daycareDays ?? this.daycareDays,
    driveDays: driveDays ?? this.driveDays,
    wake: wake ?? this.wake,
    leave: leave ?? this.leave,
    back: back ?? this.back,
    drive: drive ?? this.drive,
    dinner: dinner ?? this.dinner,
    bedtime: bedtime ?? this.bedtime,
    morningMinutes: morningMinutes ?? this.morningMinutes,
    homeDates: homeDates ?? this.homeDates,
    sickUntil: clearSick ? null : (sickUntil ?? this.sickUntil),
    notify: notify ?? this.notify,
    configured: true,
  );

  Map<String, Object?> toJson() => {
    'daycare': daycareDays.toList()..sort(),
    'drive_days': driveDays.toList()..sort(),
    'wake': wake,
    'leave': leave,
    'back': back,
    'drive': drive,
    'dinner': dinner,
    'bedtime': bedtime,
    'morning': morningMinutes,
    'home': homeDates.toList()..sort(),
    'sick': ?sickUntil == null ? null : dayKey(sickUntil!),
    'notify': [for (final k in notify) k.name],
    'configured': configured,
  };

  factory DayRoutine.fromJson(Map<String, Object?> j) {
    Set<int> ints(Object? v, Set<int> fallback) => v is List ? {for (final x in v) (x as num).toInt()} : fallback;
    int minutes(Object? v, int fallback) => v is num ? v.toInt().clamp(0, 24 * 60 - 1) : fallback;
    const d = DayRoutine();
    return DayRoutine(
      daycareDays: ints(j['daycare'], d.daycareDays),
      driveDays: ints(j['drive_days'], d.driveDays),
      wake: minutes(j['wake'], d.wake),
      leave: minutes(j['leave'], d.leave),
      back: minutes(j['back'], d.back),
      drive: minutes(j['drive'], d.drive).clamp(5, 180),
      dinner: minutes(j['dinner'], d.dinner),
      bedtime: minutes(j['bedtime'], d.bedtime),
      morningMinutes: minutes(j['morning'], d.morningMinutes).clamp(5, 60),
      homeDates: j['home'] is List ? {for (final x in j['home']! as List) '$x'} : const {},
      sickUntil: j['sick'] is String ? DateTime.tryParse(j['sick']! as String) : null,
      notify: j['notify'] is List
          ? {
              for (final x in j['notify']! as List)
                ?DayMomentKind.values.where((k) => k.name == x).firstOrNull,
            }
          : d.notify,
      configured: j['configured'] == true,
    );
  }
}

String dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Easter Sunday (Anonymous Gregorian algorithm).
DateTime easterSunday(int year) {
  final a = year % 19, b = year ~/ 100, c = year % 100, d = b ~/ 4, e = b % 4;
  final f = (b + 8) ~/ 25, g = (b - f + 1) ~/ 3, h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7, m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31, day = ((h + l - 7 * m + 114) % 31) + 1;
  return DateTime(year, month, day);
}

/// Polish public holidays (days off work and kindergarten), by name. Wigilia is a day off
/// from 2025.
Map<String, String> polishHolidays(int year) {
  final easter = easterSunday(year);
  DateTime plus(int days) => DateTime(easter.year, easter.month, easter.day + days);
  return {
    dayKey(DateTime(year, 1, 1)): 'Nowy Rok',
    dayKey(DateTime(year, 1, 6)): 'Trzech Króli',
    dayKey(easter): 'Wielkanoc',
    dayKey(plus(1)): 'Poniedziałek Wielkanocny',
    dayKey(DateTime(year, 5, 1)): 'Święto Pracy',
    dayKey(DateTime(year, 5, 3)): 'Święto Konstytucji 3 Maja',
    dayKey(plus(49)): 'Zielone Świątki',
    dayKey(plus(60)): 'Boże Ciało',
    dayKey(DateTime(year, 8, 15)): 'Wniebowzięcie',
    dayKey(DateTime(year, 11, 1)): 'Wszystkich Świętych',
    dayKey(DateTime(year, 11, 11)): 'Święto Niepodległości',
    if (year >= 2025) dayKey(DateTime(year, 12, 24)): 'Wigilia',
    dayKey(DateTime(year, 12, 25)): 'Boże Narodzenie',
    dayKey(DateTime(year, 12, 26)): 'Drugi dzień świąt',
  };
}

/// Why the child is at home on [day] (null: an ordinary kindergarten day).
String? homeReason(DayRoutine r, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  if (r.sickUntil != null && !d.isAfter(r.sickUntil!)) return 'Dziecko choruje';
  if (polishHolidays(d.year)[dayKey(d)] case final name?) return name;
  if (r.homeDates.contains(dayKey(d))) return 'Dzień w domu';
  if (!r.daycareDays.contains(d.weekday)) return d.weekday >= 6 ? 'Weekend' : 'Dzień w domu';
  return null;
}

/// The moments of a family day the app can help with.
enum DayMomentKind { morning, car, afterDaycare, homeDay, meal, bedtime }

/// What fits now: the card's words, where it leads, and when it is worth a notification.
class DayMoment {
  const DayMoment({
    required this.kind,
    required this.title,
    required this.line,
    required this.action,
    required this.route,
    required this.startsAt,
  });

  final DayMomentKind kind;
  final String title;
  final String line;
  final String action;
  final String route;

  /// When this moment begins (a notification goes out then).
  final DateTime startsAt;
}

/// Today's moments in order, from the routine and the calendar.
List<DayMoment> momentsOf(DayRoutine r, DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  DateTime at(int minutes) => d.add(Duration(minutes: minutes));
  final home = homeReason(r, d);
  final sick = home == 'Dziecko choruje';
  final drives = home == null && r.driveDays.contains(d.weekday);
  final moments = <DayMoment>[
    DayMoment(
      kind: DayMomentKind.morning,
      title: home == null ? 'Poranek bez pośpiechu' : 'Dzień dobry! $home',
      line: home == null
          ? '${r.morningMinutes} minut zabaw na rozruch, zanim trzeba wyjść.'
          : 'Zacznijcie dzień od ${r.morningMinutes} minut zabaw. Czas zmienisz jednym dotknięciem.',
      action: 'Włącz ${r.morningMinutes} min',
      route: '/obiad?pora=rano&minuty=${r.morningMinutes}',
      startsAt: at(r.wake),
    ),
    if (drives)
      DayMoment(
        kind: DayMomentKind.car,
        title: 'Za chwilę wyjazd',
        line: 'Zabawy na drogę na ${r.drive} minut. Dziecko odpowiada, Ty prowadzisz.',
        action: 'Zabawy do auta',
        route: '/podroz?minuty=${r.drive}',
        startsAt: at(r.leave - 15),
      ),
    if (home == null && r.daycareDays.contains(d.weekday)) ...[
      if (drives)
        DayMoment(
          kind: DayMomentKind.car,
          title: 'Droga z przedszkola',
          line: 'Na powrót: ${r.drive} minut zabaw zamiast „daleko jeszcze?”.',
          action: 'Zabawy do auta',
          route: '/podroz?minuty=${r.drive}',
          startsAt: at(r.back - 15),
        ),
      DayMoment(
        kind: DayMomentKind.afterDaycare,
        title: 'Po przedszkolu',
        line: 'Kwadrans na kanapie: dziecko odpowiada i wymyśla, a Ty odzyskujesz oddech.',
        action: 'Włącz 15 min',
        route: '/obiad?pora=po&minuty=15',
        startsAt: at(r.back + (drives ? r.drive : 0)),
      ),
    ] else
      DayMoment(
        kind: DayMomentKind.homeDay,
        title: sick ? 'Spokojne zabawy w łóżku' : 'Dzień w domu',
        line: sick
            ? 'Zabawy na leżąco, bez biegania. Dziecko słucha i odpowiada, Ty masz chwilę.'
            : 'Dłuższy blok zabaw na środek dnia, kiedy pomysły się kończą.',
        action: sick ? 'Włącz 20 min' : 'Włącz 30 min',
        route: sick ? '/obiad?pora=chory&minuty=20' : '/obiad?pora=dom&minuty=30',
        startsAt: at(11 * 60),
      ),
    DayMoment(
      kind: DayMomentKind.meal,
      title: 'Kolacja bez wołania',
      line: 'Zabawy jedna po drugiej, kiedy Ty gotujesz.',
      action: 'Włącz 25 min',
      route: '/obiad?pora=kolacja&minuty=25',
      startsAt: at(r.dinner - 45),
    ),
    DayMoment(
      kind: DayMomentKind.bedtime,
      title: 'Pora na dobranoc',
      line: 'Wyciszenie przed snem i spokojny koniec dnia.',
      action: 'Dobranoc',
      route: '/dobranoc',
      startsAt: at(r.bedtime - 30),
    ),
  ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return moments;
}

/// The moment for [now]: the latest one that has begun (each lasts until the next begins),
/// or none before the morning one and after bedtime has passed by an hour.
DayMoment? momentAt(DayRoutine r, DateTime now) {
  final today = momentsOf(r, now);
  DayMoment? current;
  for (final m in today) {
    if (!m.startsAt.isAfter(now)) current = m;
  }
  if (current == null) return null;
  if (current.kind == DayMomentKind.bedtime && now.isAfter(current.startsAt.add(const Duration(minutes: 90)))) {
    return null;
  }
  return current;
}

class DayRoutineController extends AsyncNotifier<DayRoutine> {
  static const key = 'day_routine';

  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<DayRoutine> build() async {
    final raw = await ref.watch(databaseProvider).readValue(key);
    if (raw == null) return const DayRoutine();
    try {
      return DayRoutine.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return const DayRoutine();
    }
  }

  Future<void> save(DayRoutine r) async {
    await _db.writeValue(key, jsonEncode(r.toJson()));
    state = AsyncData(r);
  }

  /// "Dziecko się rozchorowało": at home from today up to and including [until].
  Future<void> sick(DateTime until) async {
    final r = state.value ?? await future;
    await save(r.copyWith(sickUntil: DateTime(until.year, until.month, until.day)));
  }

  Future<void> healthy() async {
    final r = state.value ?? await future;
    await save(r.copyWith(clearSick: true));
  }

  Future<void> toggleHomeDate(DateTime day) async {
    final r = state.value ?? await future;
    final k = dayKey(day);
    await save(r.copyWith(homeDates: r.homeDates.contains(k) ? ({...r.homeDates}..remove(k)) : {...r.homeDates, k}));
  }
}

final dayRoutineProvider = AsyncNotifierProvider<DayRoutineController, DayRoutine>(DayRoutineController.new);
