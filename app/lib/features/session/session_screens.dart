import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/doodles.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../downloads/download_providers.dart';
import '../family/family.dart';
import '../family/plan_texts.dart';
import '../parent_voice/parent_voice.dart';
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

  static const durations = [15, 30, 45, 60, 90];

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
          const Center(child: Kiddo(size: 110, mood: KiddoMood.happy, wave: true)),
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
                child: FloatingDoodles(count: 22, color: Color(0xFFFFE9A8), opacity: 0.45, seed: 42),
              ),
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(AkSpace.l),
                  children: [
                    const SizedBox(height: AkSpace.l),
                    const Center(child: Kiddo(size: 130, mood: KiddoMood.sleepy)),
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

/// The running session: what plays, what comes next, skip and stop. Dark and calm; the
/// phone can lie face down.
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
      LineStep() => l10n.sessionKiddo,
      ParentStep() => l10n.sessionParent,
      null => '',
    };
    final mood = switch (session.current) {
      _ when session.finished => night ? KiddoMood.sleepy : KiddoMood.happy,
      ItemStep() => night ? KiddoMood.sleepy : KiddoMood.listening,
      _ => KiddoMood.talking,
    };

    Future<void> close() async {
      await ref.read(sessionProvider.notifier).stop();
      if (context.mounted) context.canPop() ? context.pop() : context.go('/');
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: night ? const Color(0xFF141226) : const Color(0xFF140E0B),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AkSpace.l),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: l10n.sessionStop,
                    onPressed: close,
                    icon: const Icon(Icons.close_rounded, color: fg),
                  ),
                ),
                Text(
                  (night ? l10n.bedtimeTitle : l10n.tripTitle).toUpperCase(),
                  style: text.labelLarge?.copyWith(color: fg.withValues(alpha: 0.7), letterSpacing: 1.6),
                ),
                const Spacer(),
                Kiddo(size: 180, mood: mood),
                const SizedBox(height: AkSpace.l),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    session.finished
                        ? (night ? l10n.sessionSleepWell : l10n.sessionArrived)
                        : title(session.current),
                    style: text.headlineMedium?.copyWith(color: fg),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AkSpace.s),
                if (!session.finished && session.next != null)
                  Text(
                    l10n.sessionNext(title(session.next)),
                    style: text.bodyLarge?.copyWith(color: fg.withValues(alpha: 0.7)),
                    textAlign: TextAlign.center,
                  ),
                if (!session.finished && session.kind == SessionKind.trip)
                  Padding(
                    padding: const EdgeInsets.only(top: AkSpace.s),
                    child: Text(
                      l10n.sessionLeft(session.secondsLeft ~/ 60),
                      style: text.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.6)),
                    ),
                  ),
                const Spacer(),
                if (!session.finished)
                  OutlinedButton.icon(
                    onPressed: () => ref.read(sessionProvider.notifier).skip(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fg,
                      side: const BorderSide(color: Color(0x66FFF3E6)),
                    ),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(l10n.sessionSkip),
                  )
                else
                  FilledButton(onPressed: close, child: Text(l10n.sessionDone)),
              ],
            ),
          ),
        ),
      ),
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
