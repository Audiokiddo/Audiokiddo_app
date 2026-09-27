import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/ambient_motion.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import 'reminders.dart';

/// The reminder texts, in turn, day by day.
ReminderTexts reminderTexts(AppLocalizations l10n) => [
  (l10n.reminder1Title, l10n.reminder1Body),
  (l10n.reminder2Title, l10n.reminder2Body),
  (l10n.reminder3Title, l10n.reminder3Body),
  (l10n.reminder4Title, l10n.reminder4Body),
  (l10n.reminder5Title, l10n.reminder5Body),
  (l10n.reminder6Title, l10n.reminder6Body),
  (l10n.reminder7Title, l10n.reminder7Body),
];

/// "Can I remind you?" with a live preview: a sample notification slides onto a phone,
/// one of the real texts. The system prompt comes only after "Włącz przypomnienia".
class ReminderOffer extends ConsumerStatefulWidget {
  const ReminderOffer({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<ReminderOffer> createState() => _ReminderOfferState();
}

class _ReminderOfferState extends ConsumerState<ReminderOffer> with SingleTickerProviderStateMixin {
  late final _slide = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  (int, int) _time = (18, 30);
  bool _busy = false;
  int _sample = 3;

  @override
  void initState() {
    super.initState();
    if (ref.read(ambientMotionProvider)) {
      _slide.addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _sample = (_sample + 1) % 7);
          _slide.forward(from: 0);
        }
      });
      _slide.forward();
    } else {
      _slide.value = 0.5;
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  Future<void> _enable() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final granted = await ref
        .read(remindersProvider.notifier)
        .enable(hour: _time.$1, minute: _time.$2, texts: reminderTexts(l10n));
    if (!mounted) return;
    setState(() => _busy = false);
    if (!granted) messenger.showSnackBar(SnackBar(content: Text(l10n.remindersDenied)));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final (title, body) = reminderTexts(l10n)[_sample];
    final times = [
      (l10n.remindersMorning, (8, 0)),
      (l10n.remindersAfternoon, (16, 0)),
      (l10n.remindersEvening, (18, 30)),
      (l10n.remindersBedtime, (19, 30)),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.l, AkSpace.m, AkSpace.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Kiddo(size: 80, mood: KiddoMood.talking),
                  const SizedBox(width: AkSpace.s),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.palette.surface,
                        border: Border.all(color: context.palette.inkMuted.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        l10n.remindersAsk,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Phone outline with the sample notification sliding in and out.
            Expanded(
              child: Center(
                child: Container(
                  width: 260,
                  height: 230,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    border: Border.all(color: context.palette.inkMuted.withValues(alpha: 0.35), width: 6),
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 26, 10, 0),
                  child: AnimatedBuilder(
                    animation: _slide,
                    builder: (context, child) {
                      final t = _slide.value;
                      final inOut = t < 0.15
                          ? Curves.easeOutBack.transform(t / 0.15)
                          : t > 0.85
                          ? 1 - Curves.easeIn.transform((t - 0.85) / 0.15)
                          : 1.0;
                      return Align(
                        alignment: Alignment.topCenter,
                        child: Opacity(
                          opacity: inOut.clamp(0, 1),
                          child: Transform.translate(offset: Offset(0, (inOut - 1) * 60), child: child),
                        ),
                      );
                    },
                    child: Semantics(
                      label: '$title. $body',
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.palette.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(blurRadius: 16, color: Color(0x22000000), offset: Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AkBrand.sun,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.headphones_rounded, size: 20, color: AkBrand.ink),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      Text(l10n.remindersPreviewTime, style: text.labelSmall),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    body,
                                    style: text.bodySmall,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.remindersWhen, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AkSpace.s),
                  Wrap(
                    spacing: AkSpace.s,
                    runSpacing: AkSpace.s,
                    children: [
                      for (final (label, time) in times)
                        ChoiceChip(
                          label: Text('$label ${time.$1}:${time.$2.toString().padLeft(2, '0')}'),
                          selected: _time == time,
                          onSelected: (_) => setState(() => _time = time),
                        ),
                    ],
                  ),
                  const SizedBox(height: AkSpace.s),
                  Text(l10n.remindersNote, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AkSpace.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _busy ? null : _enable,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: Text(l10n.remindersEnable),
                  ),
                  TextButton(onPressed: _busy ? null : widget.onDone, child: Text(l10n.remindersLater)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the next week of reminders fresh whenever the parent zone opens, and skips today's
/// once the active child's portion is done.
class RemindersKeeper extends ConsumerStatefulWidget {
  const RemindersKeeper({super.key, required this.child, this.todayDone});

  final Widget child;

  /// Whether today's plan portion is done (null while unknown).
  final bool? todayDone;

  @override
  ConsumerState<RemindersKeeper> createState() => _RemindersKeeperState();
}

class _RemindersKeeperState extends ConsumerState<RemindersKeeper> {
  bool? _scheduledFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refresh();
  }

  @override
  void didUpdateWidget(RemindersKeeper old) {
    super.didUpdateWidget(old);
    _refresh();
  }

  void _refresh() {
    final done = widget.todayDone ?? false;
    if (_scheduledFor == done) return;
    _scheduledFor = done;
    final texts = reminderTexts(AppLocalizations.of(context));
    ref.read(remindersProvider.notifier).reschedule(texts: texts, todayDone: done);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
