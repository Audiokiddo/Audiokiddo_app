import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/item_views.dart';
import '../../core/widgets/szop.dart';
import '../catalog/widgets/item_art.dart';
import '../discovery/reference_widgets.dart';
import '../home/quick_pick.dart';
import '../purchases/shop.dart';
import 'family.dart';
import 'plan_texts.dart';

/// The parent's daily path, Duolingo-style: one portion a day, levels that unlock features
/// gradually, a chest at the end of each week, Kiddo standing on today's step.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.navPlan,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (child != null)
            IconButton(
              tooltip: l10n.progressTitle,
              icon: const Icon(Icons.insights_rounded),
              onPressed: () => context.push('/plan/postep'),
            ),
        ],
      ),
      body: family == null
          ? const Center(child: CircularProgressIndicator())
          : child == null
          ? const _NoChildren()
          : _Path(child: child, family: family),
    );
  }
}

class _NoChildren extends StatelessWidget {
  const _NoChildren();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AkSpace.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Kiddo(size: 140, mood: KiddoMood.sleepy),
            const SizedBox(height: AkSpace.m),
            Text(
              l10n.planEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AkSpace.s),
            Text(l10n.planEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: AkSpace.l),
            FilledButton.icon(
              onPressed: () => context.push('/plan/dziecko'),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(l10n.planEmptyButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// The parent's path: what to play today (one tap), where the week stands, what the child is
/// developing, and what comes next, with the packs that open more of it.
class _Path extends ConsumerWidget {
  const _Path({required this.child, required this.family});

  final ChildProfile child;
  final FamilyState family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planProvider(child.id));
    final position = ref.watch(planPositionProvider(child.id));
    final progress = ref.watch(progressProvider(child.id));
    final catalog = ref.watch(catalogProvider).value;
    if (plan.isEmpty || position == null || catalog == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final today = plan[position.currentDay - 1];
    final tomorrow = position.currentDay < plan.length ? plan[position.currentDay] : null;
    final weekStart = (position.currentDay - 1) ~/ 7 * 7;
    final week = plan.sublist(weekStart, math.min(weekStart + 7, plan.length));
    return ListView(
      padding: EdgeInsets.only(bottom: AkSpace.xl + MediaQuery.paddingOf(context).bottom),
      children: [
        _ChildSwitcher(family: family),
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.s, AkSpace.m, 0),
          child: _TodayCard(
            child: child,
            day: today,
            done: position.todayDone,
            tomorrow: tomorrow,
            total: plan.length,
            catalog: catalog,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, 0),
          child: _WeekStrip(days: week, position: position, onOpen: (d) => _openDay(context, d, position)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, 0),
          child: _Numbers(progress: progress),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.l, AkSpace.m, 0),
          child: _Growing(child: child, progress: progress, catalog: catalog),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.l, AkSpace.m, 0),
          child: _NextStages(plan: plan, position: position, catalog: catalog),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.insights_rounded, size: 18),
                label: const Text('Szczegółowe postępy'),
                onPressed: () => context.push('/plan/postep'),
              ),
              ActionChip(
                avatar: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Zmień cele i czas'),
                onPressed: () => context.push('/plan/dziecko'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openDay(BuildContext context, PlanDay day, PlanPosition position) {
    final l10n = AppLocalizations.of(context);
    final open = day.day <= position.completedDays || day.day == position.currentDay;
    if (!open) {
      final text = day.day == position.completedDays + 1
          ? l10n.planOpensTomorrow
          : l10n.planLockedDay(day.day - 1);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => _DaySheet(day: day),
    );
  }
}

/// "Dziś dla Zosi": the day's plays, each one tap from playing. No browsing, no deciding.
class _TodayCard extends ConsumerWidget {
  const _TodayCard({
    required this.child,
    required this.day,
    required this.done,
    required this.tomorrow,
    required this.total,
    required this.catalog,
  });

  final ChildProfile child;
  final PlanDay day;
  final bool done;
  final PlanDay? tomorrow;
  final int total;
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    const ink = Colors.white;
    final title = child.name.isEmpty ? 'Plan na dziś' : 'Dziś dla: ${child.name}';
    final items = [for (final id in day.itemIds) ?catalog.item(id)];
    final next = [for (final id in tomorrow?.itemIds ?? const <String>[]) ?catalog.item(id)];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A3670), Color(0xFF2B1F45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DZIEŃ ${day.day} Z $total · ${levelName(l10n, day.level.number).toUpperCase()}',
                  style: text.labelMedium?.copyWith(
                    color: AkBrand.sun,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
              SzopSticker(done ? SzopPose.zadowolony : SzopPose.chytry, height: 54),
            ],
          ),
          Text(
            done ? 'Na dziś zrobione!' : title,
            style: text.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            done
                ? 'Brawo. Kolejny krok otworzy się jutro.'
                : 'Gotowe na ${(items.fold(0, (s, i) => s + i.durationSec) / 60).ceil()} min. Wystarczy nacisnąć.',
            style: text.bodyMedium?.copyWith(color: ink.withValues(alpha: .85)),
          ),
          const SizedBox(height: 12),
          for (final item in done ? next : items) _PlanItemRow(item: item, preview: done),
          if (!done && day.tip != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: AkBrand.sun, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(tipText(l10n, day.tip!), style: text.bodySmall?.copyWith(color: ink)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One play of the day on the dark card: cover, title, minutes, and play (or what unlocks it).
class _PlanItemRow extends ConsumerWidget {
  const _PlanItemRow({required this.item, this.preview = false});

  final ContentItem item;

  /// Tomorrow's play: shown, not started.
  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPlay = ref.watch(canPlayProvider(item));
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/zabawa/${item.id}'),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 52,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ItemArt(item: item),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview ? 'Jutro: ${item.title}' : item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${(item.durationSec / 60).ceil()} min${canPlay ? '' : ' · w pakiecie'}',
                        style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: .8)),
                      ),
                    ],
                  ),
                ),
                if (!preview)
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: canPlay ? AkBrand.teal : AkBrand.sun,
                      foregroundColor: canPlay ? Colors.white : const Color(0xFF211C35),
                    ),
                    tooltip: canPlay ? 'Zaczynamy: ${item.title}' : 'Odblokuj: ${item.title}',
                    onPressed: () => canPlay
                        ? startItem(context, item)
                        : (item.packId != null
                              ? openPack(context, item.packId!)
                              : context.push('/zabawa/${item.id}')),
                    icon: Icon(canPlay ? Icons.play_arrow_rounded : Icons.lock_open_rounded),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The current week as seven steps: done, today, still ahead.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days, required this.position, required this.onOpen});

  final List<PlanDay> days;
  final PlanPosition position;
  final ValueChanged<PlanDay> onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tydzień ${(days.first.day - 1) ~/ 7 + 1}',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, box) {
              // Seven steps across even on the narrowest phones.
              final size = math.min(38.0, (box.maxWidth - 6 * 4) / 7);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final d in days)
                    () {
                      final done = d.day <= position.completedDays;
                      final today = d.day == position.currentDay && !position.todayDone;
                      final label = done
                          ? 'Dzień ${d.day}, zrobiony.'
                          : today
                          ? 'Dzień ${d.day}, dzisiaj. Otwórz zabawy.'
                          : 'Dzień ${d.day}, zablokowany.';
                      return Semantics(
                        button: true,
                        label: label,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => onOpen(d),
                          child: Container(
                            width: size,
                            height: size,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? AkBrand.teal
                                  : today
                                  ? AkBrand.sun
                                  : palette.surfaceMuted,
                              border: today ? Border.all(color: const Color(0xFF211C35), width: 2) : null,
                            ),
                            child: done
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                : d.chest
                                ? Icon(
                                    Icons.redeem_rounded,
                                    size: 18,
                                    color: today ? const Color(0xFF211C35) : palette.inkMuted,
                                  )
                                : Text(
                                    '${d.day}',
                                    style: text.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: today ? const Color(0xFF211C35) : palette.inkMuted,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Numbers extends StatelessWidget {
  const _Numbers({required this.progress});

  final ChildProgress? progress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget n(IconData icon, Color color, String value, String label) => Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
    return Row(
      children: [
        n(Icons.local_fire_department_rounded, AkBrand.orange, '${progress?.streak ?? 0}', 'dni z rzędu'),
        n(Icons.headphones_rounded, AkBrand.tealDeep, '${progress?.minutes ?? 0} min', 'bez ekranu'),
        n(Icons.emoji_events_rounded, AkBrand.sunDeep, '${progress?.activities ?? 0}', 'zabaw'),
      ],
    );
  }
}

/// "Co rozwijamy": each goal of the child with how much it was practised, and the pack that
/// would add most for it when the family does not have it yet.
class _Growing extends ConsumerWidget {
  const _Growing({required this.child, required this.progress, required this.catalog});

  final ChildProfile child;
  final ChildProgress? progress;
  final Catalog catalog;

  static const _target = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scopes = ref.watch(activeScopesProvider);
    final goals = child.goals.isEmpty
        ? const [DevGoal.listening, DevGoal.imagination, DevGoal.language]
        : child.goals.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Co rozwijamy', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final goal in goals)
          () {
            final practised = goal.skills.fold(0, (s, skill) => s + (progress?.skillPractice[skill] ?? 0));
            // The pack the family lacks that trains this goal most.
            Pack? best;
            var bestCount = 0;
            for (final pack in catalog.packs) {
              if (ownsPack(scopes, pack.id)) continue;
              final count = catalog
                  .itemsInPack(pack.id)
                  .where((i) => i.skills.any(goal.skills.contains))
                  .length;
              if (count > bestCount) {
                best = pack;
                bestCount = count;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goalName(l10n, goal),
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('$practised / $_target', style: text.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (practised / _target).clamp(0, 1).toDouble(),
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(8),
                    color: AkBrand.teal,
                    backgroundColor: context.palette.surfaceMuted,
                  ),
                  if (best != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => openPack(context, best!.id),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: Text(
                        'Pakiet ${best.title}: +$bestCount ${bestCount == 1 ? 'zabawa' : 'zabaw'} na ten cel',
                      ),
                    ),
                ],
              ),
            );
          }(),
      ],
    );
  }
}

