import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/szop.dart';
import 'day_routine.dart';
import 'day_screen.dart' show clockOf;

/// In the welcome: Mój dzień in three questions (kindergarten days, leaving, bedtime), so the
/// "Teraz" card fits the family from the first day. Everything else waits in Więcej → Mój dzień.
class DayWelcome extends ConsumerStatefulWidget {
  const DayWelcome({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<DayWelcome> createState() => _DayWelcomeState();
}

class _DayWelcomeState extends ConsumerState<DayWelcome> {
  static const _weekdays = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];
  Set<int> _days = {1, 2, 3, 4, 5};
  int _leave = 7 * 60 + 45;
  int _bedtime = 20 * 60;

  Future<int?> _pick(String help, int current) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: help,
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  Future<void> _save() async {
    final r = ref.read(dayRoutineProvider).value ?? const DayRoutine();
    await ref
        .read(dayRoutineProvider.notifier)
        .save(r.copyWith(daycareDays: _days, driveDays: _days, leave: _leave, bedtime: _bedtime));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [TextButton(onPressed: widget.onDone, child: const Text('Pomiń'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            const Center(child: SzopSticker(SzopPose.chytry, height: 110)),
            const SizedBox(height: 12),
            Text('Jak wygląda Wasz dzień?', style: text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Trzy pytania, a na Starcie podpowiem zabawy na właściwą chwilę: rano, w aucie, po przedszkolu '
              'i na dobranoc. Zmienisz to w Więcej → Mój dzień.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text('W które dni przedszkole albo szkoła?', style: text.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var d = 1; d <= 7; d++)
                  FilterChip(
                    label: Text(_weekdays[d - 1]),
                    selected: _days.contains(d),
                    labelStyle: selectableChipLabel(context, selected: _days.contains(d)),
                    showCheckmark: false,
                    onSelected: (on) => setState(() => _days = on ? {..._days, d} : ({..._days}..remove(d))),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('O której wychodzicie z domu?'),
              trailing: OutlinedButton.icon(
                onPressed: () async {
                  final v = await _pick('O której wychodzicie?', _leave);
                  if (v != null) setState(() => _leave = v);
                },
                icon: const Icon(Icons.schedule_rounded),
                label: Text(clockOf(_leave), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('O której dziecko idzie spać?'),
              trailing: OutlinedButton.icon(
                onPressed: () async {
                  final v = await _pick('O której sen?', _bedtime);
                  if (v != null) setState(() => _bedtime = v);
                },
                icon: const Icon(Icons.schedule_rounded),
                label: Text(clockOf(_bedtime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Gotowe')),
          ],
        ),
      ),
    );
  }
}
