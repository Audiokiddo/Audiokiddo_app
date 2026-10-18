import 'dart:async';
import 'dart:math';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../player/audio_handler.dart';
import '../player/player_providers.dart';
import '../../core/widgets/szop.dart';
import '../../core/widgets/doodles.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/home_screen.dart' show dinnerPicks;
import '../downloads/download_providers.dart';
import '../family/family.dart';
import '../family/plan_texts.dart';
import '../parent_voice/parent_voice.dart';
import '../lord/lord_lines.dart';
import '../lord/lord_widgets.dart';
import '../family/listeners.dart';
import 'plan.dart';
import 'plan_editor.dart';
import 'session.dart';
import '../day/day_routine.dart';
import '../day/play_moments.dart';

/// The age plans are made for: with siblings the youngest of those listening, so everyone in
/// the car or at the table can join in (Mój dzień, 2026-10-17; who listens: the Teraz card).
int _ageOf(WidgetRef ref) => ref.watch(listeningAgeProvider);

/// Back when there is somewhere to go back to; a close button to Start when the screen was
/// opened from the home-screen widget (a deep link replaces the stack).
class _CloseToStart extends StatelessWidget {
  const _CloseToStart();

  @override
  Widget build(BuildContext context) => context.canPop()
      ? const BackButton()
      : IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.close_rounded),
        );
}

