import 'dart:async';

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
import '../downloads/download_providers.dart';
import '../family/family.dart';
import '../family/plan_texts.dart';
import '../parent_voice/parent_voice.dart';
import '../lord/lord_lines.dart';
import '../lord/lord_widgets.dart';
import 'session.dart';

int _ageOf(WidgetRef ref) => ref.watch(familyProvider).value?.active?.age ?? 6;

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
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  int _minutes = 30;

  static const durations = [15, 20, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final catalog = ref.watch(catalogProvider).value;
    final downloaded = {...?ref.watch(downloadSummaryProvider).value?.itemIds};
    final child = ref.watch(familyProvider).value?.active;
    final steps = catalog == null
        ? const <SessionStep>[]
        : buildTrip(
            catalog,
            minutes: _minutes,
            age: _ageOf(ref),
            canPlay: (i) => ref.watch(canPlayProvider(i)),
            downloaded: downloaded,
          );
    final items = [
      for (final s in steps)
        if (s is ItemStep) s.item,
    ];
    final missing = [
      for (final i in items)
        if (!downloaded.contains(i.id)) i,
    ];
    final minutes = items.fold(0, (a, i) => a + i.durationSec) ~/ 60;

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
          Wrap(
            spacing: AkSpace.s,
            runSpacing: AkSpace.s,
            children: [
              for (final m in durations)
                ChoiceChip(
                  label: Text(l10n.tripMinutes(m)),
                  selected: _minutes == m,
                  labelStyle: selectableChipLabel(context, selected: _minutes == m),
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _minutes = m),
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
                Text(l10n.tripPlanned(items.length, minutes), style: text.titleMedium),
                const SizedBox(height: AkSpace.xs),
                Text(l10n.tripBreaks, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
                const SizedBox(height: AkSpace.s),
                for (final i in items.take(6))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(
                          i.kind == ContentKind.song ? Icons.music_note_rounded : Icons.headphones_rounded,
                          size: 18,
                          color: context.palette.primary,
                        ),
                        const SizedBox(width: AkSpace.s),
                        Expanded(child: Text(i.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (downloaded.contains(i.id))
                          Icon(Icons.offline_pin_rounded, size: 18, color: context.palette.inkMuted),
                      ],
                    ),
                  ),
                if (items.length > 6) Text(l10n.tripMore(items.length - 6), style: text.bodySmall),
              ],
            ),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: AkSpace.m),
            OutlinedButton.icon(
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
                    ref.read(sessionProvider.notifier).start(SessionKind.trip, steps, childId: child?.id);
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
      ParentStep() => clips?[ParentClip.goodnight] != null ? l10n.bedtimeParentGoodnight : l10n.bedtimeKiddoGoodnight,
    };
    const fg = Color(0xFFFFF3E6);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1A3A),
        appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: fg, leading: const _CloseToStart()),
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
                        ref.read(sessionProvider.notifier).start(SessionKind.bedtime, steps, childId: child?.id);
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
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);
    final night = session.kind == SessionKind.bedtime;
    const fg = Color(0xFFFFF3E6);
    String title(SessionStep? s) => switch (s) {
      ItemStep(:final item) => item.title,
      LineStep(:final line) when line.startsWith('window') => l10n.sessionWindow,
      LineStep(:final line) when line == 'bedtime_start' => l10n.bedtimeBreaths,
      LineStep(:final line) when line == 'trip_end' => l10n.sessionArrived,
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
        SzopSticker(pose, height: landscape ? 110 : (small ? 120 : 170)),
        const SizedBox(height: AkSpace.m),
        Semantics(
          liveRegion: true,
          child: Text(
            session.finished ? (night ? l10n.sessionSleepWell : l10n.sessionArrived) : title(session.current),
            style: text.headlineMedium?.copyWith(color: fg, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: AkSpace.s),
        if (waiting)
          _Countdown(seconds: session.countdown!, held: session.held, color: fg)
        else if (!session.finished && session.next != null)
          Text(
            l10n.sessionNext(title(session.next)),
            style: text.titleMedium?.copyWith(color: fg.withValues(alpha: 0.75)),
            textAlign: TextAlign.center,
          ),
        if (!session.finished && session.kind == SessionKind.trip)
          Padding(
            padding: const EdgeInsets.only(top: AkSpace.s),
            child: Text(
              l10n.sessionLeft(session.secondsLeft ~/ 60),
              style: text.titleSmall?.copyWith(color: fg.withValues(alpha: 0.6)),
            ),
          ),
      ],
    );

    // Big round buttons: from the start, play/pause (or hold the countdown), next.
    final controls = session.finished
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
                label: waiting ? (session.held ? l10n.sessionResume : l10n.sessionHold) : (playing ? 'Pauza' : 'Graj'),
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
      (night ? l10n.bedtimeTitle : l10n.tripTitle).toUpperCase(),
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
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFFFFF3E6))),
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
                          onPressed: _recording != null && _recording != clip ? null : () => _toggle(child.id, clip),
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
