import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/doodles.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import 'family.dart';

/// The short parent quiz (about a minute per child): name, age, goals, when you listen,
/// minutes a day. Kiddo asks in a speech bubble, a progress bar shows how little is left.
/// Several children: "Dodaj kolejne dziecko" on the summary starts the quiz again.
class ChildQuiz extends ConsumerStatefulWidget {
  const ChildQuiz({super.key, required this.onDone, this.editing});

  final VoidCallback onDone;

  /// Change an existing profile instead of adding a child.
  final ChildProfile? editing;

  @override
  ConsumerState<ChildQuiz> createState() => _ChildQuizState();
}

enum _Step { hello, name, age, goals, situations, minutes, summary }

class _ChildQuizState extends ConsumerState<ChildQuiz> {
  late _Step _step = widget.editing == null ? _Step.hello : _Step.name;
  final _name = TextEditingController();
  int? _age;
  final _goals = <DevGoal>{};
  final _situations = <Situation>{};
  int? _minutes;
  ChildProfile? _saved;

  static const ages = [2, 3, 4, 5, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _name.text = e.name;
      _age = e.age;
      _goals.addAll(e.goals);
      _situations.addAll(e.situations);
      _minutes = e.dailyMinutes;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    _Step.age => _age != null,
    _Step.goals => _goals.isNotEmpty,
    _Step.minutes => _minutes != null,
    _ => true,
  };

  Future<void> _next() async {
    if (_step == _Step.minutes) {
      final e = widget.editing;
      final child = ChildProfile(
        id: e?.id ?? newChildId(),
        name: _name.text.trim(),
        age: _age!,
        startedOn: e?.startedOn ?? DateTime.now(),
        goals: {..._goals},
        situations: {..._situations},
        dailyMinutes: _minutes!,
      );
      await ref.read(familyProvider.notifier).saveChild(child);
      if (e != null) {
        widget.onDone();
        return;
      }
      setState(() {
        _saved = child;
        _step = _Step.summary;
      });
      return;
    }
    setState(() => _step = _Step.values[_step.index + 1]);
  }

  void _back() {
    if (_step.index == 0 || (widget.editing != null && _step == _Step.name)) return;
    setState(() => _step = _Step.values[_step.index - 1]);
  }

  void _anotherChild() => setState(() {
    _name.clear();
    _age = null;
    _goals.clear();
    _situations.clear();
    _minutes = null;
    _saved = null;
    _step = _Step.name;
  });