/// "W drogę": pick how long the ride is, see what Kiddo lined up, download it, go.
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key, this.minutes});

  /// The ride length chosen before (e.g. in "Co teraz?"), else 30 minutes.
  final int? minutes;

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  late int _minutes = widget.minutes ?? 30;
  // Which of Szop'en's lines this ride gets; fixed while the screen is open.
  final int _variant = Random().nextInt(1 << 16);

  /// Three suggestions in one row, and "Własny" for the exact length of the ride.
  static const durations = [15, 30, 60];

  /// The plan the parent sees and may change; made again when the length changes.
  List<SessionStep>? _plan;
  int _planFor = -1;

  /// "2 h 30 min", "45 min".
  static String _rideLabel(int minutes) {
    final h = minutes ~/ 60, m = minutes % 60;
    if (h == 0) return '$m min';
    return m == 0 ? '$h h' : '$h h $m min';
  }

  /// The parent's own ride length: hours and minutes, up to 8 hours.
  Future<void> _pickOwnTime(BuildContext context) async {
    var hours = _minutes ~/ 60;
    var minutes = (_minutes % 60) ~/ 5 * 5;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          final text = Theme.of(sheet).textTheme;
          Widget stepper(String label, int value, int max, int step, void Function(int) set) => Column(
            children: [
              Text(label, style: text.labelLarge),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Mniej',
                    onPressed: value - step < 0 ? null : () => setSheet(() => set(value - step)),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 56,
                    child: Text('$value', textAlign: TextAlign.center, style: text.headlineMedium),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Więcej',
                    onPressed: value + step > max ? null : () => setSheet(() => set(value + step)),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ],
          );
          final total = hours * 60 + minutes;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Ile potrwa podróż?', style: text.titleLarge),
                  const SizedBox(height: AkSpace.m),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      stepper('godziny', hours, 8, 1, (v) => hours = v),
                      stepper('minuty', minutes, 55, 5, (v) => minutes = v),
                    ],
                  ),
                  const SizedBox(height: AkSpace.l),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: total < 10 ? null : () => Navigator.pop(sheet, total),
                      child: Text(total < 10 ? 'Co najmniej 10 min' : 'Gotowe: ${_rideLabel(total)}'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (picked != null && mounted) setState(() => _minutes = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final catalog = ref.watch(catalogProvider).value;
    final downloaded = {...?ref.watch(downloadSummaryProvider).value?.itemIds};
    final child = ref.watch(familyProvider).value?.active;
    if (catalog != null && (_plan == null || _planFor != _minutes)) {
      _planFor = _minutes;
      _plan = buildTrip(
        catalog,
        minutes: _minutes,
        age: _ageOf(ref),
        canPlay: (i) => ref.read(canPlayProvider(i)),
        downloaded: downloaded,
        variant: _variant,
        // To kindergarten in the morning, home in the afternoon (Mój dzień).
        startLine: momentStart(
          PlayMoment.auto,
          DayContext.of(ref.read(dayRoutineProvider).value, ref.read(clockProvider)()),
          _variant,
        ),
      );
    }
    final steps = _plan ?? const <SessionStep>[];
    final items = playsFrom(steps, 0);
    final missing = {
      for (final i in items)
        if (!downloaded.contains(i.id)) i.id: i,
    }.values.toList();
    // Too few plays for the whole ride: some come again (buildTrip), and the parent is told so.
    final repeats = items.length > {for (final i in items) i.id}.length;

    return Scaffold(
      appBar: AppBar(leading: const _CloseToStart()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.xl),
        children: [
          const Center(child: SzopSticker(SzopPose.klaszcze, height: 120)),
          const SizedBox(height: AkSpace.m),
          Text(l10n.tripTitle, style: text.displaySmall, textAlign: TextAlign.center),
          const SizedBox(height: AkSpace.s),
          Text(
            l10n.tripBody,
            style: text.bodyLarge?.copyWith(color: context.palette.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkSpace.l),
          Text(l10n.tripHowLong, style: text.titleMedium),
          const SizedBox(height: AkSpace.s),
          // Three suggestions and the parent's own time, in one row.
          Row(
            children: [
              for (final m in durations)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AkSpace.s),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Center(child: Text(l10n.tripMinutes(m))),
                      ),
                      selected: _minutes == m,
                      labelStyle: selectableChipLabel(context, selected: _minutes == m),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _minutes = m),
                    ),
                  ),
                ),
              // Any length of ride: "3 h 20 min to grandma's".
              Expanded(
                child: ChoiceChip(
                  avatar: const Icon(Icons.edit_rounded, size: 16),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(durations.contains(_minutes) ? 'Własny' : _rideLabel(_minutes)),
                  ),
                  selected: !durations.contains(_minutes),
                  labelStyle: selectableChipLabel(context, selected: !durations.contains(_minutes)),
                  showCheckmark: false,
                  onSelected: (_) => _pickOwnTime(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AkSpace.l),
          Container(
            padding: const EdgeInsets.all(AkSpace.m),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(AkRadius.card),
              boxShadow: akSoftShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlanEditor(
                  heading: 'Plan:',
                  plays: items,
                  minutesLeft: (planSecondsLeft(steps, index: 0, started: false) + 59) ~/ 60,
                  candidates: catalog == null
                      ? const []
                      : planCandidates(
                          catalog,
                          age: _ageOf(ref),
                          canPlay: (i) => ref.read(canPlayProvider(i)),
                          exclude: {for (final i in items) i.id},
                          downloaded: downloaded,
                        ),
                  onRemove: (pos) => setState(() => _plan = planRemove(steps, pos)),
                  onReorder: (o, n) => setState(() => _plan = planReorder(steps, o, n)),
                  onReplace: (id, item, {nth = 0}) => setState(() {
                    final current = _plan ?? const <SessionStep>[];
                    final pos = nthPlayPos(playsFrom(current, 0), id, nth);
                    _plan = planReplace(current, pos, item);
                  }),
                  onAdd: (add) => setState(() => _plan = planAdd(steps, add)),
                ),
                const SizedBox(height: AkSpace.s),
                if (repeats) ...[
                  Text(
                    'Na całą trasę zabaw jest za mało, więc kilka zagra jeszcze raz, '
                    'z przerwą na okno pomiędzy. Dzieci lubią powtórki.',
                    style: text.bodySmall?.copyWith(color: context.palette.inkMuted),
                  ),
                  const SizedBox(height: AkSpace.xs),
                ],
                Text(l10n.tripBreaks, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
              ],
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: AkSpace.m),
            // Before the road: what is not on the phone will not play without internet.
            Text(
              missing.length == 1
                  ? '1 zabawa nie jest jeszcze na telefonie. Bez internetu nie zagra.'
                  : playsLabel(missing.length).endsWith('zabawy')
                  ? '${playsLabel(missing.length)} nie są jeszcze na telefonie. Bez internetu nie zagrają.'
                  : '${playsLabel(missing.length)} nie jest jeszcze na telefonie. Bez internetu nie zagrają.',
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AkSpace.s),
            FilledButton.tonalIcon(
              onPressed: () async {
                final manager = ref.read(downloadManagerProvider);
                for (final i in missing) {
                  await manager.download(i);
                }
              },
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.tripDownload(missing.length)),
            ),
          ],
          const SizedBox(height: AkSpace.m),
          FilledButton.icon(
            onPressed: items.isEmpty
                ? null
                : () {
                    ref
                        .read(sessionProvider.notifier)
                        .start(SessionKind.trip, steps, childId: child?.id, label: PlayMoment.auto.label);
                    // Mój dzień learns the real hour of leaving from the car plans started.
                    unawaited(ref.read(tripLogProvider.notifier).record(ref.read(clockProvider)()));
                    context.pushReplacement('/sesja');
                  },
            icon: const Icon(Icons.directions_car_rounded),
            label: Text(l10n.tripGo),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AkSpace.s),
              child: Text(l10n.tripEmpty, textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}

