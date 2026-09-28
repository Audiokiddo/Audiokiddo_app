import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'kiddo.dart';

/// Deliberately separate audiences. No generated text or microphone is needed.
abstract final class GoldenLines {
  static const parent = [
    'Golden von Ekran. „Von” brzmi drogo. Reszta reaguje na szynkę.',
    'Ty zrób kawę, ja ogarnę zagadki. Zamienilibyśmy się, ale ekspres ma do mnie zakaz zbliżania.',
    'Wybierz zabawę. Tylko nie róbmy z tego wieczoru pod tytułem „co obejrzymy”.',
    'Mam plan. Poprzedni też był dobry, tylko kanapa się nie zgodziła.',
    'Pięć minut spokoju? Rozumiem. Pakiet luksusowy.',
  ];
  static const child = [
    'Uszy gotowe? Moje są duże. To trochę nie fair.',
    'Potrzebuję kogoś z wyobraźnią. Ja mam głównie sierść. Wchodzisz w to?',
    'Jeśli usłyszysz burczenie, to mój brzuch. Tego nie liczymy jako zagadki.',
    'Przybij łapę! Tę czystą. Nie, czekaj… obie są podejrzane.',
  ];
}

int _nextParentLine = 0;

/// A user-requested, silent encounter: never talks over an audio activity.
Future<void> showGoldenHello(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => const _GoldenHello(),
);

class _GoldenHello extends StatefulWidget {
  const _GoldenHello();
  @override
  State<_GoldenHello> createState() => _GoldenHelloState();
}

class _GoldenHelloState extends State<_GoldenHello> {
  late int _line = _nextParentLine++ % GoldenLines.parent.length;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Kiddo(size: 160, cheeky: true, wave: true),
          Text(
            'Golden von Ekran',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              GoldenLines.parent[_line],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => setState(() {
                  _line = (_line + 1) % GoldenLines.parent.length;
                  _nextParentLine = _line + 1;
                }),
                child: const Text('Masz coś jeszcze?'),
              ),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Wybieram zabawę')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dotrzymuję towarzystwa. Nagrania mają pierwszeństwo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.palette.inkMuted),
          ),
        ],
      ),
    ),
  );
}
