import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/szop.dart';
import '../insights/events.dart';
import 'welcome_controller.dart';

/// One stop of the tour: which slot of the bottom bar Szop’en points at (0–4, the play button
/// is 2; null for none) and what he says.
typedef TourStop = ({int? slot, SzopPose pose, String title, String body});

const tourStops = <TourStop>[
  (
    slot: null,
    pose: SzopPose.prosi,
    title: 'Cześć, jestem Szop’en!',
    body: 'Pokażę Ci w 20 sekund, gdzie co jest. Stuknij gdziekolwiek, żeby iść dalej.',
  ),
  (
    slot: 0,
    pose: SzopPose.zadowolony,
    title: 'Start',
    body: 'Tu codziennie czeka zabawa dobrana do wieku dziecka i to, co zaczęliście.',
  ),
  (
    slot: 2,
    pose: SzopPose.klaszcze,
    title: 'Co teraz?',
    body: 'Najszybsza droga: powiedz mi, gdzie jesteście, a ja dobiorę zabawę. Jedno stuknięcie i gra.',
  ),
  (
    slot: 1,
    pose: SzopPose.nasluchuje,
    title: 'Biblioteka',
    body: 'Wszystkie zabawy według pakietów i wieku. Serduszkiem dodasz je do ulubionych.',
  ),
  (
    slot: 3,
    pose: SzopPose.chytry,
    title: 'Sklep',
    body: 'Abonament otwiera wszystko i co miesiąc dokłada nowy pakiet. Możesz też kupić jeden pakiet.',
  ),
  (
    slot: 4,
    pose: SzopPose.zdziwiony,
    title: 'Więcej',
    body: 'Profil dziecka, tryb dziecka, pobrane zabawy, wygląd i konto.',
  ),
  (
    slot: null,
    pose: SzopPose.klaszcze,
    title: 'Gotowe!',
    body: 'Zacznijcie od darmowej zabawy na Starcie. Ja będę w pobliżu.',
  ),
];

/// Szop’en's short tour of the bottom bar, over the whole parent screen. Shown once after the
/// welcome (and again from Więcej → Pomoc). A tap anywhere moves on; "Pomiń" ends it.
class SzopTour extends ConsumerStatefulWidget {
  const SzopTour({super.key, required this.barHeight});

  /// Height of the bottom bar without the safe area, to point at its slots.
  final double barHeight;

  @override
  ConsumerState<SzopTour> createState() => _SzopTourState();
}

class _SzopTourState extends ConsumerState<SzopTour> {
  int _i = 0;

  void _end({bool finished = false}) {
    if (finished) ref.read(eventSinkProvider).track(AppEvent.tourDone);
    ref.read(welcomeProvider).endTour();
  }

  void _next() {
    if (_i == tourStops.length - 1) {
      _end(finished: true);
    } else {
      setState(() => _i++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stop = tourStops[_i];
    final size = MediaQuery.sizeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    final slotX = stop.slot == null ? null : size.width * (stop.slot! + .5) / 5;
    final last = _i == tourStops.length - 1;
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: .62))),
            // A bright ring around the tab he talks about.
            if (slotX != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: slotX - 36,
                bottom: bottom + widget.barHeight / 2 - 36 + (stop.slot == 2 ? 8 : 0),
                child: IgnorePointer(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x88FFFFFF), blurRadius: 18)],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              top: MediaQuery.paddingOf(context).top + 12,
              bottom: bottom + widget.barHeight + 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small phones with large text: the bubble scrolls rather than overflowing.
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.title,
                              style: text.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(stop.body, style: text.bodyLarge?.copyWith(color: ink, height: 1.3)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_i + 1} / ${tourStops.length}',
                                    style: text.labelMedium?.copyWith(color: ink.withValues(alpha: .6)),
                                  ),
                                ),
                                if (!last) TextButton(onPressed: _end, child: const Text('Pomiń')),
                                FilledButton(
                                  style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
                                  onPressed: _next,
                                  child: Text(last ? 'Zaczynamy' : 'Dalej'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Szop’en under the bubble, leaning towards the tab.
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    alignment: slotX == null
                        ? Alignment.center
                        : Alignment(((slotX - 16) / (size.width - 32)) * 2 - 1, 0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: SzopSticker(stop.pose, key: ValueKey(_i), height: size.height < 700 ? 64 : 96),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
