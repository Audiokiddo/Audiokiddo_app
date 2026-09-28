import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/audio/kiddo_voice.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/doodles.dart';
import '../../core/widgets/kiddo.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/item_views.dart';
import '../family/family.dart';
import '../family/plan_texts.dart';

/// Parts of the family day the app fits into: a morning warm-up, an adventure, the drive
/// home, the calm evening.
enum DayPart { morning, midday, afternoon, evening }

DayPart dayPartOf(DateTime t) => switch (t.hour) {
  >= 5 && < 11 => DayPart.morning,
  >= 11 && < 15 => DayPart.midday,
  >= 15 && < 19 => DayPart.afternoon,
  _ => DayPart.evening,
};

/// The big card at the top of Start: what to do right now, for the child who listens.
class TodayHero extends ConsumerWidget {
  const TodayHero({super.key});

  static const _gradients = {
    DayPart.morning: [Color(0xFFFFD27A), Color(0xFFFF9A6B)],
    DayPart.midday: [Color(0xFF7FD3D6), Color(0xFFFFD27A)],
    DayPart.afternoon: [Color(0xFFFFB38A), Color(0xFFC9A6E0)],
    DayPart.evening: [Color(0xFF3B2E5A), Color(0xFF1E2A4A)],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final part = dayPartOf(now);
    final night = part == DayPart.evening;
    final fg = night ? Colors.white : AkBrand.cocoa;
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final catalog = ref.watch(catalogProvider).value;
    final plan = child == null ? const <PlanDay>[] : ref.watch(planProvider(child.id));
    final position = child == null ? null : ref.watch(planPositionProvider(child.id));
    final index = family?.children.indexWhere((c) => c.id == child?.id) ?? 0;

    final (title, mood) = switch (part) {
      DayPart.morning => (l10n.todayMorning, KiddoMood.happy),
      DayPart.midday => (l10n.todayMidday, KiddoMood.idle),
      DayPart.afternoon => (l10n.todayAfternoon, KiddoMood.idle),
      DayPart.evening => (l10n.todayEvening, KiddoMood.sleepy),
    };

    String subtitle;
    String action;
    VoidCallback onAction;
    if (child == null || catalog == null || position == null || plan.isEmpty) {
      subtitle = l10n.todayNoPlan;
      action = l10n.planEmptyButton;
      onAction = () => context.push('/plan/dziecko');
    } else if (position.todayDone) {
      subtitle = l10n.todayDone(childLabel(l10n, child, index));
      action = l10n.todayListenMelody;
      onAction = () => context.go('/plan');
    } else {
      final day = plan[position.currentDay - 1];
      final minutes =
          day.itemIds.map((id) => catalog.item(id)?.durationSec ?? 0).fold(0, (a, b) => a + b) ~/ 60;
      subtitle = l10n.todayPortion(childLabel(l10n, child, index), day.day, minutes);
      action = l10n.todayStart;
      final results = family!.resultsOf(child.id);
      final next = day.itemIds.firstWhere(
        (id) => !results.any((r) => r.itemId == id && r.completed && _sameDay(r.at, now)),
        orElse: () => day.itemIds.first,
      );
      onAction = () {
        final item = catalog.item(next);
        if (item != null) context.push(itemRoute(item));
      };
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
      child: Pressable(
        onTap: onAction,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _gradients[part]!,
            ),
            boxShadow: akSoftShadow(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: FloatingDoodles(
                  count: 10,
                  color: night ? const Color(0xFFFFE9A8) : Colors.white,
                  opacity: night ? 0.5 : 0.45,
                  seed: part.index + 20,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AkSpace.l, AkSpace.l, AkSpace.m, AkSpace.l),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.EEEE('pl').format(now).toUpperCase(),
                            style: text.labelMedium?.copyWith(
                              color: fg.withValues(alpha: 0.75),
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AkSpace.xs),
                          Text(title, style: text.headlineMedium?.copyWith(color: fg)),
                          const SizedBox(height: AkSpace.s),
                          Text(subtitle, style: text.bodyLarge?.copyWith(color: fg.withValues(alpha: 0.9))),
                          const SizedBox(height: AkSpace.m),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: night ? Colors.white : AkBrand.cocoa,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: night ? AkBrand.cocoa : Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    action,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.titleMedium?.copyWith(
                                      color: night ? AkBrand.cocoa : Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PokeKiddo(mood: mood),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Kiddo on the hero card: touch him and he says something.
class _PokeKiddo extends ConsumerStatefulWidget {
  const _PokeKiddo({required this.mood});

  final KiddoMood mood;

  @override
  ConsumerState<_PokeKiddo> createState() => _PokeKiddoState();
}

class _PokeKiddoState extends ConsumerState<_PokeKiddo> {
  bool _talking = false;
  int _line = 0;

  Future<void> _poke() async {
    if (_talking) return;
    setState(() {
      _talking = true;
      _line = _line % 3 + 1;
    });
    await ref.read(kiddoVoiceProvider).say('kids_$_line');
    if (mounted) setState(() => _talking = false);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: AppLocalizations.of(context).homeKiddo,
    child: GestureDetector(
      onTap: _poke,
      child: Kiddo(
        size: 92,
        mood: _talking ? KiddoMood.talking : widget.mood,
        wave: widget.mood == KiddoMood.happy,
      ),
    ),
  );
}

/// "Porozmawiajcie": one question for the parent, from today's activity, so the play goes
/// on at the dinner table and in the car. The app becomes part of the day, not a screen.
class TalkCard extends ConsumerWidget {
  const TalkCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final catalog = ref.watch(catalogProvider).value;
    if (child == null || catalog == null) return const SizedBox.shrink();
    final now = ref.watch(clockProvider)();
    final today = [
      for (final r in family!.resultsOf(child.id))
        if (r.completed && r.at.year == now.year && r.at.month == now.month && r.at.day == now.day) r,
    ];
    ContentItem? item;
    var after = true;
    if (today.isNotEmpty) {
      item = catalog.item(today.last.itemId);
    } else {
      final plan = ref.watch(planProvider(child.id));
      final position = ref.watch(planPositionProvider(child.id));
      if (plan.isNotEmpty && position != null) {
        item = catalog.item(plan[position.currentDay - 1].itemIds.first);
      }
      after = false;
    }
    if (item == null) return const SizedBox.shrink();
    final evening = dayPartOf(now) == DayPart.evening || now.hour >= 17;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, 0),
      child: Container(
        padding: const EdgeInsets.all(AkSpace.l),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AkRadius.card),
          boxShadow: akSoftShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.forum_rounded, color: AkBrand.terracotta),
                const SizedBox(width: AkSpace.s),
                Text(
                  (evening ? l10n.talkDinner : l10n.talkTitle).toUpperCase(),
                  style: text.labelMedium?.copyWith(
                    color: AkBrand.terracotta,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AkSpace.s),
            Text(talkPrompt(l10n, item), style: text.titleLarge),
            const SizedBox(height: AkSpace.xs),
            Text(
              after ? l10n.talkAfter(item.title) : l10n.talkBefore(item.title),
              style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A question that carries the play into family life. Chosen by what the activity trains.
String talkPrompt(AppLocalizations l10n, ContentItem item) {
  if (item.kind == ContentKind.song) return l10n.talkSong;
  if (item.kind == ContentKind.interactiveGame) return l10n.talkGame;
  if (item.packId == 'detektyw') return l10n.talkDetective;
  final skills = item.skills.toSet();
  if (skills.contains('słownictwo')) return l10n.talkWords;
  if (skills.contains('logiczne myślenie')) return l10n.talkLogic;
  if (skills.contains('wyobraźnia') || skills.contains('opowiadanie')) return l10n.talkImagination;
  return l10n.talkListening;
}