/// "Dobranoc": the evening ritual behind one button, in night colours.
class BedtimeScreen extends ConsumerWidget {
  const BedtimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final catalog = ref.watch(catalogProvider).value;
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final clips = child == null ? null : ref.watch(parentClipsProvider(child.id)).value;
    final steps = catalog == null
        ? const <SessionStep>[]
        : buildBedtime(catalog, age: _ageOf(ref), canPlay: (i) => ref.watch(canPlayProvider(i)));
    String describe(SessionStep s) => switch (s) {
      LineStep() => l10n.bedtimeBreaths,
      ItemStep(:final item) =>
        item.kind == ContentKind.song ? l10n.bedtimeSong(item.title) : l10n.bedtimeQuiet(item.title),
      ParentStep() =>
        clips?[ParentClip.goodnight] != null ? l10n.bedtimeParentGoodnight : l10n.bedtimeKiddoGoodnight,
    };
    const fg = Color(0xFFFFF3E6);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1A3A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: fg,
          leading: const _CloseToStart(),
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B2E5A), Color(0xFF141226)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: FloatingDoodles(count: 10, color: Color(0xFFFFE9A8), opacity: 0.25, seed: 42),
              ),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(AkSpace.l),
                  children: [
                    const SizedBox(height: AkSpace.l),
                    const Center(child: SzopSticker(SzopPose.zmeczony, height: 130)),
                    const SizedBox(height: AkSpace.m),
                    Text(
                      l10n.bedtimeTitle,
                      style: text.displaySmall?.copyWith(color: fg),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AkSpace.s),
                    Text(
                      l10n.bedtimeBody,
                      style: text.bodyLarge?.copyWith(color: fg.withValues(alpha: 0.8)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AkSpace.l),
                    for (final (i, s) in steps.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0x33FFE9A8),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: fg, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: AkSpace.m),
                            Expanded(
                              child: Text(describe(s), style: text.bodyLarge?.copyWith(color: fg)),
                            ),
                          ],
                        ),
                      ),
                    if (child != null && clips?[ParentClip.goodnight] == null)
                      TextButton.icon(
                        onPressed: () => context.push('/plan/glos'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFE9A8)),
                        icon: const Icon(Icons.mic_rounded),
                        label: Text(l10n.bedtimeRecordHint),
                      ),
                    const SizedBox(height: AkSpace.l),
                    FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(sessionProvider.notifier)
                            .start(SessionKind.bedtime, steps, childId: child?.id);
                        context.pushReplacement('/sesja');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE9A8),
                        foregroundColor: AkBrand.cocoa,
                      ),
                      icon: const Icon(Icons.bedtime_rounded),
                      label: Text(l10n.bedtimeGo),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The running session (car trip or bedtime): a simple player with big buttons a parent can
/// hit without looking twice. Upright: Szop’en and the title on top, buttons below. Sideways
/// (phone in a car holder): the title on the left, the buttons on the right under the thumb.
/// The line at the end of a trip, from the real time it took.
String tripSummary(int minutes) => 'Trasa: $minutes min zabaw. Wpisuję do protokołu.';

