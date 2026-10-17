import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

const momentLabels = {
  DayMomentKind.morning: 'Poranek',
  DayMomentKind.car: 'Wyjazd i powrót autem',
  DayMomentKind.afterDaycare: 'Po przedszkolu',
  DayMomentKind.homeDay: 'Dzień w domu',
  DayMomentKind.meal: 'Kolacja',
  DayMomentKind.bedtime: 'Dobranoc',
};

/// Więcej → Mój dzień: the family's week, so Start and the notifications suggest what fits.
class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  Future<void> _save(WidgetRef ref, DayRoutine r) async {
    await ref.read(dayRoutineProvider.notifier).save(r);
    unawaited(rescheduleDayMoments(ref));
  }

  Future<int?> _pickTime(BuildContext context, String help, int current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: help,
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    return picked == null ? null : picked.hour * 60 + picked.minute;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(dayRoutineProvider).value;
    final now = ref.watch(currentTimeProvider);
    final text = Theme.of(context).textTheme;
    if (r == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final today = DateTime(now.year, now.month, now.day);
    final sick = r.sickUntil != null && !today.isAfter(r.sickUntil!);

    Widget chips(Set<int> days, void Function(Set<int>) onChanged) => Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var d = 1; d <= 7; d++)
          FilterChip(
            label: Text(_weekdays[d - 1]),
            selected: days.contains(d),
            showCheckmark: false,
            onSelected: (on) => onChanged(on ? {...days, d} : ({...days}..remove(d))),
          ),
      ],
    );

    Widget time(String label, String help, int value, DayRoutine Function(int) apply) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(clockOf(value), style: text.titleMedium),
      onTap: () async {
        final picked = await _pickTime(context, help, value);
        if (picked != null) await _save(ref, apply(picked));
      },
    );

    Widget lengths(List<int> options, int value, DayRoutine Function(int) apply) => Wrap(
      spacing: 6,
      children: [
        for (final m in options)
          ChoiceChip(
            label: Text('$m min'),
            selected: value == m,
            showCheckmark: false,
            onSelected: (_) => _save(ref, apply(m)),
          ),
      ],
    );

    final days = [for (var i = 0; i < 60; i++) today.add(Duration(days: i))];
    final holidays = {...polishHolidays(today.year), ...polishHolidays(today.year + 1)};
    final offDays = [
      for (final d in days)
        if (holidays[dayKey(d)] != null || r.homeDates.contains(dayKey(d))) d,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mój dzień')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Row(
            children: [
              const SzopSticker(SzopPose.chytry, height: 70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Powiedz mi, jak wygląda Wasz tydzień, a na Starcie i w powiadomieniach podpowiem zabawy na '
                  'właściwą chwilę: rano, w aucie, po przedszkolu, przy kolacji i na dobranoc.',
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
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
                    children: [
                      if (sick)
                        FilledButton(
                          onPressed: () async {
                            await ref.read(dayRoutineProvider.notifier).healthy();
                            unawaited(rescheduleDayMoments(ref));
                          },
                          child: const Text('Już zdrowe'),
                        ),
                      OutlinedButton(
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
                        child: Text(sick ? 'Zmień datę' : 'Dziecko się rozchorowało'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Przedszkole albo szkoła', style: text.titleMedium),
          const SizedBox(height: 6),
          chips(r.daycareDays, (d) => _save(ref, r.copyWith(daycareDays: d))),
          const SizedBox(height: 16),
          Text('Jazda autem (tam i z powrotem)', style: text.titleMedium),
          const SizedBox(height: 6),
          chips(r.driveDays, (d) => _save(ref, r.copyWith(driveDays: d))),
          const SizedBox(height: 8),
          Text('Ile trwa jazda?', style: text.bodyMedium),
          lengths(const [10, 20, 30, 45], r.drive, (m) => r.copyWith(drive: m)),
          const SizedBox(height: 16),
          Text('Godziny', style: text.titleMedium),
          time('Pobudka', 'O której wstajecie?', r.wake, (v) => r.copyWith(wake: v)),
          time('Wyjście z domu', 'O której wychodzicie?', r.leave, (v) => r.copyWith(leave: v)),
          time('Odbiór z przedszkola', 'O której odbierasz dziecko?', r.back, (v) => r.copyWith(back: v)),
          time('Kolacja', 'O której kolacja?', r.dinner, (v) => r.copyWith(dinner: v)),
          time('Pora snu', 'O której dziecko idzie spać?', r.bedtime, (v) => r.copyWith(bedtime: v)),
          const SizedBox(height: 8),
          Text('Poranne zabawy: ile mają trwać?', style: text.bodyMedium),
          lengths(const [10, 15, 20, 30], r.morningMinutes, (m) => r.copyWith(morningMinutes: m)),
          const SizedBox(height: 20),
          Text('Dni wolne w kalendarzu', style: text.titleMedium),
          Text(
            'Święta liczę sam. Dodaj dni, kiedy przedszkole jest zamknięte albo macie wolne.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 6),
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
          TextButton.icon(
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
          const SizedBox(height: 20),
          Text('Powiadomienia', style: text.titleMedium),
          Text(
            'Krótka podpowiedź w odpowiedniej chwili, tylko w zaznaczonych porach.',
            style: text.bodySmall,
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
          const SizedBox(height: 20),
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
