import 'dart:async';
import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../purchases/shop.dart';
import '../../core/open_player.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/home_screen.dart' show AudioKiddoLogo;
import '../catalog/seasonal.dart';
import '../discovery/discovery_model.dart';
import '../family/family.dart' hide progressProvider;
import '../kids_mode/kids_mode_controller.dart';
import '../personal/personal_repository.dart';
import '../player/bottom_dock.dart' show ResumeCard, resumeCardProvider;
import '../welcome/welcome_controller.dart';
import 'quick_pick.dart';

/// What Szop’en has to say when the app opens: the unfinished play, something new, and how
/// many plays are still waiting. Null when there is nothing worth saying.
@immutable
class LaunchNews {
  const LaunchNews({this.resume, this.fresh, this.left = 0, this.leftMinutes = 0, this.locked = 0});

  final ResumeCard? resume;
  final ContentItem? fresh;

  /// Plays the family may play and has not heard yet.
  final int left;
  final int leftMinutes;

  /// Plays waiting behind the subscription.
  final int locked;

  bool get isEmpty => resume == null && fresh == null && left == 0 && locked == 0;
}

LaunchNews launchNews({
  required Catalog catalog,
  required ResumeCard? resume,
  required List<ContentItem> newItems,
  required Set<String> heard,
  required bool Function(ContentItem) canPlay,
  int? age,
  bool subscribed = false,
}) {
  bool fits(ContentItem i) => age == null || (i.ageMin <= age && (i.ageMax == null || age <= i.ageMax!));
  final waiting = [
    for (final i in catalog.items)
      if (i.audio.isNotEmpty && fits(i) && !heard.contains(i.id) && canPlay(i)) i,
  ];
  return LaunchNews(
    resume: resume,
    fresh: newItems.where((i) => !heard.contains(i.id) && canPlay(i)).firstOrNull,
    left: waiting.length,
    leftMinutes: waiting.fold(0, (m, i) => m + i.durationSec) ~/ 60,
    locked: subscribed ? 0 : catalog.items.where((i) => fits(i) && !canPlay(i)).length,
  );
}

/// Off in widget tests (they check Start without a sheet over it).
final launchGreetingEnabledProvider = Provider<bool>((ref) => true);

final _random = math.Random();
T _pick<T>(List<T> options) => options[_random.nextInt(options.length)];

/// Szop’en's welcome, once per app start. A short curtain with his entrance covers Start while
/// the news is worked out, and the sheet slides up the moment the curtain lifts, so nothing
/// pops up under a thumb that has already reached for a tile. Not during the first welcome or
/// the tour, not in kids mode, and never with "Komentarze Szop’ena" off.
class LaunchGreeting extends ConsumerStatefulWidget {
  const LaunchGreeting({super.key});

  /// Once per launch, across rebuilds of Start.
  static bool shown = false;

  /// How long the curtain stays at least (its entrance takes this long), and at most.
  static const curtainTime = Duration(milliseconds: 1500);
  static const curtainLimit = Duration(seconds: 4);

  @override
  ConsumerState<LaunchGreeting> createState() => _LaunchGreetingState();
}

