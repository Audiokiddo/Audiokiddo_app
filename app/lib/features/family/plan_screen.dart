import 'dart:math' as math;

import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/kiddo.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/ambient_motion.dart';
import '../../core/audio/kiddo_voice.dart';
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

    _NodeState stateOf(PlanDay day) => day.day <= position.completedDays
        ? _NodeState.done
        : day.day == position.currentDay && !position.todayDone
        ? _NodeState.today
        : _NodeState.locked;

    final sections = <Widget>[];
    for (var start = 0; start < plan.length; start += 7) {
      final week = plan.sublist(start, math.min(start + 7, plan.length));
      if (week.first.day == week.first.level.firstDay) sections.add(_LevelHeader(level: week.first.level));
      sections.add(
        ScrollReveal(
          child: _WeekStaff(
            week: start ~/ 7 + 1,
            days: week,
            states: [for (final d in week) stateOf(d)],
            onOpen: (day, state) => _openDay(context, ref, day, state, position),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.only(bottom: AkSpace.xl + MediaQuery.paddingOf(context).bottom),
      children: [
        _ChildSwitcher(family: family),
        _Stats(progress: progress, position: position, days: plan.length),
        if (position.todayDone)
          Padding(
            padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.s),
            child: _Note(icon: Icons.celebration_rounded, text: l10n.planTodayDone),
          ),
        ...sections,
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

class _Stats extends StatelessWidget {
  const _Stats({required this.progress, required this.position, required this.days});

  final ChildProgress? progress;
  final PlanPosition position;
  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final accuracy = progress?.accuracy;
    Widget stat(IconData icon, Color color, String value, String label) => Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(
              label,
              style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, AkSpace.s),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AkSpace.m),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AkRadius.card),
          boxShadow: akSoftShadow(context),
        ),
        child: Row(
          children: [
            stat(
              Icons.music_note_rounded,
              AkBrand.terracotta,
              '${position.completedDays}/$days',
              l10n.planDays,
            ),
            stat(Icons.wb_sunny_rounded, AkBrand.orange, '${progress?.streak ?? 0}', l10n.planStreak),
            stat(
              Icons.star_rounded,
              AkBrand.sunDeep,
              accuracy == null ? '–' : '${(accuracy * 100).round()}%',
              l10n.planAccuracy,
            ),
          ],
        ),
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
    final text = Theme.of(context).textTheme;
    return ScrollReveal(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AkSpace.l, AkSpace.xl, AkSpace.l, AkSpace.m),
        child: Semantics(
          header: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planLevel(level.number, level.firstDay, level.lastDay).toUpperCase(),
                style: text.labelMedium?.copyWith(
                  color: context.palette.primary,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(levelName(l10n, level.number), style: text.headlineMedium),
              const SizedBox(height: 4),
              Text(
                levelNews(l10n, level.number),
                style: text.bodyLarge?.copyWith(color: context.palette.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NodeState { done, today, locked }

/// Each week is a short tune: seven notes, one per day. Finishing a day adds its note;
/// touching a finished note plays it, and the play button plays the tune collected so far.
/// The whole week together is "Melodia tygodnia", the child's own little song.
class _WeekStaff extends ConsumerStatefulWidget {
  const _WeekStaff({required this.week, required this.days, required this.states, required this.onOpen});

  final int week;
  final List<PlanDay> days;
  final List<_NodeState> states;
  final void Function(PlanDay day, _NodeState state) onOpen;

  /// Pitches (0 = C4 … 9 = E5) of each week's tune.
  static const motifs = [
    [0, 2, 4, 5, 4, 2, 0],
    [4, 5, 7, 5, 4, 2, 4],
    [2, 4, 5, 7, 8, 7, 5],
    [7, 5, 4, 2, 4, 5, 7],
    [0, 4, 7, 9, 7, 4, 0],
  ];

  @override
  ConsumerState<_WeekStaff> createState() => _WeekStaffState();
}

class _WeekStaffState extends ConsumerState<_WeekStaff> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  int? _playing;
  Timer? _timer;

  List<int> get _motif => _WeekStaff.motifs[(widget.week - 1) % _WeekStaff.motifs.length];

  @override
  void initState() {
    super.initState();
    if (ref.read(ambientMotionProvider)) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _playNote(int i) {
    ref.read(kiddoVoiceProvider).effect('note_${_motif[i]}');
    setState(() => _playing = i);
  }

  void _playTune() {
    final done = [
      for (var i = 0; i < widget.states.length; i++)
        if (widget.states[i] == _NodeState.done) i,
    ];
    if (done.isEmpty) return;
    _timer?.cancel();
    var step = 0;
    _playNote(done[step]);
    _timer = Timer.periodic(const Duration(milliseconds: 420), (t) {
      step++;
      if (!mounted || step >= done.length) {
        t.cancel();
        if (mounted) setState(() => _playing = null);
        return;
      }
      _playNote(done[step]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final done = widget.states.where((s) => s == _NodeState.done).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.m),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.s, AkSpace.m),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.planWeek(widget.week), style: text.titleLarge),
                      Text(
                        l10n.planWeekNotes(done, widget.days.length),
                        style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
                      ),
                    ],
                  ),
                ),
                if (widget.days.any((d) => d.chest))
                  Tooltip(
                    message: l10n.planChest,
                    child: Icon(
                      Icons.redeem_rounded,
                      color: done == widget.days.length ? AkBrand.terracotta : context.palette.inkMuted,
                    ),
                  ),
                IconButton(
                  tooltip: l10n.planPlayTune,
                  onPressed: done == 0 ? null : _playTune,
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 36),
                  color: context.palette.primary,
                ),
              ],
            ),
            SizedBox(
              height: 150,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StaffPainter(
                          motif: _motif,
                          states: widget.states,
                          playing: _playing,
                          pulse: _pulse.value,
                          ink: context.palette.ink,
                          faint: context.palette.inkMuted.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final (i, day) in widget.days.indexed)
                          Expanded(child: _noteCell(context, l10n, i, day, widget.states[i])),
                        for (var i = widget.days.length; i < 7; i++) const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteCell(BuildContext context, AppLocalizations l10n, int i, PlanDay day, _NodeState state) {
    final label = switch (state) {
      _NodeState.done => l10n.planNodeDone(day.day),
      _NodeState.today => l10n.planNodeToday(day.day),
      _NodeState.locked => l10n.planNodeLocked(day.day),
    };
    void open() {
      if (state == _NodeState.done) _playNote(i);
      widget.onOpen(day, state);
    }

    return Semantics(
      button: true,
      label: label,
      onTap: open,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: state == _NodeState.today
                  ? const FittedBox(child: Kiddo(size: 44, mood: KiddoMood.idle, wave: true))
                  : null,
            ),
            const Spacer(),
            Text(
              '${day.day}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: state == _NodeState.today ? context.palette.primary : context.palette.inkMuted,
                fontWeight: state == _NodeState.today ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffPainter extends CustomPainter {
  _StaffPainter({
    required this.motif,
    required this.states,
    required this.playing,
    required this.pulse,
    required this.ink,
    required this.faint,
  });

  final List<int> motif;
  final List<_NodeState> states;
  final int? playing;
  final double pulse;
  final Color ink;
  final Color faint;

  static const _noteColors = [
    AkBrand.terracotta,
    AkBrand.orange,
    AkBrand.sunDeep,
    AkBrand.tealDeep,
    AkBrand.lavenderDeep,
    AkBrand.terracotta,
    AkBrand.orange,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 11.0;
    const bottomLine = 112.0; // E4
    final line = Paint()
      ..color = faint
      ..strokeWidth = 1.2;
    for (var i = 0; i < 5; i++) {
      final y = bottomLine - i * gap;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final cell = size.width / 7;
    for (var i = 0; i < states.length; i++) {
      final pitch = motif[i];
      // C4 sits a step below the bottom line (E4), on its own ledger line.
      final y = bottomLine + gap - pitch * gap / 2;
      final x = cell * (i + 0.5);
      final state = states[i];
      if (pitch == 0) canvas.drawLine(Offset(x - 14, y), Offset(x + 14, y), line);
      final color = _noteColors[i % _noteColors.length];
      final lift = playing == i ? -6.0 : 0.0;
      final head = Rect.fromCenter(center: Offset(x, y + lift), width: 18, height: 13);
      canvas.save();
      canvas.translate(head.center.dx, head.center.dy);
      canvas.rotate(-0.35);
      canvas.translate(-head.center.dx, -head.center.dy);
      if (state == _NodeState.today) {
        canvas.drawOval(
          head.inflate(6 + pulse * 5),
          Paint()..color = AkBrand.sun.withValues(alpha: 0.45 * (1 - pulse * 0.6)),
        );
      }
      canvas.drawOval(
        head,
        state == _NodeState.locked
            ? (Paint()
                ..color = faint
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2)
            : (Paint()..color = state == _NodeState.today ? AkBrand.sun : color),
      );
      canvas.restore();
      // Stem up for low notes, down for high ones, like real notation.
      final up = pitch < 6;
      final stem = Paint()
        ..color = state == _NodeState.locked ? faint : (state == _NodeState.today ? AkBrand.sunDeep : color)
        ..strokeWidth = 2;
      final sx = up ? x + 8 : x - 8;
      canvas.drawLine(Offset(sx, y + lift - 1), Offset(sx, y + lift + (up ? -34 : 34)), stem);
    }
  }

  @override
  bool shouldRepaint(_StaffPainter old) =>
      old.pulse != pulse || old.playing != playing || old.states != states || old.ink != ink;
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