/// "Poranek z Szop’enem · 2 z 4": the moment and the play it is on.
String _progress(SessionState session) {
  final plays = [for (final s in session.steps) if (s is ItemStep) s];
  final done = [for (final s in session.steps.take(session.index + 1)) if (s is ItemStep) s].length;
  return plays.isEmpty ? session.label! : '${session.label} · ${done.clamp(1, plays.length)} z ${plays.length}';
}

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);
    final night = session.kind == SessionKind.bedtime;
    final dinner = session.kind == SessionKind.dinner;
    const fg = Color(0xFFFFF3E6);
    String title(SessionStep? s) => switch (s) {
      ItemStep(:final item) => item.title,
      LineStep(:final line) when line.startsWith('window') => l10n.sessionWindow,
      LineStep(:final line) when line == 'bedtime_start' => l10n.bedtimeBreaths,
      LineStep(:final line) when line.startsWith('trip_end') => l10n.sessionArrived,
      LineStep() => 'Szop’en mówi',
      ParentStep() => l10n.sessionParent,
      null => '',
    };
    final waiting = !session.finished && session.countdown != null;
    final playing = ref.watch(playbackStateProvider).value?.playing ?? false;
    final pose = switch (session.current) {
      _ when session.finished => SzopPose.klaszcze,
      _ when night => SzopPose.zmeczony,
      _ when waiting => SzopPose.zadowolony,
      ItemStep() => SzopPose.nasluchuje,
      _ => SzopPose.prosi,
    };
    final notifier = ref.read(sessionProvider.notifier);
    // Read on tap: the handler starts with the app, not with this screen.
    AkAudioHandler handler() => ref.read(audioHandlerProvider);

    Future<void> close() async {
      await notifier.stop();
      if (context.mounted) context.canPop() ? context.pop() : context.go('/');
    }

    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final small = MediaQuery.sizeOf(context).shortestSide < 380;

    final info = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Poranek z Szop’enem · 2 z 4": which moment, and how far into it.
        if (session.label != null && !session.finished)
          Padding(
            padding: const EdgeInsets.only(bottom: AkSpace.s),
            child: Text(
              _progress(session),
              style: text.titleSmall?.copyWith(color: fg.withValues(alpha: 0.85), fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        SzopSticker(pose, height: landscape ? 110 : (small ? 120 : 170)),
        const SizedBox(height: AkSpace.m),
        Semantics(
          liveRegion: true,
          child: Text(
            session.error != null
                ? 'Odtwarzanie zatrzymane'
                : session.finished
                ? (night
                      ? l10n.sessionSleepWell
                      : (dinner
                            ? (session.label == null || session.label!.startsWith('Kolacja')
                                  ? 'Smacznego! To już wszystko.'
                                  : 'To już wszystko. Brawo!')
                            : l10n.sessionArrived))
                : title(session.current),
            style: text.headlineMedium?.copyWith(color: fg, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: AkSpace.s),
        if (session.error != null)
          Text(
            session.error!,
            style: text.bodyLarge?.copyWith(color: fg),
            textAlign: TextAlign.center,
          )
        else if (waiting)
          _Countdown(seconds: session.countdown!, held: session.held, color: fg)
        else if (!session.finished && session.next != null)
          Text(
            l10n.sessionNext(title(session.next)),
            style: text.titleMedium?.copyWith(color: fg.withValues(alpha: 0.75)),
            textAlign: TextAlign.center,
          ),
        // At the end of a trip: one dry line with real minutes (research 2026-10-12).
        if (session.finished && session.kind == SessionKind.trip && (session.minutesTaken ?? 0) >= 1)
          Text(
            tripSummary(session.minutesTaken!),
            style: text.titleMedium?.copyWith(color: fg.withValues(alpha: 0.85)),
            textAlign: TextAlign.center,
          ),
        // How long is left, and the plan behind it: change, swap, add time.
        if (session.running && (session.kind == SessionKind.trip || dinner))
          Padding(
            padding: const EdgeInsets.only(top: AkSpace.s),
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: fg),
              onPressed: () => showPlanSheet(context),
              icon: const Icon(Icons.queue_music_rounded),
              label: Text('Zostało ${minutesLabel(ref.watch(planMinutesLeftProvider) * 60)} · plan'),
            ),
          ),
      ],
    );

    // Big round buttons: from the start, play/pause (or hold the countdown), next.
    final controls = session.finished || session.error != null
        ? FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(220, 72), textStyle: text.titleLarge),
            onPressed: close,
            child: Text(l10n.sessionDone),
          )
        : Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 18,
            runSpacing: 18,
            children: [
              _BigButton(
                icon: Icons.replay_rounded,
                label: 'Od początku',
                size: 76,
                color: fg,
                onTap: session.current is ItemStep ? () => handler().seek(Duration.zero) : null,
              ),
              _BigButton(
                icon: waiting
                    ? (session.held ? Icons.play_arrow_rounded : Icons.pause_rounded)
                    : (playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: waiting
                    ? (session.held ? l10n.sessionResume : l10n.sessionHold)
                    : (playing ? 'Pauza' : 'Graj'),
                size: 112,
                color: AkBrand.sun,
                filled: true,
                onTap: () {
                  if (waiting) {
                    session.held ? notifier.resume() : notifier.hold();
                  } else {
                    playing ? handler().pause() : handler().play();
                  }
                },
              ),
              _BigButton(
                icon: Icons.skip_next_rounded,
                label: l10n.sessionSkip,
                size: 76,
                color: fg,
                onTap: notifier.skip,
              ),
            ],
          );

    final close_ = IconButton(
      tooltip: l10n.sessionStop,
      iconSize: 32,
      onPressed: close,
      icon: const Icon(Icons.close_rounded, color: fg),
    );
    final heading = Text(
      (night ? l10n.bedtimeTitle : (dinner ? 'Obiad bez wołania' : l10n.tripTitle)).toUpperCase(),
      style: text.labelLarge?.copyWith(color: fg.withValues(alpha: 0.7), letterSpacing: 1.6),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: night ? const Color(0xFF141226) : const Color(0xFF140E0B),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AkSpace.m),
            child: landscape
                ? Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            Align(alignment: Alignment.centerLeft, child: heading),
                            Expanded(
                              child: Center(child: SingleChildScrollView(child: info)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AkSpace.m),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Align(alignment: Alignment.centerRight, child: close_),
                            Expanded(child: Center(child: controls)),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(children: [heading, const Spacer(), close_]),
                      Expanded(
                        child: Center(child: SingleChildScrollView(child: info)),
                      ),
                      ParentAside(dark: true, pool: night ? LordPool.bedtime : LordPool.trip),
                      const SizedBox(height: AkSpace.m),
                      controls,
                      const SizedBox(height: AkSpace.m),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A round button big enough to hit in a moving car, with its word under it.
class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.size,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final double size;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : .35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: filled ? color : Colors.transparent,
              shape: CircleBorder(
                side: BorderSide(color: color, width: filled ? 0 : 3),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox.square(
                  dimension: size,
                  child: Icon(icon, size: size * .55, color: filled ? const Color(0xFF211C35) : color),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFFFFF3E6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The few seconds before the next recording starts by itself: a draining ring and the
/// seconds left, or a note that the parent held it.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.seconds, required this.held, required this.color});

  final int seconds;
  final bool held;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final total = autoNextDelay.inSeconds;
    return Column(
      children: [
        SizedBox.square(
          dimension: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: held ? 1 : (seconds - 1).clamp(0, total) / total),
                  duration: held ? Duration.zero : const Duration(seconds: 1),
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
              ),
              held
                  ? Icon(Icons.pause_rounded, color: color, size: 30)
                  : Text('$seconds', style: text.headlineSmall?.copyWith(color: color)),
            ],
          ),
        ),
        const SizedBox(height: AkSpace.s),
        Text(
          held ? l10n.sessionHeldInfo : l10n.sessionUpNext(seconds),
          style: text.bodyLarge?.copyWith(color: color.withValues(alpha: 0.75)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// "Twój głos": three short messages the parent records for the active child.
class ParentVoiceScreen extends ConsumerStatefulWidget {
  const ParentVoiceScreen({super.key});

  @override
  ConsumerState<ParentVoiceScreen> createState() => _ParentVoiceScreenState();
}

class _ParentVoiceScreenState extends ConsumerState<ParentVoiceScreen> {
  ParentClip? _recording;
  Timer? _limit;

  /// Short messages work best; the recording stops by itself after this.
  static const maxLength = Duration(seconds: 12);

  late final ParentVoiceStore _store;

  @override
  void initState() {
    super.initState();
    _store = ref.read(parentVoiceStoreProvider);
  }

  @override
  void dispose() {
    _limit?.cancel();
    if (_recording != null) unawaited(_store.stopRecording());
    unawaited(_store.stopPlayback());
    super.dispose();
  }

  Future<void> _stop(String childId) async {
    _limit?.cancel();
    await _store.stopRecording();
    if (!mounted) return;
    setState(() => _recording = null);
    ref.invalidate(parentClipsProvider(childId));
  }

  Future<void> _toggle(String childId, ParentClip clip) async {
    final store = ref.read(parentVoiceStoreProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (_recording == clip) return _stop(childId);
    if (_recording != null) return;
    if (!await store.requestMicrophone()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.voiceMicDenied)));
      return;
    }
    await store.startRecording(childId, clip);
    if (!mounted) return;
    setState(() => _recording = clip);
    _limit = Timer(maxLength, () => _stop(childId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    if (child == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.planEmptyTitle)),
      );
    }
    final name = childLabel(l10n, child, family!.children.indexOf(child));
    final clips = ref.watch(parentClipsProvider(child.id)).value ?? const {};
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.xl),
        children: [
          Text(l10n.voiceTitle, style: text.displaySmall),
          const SizedBox(height: AkSpace.s),
          Text(l10n.voiceBody(name), style: text.bodyLarge?.copyWith(color: context.palette.inkMuted)),
          const SizedBox(height: AkSpace.l),
          for (final clip in ParentClip.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AkSpace.m),
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
                    Text(switch (clip) {
                      ParentClip.hello => l10n.voiceHello,
                      ParentClip.praise => l10n.voicePraise,
                      ParentClip.goodnight => l10n.voiceGoodnight,
                    }, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Text(switch (clip) {
                      ParentClip.hello => l10n.voiceHelloHint(name),
                      ParentClip.praise => l10n.voicePraiseHint(name),
                      ParentClip.goodnight => l10n.voiceGoodnightHint(name),
                    }, style: text.bodyMedium?.copyWith(color: context.palette.inkMuted)),
                    const SizedBox(height: AkSpace.s),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _recording != null && _recording != clip
                              ? null
                              : () => _toggle(child.id, clip),
                          icon: Icon(_recording == clip ? Icons.stop_rounded : Icons.mic_rounded),
                          label: Text(
                            _recording == clip
                                ? l10n.voiceStop
                                : (clips[clip] == null ? l10n.voiceRecord : l10n.voiceRerecord),
                          ),
                        ),
                        const SizedBox(width: AkSpace.s),
                        if (clips[clip] case final path?) ...[
                          IconButton(
                            tooltip: l10n.voicePlay,
                            onPressed: () => ref.read(parentVoiceStoreProvider).play(path),
                            icon: const Icon(Icons.play_circle_rounded),
                          ),
                          IconButton(
                            tooltip: l10n.voiceDelete,
                            onPressed: () async {
                              await ref.read(parentVoiceStoreProvider).delete(child.id, clip);
                              ref.invalidate(parentClipsProvider(child.id));
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Text(l10n.voicePrivacy, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
        ],
      ),
    );
  }
}

/// The plan of the running ride or dinner in a sheet: what is ahead, how long is left, and the
/// means to swap, move, remove or add plays.
Future<void> showPlanSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: const Color(0xFF1E1A3A),
  builder: (_) => const _RunningPlan(),
);

