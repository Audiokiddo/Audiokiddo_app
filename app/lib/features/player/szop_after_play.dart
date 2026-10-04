import 'dart:async';
import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../discovery/discovery_model.dart';
import 'szop_lines.dart';

/// What Szop’en says when a recording ends: a dry joke for the parent, or a small tip for
/// what to do next with the child. Never about the child, never a modal.
@immutable
class SzopLine {
  const SzopLine(this.pose, this.text, {this.tip = false});

  final SzopPose pose;
  final String text;

  /// Advice rather than a joke (shown with a small "Rada Szop’ena" label).
  final bool tip;
}

const _jokes = <SzopLine>[
  SzopLine(SzopPose.klaszcze, 'Przygoda zaliczona. Wpisuję do akt jako rodzinny sukces.'),
  SzopLine(SzopPose.zadowolony, 'Koniec nagrania. Brawa przyjmuję w orzeszkach.'),
  SzopLine(SzopPose.chytry, 'Cisza przez całe nagranie. Nikt nie musi wiedzieć, że to moja zasługa.'),
  SzopLine(SzopPose.zmeczony, 'Ja bym teraz poleżał. Dziecko pewnie nie. Następna zabawa jest niżej.'),
  SzopLine(SzopPose.zdziwiony, 'Już koniec? Dopiero się rozsiadłem.'),
  SzopLine(SzopPose.zadowolony, 'Kolejne minuty bez ekranu. Potwierdzam urzędowo, z pieczątką.'),
  SzopLine(SzopPose.znudzony, 'Nagranie skończone. Moja kariera lektora nadal w zawieszeniu.'),
  SzopLine(SzopPose.klaszcze, 'Gdyby za słuchanie dawali medale, mielibyście już szufladę.'),
];

const _tips = <SzopLine>[
  SzopLine(
    SzopPose.nasluchuje,
    'Zapytaj, co było najśmieszniejsze. Opowiadając, dzieci zapamiętują więcej.',
    tip: true,
  ),
  SzopLine(
    SzopPose.prosi,
    'Chwila ciszy przed kolejną zabawą też się liczy. Mózg lubi przerwę na herbatkę.',
    tip: true,
  ),
  SzopLine(SzopPose.chytry, 'Poproś o opowiedzenie przygody od końca. Trudne i bardzo zabawne.', tip: true),
  SzopLine(
    SzopPose.zdziwiony,
    'Zapytaj, jak inaczej mogła się skończyć ta historia. Wyobraźnia rośnie od pytań.',
    tip: true,
  ),
];

const _songTips = <SzopLine>[
  SzopLine(
    SzopPose.klaszcze,
    'Zaśpiewajcie refren jeszcze raz, już bez nagrania. Ja nie oceniam. Prawie.',
    tip: true,
  ),
  SzopLine(SzopPose.zadowolony, 'Wystukajcie rytm na kolanach. Sąsiedzi zrozumieją. Chyba.', tip: true),
];

const _detectiveTips = <SzopLine>[
  SzopLine(
    SzopPose.chytry,
    'Akta sprawy czekają w odtwarzaczu. Detektyw bez notatek to tylko ktoś w płaszczu.',
    tip: true,
  ),
  SzopLine(
    SzopPose.nasluchuje,
    'Zapytaj, kogo dziecko podejrzewało od początku. Ja podejrzewam wszystkich.',
    tip: true,
  ),
];

const _calmTips = <SzopLine>[
  SzopLine(SzopPose.zmeczony, 'Teraz najlepiej przytulić i przygasić światło. Ja już ziewam.', tip: true),
  SzopLine(SzopPose.zmeczony, 'Po spokojnej zabawie nic głośnego. Szopy też tak robią.', tip: true),
];

const _movementTips = <SzopLine>[
  SzopLine(
    SzopPose.zestresowany,
    'Teraz szklanka wody i trzy głębokie oddechy. Dla dziecka. I dla Ciebie.',
    tip: true,
  ),
];

const _creativeTips = <SzopLine>[
  SzopLine(
    SzopPose.zadowolony,
    'Narysujcie bohatera tej przygody. Mnie zawsze rysują grubszego, niż jestem.',
    tip: true,
  ),
];

/// The lines that fit [item]: its own tips first in the pool, then the general ones.
List<SzopLine> szopAfterPlayPool(ContentItem? item) => [
  if (item != null) ...[
    if (PlayCategory.songs.matches(item)) ..._songTips,
    if (PlayCategory.detective.matches(item) || item.pdf.isNotEmpty) ..._detectiveTips,
    if (PlayCategory.calm.matches(item)) ..._calmTips,
    if (PlayCategory.movement.matches(item)) ..._movementTips,
    if (PlayCategory.creative.matches(item)) ..._creativeTips,
  ],
  ..._jokes,
  ..._tips,
];

