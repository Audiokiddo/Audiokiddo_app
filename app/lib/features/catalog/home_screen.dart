import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/doodles.dart';
import '../../core/widgets/kiddo.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/app_localizations.dart';
import '../family/family.dart';
import '../home/first_steps.dart';
import '../home/quick_pick.dart';
import '../home/today.dart';
import '../kids_mode/kids_mode_setup.dart';
import 'catalog_providers.dart';
import 'widgets/catalog_loader.dart';
import 'widgets/item_views.dart';

/// Start answers one question: what do we put on now? Today's portion, four ways to play,
/// first steps for a new parent, a question for the dinner table. Browsing lives in the
/// library.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CatalogLoader(builder: (context, catalog) => _HomeContent(catalog: catalog)),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final news = [
      for (final s in catalog.shelves.where((s) => s.id == 'nowosci'))
        for (final id in s.itemIds) ?catalog.item(id),
    ];

    return ListView(
      // The frosted tab bar floats over the list: leave room under the last card.
      padding: EdgeInsets.only(bottom: AkSpace.xl + MediaQuery.paddingOf(context).bottom),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.l, AkSpace.m, AkSpace.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeGreeting, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: AkSpace.xs),
              const _ScreenFreeLine(),
            ],
          ),
        ),
        const TodayHero(),
        const _Modes(),
        const FirstStepsCard(),
        const TalkCard(),
        if (news.isNotEmpty) ScrollReveal(child: _NewsBanner(item: news.first)),
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, 0),
          child: OutlinedButton.icon(
            onPressed: () => context.go('/biblioteka'),
            icon: const Icon(Icons.grid_view_rounded),
            label: Text(l10n.homeAllActivities(catalog.items.length)),
          ),
        ),
      ],
    );
  }
}

/// Minutes of play instead of a screen in the last seven days, all children together.
final screenFreeMinutesProvider = Provider<int>((ref) {
  final family = ref.watch(familyProvider).value;
  if (family == null) return 0;
  final since = ref.watch(clockProvider)().subtract(const Duration(days: 7));
  var seconds = 0;
  for (final child in family.children) {
    for (final r in family.resultsOf(child.id)) {
      if (r.at.isAfter(since)) seconds += r.seconds;
    }
  }
  // Rounded up: the first short activity already counts.
  return (seconds + 59) ~/ 60;
});

/// "84 min without a screen this week (like 4 cartoon episodes)", or the plain promise.
class _ScreenFreeLine extends ConsumerWidget {
  const _ScreenFreeLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final minutes = ref.watch(screenFreeMinutesProvider);
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.palette.inkMuted);
    if (minutes == 0) return Text(l10n.homeSubtitle, style: style);
    // A cartoon episode is about 20 minutes: the comparison parents count in.
    final episodes = minutes ~/ 20;
    return Row(
      children: [
        const Icon(Icons.visibility_off_rounded, size: 20, color: AkBrand.teal),
        const SizedBox(width: AkSpace.s),
        Expanded(
          child: Text(
            episodes > 0 ? l10n.screenFreeEpisodes(minutes, episodes) : l10n.screenFree(minutes),
            style: style?.copyWith(color: context.palette.ink, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// Four big ways to play, the one that fits this part of the day first.
class _Modes extends ConsumerWidget {
  const _Modes();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final part = dayPartOf(ref.watch(clockProvider)());
    final quick = _Mode(
      Icons.timer_rounded,
      l10n.modeQuick,
      l10n.modeQuickHint,
      AkBrand.teal,
      () => showQuickPick(context),
    );
    final trip = _Mode(
      Icons.directions_car_rounded,
      l10n.modeTrip,
      l10n.modeTripHint,
      AkBrand.terracotta,
      () => context.push('/podroz'),
    );
    final bed = _Mode(
      Icons.bedtime_rounded,
      l10n.modeBedtime,
      l10n.modeBedtimeHint,
      const Color(0xFF3B2E5A),
      () => context.push('/dobranoc'),
    );
    final kids = _Mode(
      Icons.child_care_rounded,
      l10n.modeKids,
      l10n.modeKidsHint,
      AkBrand.lavenderDeep,
      () => showKidsModeSetup(context, ref),
    );
    final modes = switch (part) {
      DayPart.evening => [bed, quick, kids, trip],
      DayPart.afternoon => [trip, quick, kids, bed],
      _ => [quick, trip, kids, bed],
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AkSpace.xs, bottom: AkSpace.s),
            child: Text(l10n.modesTitle, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (var row = 0; row < 2; row++)
            Padding(
              padding: EdgeInsets.only(bottom: row == 0 ? AkSpace.s : 0),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: modes[row * 2]),
                    const SizedBox(width: AkSpace.s),
                    Expanded(child: modes[row * 2 + 1]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Mode extends StatelessWidget {
  const _Mode(this.icon, this.title, this.hint, this.color, this.onTap);

  final IconData icon;
  final String title;
  final String hint;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title. $hint',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AkSpace.m),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(AkRadius.card),
            boxShadow: akSoftShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: AkSpace.s),
              Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(hint, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lavender "Nowość!" card like in picture-book apps: a sticker, the title, a hint.
class _NewsBanner extends StatelessWidget {
  const _NewsBanner({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.s, AkSpace.m, 0),
      child: Semantics(
        button: true,
        label: '${l10n.homeNew}: ${item.title}',
        excludeSemantics: true,
        child: Material(
          color: const Color(0xFFE9DDF5),
          borderRadius: BorderRadius.circular(AkRadius.card),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(itemRoute(item)),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: FloatingDoodles(count: 6, opacity: 0.12, color: AkBrand.lavenderDeep, seed: 11),
                ),
                Padding(
                  padding: const EdgeInsets.all(AkSpace.m),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AkBrand.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                l10n.homeNew,
                                style: text.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: AkSpace.s),
                            Text(
                              item.title,
                              style: text.titleLarge?.copyWith(
                                color: AkBrand.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(l10n.homeNewHint, style: text.bodyMedium?.copyWith(color: AkBrand.ink)),
                          ],
                        ),
                      ),
                      const Kiddo(size: 76, mood: KiddoMood.listening),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
