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

class _SzopTourState extends ConsumerState<SzopTour> with SingleTickerProviderStateMixin {
  int _i = 0;

  /// What is lit up now, in this overlay's coordinates; followed every frame until the page
  /// has settled, so the frame stays on the feature when it scrolls or rebuilds after it was
  /// found. (The tour covers the screen, so nothing moves it afterwards.)
  Rect? _light;
  late final _ticker = createTicker(_follow);
  Duration _stableSince = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _show());
  }

  void _track() {
    _stableSince = Duration.zero;
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
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
        _light = null;
      });
      _show();
    }
  }

  /// The id lit up at this stop: a feature on the page, else a slot of the bottom bar.
  static String? _lightId(TourStop stop) => stop.target ?? (stop.slot == null ? null : 'slot-${stop.slot}');

  /// Opens the stop's tab and scrolls its feature into view; [_follow] then keeps the frame on it.
  Future<void> _show() async {
    final stop = tourStops[_i];
    final step = _i;
    if (stop.branch case final branch?) widget.onBranch(branch);
    _track();
    if (stop.target == null) return;
    // The tab may still be building or sliding in.
    for (var attempt = 0; attempt < 2; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final target = _targetContext(stop.target!);
      if (!mounted || step != _i) return;
      if (target == null || !target.mounted) continue;
      await Scrollable.ensureVisible(
        target,
        alignment: .15,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      if (mounted && step == _i) _track();
    }
  }

  void _follow(Duration elapsed) {
    if (!mounted) return;
    final id = _lightId(tourStops[_i]);
    final rect = id == null ? null : _measure(id);
    final old = _light;
    final moved = rect == null || old == null
        ? rect != old
        : (rect.topLeft - old.topLeft).distance > .5 || (rect.size - old.size as Offset).distance > .5;
    if (moved) {
      _stableSince = elapsed;
      setState(() => _light = rect);
    } else if (elapsed - _stableSince > const Duration(milliseconds: 900)) {
      _ticker.stop();
    }
  }

  /// The target on screen now: the visible one when a tab kept an older copy offstage.
  BuildContext? _targetContext(String id) {
    final context = tourTargetKeys[id]?.currentContext;
    return context != null && context.mounted ? context : null;
  }

  /// The target's box in this overlay's coordinates, only when it is really on screen.
  Rect? _measure(String id) {
    final box = _targetContext(id)?.findRenderObject() as RenderBox?;
    final overlay = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached || overlay == null || !overlay.hasSize) return null;
    final topLeft = overlay.globalToLocal(box.localToGlobal(Offset.zero));
    final rect = topLeft & box.size;
    // A feature is lit only between the status bar and the bottom bar (a tall card would
    // otherwise frame the bar too); the bar's own slots are lit where they are.
    final padding = MediaQuery.paddingOf(context);
    final visible = id.startsWith('slot-')
        ? Offset.zero & overlay.size
        : Rect.fromLTRB(
            0,
            padding.top,
            overlay.size.width,
            overlay.size.height - padding.bottom - widget.barHeight - 4,
          );
    return visible.overlaps(rect) ? rect.intersect(visible) : null;
  }

  @override
  Widget build(BuildContext context) {
    final stop = tourStops[_i];
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    final last = _i == tourStops.length - 1;
    final small = size.height < 700;
    final slot = stop.target == null && stop.slot != null;
    // A tab gets a ring around it, a feature a rounded frame.
    final light = _light;
    final hole = light == null
        ? null
        : slot
        ? Rect.fromCircle(center: light.center, radius: light.shortestSide / 2 + 10)
        : light.inflate(6);
    final radius = slot && hole != null ? hole.width / 2 : 22.0;

    // The bubble goes where it fits whole: under the feature, above it, or (a feature taller
    // than half the screen) over its lower part, just above the bar.
    final barTop = size.height - padding.bottom - widget.barHeight;
    final need = small ? 190.0 : 220.0;
    final top = padding.top + 12;
    double? bubbleTop;
    double? bubbleBottom;
    var alignEnd = true;
    if (hole == null || slot) {
      bubbleTop = top;
      bubbleBottom = size.height - (slot && hole != null ? hole.top : barTop) + 16;
    } else if (barTop - 12 - (hole.bottom + 12) >= need) {
      bubbleTop = hole.bottom + 12;
      bubbleBottom = size.height - barTop + 12;
      alignEnd = false;
    } else if (hole.top - 12 - top >= need) {
      bubbleTop = top;
      bubbleBottom = size.height - hole.top + 12;
    } else {
      bubbleTop = top;
      bubbleBottom = size.height - barTop + 12;
    }

    final bubble = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      // Small phones with large text: the bubble scrolls rather than overflowing.
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    stop.title,
                    style: text.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
                  ),
                ),
                // Szop’en in the bubble's corner: he never covers what he explains.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: SzopSticker(stop.pose, key: ValueKey(_i), height: small ? 48 : 60),
                ),
              ],
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
    );

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _Dim(hole: hole, radius: radius)),
            ),
            // A bright frame around the feature, or a ring around the tab.
            if (hole != null)
              Positioned.fromRect(
                rect: hole,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: const Color(0xFFFAC119), width: 4),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              top: bubbleTop,
              bottom: bubbleBottom.clamp(0, size.height - bubbleTop - 120),
              child: Column(
                mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
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
  _Dim({this.hole, this.radius = 22});

  final Rect? hole;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (hole case final hole?) {
      path
        ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .72));
  }

  @override
  bool shouldRepaint(_Dim old) => old.hole != hole || old.radius != radius;
}