/// One line per finished play: about half the time a tip that fits the play, otherwise
/// anything from the pool (so a joke now and then, and never the same line twice in a row).
SzopLine pickSzopAfterPlay(ContentItem? item, math.Random random, {SzopLine? previous}) {
  final pool = szopAfterPlayPool(item).where((l) => l != previous).toList();
  final fitting = pool.where((l) => _fits(l, item)).toList();
  if (fitting.isNotEmpty && random.nextBool()) return fitting[random.nextInt(fitting.length)];
  return pool[random.nextInt(pool.length)];
}

bool _fits(SzopLine line, ContentItem? item) =>
    item != null && !_jokes.contains(line) && !_tips.contains(line);

final _random = math.Random();
SzopLine? _previous;

/// The line for the play that just ended (by its item), shared by the player and the bar so
/// both say the same thing. Watched only while the play is over, so each end gets a new one.
final szopAfterPlayProvider = Provider.autoDispose.family<SzopLine, ContentItem?>((ref, item) {
  final line = pickSzopAfterPlay(item, _random, previous: _previous);
  _previous = line;
  return line;
});

/// Szop’en’s line under a finished play, in the player: small, closable, gone with
/// "Komentarze Szop’ena" off.
class SzopAfterPlayCard extends ConsumerStatefulWidget {
  const SzopAfterPlayCard({super.key, required this.item});

  final ContentItem? item;

  @override
  ConsumerState<SzopAfterPlayCard> createState() => _SzopAfterPlayCardState();
}

class _SzopAfterPlayCardState extends ConsumerState<SzopAfterPlayCard> {
  bool _closed = false;

  @override
  Widget build(BuildContext context) {
    if (_closed || (ref.watch(discoveryProvider).value?.quiet ?? false)) return const SizedBox.shrink();
    final line = ref.watch(szopAfterPlayProvider(widget.item));
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Dismissible(
      key: ValueKey(line),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => setState(() => _closed = true),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .85, end: 1),
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SzopSticker(line.pose, height: 72),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: 'Szop’en ${line.tip ? 'radzi' : 'mówi'}: ${line.text}',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (line.tip)
                                Text(
                                  'RADA SZOP’ENA',
                                  style: text.labelSmall?.copyWith(
                                    color: const Color(0xFF6B5A8E),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                              Text(
                                line.text,
                                style: text.bodyMedium?.copyWith(
                                  color: ink,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Schowaj Szop’ena',
                          visualDensity: VisualDensity.compact,
                          color: ink,
                          onPressed: () => setState(() => _closed = true),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Szop’en in the player while a play runs: a line a little after it starts, then every few
/// minutes, each gone after a while or with a swipe to the left. Off with "Komentarze Szop’ena".
class SzopWhilePlaying extends ConsumerStatefulWidget {
  const SzopWhilePlaying({super.key, required this.playing});

  final bool playing;

  @override
  ConsumerState<SzopWhilePlaying> createState() => _SzopWhilePlayingState();
}

class _SzopWhilePlayingState extends ConsumerState<SzopWhilePlaying> {
  static const _first = Duration(seconds: 20);
  static const _every = Duration(minutes: 2, seconds: 30);
  static const _shown = Duration(seconds: 14);

  (SzopPose, String)? _line;
  Timer? _next;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    if (widget.playing) _next = Timer(_first, _speak);
  }

  @override
  void didUpdateWidget(SzopWhilePlaying old) {
    super.didUpdateWidget(old);
    if (widget.playing && !old.playing) {
      _next?.cancel();
      _next = Timer(_first, _speak);
    } else if (!widget.playing && old.playing) {
      _next?.cancel();
    }
  }

  void _speak() {
    if (!mounted || !widget.playing) return;
    if (!(ref.read(discoveryProvider).value?.quiet ?? false)) {
      setState(() => _line = ref.read(szopPlayingBagProvider).next());
      _hide?.cancel();
      _hide = Timer(_shown, () {
        if (mounted) setState(() => _line = null);
      });
    }
    _next = Timer(_every, _speak);
  }

  @override
  void dispose() {
    _next?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    const ink = Color(0xFF211C35);
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: line == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Dismissible(
                key: ValueKey(line),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => setState(() => _line = null),
                child: Semantics(
                  liveRegion: true,
                  label: 'Szop’en mówi: ${line.$2}',
                  excludeSemantics: true,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                    decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        SzopSticker(line.$1, height: 48),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            line.$2,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ink, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
