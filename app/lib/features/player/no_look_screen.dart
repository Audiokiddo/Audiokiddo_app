import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'player_providers.dart';

/// "Tryb bez patrzenia": nothing to watch, one huge pause/play button.
///
/// The screen does not keep the phone awake — it may lock as usual and audio carries on.
/// Leaving needs a long press so a child does not exit by accident.
class NoLookScreen extends ConsumerWidget {
  const NoLookScreen({super.key});

  static const _background = Color(0xFF0B1210);
  static const _foreground = Color(0xFFB9C4BF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final handler = ref.watch(audioHandlerProvider);
    final playing = ref.watch(playbackStateProvider).value?.playing ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AkSpace.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AkSpace.l),
                child: Text(
                  l10n.noLookHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _foreground),
                ),
              ),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: playing ? l10n.pause : l10n.play,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: playing ? handler.pause : handler.play,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1F332C)),
                        child: Icon(
                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 120,
                          color: _foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: l10n.noLookExit,
                onLongPress: () => context.pop(),
                excludeSemantics: true,
                child: GestureDetector(
                  onLongPress: () => context.pop(),
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
