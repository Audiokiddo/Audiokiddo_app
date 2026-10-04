import 'dart:async';
import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/storage/storage_providers.dart';
import '../discovery/discovery_model.dart';
import '../../core/widgets/ambient_motion.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../discovery/reference_widgets.dart';
import '../home/quick_pick.dart';
import '../personal/personal_repository.dart';
import 'playback_controller.dart';
import 'player_providers.dart';
import 'szop_after_play.dart';

const _barColor = referencePurple;
const _barHeight = 68.0;

/// One tab of the bar (the middle play button is not a tab).
typedef DockTab = ({IconData icon, IconData selected, String label});

/// The bottom of the parent app: the "carry on" card with Szop’en peeking out of the bar, and
/// the bar itself with a big play button in the middle.
class BottomDock extends ConsumerWidget {
  const BottomDock({super.key, required this.tabs, required this.current, required this.onTab});

  /// Exactly four: two left and two right of the play button.
  final List<DockTab> tabs;
  final int current;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final resume = ref.watch(resumeCardProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (resume != null)
          // Swiped to the left, the card goes away until something else is playing or paused.
          Dismissible(
            key: ValueKey(resume.key),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              ref.read(hiddenResumeProvider.notifier).hide(resume.key);
              // Swiping the card away ends the play too, playing or paused.
              if (resume.loaded) ref.read(audioHandlerProvider).endSession();
            },
            child: _ResumeCard(resume: resume),
          ),
        Container(
          height: _barHeight + bottom,
          padding: EdgeInsets.only(bottom: bottom),
          decoration: const BoxDecoration(
            color: _barColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < 2; i++) _tab(i),
              const Expanded(child: Center(child: _PlayButton())),
              for (var i = 2; i < 4; i++) _tab(i),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tab(int i) {
    final tab = tabs[i];
    final selected = i == current;
    final color = selected ? Colors.white : Colors.white.withValues(alpha: .62);
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: tab.label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: () => onTab(i),
          radius: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? tab.selected : tab.icon, color: color, size: 25),
              const SizedBox(height: 3),
              Text(
                tab.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plays what is loaded (opens the player), or offers a quick pick when nothing is.
class _PlayButton extends ConsumerWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(currentMediaProvider).value;
    final playing = ref.watch(playbackStateProvider).value?.playing ?? false;
    return Semantics(
      button: true,
      label: media == null ? 'Szybki wybór zabawy' : 'Otwórz odtwarzacz: ${media.title}',
      excludeSemantics: true,
      child: GestureDetector(
        // Playing: back to it. Otherwise a choice (with "carry on" on top when something waits).
        onTap: () {
          if (media != null && playing) {
            context.push(media.id.startsWith(gameMediaPrefix) ? '/gra' : '/odtwarzacz');
          } else {
            showQuickPick(context);
          }
        },
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AkBrand.teal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .9), width: 3),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Icon(
            media != null && playing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}

/// What the card above the bar offers: the loaded recording, or the last unfinished one.
@immutable
class ResumeCard {
  const ResumeCard({required this.title, this.item, this.mediaId, this.loaded = false});

  final String title;
  final ContentItem? item;
  final String? mediaId;

  /// Already in the player (play/pause), rather than to be started.
  final bool loaded;

  String get key => mediaId ?? item?.id ?? title;
}

/// The card the parent swiped away (by [ResumeCard.key]); it stays hidden for that play.
final hiddenResumeProvider = NotifierProvider<HiddenResume, String?>(HiddenResume.new);

class HiddenResume extends Notifier<String?> {
  @override
  String? build() => null;

  void hide(String key) => state = key;
}

final resumeCardProvider = Provider<ResumeCard?>((ref) {
  final card = ref.watch(_resumeCandidateProvider);
  return card == null || card.key == ref.watch(hiddenResumeProvider) ? null : card;
});

final _resumeCandidateProvider = Provider<ResumeCard?>((ref) {
  final media = ref.watch(currentMediaProvider).value;
  if (media != null) return ResumeCard(title: media.title, mediaId: media.id, loaded: true);
  final catalog = ref.watch(catalogProvider).value;
  for (final id in ref.watch(recentProvider).value ?? const <String>[]) {
    final item = catalog?.item(id);
    final progress = ref.watch(progressProvider(id)).value;
    if (item != null && progress != null && !progress.completed && progress.positionMs > 15000) {
      return ResumeCard(title: item.title, item: item);
    }
    break; // only the very last one: older unfinished plays are in "Kontynuuj"
  }
  return null;
});

class _ResumeCard extends ConsumerStatefulWidget {
  const _ResumeCard({required this.resume});

  final ResumeCard resume;

  @override
  ConsumerState<_ResumeCard> createState() => _ResumeCardState();
}

class _ResumeCardState extends ConsumerState<_ResumeCard> {
  // He rises from the bar when the card appears, then breathes gently.
  bool _risen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _risen = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resume = widget.resume;
    final handler = ref.watch(audioHandlerProvider);
    final playing = resume.loaded && (ref.watch(playbackStateProvider).value?.playing ?? false);
    final ended =
        resume.loaded &&
        ref.watch(playbackStateProvider).value?.processingState == AudioProcessingState.completed;
    final endedItem = ended ? ref.watch(catalogProvider).value?.item(resume.mediaId!) : null;
    final afterPlay = ended && !(ref.watch(discoveryProvider).value?.quiet ?? false)
        ? ref.watch(szopAfterPlayProvider(endedItem))
        : null;
    final pose =
        afterPlay?.pose ?? (playing ? SzopPose.klaszcze : (resume.loaded ? SzopPose.prosi : SzopPose.chytry));
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    void open() {
      if (resume.loaded) {
        context.push(resume.mediaId!.startsWith(gameMediaPrefix) ? '/gra' : '/odtwarzacz');
      } else {
        startItem(context, resume.item!);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ResumeAside(key: ValueKey((afterPlay, playing)), afterPlay: afterPlay?.text, playing: playing),
        SizedBox(
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 12,
                right: 12,
                top: 6,
                bottom: 6,
                child: Material(
                  color: AkBrand.sun,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: open,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(106, 6, 8, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  playing
                                      ? 'Teraz słuchacie'
                                      : ended
                                      ? 'Brawo! Przygoda skończona'
                                      : resume.loaded
                                      ? 'Wróćmy do zabawy'
                                      : 'Dokończ przygodę',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  resume.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall?.copyWith(color: ink),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AkBrand.tealDeep,
                              foregroundColor: Colors.white,
                            ),
                            tooltip: playing ? 'Pauza' : 'Odtwórz',
                            onPressed: !resume.loaded ? open : (playing ? handler.pause : handler.play),
                            icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Szop’en: his feet hide behind the bar, as if he climbed up from it.
              Positioned(
                left: 18,
                bottom: -14,
                child: IgnorePointer(
                  child: AnimatedSlide(
                    offset: _risen ? Offset.zero : const Offset(0, .9),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    child: _Breathing(child: SzopSticker(pose, height: 84)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A slow up-and-down bob, off when the system asks for less motion.
class _Breathing extends ConsumerStatefulWidget {
  const _Breathing({required this.child});

  final Widget child;

  @override
  ConsumerState<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends ConsumerState<_Breathing> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        !TickerMode.valuesOf(context).enabled ||
        !ref.read(ambientMotionProvider);
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      unawaited(_c.repeat());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) =>
        Transform.translate(offset: Offset(0, 2.5 * math.sin(_c.value * 2 * math.pi)), child: child),
    child: widget.child,
  );
}

/// One brief comment now and then beside a paused adventure, and always one when a play has
/// just ended ([afterPlay]). Never speaks over audio.
class ResumeAside extends ConsumerStatefulWidget {
  const ResumeAside({super.key, this.afterPlay, this.playing = false});

  /// Szop’en’s line for the play that just ended: shown at once, outside the daily limit.
  final String? afterPlay;

  /// Something plays: quieter lines for the parent (the bubble never makes a sound).
  final bool playing;

  @override
  ConsumerState<ResumeAside> createState() => _ResumeAsideState();
}

class _ResumeAsideState extends ConsumerState<ResumeAside> {
  String? _line;
  Timer? _hide;
  Timer? _next;
  static final _random = math.Random();

  /// Lines for a paused play, then the general nudges (with their own moods elsewhere).
  static final _lines = [
    'Zatrzymałem przygodę. Prania nie umiem, próbowałem.',
    'Wracamy? Zdążyłem udawać, że pracuję.',
    'Bohaterowie czekają. Jako jedyni w tym domu cierpliwie.',
    'Przerwa zaliczona. Kawa pewnie też już zimna.',
    'Byłem cały czas na posterunku. Chrapanie to wentylacja.',
    'Przygoda zapisana. Gdzie są drugie skarpetki — nadal nie wiem.',
    for (final (_, line) in szopNudges) line,
  ];

  /// While a play runs: a wink or a tip, never anything for the child to look at.
  static const _playingLines = [
    'Ja pilnuję nagrania. Ty pilnuj kawy, zanim wystygnie.',
    'Dziecko słucha, Ty masz chwilę. Nie zmarnuj jej na składanie skarpetek.',
    'Jeśli dziecko odpowiada głośno, to znak, że działa. Sąsiedzi niech też się cieszą.',
    'Możesz zablokować telefon. Nagranie gra dalej, a ja nikomu nie powiem.',
    'Zabawa za długa? Na dole odtwarzacza jest Timer snu. Szopy też lubią krótkie zmiany.',
    'Dziecko się zgubiło w zadaniu? Cofnij o 15 sekund, bez stresu.',
  ];

  // Now and then, never nagging: first after a few seconds, then every few minutes while the
  // card is on screen, at most a handful a day (and never with "Komentarze Szop’ena" off).
  static const _first = Duration(seconds: 3);
  static const _every = Duration(minutes: 2);
  static const _perDay = 15;

  @override
  void initState() {
    super.initState();
    if (widget.afterPlay case final line?) {
      _line = line;
      _hide = Timer(const Duration(seconds: 12), () {
        if (mounted) setState(() => _line = null);
      });
      return;
    }
    _next = Timer(_first, _show);
  }

  Future<void> _show() async {
    try {
      final settings = await ref.read(discoveryProvider.future);
      if (!mounted || settings.quiet) return;
      final db = ref.read(databaseProvider);
      final now = ref.read(clockProvider)();
      final day = '${now.year}-${now.month}-${now.day}';
      final saved = (await db.readValue('szopen_bubbles') ?? '').split('|');
      final count = saved.first == day && saved.length > 1 ? int.tryParse(saved[1]) ?? 0 : 0;
      if (count >= _perDay || !mounted) return;
      await db.writeValue('szopen_bubbles', '$day|${count + 1}');
      if (!mounted) return;
      final pool = widget.playing ? _playingLines : _lines;
      setState(() => _line = pool[_random.nextInt(pool.length)]);
      _hide = Timer(const Duration(seconds: 9), () {
        if (mounted) setState(() => _line = null);
      });
      _next = Timer(_every, _show);
    } on Object {
      /* A decorative comment must never block playback. */
    }
  }

  @override
  void dispose() {
    _hide?.cancel();
    _next?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    final show = line != null && !(ref.watch(discoveryProvider).value?.quiet ?? false);
    const ink = Color(0xFF211C35);
    // A comic speech bubble over Szop’en (left of the card), popping in and out.
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomLeft,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 24, 0),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .6, end: 1),
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack,
                builder: (context, v, child) =>
                    Transform.scale(scale: v, alignment: Alignment.bottomLeft, child: child),
                child: Dismissible(
                  key: ValueKey(line),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => setState(() => _line = null),
                  child: GestureDetector(
                    onTap: () => setState(() => _line = null),
                    child: Semantics(
                      label: 'Szop’en mówi: $line',
                      child: CustomPaint(
                        painter: const _BubblePainter(color: Colors.white, tailX: 46),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                          child: Text(
                            line,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: ink, fontWeight: FontWeight.w600, height: 1.25),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Rounded bubble with a tail at the bottom pointing down to Szop’en.
class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.color, required this.tailX});

  final Color color;
  final double tailX;

  @override
  void paint(Canvas canvas, Size size) {
    const tail = 10.0;
    final body = RRect.fromLTRBR(0, 0, size.width, size.height - tail, const Radius.circular(18));
    final path = Path()
      ..addRRect(body)
      ..moveTo(tailX - 9, size.height - tail - 1)
      ..lineTo(tailX - 4, size.height)
      ..lineTo(tailX + 10, size.height - tail - 1)
      ..close();
    canvas.drawShadow(path, const Color(0x55000000), 6, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color || old.tailX != tailX;
}
