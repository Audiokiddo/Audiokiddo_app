import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/kiddo_voice.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/doodles.dart';
import '../../core/widgets/szop.dart';
import '../../l10n/app_localizations.dart';
import 'family.dart';

/// The short parent quiz (half a minute per child): the name (from the names Szop’en can say)
/// and the age. Goals and situations are no longer asked (2026-10-15): every goal counts. Kiddo asks in a speech bubble, a progress bar shows how little is left.
/// Several children: "Dodaj kolejne dziecko" on the summary starts the quiz again.
class ChildQuiz extends ConsumerStatefulWidget {
  const ChildQuiz({super.key, required this.onDone, this.editing, this.allowSkip = true});

  final VoidCallback onDone;

  /// The first sign-in needs at least the child's age, so it hides "Pomiń".
  final bool allowSkip;

  /// Change an existing profile instead of adding a child.
  final ChildProfile? editing;

  @override
  ConsumerState<ChildQuiz> createState() => _ChildQuizState();
}

enum _Step { hello, name, age, summary }

class _ChildQuizState extends ConsumerState<ChildQuiz> {
  late _Step _step = widget.editing == null ? _Step.hello : _Step.name;
  final _name = TextEditingController();
  int? _age;
  final _goals = <DevGoal>{};
  final _situations = <Situation>{};
  int? _minutes;

  /// The parent did not find the child's name among the recorded ones: typed freely, and
  /// Szop’en does not say it.
  bool _nameNotListed = false;
  ChildProfile? _saved;

  static const ages = [3, 4, 5, 6, 7, 8, 9];

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
    _ => true,
  };

  Future<void> _next() async {
    if (_step == _Step.age) {
      final e = widget.editing;
      final child = ChildProfile(
        id: e?.id ?? newChildId(),
        name: _name.text.trim(),
        age: _age!,
        startedOn: e?.startedOn ?? DateTime.now(),
        // Not asked any more: an edited child keeps theirs, a new one gets every goal.
        goals: _goals.isEmpty ? DevGoal.values.toSet() : {..._goals},
        situations: {..._situations},
        // No longer asked (2026-10-14): what the parent had, or ten minutes.
        dailyMinutes: _minutes ?? 10,
      );
      await ref.read(familyProvider.notifier).saveChild(child, makeActive: e == null);
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

  Future<void> _anotherChild() async {
    setState(() {
      _name.clear();
      _age = null;
      _goals.clear();
      _situations.clear();
      _minutes = null;
      _nameNotListed = false;
      _saved = null;
      _step = _Step.name;
    });
  }

  SzopPose get _pose => switch (_step) {
    _Step.hello => SzopPose.prosi,
    _Step.name => SzopPose.zadowolony,
    _Step.age => SzopPose.zdziwiony,
    _Step.summary => SzopPose.klaszcze,
  };

  Color get _stageColor => switch (_step) {
    _Step.hello || _Step.summary => AkBrand.sun,
    _Step.name => AkBrand.teal,
    _Step.age => AkBrand.orange,
  };

  String _who(AppLocalizations l10n) => _name.text.trim().isEmpty ? l10n.quizYourChild : _name.text.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = (_step.index) / (_Step.values.length - 1);
    final question = switch (_step) {
      _Step.hello => l10n.quizHello,
      _Step.name => l10n.quizName,
      _Step.age => l10n.quizAge(_who(l10n)),
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
                  if (widget.allowSkip && widget.editing == null && _step != _Step.summary)
                    TextButton(onPressed: widget.onDone, child: Text(l10n.introSkip)),
                ],
              ),
            ),
            // Szop’en on a coloured stage that changes with every question.
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.m, AkSpace.m, AkSpace.m),
              padding: const EdgeInsets.fromLTRB(AkSpace.s, AkSpace.m, AkSpace.m, AkSpace.m),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_stageColor.withValues(alpha: .28), _stageColor.withValues(alpha: .10)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    transitionBuilder: (child, a) => ScaleTransition(
                      scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
                      child: FadeTransition(opacity: a, child: child),
                    ),
                    child: SzopSticker(_pose, key: ValueKey(_pose), height: 96),
                  ),
                  const SizedBox(width: AkSpace.s),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      // Short questions stay next to Szop’en instead of floating to the middle.
                      layoutBuilder: (current, previous) =>
                          Stack(alignment: Alignment.bottomLeft, children: [...previous, ?current]),
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
                  // Answers slide in from the right, question by question.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(.15, 0), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    ),
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
                      _Step.age when widget.editing != null => l10n.quizSave,
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
      _Step.name => _NamePicker(
        controller: _name,
        notListed: _nameNotListed,
        onPick: (name) => setState(() {
          _name.text = name;
          _nameNotListed = false;
        }),
        onNotListed: () => setState(() {
          _name.clear();
          _nameNotListed = true;
        }),
        onSubmitted: _next,
      ),
      _Step.age => GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(AkSpace.m),
        mainAxisSpacing: AkSpace.s,
        crossAxisSpacing: AkSpace.s,
        children: [
          for (final (n, a) in ages.indexed)
            _Option(
              color: _optionColors[n % _optionColors.length],
              label: a == 9 ? '9+' : '$a',
              selected: _age == a,
              big: true,
              onTap: () => setState(() => _age = a),
            ),
        ],
      ),
      _Step.summary => ListView(
        padding: const EdgeInsets.all(AkSpace.m),
        children: [
          if (_saved case final child?)
            for (final line in [l10n.quizSummaryAge(child.age), l10n.quizSummaryLevels, l10n.quizSummaryChange])
              ListTile(
                leading: const Icon(Icons.check_circle_rounded, color: AkBrand.teal),
                title: Text(line),
              ),
        ],
      ),
    };
  }
}

