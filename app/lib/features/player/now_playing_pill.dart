import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../discovery/queue_controller.dart';
import '../kids_mode/kids_mode_controller.dart';
import '../pdf/case_file_tutorial.dart';
import '../purchases/after_free_play.dart';
import 'playback_controller.dart';
import 'player_providers.dart';

/// Pages with their own way back to the player: the tabs (Szop’en’s card above the bar), the
/// player and games themselves, the running session and kids mode.
bool showsNowPlayingPill(String path) =>
    !const {'/', '/biblioteka', '/sklep', '/moje'}.contains(path) &&
    !['/odtwarzacz', '/gra', '/dziecko', '/sesja', '/powitanie', '/logowanie'].any(path.startsWith);

/// Height the pill takes at the bottom of a page (pages get it as extra bottom padding).
const nowPlayingPillSpace = 76.0;

/// On every other page, a small Szop’en pill floats at the bottom while something is loaded
/// in the player: one tap back to the player, pause right there.
class NowPlayingPill extends ConsumerStatefulWidget {
  const NowPlayingPill({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<NowPlayingPill> createState() => _NowPlayingPillState();
}

class _NowPlayingPillState extends ConsumerState<NowPlayingPill> {
  String _path = '/';

  /// Free plays that already had their window this launch.
  final _offered = <String>{};

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRoute);
    _onRoute();
    // A free play heard to the end: its own window with the next free play or the offer.
    ref.listenManual(playbackStateProvider, (before, now) {
      final ended = now.value?.processingState == AudioProcessingState.completed;
      final wasEnded = before?.value?.processingState == AudioProcessingState.completed;
      if (ended && !wasEnded) _afterPlay();
    });
    // The first case with a case file: Szop’en's detective tutorial before it plays.
    ref.listenManual(currentMediaProvider, (before, now) {
      final id = now.value?.id;
      if (id == null || id == before?.value?.id) return;
      final item = ref.read(catalogProvider).value?.item(id);
      final context = widget.router.routerDelegate.navigatorKey.currentContext;
      if (item == null || context == null || ref.read(kidsModeProvider).active) return;
      maybeShowCaseFileTutorial(context, ref, item);
    });
  }

  void _afterPlay() {
    final id = ref.read(currentMediaProvider).value?.id;
    final item = id == null ? null : ref.read(catalogProvider).value?.item(id);
    if (item == null || !item.isFree || _offered.contains(item.id)) return;
    if (ref.read(kidsModeProvider).active || ref.read(queueRunnerProvider).running) return;
    // Let the family results catch up with this play first.
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      final context = widget.router.routerDelegate.navigatorKey.currentContext;
      if (!mounted || context == null || !context.mounted || !hasAfterFreePlay(ref, item)) return;
      _offered.add(item.id);
      showAfterFreePlay(context, item);
    });
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  // The router reports changes while the navigator builds; the pill follows a frame later.
  void _onRoute() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || widget.router.routerDelegate.currentConfiguration.isEmpty) return;
    // The top page, pushed ones included.
    final path = widget.router.state.uri.path;
    if (path != _path) setState(() => _path = path);
  });

  @override
  Widget build(BuildContext context) {
    final media = ref.watch(currentMediaProvider).value;
    final show = media != null && showsNowPlayingPill(_path);
    final mq = MediaQuery.of(context);
    // The same tree either way, so the navigator below never moves.
    return Stack(
      children: [
        MediaQuery(
          data: mq.copyWith(padding: mq.padding.copyWith(bottom: mq.padding.bottom + (show ? nowPlayingPillSpace : 0))),
          child: widget.child,
        ),
        if (show && mq.viewInsets.bottom == 0)
          Positioned(
            left: 16,
            right: 16,
            bottom: mq.padding.bottom + 10,
            // Swiped to the left, like the card above the bar: the play ends.
            child: Dismissible(
              key: ValueKey(media.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => ref.read(audioHandlerProvider).endSession(),
              child: _Pill(media: media, open: () => widget.router.push(_route(media))),
            ),
          ),
      ],
    );
  }

  static String _route(MediaItem media) => media.id.startsWith(gameMediaPrefix) ? '/gra' : '/odtwarzacz';
}

class _Pill extends ConsumerWidget {
  const _Pill({required this.media, required this.open});

  final MediaItem media;
  final VoidCallback open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final state = ref.watch(playbackStateProvider).value;
    final playing = state?.playing ?? false;
    final ended = state?.processingState == AudioProcessingState.completed;
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return SizedBox(
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: AkBrand.sun,
              elevation: 6,
              shadowColor: const Color(0x66000000),
              borderRadius: BorderRadius.circular(29),
              child: InkWell(
                borderRadius: BorderRadius.circular(29),
                onTap: open,
                child: Semantics(
                  button: true,
                  label: 'Otwórz odtwarzacz: ${media.title}',
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(70, 4, 64, 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playing
                              ? 'Teraz słuchacie'
                              : ended
                              ? 'Brawo! Przygoda skończona'
                              : 'Pauza',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          media.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Szop’en leans out of the left end of the pill.
          Positioned(
            left: 8,
            bottom: 2,
            child: IgnorePointer(child: SzopSticker(playing ? SzopPose.klaszcze : SzopPose.prosi, height: 66)),
          ),
          Positioned(
            right: 6,
            top: 5,
            bottom: 5,
            child: Semantics(
              button: true,
              label: playing ? 'Pauza' : 'Odtwórz',
              excludeSemantics: true,
              child: Material(
                color: AkBrand.tealDeep,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: playing ? handler.pause : handler.play,
                  child: SizedBox.square(
                    dimension: 48,
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