class _LaunchGreetingState extends ConsumerState<LaunchGreeting> {
  @override
  void initState() {
    super.initState();
    if (!LaunchGreeting.shown && ref.read(launchGreetingEnabledProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  /// What there is to say, or null (no catalog yet, nothing new).
  Future<LaunchNews?> _news() async {
    final catalog = await ref.read(catalogProvider.future);
    if (!mounted) return null;
    final family = ref.read(familyProvider).value;
    return launchNews(
      catalog: catalog,
      resume: ref.read(resumeCardProvider),
      newItems: ref.read(newItemsProvider),
      heard: {
        ...?ref.read(recentProvider).value,
        for (final r in family?.results ?? const <ActivityResult>[]) r.itemId,
      },
      canPlay: (i) => ref.read(canPlayProvider(i)),
      age: family?.active?.age,
      // Subscribers are not told what the subscription would open (only "Wkrótce" is locked).
      subscribed: ref.read(hasSubscriptionProvider),
    );
  }

  Future<void> _run() async {
    if (!mounted || LaunchGreeting.shown) return;
    final welcome = ref.read(welcomeProvider);
    if (!welcome.done || welcome.tourPending || ref.read(kidsModeProvider).active) return;
    final quiet = (await ref.read(discoveryProvider.future)).quiet;
    if (quiet || !mounted || LaunchGreeting.shown) return;
    LaunchGreeting.shown = true;

    final nav = Navigator.of(context, rootNavigator: true);
    final skip = Completer<void>();
    final minimum = Future<void>.delayed(LaunchGreeting.curtainTime);
    unawaited(
      showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 260),
        // In at once (no flash of Start first), out with a fade while the sheet comes up.
        transitionBuilder: (_, animation, _, child) => AnimatedBuilder(
          animation: animation,
          builder: (_, child) => Opacity(
            opacity: animation.status == AnimationStatus.reverse ? animation.value : 1,
            child: child,
          ),
          child: child,
        ),
        pageBuilder: (_, _, _) => PopScope(
          canPop: false,
          child: LaunchCurtain(onSkip: () => skip.isCompleted ? null : skip.complete()),
        ),
      ),
    );

    LaunchNews? news;
    try {
      news = await _news().timeout(LaunchGreeting.curtainLimit);
    } on Object {
      news = null; // slow or broken: no greeting this time rather than one that pops up late
    }
    await Future.any([minimum, skip.future]);
    if (nav.canPop()) nav.pop();
    if (news == null || news.isEmpty || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _GreetingSheet(news: news!, host: context),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Szop’en's entrance: a burst of confetti, him bouncing in, the name dropping in letter by
/// letter. About a second and a half; a tap skips it.
class LaunchCurtain extends StatefulWidget {
  const LaunchCurtain({super.key, this.onSkip});

  final VoidCallback? onSkip;

  @override
  State<LaunchCurtain> createState() => _LaunchCurtainState();
}

class _LaunchCurtainState extends State<LaunchCurtain> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: LaunchGreeting.curtainTime);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduced motion: the finished picture, no movement.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: 'AudioKiddo się uruchamia',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSkip,
        child: ColoredBox(
          color: palette.background,
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                final pop = Curves.elasticOut.transform(const Interval(0.04, 0.55).transform(t));
                final tilt = (1 - Curves.easeOut.transform(const Interval(0, 0.5).transform(t))) * -.5;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _BurstPainter(const Interval(0.08, 0.85).transform(t)),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, (1 - pop.clamp(0, 1)) * 60),
                            child: Transform.rotate(
                              angle: tilt,
                              child: Transform.scale(
                                scale: .3 + .7 * pop,
                                child: const SzopSticker(SzopPose.klaszcze, height: 170),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // The real logo drops in and settles; no lettering of its own.
                    Builder(
                      builder: (_) {
                        final v = Curves.easeOutBack.transform(const Interval(.3, .7).transform(t));
                        return Opacity(
                          opacity: v.clamp(0, 1),
                          child: Transform.translate(
                            offset: Offset(0, (1 - v) * 24),
                            child: Transform.scale(scale: .85 + .15 * v, child: const AudioKiddoLogo(height: 64)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Opacity(
                      opacity: const Interval(.7, 1).transform(t),
                      child: Text(
                        'Szop’en odkurza mikrofon…',
                        style: text.bodyMedium?.copyWith(color: palette.inkMuted),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Confetti: dots and little stars flying out from the middle and fading.
class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.t);

  final double t;

  static const _colors = [AkBrand.sun, AkBrand.teal, AkBrand.orange, AkBrand.lavender, AkBrand.coral];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final centre = size.center(Offset.zero);
    final out = Curves.easeOutCubic.transform(t);
    const count = 18;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * math.pi / count + (i.isEven ? .12 : -.1);
      final reach = 70 + (i % 3) * 26.0;
      final pos = centre + Offset(math.cos(angle), math.sin(angle)) * (reach * out + 20);
      final size = (i % 2 == 0 ? 9.0 : 13.0) * (1 - t * .7);
      final paint = Paint()..color = _colors[i % _colors.length].withValues(alpha: (1 - t * t).clamp(0, 1));
      if (i % 2 == 0) {
        canvas.drawCircle(pos, size / 2, paint);
      } else {
        canvas
          ..save()
          ..translate(pos.dx, pos.dy)
          ..rotate(t * 3 + i)
          ..drawPath(_star(size), paint)
          ..restore();
      }
    }
  }

  static Path _star(double r) {
    final path = Path();
    for (var k = 0; k < 8; k++) {
      final radius = k.isEven ? r : r * .4;
      final a = k * math.pi / 4;
      final p = Offset(math.cos(a), math.sin(a)) * radius;
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

class _GreetingSheet extends StatelessWidget {
  const _GreetingSheet({required this.news, required this.host});

  final LaunchNews news;
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final resume = news.resume;
    final fresh = news.fresh;
    final hello = _pick([
      'O, jesteście! Już myślałem, że zostanę tu sam z pilotem.',
      'Cześć! Odkurzyłem mikrofon. Prawie. Trochę.',
      'Wróciliście! Zgadnijcie, kto nie spał całą noc. Ja też nie wiem.',
      'Hej! Szop’en melduje się na służbie. Kawa niestety tylko dla dorosłych.',
    ]);

    void go(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    final cards = <Widget>[
      if (resume != null)
        _Line(
          icon: Icons.history_rounded,
          color: AkBrand.sun,
          text: _pick([
            'Zatrzymaliście „${resume.title}” w połowie. Bohaterowie stoją z jedną nogą w powietrzu i robi im się zimno.',
            '„${resume.title}” czeka na dokończenie. Obiecałem, że wrócicie. Nie róbcie ze mnie kłamczucha.',
          ]),
          action: 'Dokończ',
          onTap: () => go(() {
            if (resume.loaded) {
              openPlayer(host, game: resume.mediaId!.startsWith('game:'));
            } else {
              startItem(host, resume.item!);
            }
          }),
        ),
      if (fresh != null)
        _Line(
          icon: Icons.fiber_new_rounded,
          color: AkBrand.teal,
          text: _pick([
            'Nowość: „${fresh.title}”! Pachnie jeszcze farbą drukarską.',
            'Mamy nową zabawę: „${fresh.title}”. Sprawdziłem: działa, a ja się nie przestraszyłem. Prawie.',
          ]),
          action: 'Posłuchaj',
          onTap: () => go(() => startItem(host, fresh)),
        ),
      if (news.left > 0)
        _Line(
          icon: Icons.explore_rounded,
          color: AkBrand.lavender,
          text: news.left == 1
              ? 'Została Wam jeszcze jedna nieodkryta zabawa. Ostatni kawałek pizzy, ale w wersji audio.'
              : _pick([
                  'Do odkrycia zostało Wam ${news.left} zabaw, czyli ${news.leftMinutes} minut słuchania. Spokojnie, do emerytury zdążymy.',
                  'Jeszcze ${news.left} zabaw przed Wami. Liczyłem na palcach. Mam ich tylko dziesięć, więc pożyczyłem od sąsiada.',
                ]),
          action: 'Losuj',
          onTap: () => go(() => showQuickPick(host)),
        )
      else if (news.locked > 0)
        _Line(
          icon: Icons.emoji_events_rounded,
          color: AkBrand.orange,
          text:
              'Przesłuchaliście wszystko, co macie. Szacun! W abonamencie czeka jeszcze ${news.locked} zabaw, a co tydzień dochodzą 2 nowe.',
          action: 'Zobacz',
          onTap: () => go(() => host.push('/abonament')),
        ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .4, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) => Transform.scale(scale: v, child: child),
                  child: SzopSticker(resume != null ? SzopPose.chytry : SzopPose.zadowolony, height: 84),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(hello, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...cards,
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Później')),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.color,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(width: 8),
        FilledButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}
