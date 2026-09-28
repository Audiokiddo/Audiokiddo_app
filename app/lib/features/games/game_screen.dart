import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/doodles.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import '../player/player_providers.dart';
import 'game_controller.dart';

/// Nothing to watch: the whole screen is one tap target when the game waits for a touch,
/// otherwise a big pause button. Leaving needs a long press (kids mode included).
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  static const _background = Color(0xFF140E0B);
  static const _foreground = Color(0xFFE9D9CB);

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
    final tapToAnswer = game.tapToAnswer;
    final text = Theme.of(context).textTheme;

    final label = switch (game.phase) {
      GamePhase.playing => l10n.gameListen,
      GamePhase.waiting => l10n.gameYourTurn,
      GamePhase.listening when game.listensToSound => l10n.gameAnswerNow,
      GamePhase.listening => l10n.gameTapNow,
      GamePhase.finished => l10n.gameFinished,
      GamePhase.failed => l10n.gameFailed,
      GamePhase.idle => '',
    };
    // A line for the parent: how the child answers right now.
    final hint = switch (game.phase) {
      GamePhase.waiting => l10n.gameHintWaiting,
      GamePhase.listening when game.listensToSound => l10n.gameHintListening,
      GamePhase.listening => l10n.gameHintTap,
      _ => null,
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
                  label: tapToAnswer ? label : (playing ? l10n.pause : l10n.play),
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
                          _GameKiddo(game: game, playing: playing),
                          const SizedBox(height: AkSpace.l),
                          Text(label, style: text.titleLarge?.copyWith(color: _foreground)),
                          if (hint != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(AkSpace.xl, AkSpace.s, AkSpace.xl, 0),
                              child: Text(
                                hint,
                                textAlign: TextAlign.center,
                                style: text.bodyLarge?.copyWith(color: _foreground.withValues(alpha: 0.7)),
                              ),
                            ),
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

/// Golden accompanies the narrator without pretending to speak their lines.
/// His head tilts while listening; his friendly expression celebrates participation.
class _GameKiddo extends StatefulWidget {
  const _GameKiddo({required this.game, required this.playing});

  final GameUiState game;
  final bool playing;

  @override
  State<_GameKiddo> createState() => _GameKiddoState();
}

class _GameKiddoState extends State<_GameKiddo> {
  bool _cheering = false;
  int _confetti = 0;
  Timer? _calmDown;

  @override
  void dispose() {
    _calmDown?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_GameKiddo old) {
    super.didUpdateWidget(old);
    if (widget.game.answers > old.game.answers) {
      setState(() {
        _cheering = true;
        _confetti++;
      });
      _calmDown?.cancel();
      _calmDown = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _cheering = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final mood = switch (game.phase) {
      _ when _cheering => KiddoMood.happy,
      GamePhase.finished => KiddoMood.happy,
      _ when game.active && !widget.playing && game.listening.isEmpty => KiddoMood.sleepy,
      GamePhase.playing => KiddoMood.listening,
      GamePhase.listening => KiddoMood.listening,
      _ => KiddoMood.idle,
    };
    return SizedBox(
      width: 260,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: game.phase == GamePhase.listening ? const Color(0xFF3A2A1F) : const Color(0xFF2A1E17),
            ),
          ),
          Kiddo(size: 170, mood: mood, outfit: GoldenOutfit.adventure),
          if (game.active && !widget.playing && game.listening.isEmpty)
            const Positioned(
              right: 30,
              bottom: 30,
              child: Icon(Icons.play_circle_fill_rounded, size: 56, color: AkBrand.sun),
            ),
          if (_confetti > 0) Positioned.fill(child: ConfettiBurst(key: ValueKey(_confetti), pieces: 40)),
        ],
      ),
    );
  }
}
