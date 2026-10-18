import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../reminders/reminders.dart';
import 'day_notifications.dart';
import 'day_routine.dart';

const _weekdays = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];

String clockOf(int minutes) => '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

String dateLabel(DateTime d) {
  const months = ['sty', 'lut', 'mar', 'kwi', 'maj', 'cze', 'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'];
  return '${d.day} ${months[d.month - 1]}';
}

String daysLabel(Set<int> days) {
  if (days.isEmpty) return 'żadne dni';
  if (days.length == 5 && days.containsAll({1, 2, 3, 4, 5})) return 'pon.–pt.';
  return [for (var d = 1; d <= 7; d++) if (days.contains(d)) _weekdays[d - 1]].join(', ');
}

const momentLabels = {
  DayMomentKind.morning: 'Poranek',
  DayMomentKind.car: 'Wyjazd i powrót autem',
  DayMomentKind.afterDaycare: 'Po przedszkolu',
  DayMomentKind.homeDay: 'Dzień w domu',
  DayMomentKind.meal: 'Kolacja',
  DayMomentKind.bedtime: 'Dobranoc',
};

/// The four steps of Mój dzień (one topic a screen, so it never feels like a form).
enum DayStep {
  week('Tydzień', 'Przedszkole i jazda autem', Icons.date_range_rounded),
  hours('Godziny', 'Pobudka, wyjście, odbiór, kolacja, sen', Icons.schedule_rounded),
  calendar('Dni w domu', 'Święta, wolne, choroba', Icons.event_available_rounded),
  notify('Powiadomienia', 'O których porach podpowiadać', Icons.notifications_active_rounded);

  const DayStep(this.title, this.line, this.icon);

  final String title;
  final String line;
  final IconData icon;
}

Future<void> _save(WidgetRef ref, DayRoutine r) async {
  await ref.read(dayRoutineProvider.notifier).save(r);
  unawaited(rescheduleDayMoments(ref));
}

/// Więcej → Mój dzień. The first time: the four steps one after another. Afterwards: a summary
/// with each part one tap away, the "dziecko choruje" button and today's moments.
class DayScreen extends ConsumerStatefulWidget {
  const DayScreen({super.key});

  @override
  ConsumerState<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  /// Decided once: a family that has not set its day yet goes through the steps first.
  bool? _steps;

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(dayRoutineProvider).value;
    if (r == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _steps ??= !r.configured;
    if (_steps!) return DayStepsScreen(onDone: () => setState(() => _steps = false));
    final now = ref.watch(currentTimeProvider);
    final text = Theme.of(context).textTheme;
    final summaries = {
      DayStep.week: 'Przedszkole: ${daysLabel(r.daycareDays)} · auto: ${daysLabel(r.driveDays)}, ${r.drive} min',
      DayStep.hours: [
        'Pobudka ${clockOf(r.wake)}',
        if (r.goesOut) ...['wyjście ${clockOf(r.leave)}', 'odbiór ${clockOf(r.back)}'],
        'kolacja ${clockOf(r.dinner)}',
        'sen ${clockOf(r.bedtime)}',
      ].join(', '),
      DayStep.calendar: r.homeDates.isEmpty ? 'Święta liczę sam' : 'Święta i ${r.homeDates.length} dni w domu',
      DayStep.notify: r.notify.isEmpty
          ? 'Wyłączone'
          : [for (final k in DayMomentKind.values) if (r.notify.contains(k)) momentLabels[k]!].join(', '),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Mój dzień')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const SickCard(),
          const SizedBox(height: 16),
          for (final step in DayStep.values)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(child: Icon(step.icon)),
                title: Text(step.title, style: text.titleMedium),
                subtitle: Text(summaries[step]!),
                trailing: const Icon(Icons.edit_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => DayStepsScreen(start: step, single: true)),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Dziś', style: text.titleMedium),
          for (final m in momentsOf(r, now))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Text(clockOf(m.startsAt.hour * 60 + m.startsAt.minute), style: text.titleSmall),
              title: Text(m.title),
              subtitle: Text(m.line),
            ),
        ],
      ),
    );
  }
}

