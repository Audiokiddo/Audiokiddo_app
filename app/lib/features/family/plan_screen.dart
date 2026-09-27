import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/item_views.dart';
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

class _Path extends ConsumerWidget {
  const _Path({required this.child, required this.family});

  final ChildProfile child;
  final FamilyState family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plan = ref.watch(planProvider(child.id));
    final position = ref.watch(planPositionProvider(child.id));
    final progress = ref.watch(progressProvider(child.id));
    if (plan.isEmpty || position == null) return const Center(child: CircularProgressIndicator());

    final rows = <Widget>[];
    for (final day in plan) {
      if (day.day == day.level.firstDay) rows.add(_LevelHeader(level: day.level));
      final state = day.day <= position.completedDays
          ? _NodeState.done
          : day.day == position.currentDay && !position.todayDone
          ? _NodeState.today
          : _NodeState.locked;
      rows.add(
        _Node(
          day: day,
          state: state,
          // A gentle zig-zag, like a path on a map.
          offset: math.sin(day.day * 0.9) * 90,
          onTap: () => _openDay(context, ref, day, state, position),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AkSpace.xl),
      children: [
        _ChildSwitcher(family: family),
        _Stats(progress: progress, position: position, days: plan.length),
        if (position.todayDone)
          Padding(
            padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.s),
            child: _Note(icon: Icons.celebration_rounded, text: l10n.planTodayDone),
          ),
        ...rows,
      ],
    );
  }

  void _openDay(BuildContext context, WidgetRef ref, PlanDay day, _NodeState state, PlanPosition position) {
    final l10n = AppLocalizations.of(context);
    if (state == _NodeState.locked) {
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
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => _DaySheet(day: day),
    );
  }
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

class _Stats extends StatelessWidget {
  const _Stats({required this.progress, required this.position, required this.days});

  final ChildProgress? progress;
  final PlanPosition position;
  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accuracy = progress?.accuracy;
    Widget stat(IconData icon, Color color, String value, String label) => Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(AkSpace.m),
      child: Row(
        children: [
          stat(
            Icons.local_fire_department_rounded,
            AkBrand.orange,
            '${progress?.streak ?? 0}',
            l10n.planStreak,
          ),
          stat(Icons.flag_rounded, AkBrand.teal, '${position.completedDays}/$days', l10n.planDays),
          stat(
            Icons.star_rounded,
            AkBrand.sunDeep,
            accuracy == null ? '–' : '${(accuracy * 100).round()}%',
            l10n.planAccuracy,
          ),
        ],
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader({required this.level});

  final PlanLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = [AkBrand.teal, AkBrand.lavender, AkBrand.orange, AkBrand.sun];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.l, AkSpace.m, AkSpace.m),
      child: Container(
        padding: const EdgeInsets.all(AkSpace.m),
        decoration: BoxDecoration(
          color: colors[(level.number - 1) % colors.length],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Semantics(
          header: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planLevel(level.number, level.firstDay, level.lastDay).toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: AkBrand.ink, letterSpacing: 1),
              ),
              Text(
                levelName(l10n, level.number),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: AkBrand.ink, fontWeight: FontWeight.w800),
              ),
              Text(levelNews(l10n, level.number), style: const TextStyle(color: AkBrand.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NodeState { done, today, locked }

class _Node extends StatelessWidget {
  const _Node({required this.day, required this.state, required this.offset, required this.onTap});

  final PlanDay day;
  final _NodeState state;
  final double offset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, icon) = switch (state) {
      _NodeState.done => (AkBrand.teal, day.chest ? Icons.redeem_rounded : Icons.check_rounded),
      _NodeState.today => (AkBrand.sun, day.chest ? Icons.redeem_rounded : Icons.play_arrow_rounded),
      _NodeState.locked => (
        context.palette.surfaceMuted,
        day.chest ? Icons.inventory_2_rounded : Icons.lock_rounded,
      ),
    };
    final label = switch (state) {
      _NodeState.done => l10n.planNodeDone(day.day),
      _NodeState.today => l10n.planNodeToday(day.day),
      _NodeState.locked => l10n.planNodeLocked(day.day),
    };
    return SizedBox(
      height: state == _NodeState.today ? 170 : 96,
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (state == _NodeState.today) const Kiddo(size: 70, mood: KiddoMood.idle, wave: true),
            Semantics(
              button: true,
              label: label,
              onTap: onTap,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 74,
                  height: 68,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    // A thick lower edge makes the step look pressable (Duolingo's trick).
                    boxShadow: [
                      BoxShadow(color: Color.lerp(color, Colors.black, 0.25)!, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 34,
                    color: state == _NodeState.locked ? context.palette.inkMuted : AkBrand.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
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
