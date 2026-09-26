import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'audio_handler.dart';
import 'playback_controller.dart';
import 'player_providers.dart';

const _speeds = [0.75, 1.0, 1.25];
const _sleepMinutes = [5, 10, 15, 30];

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final handler = ref.watch(audioHandlerProvider);
    final media = ref.watch(currentMediaProvider).value;
    final state = ref.watch(playbackStateProvider).value;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = media?.duration ?? Duration.zero;
    final playing = state?.playing ?? false;
    final timingSensitive = media?.extras?[timingSensitiveExtra] == true;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AkSpace.l),
          child: Column(
            children: [
              const SizedBox(height: AkSpace.l),
              Text(media?.album ?? '', style: text.labelLarge),
              Text(media?.title ?? '', style: text.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: AkSpace.xl),
              Slider(
                value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                semanticFormatterCallback: (_) => formatClock(position),
                onChanged: duration == Duration.zero
                    ? null
                    : (v) => handler.seek(Duration(milliseconds: v.round())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(formatClock(position)), Text(formatClock(duration))],
              ),
              const SizedBox(height: AkSpace.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 40,
                    tooltip: l10n.rewind,
                    onPressed: handler.rewind,
                    icon: const Icon(Icons.fast_rewind_rounded),
                  ),
                  SizedBox.square(
                    dimension: 96,
                    child: IconButton.filled(
                      iconSize: 56,
                      tooltip: playing ? l10n.pause : l10n.play,
                      onPressed: playing ? handler.pause : handler.play,
                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                  ),
                  IconButton(
                    iconSize: 40,
                    tooltip: l10n.forward,
                    onPressed: handler.fastForward,
                    icon: const Icon(Icons.fast_forward_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AkSpace.xl),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/odtwarzacz/bez-patrzenia'),
                icon: const Icon(Icons.visibility_off_rounded),
                label: Text(l10n.noLookMode),
              ),
              const SizedBox(height: AkSpace.l),
              const _SleepTimerRow(),
              const SizedBox(height: AkSpace.m),
              _SpeedRow(speed: state?.speed ?? 1, locked: timingSensitive, onChanged: handler.setSpeed),
              if (state?.processingState == AudioProcessingState.error) ...[
                const SizedBox(height: AkSpace.l),
                Text(l10n.playbackUnavailable, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow({required this.speed, required this.locked, required this.onChanged});

  final double speed;
  final bool locked;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(l10n.speed, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AkSpace.s),
        if (locked)
          Text(l10n.speedLocked)
        else
          SegmentedButton<double>(
            segments: [
              for (final s in _speeds)
                ButtonSegment(value: s, label: Text('${s.toString().replaceAll('.', ',')}×')),
            ],
            selected: {_speeds.reduce((a, b) => (a - speed).abs() < (b - speed).abs() ? a : b)},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onChanged(s.single),
          ),
      ],
    );
  }
}

class _SleepTimerRow extends ConsumerWidget {
  const _SleepTimerRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final timer = ref.watch(sleepTimerProvider).value;
    // Rebuilds with the position stream while a countdown runs.
    ref.watch(positionProvider);
    final status = switch (timer) {
      SleepAfter(:final endsAt) => l10n.sleepRemaining(formatClock(endsAt.difference(DateTime.now()))),
      SleepAtEndOfItem() => l10n.sleepAtEnd,
      null => null,
    };
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () => _pick(context, ref),
          icon: const Icon(Icons.bedtime_rounded),
          label: Text(l10n.sleepTimer),
        ),
        if (status != null) ...[const SizedBox(height: AkSpace.xs), Text(status)],
      ],
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final handler = ref.read(audioHandlerProvider);
    void choose(BuildContext sheet, void Function() action) {
      action();
      Navigator.pop(sheet);
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in _sleepMinutes)
              ListTile(
                title: Text(l10n.minutes(m)),
                onTap: () => choose(
                  sheet,
                  () => handler.setSleepTimer(SleepAfter(DateTime.now().add(Duration(minutes: m)))),
                ),
              ),
            ListTile(
              title: Text(l10n.sleepEndOfItem),
              onTap: () => choose(sheet, () => handler.setSleepTimer(const SleepAtEndOfItem())),
            ),
            ListTile(title: Text(l10n.sleepOff), onTap: () => choose(sheet, handler.cancelSleepTimer)),
          ],
        ),
      ),
    );
  }
}