/// "Dziecko się rozchorowało": at home until a date, then back to the usual week.
class SickCard extends ConsumerWidget {
  const SickCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(dayRoutineProvider).value ?? const DayRoutine();
    final now = ref.watch(currentTimeProvider);
    final today = DateTime(now.year, now.month, now.day);
    final sick = r.sickUntil != null && !today.isAfter(r.sickUntil!);
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sick ? 'Dziecko choruje' : 'Dziecko zostaje w domu?', style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              sick
                  ? 'Do ${dateLabel(r.sickUntil!)} podpowiadam spokojne zabawy w domu, bez auta.'
                  : 'Gdy dziecko się rozchoruje, zaznacz to: do wyzdrowienia podpowiem spokojne zabawy w domu.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (sick)
                  FilledButton(
                    onPressed: () async {
                      await ref.read(dayRoutineProvider.notifier).healthy();
                      unawaited(rescheduleDayMoments(ref));
                    },
                    child: const Text('Już zdrowe'),
                  ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.healing_rounded),
                  onPressed: () async {
                    final until = await showDatePicker(
                      context: context,
                      helpText: 'Do kiedy w domu?',
                      initialDate: r.sickUntil ?? today.add(const Duration(days: 2)),
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 30)),
                    );
                    if (until == null) return;
                    await ref.read(dayRoutineProvider.notifier).sick(until);
                    unawaited(rescheduleDayMoments(ref));
                  },
                  label: Text(sick ? 'Zmień datę' : 'Dziecko się rozchorowało'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The steps: [start] first; with [single] only that one (editing from the summary).
class DayStepsScreen extends ConsumerStatefulWidget {
  const DayStepsScreen({super.key, this.start = DayStep.week, this.single = false, this.onDone});

  final DayStep start;
  final bool single;

  /// After the last step (instead of closing the screen).
  final VoidCallback? onDone;

  @override
  ConsumerState<DayStepsScreen> createState() => _DayStepsScreenState();
}

class _DayStepsScreenState extends ConsumerState<DayStepsScreen> {
  late DayStep _step = widget.start;

  bool get _last => widget.single || _step == DayStep.values.last;

  Future<void> _next() async {
    final r = ref.read(dayRoutineProvider).value ?? const DayRoutine();
    // Leaving the first run marks the routine as set (defaults included), so Start uses it.
    if (!r.configured) await _save(ref, r.copyWith());
    if (_last) {
      if (widget.onDone != null) {
        widget.onDone!();
      } else if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }
    setState(() => _step = DayStep.values[_step.index + 1]);
  }

  @override
  Widget build(BuildContext context) {
    final r = ref.watch(dayRoutineProvider).value ?? const DayRoutine();
    final text = Theme.of(context).textTheme;
    final body = switch (_step) {
      DayStep.week => _WeekStep(r: r),
      DayStep.hours => _HoursStep(r: r),
      DayStep.calendar => _CalendarStep(r: r),
      DayStep.notify => _NotifyStep(r: r),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.single ? _step.title : 'Mój dzień · krok ${_step.index + 1} z ${DayStep.values.length}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.single) LinearProgressIndicator(value: (_step.index + 1) / DayStep.values.length),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Row(
                    children: [
                      const SzopSticker(SzopPose.chytry, height: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_step.title, style: text.headlineSmall),
                            Text(_step.line, style: text.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  body,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (!widget.single && _step.index > 0)
                    TextButton(
                      onPressed: () => setState(() => _step = DayStep.values[_step.index - 1]),
                      child: const Text('Wstecz'),
                    ),
                  const Spacer(),
                  FilledButton(onPressed: _next, child: Text(_last ? 'Gotowe' : 'Dalej')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Day chips with labels that stay readable in both themes when selected.
class _Days extends StatelessWidget {
  const _Days({required this.days, required this.onChanged});

  final Set<int> days;
  final void Function(Set<int>) onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (var d = 1; d <= 7; d++)
        FilterChip(
          label: Text(_weekdays[d - 1]),
          selected: days.contains(d),
          labelStyle: selectableChipLabel(context, selected: days.contains(d)),
          showCheckmark: false,
          onSelected: (on) => onChanged(on ? {...days, d} : ({...days}..remove(d))),
        ),
    ],
  );
}

class _Lengths extends ConsumerWidget {
  const _Lengths({required this.options, required this.value, required this.apply});

  final List<int> options;
  final int value;
  final DayRoutine Function(int) apply;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final m in options)
        ChoiceChip(
          label: Text('$m min'),
          selected: value == m,
          labelStyle: selectableChipLabel(context, selected: value == m),
          showCheckmark: false,
          onSelected: (_) => _save(ref, apply(m)),
        ),
    ],
  );
}

class _WeekStep extends ConsumerWidget {
  const _WeekStep({required this.r});

  final DayRoutine r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('W które dni przedszkole albo szkoła?', style: text.titleMedium),
        const SizedBox(height: 8),
        _Days(days: r.daycareDays, onChanged: (d) => _save(ref, r.copyWith(daycareDays: d))),
        const SizedBox(height: 20),
        Text('W które dni jedziecie autem (tam i z powrotem)?', style: text.titleMedium),
        const SizedBox(height: 8),
        _Days(days: r.driveDays, onChanged: (d) => _save(ref, r.copyWith(driveDays: d))),
        const SizedBox(height: 20),
        Text('Ile trwa jazda?', style: text.titleMedium),
        const SizedBox(height: 8),
        _Lengths(options: const [10, 20, 30, 45], value: r.drive, apply: (m) => r.copyWith(drive: m)),
      ],
    );
  }
}