/// The stages still ahead, with what each brings and which plays wait in packs.
class _NextStages extends ConsumerWidget {
  const _NextStages({required this.plan, required this.position, required this.catalog});

  final List<PlanDay> plan;
  final PlanPosition position;
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final current = PlanLevel.of(position.currentDay);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dalej na ścieżce', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final level in PlanLevel.all)
          () {
            final days = plan.where((d) => d.level.number == level.number).toList();
            final items = {for (final d in days) ...d.itemIds}.map(catalog.item).nonNulls.toList();
            final locked = items.where((i) => !ref.watch(canPlayProvider(i))).toList();
            final packs = {for (final i in locked) ?i.packId};
            final isCurrent = level.number == current.number;
            final past = level.number < current.number;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCurrent ? referenceMint : context.palette.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: LightSurfaceIf(
                light: isCurrent,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: past
                          ? AkBrand.teal
                          : (isCurrent ? AkBrand.sun : context.palette.surfaceMuted),
                      child: past
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : Text(
                              '${level.number}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF211C35)),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${levelName(l10n, level.number)} · dni ${level.firstDay}–${level.lastDay}',
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(levelNews(l10n, level.number), style: text.bodySmall),
                          if (locked.isNotEmpty && !past)
                            Text(
                              '${locked.length} z ${items.length} zabaw czeka w pakietach',
                              style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ),
                    if (locked.isNotEmpty && !past && packs.isNotEmpty)
                      TextButton(
                        onPressed: () => openPack(context, packs.first),
                        child: const Text('Odblokuj'),
                      ),
                  ],
                ),
              ),
            );
          }(),
      ],
    );
  }
}

