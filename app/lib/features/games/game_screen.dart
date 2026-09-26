import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../player/player_providers.dart';
import 'game_controller.dart';

/// Nothing to watch: the whole screen is one tap target when the game waits for a touch,
/// otherwise a big pause button. Leaving needs a long press (kids mode included).
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  static const _background = Color(0xFF0B1210);
  static const _foreground = Color(0xFFB9C4BF);

  Future<void> _exit(BuildContext context, WidgetRef ref) async {
    await ref.read(gameControllerProvider.notifier).stop();
    if (context.mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final game = ref.watch(gameControllerProvider);
    final playing = ref.watch(playbackStateProvider).value?.playing ?? false;
    final handler = ref.watch(audioHandlerProvider);
    final tapToAnswer = game.listeningFor != null;
    final text = Theme.of(context).textTheme;

    final (icon, label) = switch (game.phase) {
      GamePhase.playing => (Icons.graphic_eq_rounded, l10n.gameListen),
      GamePhase.waiting => (Icons.hourglass_bottom_rounded, l10n.gameYourTurn),
      GamePhase.listening => (Icons.touch_app_rounded, l10n.gameTapNow),
      GamePhase.finished => (Icons.celebration_rounded, l10n.gameFinished),
      GamePhase.failed => (Icons.error_outline_rounded, l10n.gameFailed),
      GamePhase.idle => (Icons.graphic_eq_rounded, ''),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AkSpace.l),
              Text(
                game.title ?? '',
                style: text.titleMedium?.copyWith(color: _foreground),
                textAlign: TextAlign.center,
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  liveRegion: true,
                  label: tapToAnswer ? l10n.gameTapNow : (playing ? l10n.pause : l10n.play),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: switch (game.phase) {
                      _ when tapToAnswer => ref.read(gameControllerProvider.notifier).tap,
                      GamePhase.finished || GamePhase.failed => () => _exit(context, ref),
                      _ => playing ? handler.pause : handler.play,
                    },
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 220,
                            height: 220,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1F332C)),
                            child: Icon(
                              game.active && !playing && !tapToAnswer ? Icons.play_arrow_rounded : icon,
                              size: 110,
                              color: _foreground,
                            ),
                          ),
                          const SizedBox(height: AkSpace.l),
                          Text(label, style: text.titleLarge?.copyWith(color: _foreground)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: l10n.noLookExit,
                onLongPress: () => _exit(context, ref),
                excludeSemantics: true,
                child: GestureDetector(
                  onLongPress: () => _exit(context, ref),
                  child: Container(
                    height: kKidsTouchTarget,
                    margin: const EdgeInsets.all(AkSpace.l),
                    padding: const EdgeInsets.symmetric(horizontal: AkSpace.l),
                    decoration: BoxDecoration(
                      border: Border.all(color: _foreground.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(AkRadius.button),
                    ),
                    alignment: Alignment.center,
                    child: Text(l10n.noLookExit, style: const TextStyle(color: _foreground)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