class _RunningPlan extends ConsumerWidget {
  const _RunningPlan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final notifier = ref.read(sessionProvider.notifier);
    final catalog = ref.watch(catalogProvider).value;
    final minutes = ref.watch(planMinutesLeftProvider);
    final downloaded = {...?ref.watch(downloadSummaryProvider).value?.itemIds};
    final ahead = playsFrom(session.steps, notifier.editFrom);
    final inPlan = {for (final i in playsFrom(session.steps, 0)) i.id};
    const fg = Color(0xFFFFF3E6);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: PlanEditor(
            color: fg,
            plays: ahead,
            minutesLeft: minutes,
            candidates: catalog == null || !session.running
                ? const []
                : planCandidates(
                    catalog,
                    age: _ageOf(ref),
                    canPlay: (i) => ref.read(canPlayProvider(i)),
                    exclude: inPlan,
                    downloaded: downloaded,
                    dinner: session.kind == SessionKind.dinner,
                  ),
            onRemove: notifier.removePlay,
            onReorder: notifier.reorderPlays,
            onReplace: (id, item, {nth = 0}) {
              if (!notifier.replacePlay(id, item, nth: nth) && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Ta zabawa już się rozpoczęła albo została usunięta. Wybierz inną z planu.',
                    ),
                  ),
                );
              }
            },
            onAdd: notifier.addPlays,
          ),
        ),
      ),
    );
  }
}

