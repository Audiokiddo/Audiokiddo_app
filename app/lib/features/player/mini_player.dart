import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'player_providers.dart';

/// Bar above the navigation showing what is loaded in the player.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(currentMediaProvider).value;
    if (media == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final handler = ref.watch(audioHandlerProvider);
    final playing = ref.watch(playbackStateProvider).value?.playing ?? false;
    final palette = context.palette;

    return Material(
      color: palette.surfaceMuted,
      child: InkWell(
        onTap: () => context.push('/odtwarzacz'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.xs, AkSpace.xs, AkSpace.xs),
          child: Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: palette.primary),
              const SizedBox(width: AkSpace.s),
              Expanded(
                child: Semantics(
                  label: '${l10n.nowPlaying}: ${media.title}',
                  excludeSemantics: true,
                  child: Text(
                    media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              IconButton(
                iconSize: 32,
                tooltip: playing ? l10n.pause : l10n.play,
                onPressed: playing ? handler.pause : handler.play,
                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