/// One hour to set: the time on a button with a clock icon, so it is clearly tappable.
class _Hour extends ConsumerWidget {
  const _Hour({required this.label, required this.help, required this.value, required this.apply});

  final String label;
  final String help;
  final int value;
  final DayRoutine Function(int) apply;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: value ~/ 60, minute: value % 60),
              helpText: help,
              builder: (context, child) =>
                  MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
            );
            if (picked != null) await _save(ref, apply(picked.hour * 60 + picked.minute));
          },
          icon: const Icon(Icons.schedule_rounded),
          label: Text(clockOf(value), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

class _HoursStep extends StatelessWidget {
  const _HoursStep({required this.r});

  final DayRoutine r;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dotknij godziny, żeby ją zmienić.', style: text.bodyMedium),
        const SizedBox(height: 12),
        _Hour(label: 'Pobudka', help: 'O której wstajecie?', value: r.wake, apply: (v) => r.copyWith(wake: v)),
        // Leaving and pick-up only matter on kindergarten or car days (parent review,
        // 2026-10-18): without such days they are not asked at all.
        if (r.goesOut) ...[
          _Hour(label: 'Wyjście z domu', help: 'O której wychodzicie?', value: r.leave, apply: (v) => r.copyWith(leave: v)),
          _Hour(
            label: 'Odbiór z przedszkola',
            help: 'O której odbierasz dziecko?',
            value: r.back,
            apply: (v) => r.copyWith(back: v),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Wyjście i odbiór liczą się tylko w dni: ${daysLabel({...r.daycareDays, ...r.driveDays})}. '
              'W weekend i w dni w domu ich nie ma.',
              style: text.bodySmall,
            ),
          ),
        ],
        _Hour(label: 'Kolacja', help: 'O której kolacja?', value: r.dinner, apply: (v) => r.copyWith(dinner: v)),
        _Hour(label: 'Pora snu', help: 'O której sen?', value: r.bedtime, apply: (v) => r.copyWith(bedtime: v)),
        const SizedBox(height: 12),
        Text('Poranne zabawy: ile mają trwać?', style: text.titleMedium),
        const SizedBox(height: 8),
        _Lengths(options: const [10, 15, 20, 30], value: r.morningMinutes, apply: (m) => r.copyWith(morningMinutes: m)),
      ],
    );
  }
}

class _CalendarStep extends ConsumerWidget {
  const _CalendarStep({required this.r});

  final DayRoutine r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentTimeProvider);
    final today = DateTime(now.year, now.month, now.day);
    final holidays = {...polishHolidays(today.year), ...polishHolidays(today.year + 1)};
    final offDays = [
      for (var i = 0; i < 60; i++)
        if (today.add(Duration(days: i)) case final d when holidays[dayKey(d)] != null || r.homeDates.contains(dayKey(d))) d,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SickCard(),
        const SizedBox(height: 16),
        Text(
          'Święta liczę sam. Dodaj dni, kiedy przedszkole jest zamknięte albo macie wolne.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        for (final d in offDays)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.event_available_rounded),
            title: Text('${dateLabel(d)} · ${holidays[dayKey(d)] ?? 'Dzień w domu'}'),
            trailing: r.homeDates.contains(dayKey(d))
                ? IconButton(
                    tooltip: 'Usuń',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () async {
                      await ref.read(dayRoutineProvider.notifier).toggleHomeDate(d);
                      unawaited(rescheduleDayMoments(ref));
                    },
                  )
                : null,
          ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              helpText: 'Który dzień w domu?',
              initialDate: today,
              firstDate: today,
              lastDate: today.add(const Duration(days: 365)),
            );
            if (picked == null || r.homeDates.contains(dayKey(picked))) return;
            await ref.read(dayRoutineProvider.notifier).toggleHomeDate(picked);
            unawaited(rescheduleDayMoments(ref));
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Dodaj dzień w domu'),
        ),
      ],
    );
  }
}

class _NotifyStep extends ConsumerWidget {
  const _NotifyStep({required this.r});

  final DayRoutine r;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Krótka podpowiedź w odpowiedniej chwili, tylko w zaznaczonych porach. Dotknięcie otwiera gotowy plan.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      for (final kind in DayMomentKind.values)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(momentLabels[kind]!),
          value: r.notify.contains(kind),
          onChanged: (on) async {
            if (on && !await ref.read(reminderSchedulerProvider).requestPermission()) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Telefon nie pozwala na powiadomienia. Zmienisz to w Ustawieniach.')),
                );
              }
              return;
            }
            await _save(ref, r.copyWith(notify: on ? {...r.notify, kind} : ({...r.notify}..remove(kind))));
          },
        ),
    ],
  );
}