/// "Obiad bez wołania": the plays one after another while someone cooks, shown as a plan first
/// (how long it takes, what comes in which order) that the parent can change before it starts.
class DinnerScreen extends ConsumerStatefulWidget {
  const DinnerScreen({super.key, this.variant, this.minutes});

  /// The moment of the day it is for (Mój dzień): rano, po, dom, chory, kolacja; null = obiad.
  final String? variant;

  /// The length to start with.
  final int? minutes;

  @override
  ConsumerState<DinnerScreen> createState() => _DinnerScreenState();
}

class _DinnerScreenState extends ConsumerState<DinnerScreen> {
  late final _moment = PlayMoment.of(widget.variant);
  late final _day = DayContext.of(ref.read(dayRoutineProvider).value, ref.read(clockProvider)());
  late int _minutes = _startMinutes();

  /// On a kindergarten morning the warm-up ends before it is time to leave: no longer than
  /// the minutes left until the leaving hour (minus five for shoes).
  int _startMinutes() {
    final wanted = widget.minutes ?? (widget.variant == 'rano' ? 15 : 25);
    final routine = ref.read(dayRoutineProvider).value;
    if (_moment != PlayMoment.rano || !_day.daycare || routine == null) return wanted;
    final now = ref.read(clockProvider)();
    final left = routine.leave - (now.hour * 60 + now.minute) - 5;
    if (left <= 0) return wanted;
    final options = durations.where((m) => m <= left).toList();
    return options.isEmpty ? durations.first : (options.contains(wanted) ? wanted : options.last);
  }
  List<SessionStep>? _plan;
  int _planFor = -1;