const _optionColors = [AkBrand.teal, AkBrand.orange, AkBrand.lavenderDeep, AkBrand.sunDeep, AkBrand.terracotta];

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
      child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
    ),
  );
}

/// A big selectable answer, Duolingo-style: bordered card, tinted and ticked when chosen.
class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
    this.big = false,
    this.color = AkBrand.teal,
  });

  final Color color;

  final String label;
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
        child: AnimatedScale(
          scale: selected ? 1.03 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: Material(
            color: selected ? color.withValues(alpha: 0.18) : palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: selected ? color : palette.inkMuted.withValues(alpha: 0.25),
                width: selected ? 3 : 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: big
                  ? Center(
                      child: Text(
                        label,
                        style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: color),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AkSpace.m, vertical: 14),
                      child: Text(label, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Jak ma na imię Twoje dziecko?": the names Szop’en can say, filtered by the first letters.
/// A name not on the list goes in as typed, with a note that Szop’en will not say it.
class _NamePicker extends ConsumerStatefulWidget {
  const _NamePicker({
    required this.controller,
    required this.notListed,
    required this.onPick,
    required this.onNotListed,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool notListed;
  final ValueChanged<String> onPick;
  final VoidCallback onNotListed;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_NamePicker> createState() => _NamePickerState();
}

class _NamePickerState extends ConsumerState<_NamePicker> {
  late final _filter = TextEditingController(text: widget.notListed ? '' : widget.controller.text);

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    if (widget.notListed) {
      return ListView(
        padding: const EdgeInsets.all(AkSpace.m),
        children: [
          TextField(
            controller: widget.controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Imię albo przezwisko (opcjonalnie)'),
            onSubmitted: (_) => widget.onSubmitted(),
          ),
          const SizedBox(height: AkSpace.s),
          Text(
            'Tego imienia Szop’en nie ma nagranego, więc nie będzie zwracał się do dziecka po imieniu. '
            'Imię zobaczysz w aplikacji.',
            style: text.bodySmall,
          ),
          TextButton(onPressed: () => widget.onPick(''), child: const Text('Wróć do listy imion')),
        ],
      );
    }
    final recorded = ref.watch(recordedNamesProvider).value;
    final shown = recorded == null ? const <String>[] : searchNames(_filter.text, recorded);
    final picked = widget.controller.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.s, AkSpace.m, AkSpace.s),
          child: TextField(
            controller: _filter,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Wpisz imię, np. Zosia albo Zofia',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (picked.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
            child: Text(
              'Szop’en powie: „Hej, $picked!”',
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.s, AkSpace.m, AkSpace.m),
            children: [
              if (shown.isEmpty && _filter.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AkSpace.s),
                  child: Text(
                    'Nie mamy tego imienia na liście. Wybierz „Nie ma imienia na liście” poniżej.',
                    style: text.bodyMedium,
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in shown)
                    ChoiceChip(
                      label: Text(n),
                      selected: n == picked,
                      showCheckmark: false,
                      selectedColor: AkBrand.sun,
                      labelStyle: TextStyle(
                        color: n == picked ? const Color(0xFF211C35) : palette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => widget.onPick(n == picked ? '' : n),
                    ),
                ],
              ),
              const SizedBox(height: AkSpace.m),
              OutlinedButton.icon(
                onPressed: widget.onNotListed,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Nie ma imienia na liście'),
              ),
              const SizedBox(height: AkSpace.xs),
              Text(
                'Wtedy wpiszesz je sam, a Szop’en nie będzie mówił imienia. ${l10n.quizNamePrivacy}',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