  String _who(AppLocalizations l10n) => _name.text.trim().isEmpty ? l10n.quizYourChild : _name.text.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = (_step.index) / (_Step.values.length - 1);
    final question = switch (_step) {
      _Step.hello => l10n.quizHello,
      _Step.name => l10n.quizName,
      _Step.age => l10n.quizAge(_who(l10n)),
      _Step.goals => l10n.quizGoals,
      _Step.situations => l10n.quizSituations,
      _Step.minutes => l10n.quizMinutes,
      _Step.summary => l10n.quizSummary(_who(l10n), _minutes ?? 10),
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AkSpace.s, AkSpace.s, AkSpace.m, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.quizBack,
                    onPressed: _step.index == 0 || _step == _Step.summary ? null : _back,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 12,
                          color: AkBrand.teal,
                          backgroundColor: context.palette.surfaceMuted,
                          semanticsLabel: l10n.quizProgress,
                        ),
                      ),
                    ),
                  ),
                  if (widget.editing == null && _step != _Step.summary)
                    TextButton(onPressed: widget.onDone, child: Text(l10n.introSkip)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.l, AkSpace.m, AkSpace.m),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Kiddo(size: 86, mood: _step == _Step.summary ? KiddoMood.happy : KiddoMood.idle),
                  const SizedBox(width: AkSpace.s),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _Bubble(key: ValueKey(question), text: question),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  if (_step == _Step.summary) const Positioned.fill(child: ConfettiBurst()),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(key: ValueKey(_step), child: _answers(context, l10n)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_step == _Step.summary) ...[
                    OutlinedButton.icon(
                      onPressed: _anotherChild,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(l10n.quizAnotherChild),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    ),
                    const SizedBox(height: AkSpace.s),
                  ],
                  FilledButton(
                    onPressed: !_canContinue
                        ? null
                        : _step == _Step.summary
                        ? widget.onDone
                        : _next,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: Text(switch (_step) {
                      _Step.hello => l10n.quizStart,
                      _Step.summary => l10n.quizFinish,
                      _Step.minutes when widget.editing != null => l10n.quizSave,
                      _ => l10n.quizContinue,
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answers(BuildContext context, AppLocalizations l10n) {
    Widget options<T>(
      List<T> values,
      bool Function(T) selected,
      void Function(T) toggle,
      String Function(T) label, {
      String? Function(T)? hint,
      IconData Function(T)? icon,
    }) => ListView(
      padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
      children: [
        for (final v in values)
          _Option(
            label: label(v),
            hint: hint?.call(v),
            icon: icon?.call(v),
            selected: selected(v),
            onTap: () => setState(() => toggle(v)),
          ),
      ],
    );

    return switch (_step) {
      _Step.hello => ListView(
        padding: const EdgeInsets.all(AkSpace.m),
        children: [
          for (final (icon, text) in [
            (Icons.timer_rounded, l10n.quizHelloPoint1),
            (Icons.lock_rounded, l10n.quizHelloPoint2),
            (Icons.people_alt_rounded, l10n.quizHelloPoint3),
          ])
            ListTile(
              leading: Icon(icon, color: AkBrand.teal),
              title: Text(text),
            ),
        ],
      ),
      _Step.name => Padding(
        padding: const EdgeInsets.all(AkSpace.m),
        child: Column(
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.nickname],
              decoration: InputDecoration(labelText: l10n.quizNameHint),
              onSubmitted: (_) => _next(),
            ),
            const SizedBox(height: AkSpace.s),
            Text(l10n.quizNamePrivacy, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      _Step.age => GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(AkSpace.m),
        mainAxisSpacing: AkSpace.s,
        crossAxisSpacing: AkSpace.s,
        children: [
          for (final a in ages)
            _Option(
              label: a == 8 ? '8+' : '$a',
              selected: _age == a,
              big: true,
              onTap: () => setState(() => _age = a),
            ),
        ],
      ),
      _Step.goals => options<DevGoal>(
        DevGoal.values,
        _goals.contains,
        (g) => _goals.contains(g) ? _goals.remove(g) : _goals.add(g),
        (g) => switch (g) {
          DevGoal.imagination => l10n.goalImagination,
          DevGoal.language => l10n.goalLanguage,
          DevGoal.logic => l10n.goalLogic,
          DevGoal.listening => l10n.goalListening,
          DevGoal.movement => l10n.goalMovement,
          DevGoal.calm => l10n.goalCalm,
        },
        icon: (g) => switch (g) {
          DevGoal.imagination => Icons.auto_awesome_rounded,
          DevGoal.language => Icons.record_voice_over_rounded,
          DevGoal.logic => Icons.extension_rounded,
          DevGoal.listening => Icons.hearing_rounded,
          DevGoal.movement => Icons.directions_run_rounded,
          DevGoal.calm => Icons.bedtime_rounded,
        },
      ),
      _Step.situations => options<Situation>(
        Situation.values,
        _situations.contains,
        (s) => _situations.contains(s) ? _situations.remove(s) : _situations.add(s),
        (s) => switch (s) {
          Situation.podroz => l10n.situationPodroz,
          Situation.przedSnem => l10n.situationPrzedSnem,
          Situation.wDomu => l10n.situationWDomu,
          Situation.czekanie => l10n.situationCzekanie,
        },
        icon: (s) => switch (s) {
          Situation.podroz => Icons.directions_car_rounded,
          Situation.przedSnem => Icons.nightlight_round,
          Situation.wDomu => Icons.house_rounded,
          Situation.czekanie => Icons.hourglass_bottom_rounded,
        },
      ),
      _Step.minutes => options<int>(
        const [5, 10, 15, 20],
        (m) => _minutes == m,
        (m) => _minutes = m,
        (m) => l10n.quizMinutesOption(m),
        hint: (m) => switch (m) {
          5 => l10n.quizMinutes5,
          10 => l10n.quizMinutes10,
          15 => l10n.quizMinutes15,
          _ => l10n.quizMinutes20,
        },
      ),
      _Step.summary => ListView(
        padding: const EdgeInsets.all(AkSpace.m),
        children: [
          if (_saved case final child?)
            for (final line in [
              l10n.quizSummaryAge(child.age),
              l10n.quizSummaryLevels,
              l10n.quizSummaryChange,
            ])
              ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: AkBrand.teal),
                title: Text(line),
              ),
        ],
      ),
    };
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AkSpace.m, vertical: 14),
    decoration: BoxDecoration(
      color: context.palette.surface,
      border: Border.all(color: context.palette.inkMuted.withValues(alpha: 0.3)),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomRight: Radius.circular(18),
        bottomLeft: Radius.circular(4),
      ),
    ),
    child: Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// A big selectable answer, Duolingo-style: bordered card, tinted and ticked when chosen.
class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint,
    this.icon,
    this.big = false,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final bool selected;
  final bool big;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: big ? 0 : AkSpace.s),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? AkBrand.teal.withValues(alpha: 0.16) : palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? AkBrand.teal : palette.inkMuted.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: big
                ? Center(
                    child: Text(label, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AkSpace.m, vertical: 14),
                    child: Row(
                      children: [
                        if (icon case final icon?) ...[
                          ExcludeSemantics(child: Icon(icon, color: AkBrand.tealDeep)),
                          const SizedBox(width: AkSpace.m),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              if (hint case final hint?)
                                Text(hint, style: text.bodySmall?.copyWith(color: palette.inkMuted)),
                            ],
                          ),
                        ),
                        if (selected)
                          const ExcludeSemantics(child: Icon(Icons.check_rounded, color: AkBrand.tealDeep)),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