  List<int> get durations => switch (widget.variant) {
    'rano' => const [10, 15, 20, 30],
    'czekamy' => const [5, 10, 15],
    _ => const [15, 25, 40],
  };

  /// Title and line for the moment of the day.
  (String, String) get _words => switch (widget.variant) {
    'rano' => ('Poranek bez pośpiechu', 'Zabawy na rozruch, zanim trzeba wyjść. Ty wybierasz, ile mają trwać.'),
    'po' => ('Po przedszkolu', 'Kwadrans spokoju: dziecko odpowiada i wymyśla, a Ty odzyskujesz oddech.'),
    'dom' => ('Dzień w domu', 'Dłuższy blok zabaw na środek dnia, kiedy pomysły się kończą.'),
    'chory' => ('Zabawy w łóżku', 'Spokojne zabawy na leżąco. Dziecko słucha i odpowiada, Ty masz chwilę.'),
    'czekamy' => ('Czekamy', 'Poczekalnia, kolejka, restauracja: kilka minut zabaw w słuchawkach, bez biegania.'),
    'kolacja' => ('Kolacja bez wołania', 'Dziecko słucha, Wy gotujecie. Zabawy bez przygotowań, jedna po drugiej.'),
    _ => ('Obiad bez wołania', 'Dziecko słucha, Wy gotujecie. Zabawy bez przygotowań, jedna po drugiej. Plan możesz zmienić.'),
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final catalog = ref.watch(catalogProvider).value;
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final age = family == null || family.children.isEmpty ? 5 : _ageOf(ref);
    if (catalog != null && (_plan == null || _planFor != _minutes)) {
      _planFor = _minutes;
      _plan = buildMomentPlan(
        dinnerPicks(
          catalog,
          age: age,
          canPlay: (i) => ref.read(canPlayProvider(i)),
          heard: {
            if (child != null)
              for (final r in family!.resultsOf(child.id)) r.itemId,
          },
          now: ref.read(clockProvider)(),
          minutes: _minutes,
          moment: _moment.name,
        ),
        _moment,
        _day,
        variant: ref.read(clockProvider)().difference(DateTime(2026)).inDays,
      );
    }
    final steps = _plan ?? const <SessionStep>[];
    final items = playsFrom(steps, 0);

    return Scaffold(
      appBar: AppBar(leading: const _CloseToStart()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.xl),
        children: [
          // Each moment has its own colour and its own Szop’en, who hosts it.
          Container(
            padding: const EdgeInsets.symmetric(vertical: AkSpace.m),
            decoration: BoxDecoration(color: _moment.color, borderRadius: BorderRadius.circular(AkRadius.card)),
            child: Column(
              children: [
                SzopSticker(_moment.pose, height: 110),
                Text(
                  _moment.label,
                  style: text.labelLarge?.copyWith(color: const Color(0xFF211C35), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: AkSpace.m),
          Text(_words.$1, style: text.displaySmall, textAlign: TextAlign.center),
          const SizedBox(height: AkSpace.s),
          Text(
            _words.$2,
            style: text.bodyLarge?.copyWith(color: context.palette.inkMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkSpace.s),
          // Szop’en's aside for this moment (parents' research, his office voice).
          Text(
            '„${lordLine(switch (widget.variant) {
              'rano' => LordPool.momentMorning,
              'po' => LordPool.momentAfterDaycare,
              'dom' => LordPool.momentHomeDay,
              'chory' => LordPool.momentSick,
              'czekamy' => LordPool.momentWaiting,
              _ => LordPool.momentMeal,
            }, DateTime.now().difference(DateTime(DateTime.now().year)).inDays)}”',
            style: text.bodySmall?.copyWith(color: context.palette.inkMuted, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AkSpace.l),
          Text('Na ile?', style: text.titleMedium),
          const SizedBox(height: AkSpace.s),
          Row(
            children: [
              for (final m in durations)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AkSpace.s),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Center(child: Text('$m min')),
                      ),
                      selected: _minutes == m,
                      labelStyle: selectableChipLabel(context, selected: _minutes == m),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _minutes = m),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AkSpace.l),
          Container(
            padding: const EdgeInsets.all(AkSpace.m),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(AkRadius.card),
              boxShadow: akSoftShadow(context),
            ),
            child: PlanEditor(
              heading: 'Plan:',
              plays: items,
              minutesLeft: (planSecondsLeft(steps, index: 0, started: false) + 59) ~/ 60,
              candidates: catalog == null
                  ? const []
                  : planCandidates(
                      catalog,
                      age: age,
                      canPlay: (i) => ref.read(canPlayProvider(i)),
                      exclude: {for (final i in items) i.id},
                      dinner: true,
                      moment: _moment.name,
                    ),
              onRemove: (pos) => setState(() => _plan = planRemove(steps, pos)),
              onReorder: (o, n) => setState(() => _plan = planReorder(steps, o, n)),
              onReplace: (id, item, {nth = 0}) => setState(() {
                final current = _plan ?? const <SessionStep>[];
                final pos = nthPlayPos(playsFrom(current, 0), id, nth);
                _plan = planReplace(current, pos, item);
              }),
              onAdd: (add) => setState(() => _plan = planAdd(steps, add)),
            ),
          ),
          const SizedBox(height: AkSpace.m),
          FilledButton.icon(
            onPressed: items.isEmpty
                ? null
                : () {
                    ref
                        .read(sessionProvider.notifier)
                        .start(SessionKind.dinner, steps, childId: child?.id, label: _moment.label);
                    context.pushReplacement('/sesja');
                  },
            icon: const Icon(Icons.restaurant_rounded),
            label: const Text('Włącz'),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AkSpace.s),
              child: Text('Nie ma teraz zabaw bez przygotowań dla tego wieku.', textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