/// [LightSurface] only when [light] (a fixed light background).
class LightSurfaceIf extends StatelessWidget {
  const LightSurfaceIf({super.key, required this.light, required this.child});

  final bool light;
  final Widget child;

  @override
  Widget build(BuildContext context) => light ? LightSurface(child: child) : child;
}

class _ChildSwitcher extends ConsumerWidget {
  const _ChildSwitcher({required this.family});

  final FamilyState family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = family.active;
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
        children: [
          for (final (i, c) in family.children.indexed)
            Padding(
              padding: const EdgeInsets.only(right: AkSpace.s),
              child: ChoiceChip(
                avatar: CircleAvatar(
                  backgroundColor: childColor(i),
                  child: Text(
                    childLabel(l10n, c, i).characters.first,
                    style: const TextStyle(color: AkBrand.ink, fontWeight: FontWeight.w800),
                  ),
                ),
                label: Text('${childLabel(l10n, c, i)} · ${l10n.planAge(c.age)}'),
                selected: c.id == active?.id,
                showCheckmark: false,
                labelStyle: selectableChipLabel(context, selected: c.id == active?.id),
                onSelected: (_) => ref.read(familyProvider.notifier).setActive(c.id),
              ),
            ),
          ActionChip(
            avatar: const Icon(Icons.add_rounded),
            label: Text(l10n.planAddChild),
            onPressed: () => context.push('/plan/dziecko'),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AkSpace.m),
    decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        Icon(icon, color: AkBrand.orange),
        const SizedBox(width: AkSpace.m),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// The day's activities, the tip of the day and (on day 7, 14…) the chest.
class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.day});

  final PlanDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(catalogProvider).value;
    if (catalog == null) return const SizedBox.shrink();
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, AkSpace.m),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
            child: Text(
              l10n.planDayTitle(day.day),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          if (day.tip case final tip?)
            Padding(
              padding: const EdgeInsets.all(AkSpace.m),
              child: _Note(icon: Icons.lightbulb_rounded, text: tipText(l10n, tip)),
            ),
          for (final id in day.itemIds)
            if (catalog.item(id) case final item?) ItemTile(item: item, catalog: catalog),
          if (day.chest)
            Padding(
              padding: const EdgeInsets.all(AkSpace.m),
              child: _Note(icon: Icons.redeem_rounded, text: l10n.planChest),
            ),
        ],
      ),
    );
  }
}
