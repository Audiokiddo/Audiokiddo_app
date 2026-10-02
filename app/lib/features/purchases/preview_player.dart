import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../downloads/download_providers.dart';
import '../player/player_providers.dart';

/// Plays one short preview at a time, streamed (previews are free files on the server).
abstract interface class PreviewAudio {
  /// Starts [url]; [onProgress] gets 0..1, [onDone] runs when the preview ends by itself.
  Future<void> play(Uri url, {required void Function(double) onProgress, required void Function() onDone});
  Future<void> stop();
}

class JustAudioPreview implements PreviewAudio {
  AudioPlayer? _player;
  final _subscriptions = <StreamSubscription<void>>[];

  @override
  Future<void> play(
    Uri url, {
    required void Function(double) onProgress,
    required void Function() onDone,
  }) async {
    await stop();
    final player = _player ??= AudioPlayer();
    final duration = await player.setUrl(url.toString());
    _subscriptions
      ..add(
        player.positionStream.listen((p) {
          final total = duration?.inMilliseconds ?? 0;
          if (total > 0) onProgress((p.inMilliseconds / total).clamp(0, 1));
        }),
      )
      ..add(
        player.playerStateStream.listen((s) {
          if (s.processingState == ProcessingState.completed) onDone();
        }),
      );
    // play() completes only when playback stops; the preview runs on its own.
    unawaited(player.play());
  }

  @override
  Future<void> stop() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    await _player?.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _player?.dispose();
  }
}

final previewAudioProvider = Provider<PreviewAudio>((ref) {
  final audio = JustAudioPreview();
  ref.onDispose(audio.dispose);
  return audio;
});

class PreviewState {
  const PreviewState({this.itemId, this.loading = false, this.progress = 0, this.failedItemId});

  /// The item whose preview is playing (or loading).
  final String? itemId;
  final bool loading;
  final double progress;

  /// The last preview that could not be fetched (offline, server).
  final String? failedItemId;
}

class PreviewController extends Notifier<PreviewState> {
  @override
  PreviewState build() => const PreviewState();

  /// Starts [item]'s preview, or stops it when it is the one playing.
  Future<void> toggle(ContentItem item) async {
    if (state.itemId == item.id) return stop();
    final asset = item.preview;
    if (asset == null) return;
    state = PreviewState(itemId: item.id, loading: true);
    // Never two sounds at once: whatever the family listens to pauses for the preview.
    if (ref.read(currentMediaProvider).value != null) await ref.read(audioHandlerProvider).pause();
    try {
      final url = await ref.read(contentUrlResolverProvider).urlFor(asset);
      if (!ref.mounted || state.itemId != item.id) return;
      await ref
          .read(previewAudioProvider)
          .play(
            url,
            onProgress: (p) {
              if (ref.mounted && state.itemId == item.id) state = PreviewState(itemId: item.id, progress: p);
            },
            onDone: () {
              if (ref.mounted && state.itemId == item.id) state = const PreviewState();
            },
          );
      if (ref.mounted && state.itemId == item.id && state.loading) state = PreviewState(itemId: item.id);
    } on Exception {
      if (ref.mounted) state = PreviewState(failedItemId: item.id);
    }
  }

  Future<void> stop() async {
    state = const PreviewState();
    await ref.read(previewAudioProvider).stop();
  }
}

final previewControllerProvider = NotifierProvider<PreviewController, PreviewState>(PreviewController.new);

/// "Posłuchaj fragmentu" for a paid item: a round button in lists, a wide one on details.
/// Leaving the screen stops the preview.
class PreviewButton extends ConsumerStatefulWidget {
  const PreviewButton({super.key, required this.item, this.wide = false});

  final ContentItem item;
  final bool wide;

  @override
  ConsumerState<PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends ConsumerState<PreviewButton> {
  late final PreviewController _controller;
  var _mine = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(previewControllerProvider.notifier);
  }

  @override
  void dispose() {
    if (_mine) unawaited(_controller.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(previewControllerProvider);
    final mine = _mine = s.itemId == widget.item.id;
    final failed = s.failedItemId == widget.item.id;
    final seconds = widget.item.kind == ContentKind.song ? 30 : 45;
    final label = mine ? 'Zatrzymaj fragment' : 'Posłuchaj fragmentu ($seconds s)';
    void tap() => unawaited(_controller.toggle(widget.item));

    if (!widget.wide) {
      return Semantics(
        button: true,
        label: mine ? 'Zatrzymaj fragment ${widget.item.title}' : 'Posłuchaj fragmentu ${widget.item.title}',
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (mine)
                SizedBox.square(
                  dimension: 40,
                  child: CircularProgressIndicator(value: s.loading ? null : s.progress, strokeWidth: 3),
                ),
              IconButton(
                onPressed: tap,
                icon: Icon(mine ? Icons.stop_rounded : Icons.headphones_rounded, size: 22),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: tap,
          icon: Icon(mine ? Icons.stop_rounded : Icons.headphones_rounded),
          label: Text(label),
        ),
        if (mine)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(value: s.loading ? null : s.progress, minHeight: 4),
          ),
        if (failed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Nie udało się pobrać fragmentu. Sprawdź internet i spróbuj jeszcze raz.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
