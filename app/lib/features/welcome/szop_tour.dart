import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/szop.dart';
import '../insights/events.dart';
import 'welcome_controller.dart';

/// Widgets the tour can scroll to and light up, by id.
final tourTargetKeys = <String, GlobalKey>{};

/// Marks [child] as a stop of Szop’en's tour ([id] as in [tourStops]).
class TourTarget extends StatelessWidget {
  TourTarget({required this.id, required this.child}) : super(key: ValueKey('tour-$id'));

  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: tourTargetKeys.putIfAbsent(id, GlobalKey.new), child: child);
}

/// One stop of the tour: the tab it opens ([branch]: 0 Start, 1 Biblioteka, 2 Sklep,
/// 3 Więcej), what it lights up (a [target] on the page, or a [slot] of the bottom bar: 0–4,
/// the play button is 2) and what Szop’en says.
typedef TourStop = ({int? branch, String? target, int? slot, SzopPose pose, String title, String body});

const tourStops = <TourStop>[
  (
    branch: 0,
    target: null,
    slot: null,
    pose: SzopPose.prosi,
    title: 'Cześć, jestem Szop’en!',
    body: 'Pokażę Ci w minutę, gdzie co jest. Stuknij „Dalej” albo gdziekolwiek na ekranie.',
  ),
  (
    branch: 0,
    target: 'hero',
    slot: null,
    pose: SzopPose.zadowolony,
    title: 'Co dziś robimy',
    body: 'Na Starcie czekają zabawy dobrane do wieku dziecka. Przesuń palcem w bok, żeby zobaczyć kolejne.',
  ),
  (
    branch: 0,
    target: null,
    slot: 2,
    pose: SzopPose.klaszcze,
    title: 'Co teraz?',
    body:
        'Najszybsza droga: wybierz, ile macie czasu, a ja wylosuję zabawy po kolei. Jedno stuknięcie i gra.',
  ),
  (
    branch: 1,
    target: null,
    slot: 1,
    pose: SzopPose.nasluchuje,
    title: 'Biblioteka',
    body: 'Wszystkie zabawy według pakietów i wieku. Serduszkiem dodasz je do ulubionych.',
  ),
  (
    branch: 1,
    target: 'offline',
    slot: null,
    pose: SzopPose.zdziwiony,
    title: 'Bez internetu',
    body:
        'Przed wyjazdem pobierz zabawy na telefon: zadziałają w aucie, samolocie i na działce, bez zasięgu.',
  ),
  (
    branch: 1,
    target: 'print',
    slot: null,
    pose: SzopPose.chytry,
    title: 'Do druku',
    body: 'Akta spraw Detektywa i karty do zabaw. Wydrukujesz je albo otworzysz w telefonie lub na tablecie.',
  ),
  (
    branch: 1,
    target: 'kids',
    slot: null,
    pose: SzopPose.zadowolony,
    title: 'Tryb dziecka',
    body: 'Dajesz dziecku telefon, a ono widzi tylko zabawy: bez zakupów, linków i ustawień.',
  ),
  (
    branch: 2,
    target: 'subscription',
    slot: 3,
    pose: SzopPose.klaszcze,
    title: 'Sklep',
    body:
        'Abonament otwiera wszystkie zabawy i co miesiąc dokłada nowy pakiet. Możesz też kupić jeden pakiet.',
  ),
  (
    branch: 3,
    target: 'downloads',
    slot: 4,
    pose: SzopPose.nasluchuje,
    title: 'Więcej',
    body:
        'Tu są pobrane zabawy, profil dziecka, wygląd aplikacji i konto. Samouczek obejrzysz tu jeszcze raz.',
  ),
  (
    branch: 0,
    target: null,
    slot: null,
    pose: SzopPose.klaszcze,
    title: 'Gotowe!',
    body: 'Zacznijcie od darmowej zabawy na Starcie. Ja będę w pobliżu.',
  ),
];

/// Szop’en's tour over the whole parent screen: it opens each tab, scrolls to the feature and
/// lights it up. Shown once after the welcome (and again from Więcej). "Pomiń" ends it.
class SzopTour extends ConsumerStatefulWidget {
  const SzopTour({super.key, required this.barHeight, required this.onBranch});

  /// Height of the bottom bar without the safe area, to point at its slots.
  final double barHeight;

  /// Opens a tab of the bottom bar.
  final ValueChanged<int> onBranch;

  @override
  ConsumerState<SzopTour> createState() => _SzopTourState();
}

class _SzopTourState extends ConsumerState<SzopTour> {
  int _i = 0;
  Rect? _target;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _end({bool finished = false}) {
    if (finished) ref.read(eventSinkProvider).track(AppEvent.tourDone);
    widget.onBranch(0);
    ref.read(welcomeProvider).endTour();
  }

  void _next() {
    if (_i == tourStops.length - 1) {
      _end(finished: true);
    } else {
      setState(() {
        _i++;
        _target = null;
      });
      _show();
    }
  }

  /// Opens the stop's tab, scrolls its feature into view and measures it for the light.
  Future<void> _show() async {
    final stop = tourStops[_i];
    final step = _i;
    if (stop.branch case final branch?) widget.onBranch(branch);
    final key = stop.target == null ? null : tourTargetKeys[stop.target];
    if (key == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final context = key.currentContext;
    if (!mounted || step != _i || context == null || !context.mounted) return;
    await Scrollable.ensureVisible(
      context,
      alignment: .35,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    if (!mounted || step != _i || !context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    setState(() => _target = box.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {
    final stop = tourStops[_i];
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    final target = _target;
    final slotX = stop.slot == null || target != null ? null : size.width * (stop.slot! + .5) / 5;
    final last = _i == tourStops.length - 1;
    // The bubble sits away from what it explains: under a feature in the top half, else above.
    final below = target != null && target.center.dy < size.height * .45;
    final small = size.height < 700;

    final bubble = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small phones with large text: the bubble scrolls rather than overflowing.
        Flexible(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
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
            child: SzopSticker(stop.pose, key: ValueKey(_i), height: small ? 60 : 88),
          ),
        ),
      ],
    );

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _Dim(hole: target?.inflate(6))),
            ),
            // A bright frame around the feature, or a ring around the tab.
            if (target != null)
              Positioned.fromRect(
                rect: target.inflate(6),
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x88FFFFFF), blurRadius: 18)],
                    ),
                  ),
                ),
              ),
            if (slotX != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: slotX - 36,
                bottom: padding.bottom + widget.barHeight / 2 - 36 + (stop.slot == 2 ? 8 : 0),
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
              top: below ? target.bottom + 16 : padding.top + 12,
              bottom: below
                  ? padding.bottom + widget.barHeight + 8
                  : target != null
                  ? (size.height - target.top + 16).clamp(0, size.height - padding.top - 120)
                  : padding.bottom + widget.barHeight + 40,
              child: Column(
                mainAxisAlignment: below ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [Flexible(child: bubble)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dim layer, with a clear window over the feature being explained.
class _Dim extends CustomPainter {
  _Dim({this.hole});

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (hole case final hole?) {
      path
        ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(22)))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .62));
  }

  @override
  bool shouldRepaint(_Dim old) => old.hole != hole;
}
