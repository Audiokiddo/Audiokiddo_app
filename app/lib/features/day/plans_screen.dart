import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../home/quick_pick.dart';
import 'day_routine.dart';
import 'play_moments.dart';
import 'moment_card.dart';

/// All the ready plans in one place, in the order of a day (report 2026-10-17: parents buy
/// minutes for a moment). Every plan opens the same editor: change it, then press play.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routine = ref.watch(dayRoutineProvider).value ?? const DayRoutine();
    final text = Theme.of(context).textTheme;
    final plans = [
      (Icons.wb_sunny_rounded, 'Poranek', 'Zabawy na rozruch, ${routine.morningMinutes} min',
          '/obiad?pora=rano&minuty=${routine.morningMinutes}'),
      (Icons.directions_car_rounded, 'Do auta', 'Na całą trasę, z przerwami', '/podroz?minuty=${routine.drive}'),
      (Icons.weekend_rounded, 'Po przedszkolu', 'Kwadrans spokoju na kanapie', '/obiad?pora=po&minuty=15'),
      (Icons.home_rounded, 'Dzień w domu', 'Dłuższy blok na środek dnia', '/obiad?pora=dom&minuty=30'),
      (Icons.healing_rounded, 'Dziecko chore', 'Spokojne zabawy na leżąco', '/obiad?pora=chory&minuty=20'),
      (Icons.hourglass_bottom_rounded, 'Czekamy', 'Poczekalnia, kolejka: 5–15 min', '/obiad?pora=czekamy&minuty=10'),
      (Icons.restaurant_rounded, 'Kolacja bez wołania', 'Zabawy jedna po drugiej', '/obiad?pora=kolacja&minuty=25'),
      (Icons.bedtime_rounded, 'Dobranoc', 'Wyciszenie przed snem', '/dobranoc'),
      (Icons.schedule_rounded, 'Mam chwilę', 'Dobierzemy zabawy na tyle, ile masz', '/ratunku'),
      (Icons.queue_music_rounded, 'Moje rutyny', 'Zapisane kolejki zabaw', '/rutyny'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Co teraz?')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          // What fits right now first; the rest in the order of a day.
          const MomentCard(),
          // The quick pick that used to sit under the big button: a few plays chosen for you.
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: FilledButton.tonalIcon(
              onPressed: () => showQuickPick(context),
              icon: const Icon(Icons.casino_rounded),
              label: const Text('Wylosuj mi zabawy'),
            ),
          ),
          for (final (icon, title, line, route) in plans)
            ListTile(
              contentPadding: EdgeInsets.zero,
              // The colour of the moment, the same as on its plan and the Teraz card.
              leading: CircleAvatar(
                backgroundColor: _colorOf(route),
                foregroundColor: const Color(0xFF211C35),
                child: Icon(icon),
              ),
              title: Text(title, style: text.titleMedium),
              subtitle: Text(line),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(route),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/moj-dzien'),
            icon: const Icon(Icons.tune_rounded),
            label: Text(routine.configured ? 'Zmień mój dzień' : 'Ustaw mój dzień'),
          ),
        ],
      ),
    );
  }
}

Color? _colorOf(String route) {
  if (route.startsWith('/podroz')) return PlayMoment.auto.color;
  final pora = Uri.parse(route).queryParameters['pora'];
  if (route.startsWith('/obiad')) return PlayMoment.of(pora).color;
  if (route.startsWith('/dobranoc')) return const Color(0xFFDAD6F0);
  return null;
}
