import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'player_providers.dart';

/// Basic full-screen player. Etap 2 adds sleep timer, speed and the "no-look" mode.
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AkSpace.l),
          child: Column(
            children: [
              MaterialBanner(
                content: Text(l10n.devToneBanner),
                backgroundColor: context.palette.surfaceMuted,
                actions: const [SizedBox.shrink()],
              ),
              const Spacer(),
              Text(media?.album ?? '', style: text.labelLarge),
              Text(media?.title ?? '', style: text.headlineMedium, textAlign: TextAlign.center),
              const Spacer(),
              Slider(
                value: position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble(),
                max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                onChanged: duration == Duration.zero
                    ? null
                    : (v) => handler.seek(Duration(milliseconds: v.round())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(_format(position)), Text(_format(duration))],
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
              const Spacer(),
              if (state?.processingState == AudioProcessingState.error)
                Text(state?.errorMessage ?? '', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ),
    );
  }

  static String _format(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
