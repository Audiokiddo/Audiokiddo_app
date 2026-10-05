import 'dart:async';
import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
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
    locked: catalog.items.where((i) => fits(i) && !canPlay(i)).length,
  );
}

/// Off in widget tests (they check Start without a sheet over it).
final launchGreetingEnabledProvider = Provider<bool>((ref) => true);

final _random = math.Random();
T _pick<T>(List<T> options) => options[_random.nextInt(options.length)];

/// Shows Szop’en's welcome once per app start, a moment after Start appears. Not during the
/// first welcome or the tour, not in kids mode, and never with "Komentarze Szop’ena" off.
class LaunchGreeting extends ConsumerStatefulWidget {
  const LaunchGreeting({super.key});

  /// Once per launch, across rebuilds of Start.
  static bool shown = false;

  @override
  ConsumerState<LaunchGreeting> createState() => _LaunchGreetingState();
}

class _LaunchGreetingState extends ConsumerState<LaunchGreeting> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!LaunchGreeting.shown && ref.read(launchGreetingEnabledProvider)) {
      _timer = Timer(const Duration(milliseconds: 1500), _maybeShow);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _maybeShow() async {
    if (!mounted || LaunchGreeting.shown) return;
    final welcome = ref.read(welcomeProvider);
    if (!welcome.done || welcome.tourPending || ref.read(kidsModeProvider).active) return;
    final quiet = (await ref.read(discoveryProvider.future)).quiet;
    final catalog = ref.read(catalogProvider).value;
    if (quiet || catalog == null || !mounted) return;
    final family = ref.read(familyProvider).value;
    final news = launchNews(
      catalog: catalog,
      resume: ref.read(resumeCardProvider),
      newItems: ref.read(newItemsProvider),
      heard: {
        ...?ref.read(recentProvider).value,
        for (final r in family?.results ?? const <ActivityResult>[]) r.itemId,
      },
      canPlay: (i) => ref.read(canPlayProvider(i)),
      age: family?.active?.age,
    );
    if (news.isEmpty) return;
    LaunchGreeting.shown = true;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _GreetingSheet(news: news, host: context),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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
              host.push(resume.mediaId!.startsWith('game:') ? '/gra' : '/odtwarzacz');
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
                  'Do odkrycia zostało Wam ${news.left} zabaw, czyli ${news.leftMinutes} minut bez ekranu. Spokojnie, do emerytury zdążymy.',
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
              'Przesłuchaliście wszystko, co macie. Szacun! W abonamencie czeka jeszcze ${news.locked} zabaw i nowy pakiet co miesiąc.',
          action: 'Zobacz',
          onTap: () => go(() => host.go('/sklep')),
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
