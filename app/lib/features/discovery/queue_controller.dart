import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog_providers.dart';
import '../player/playback_controller.dart';
import '../player/player_providers.dart';
import '../player/audio_handler.dart';
import '../session/session.dart';

class QueueRun {
  const QueueRun({this.running = false, this.index = 0, this.error});
  final bool running;
  final int index;
  final String? error;
}

class QueueRunner extends Notifier<QueueRun> {
  StreamSubscription<PlaybackState>? _subscription;
  List<ContentItem> _items = [];
  bool _ready = false, _advancing = false;
  bool stopAfterCurrent = false;
  int _generation = 0;
  @override
  QueueRun build() {
    ref.onDispose(() => _subscription?.cancel());
    return const QueueRun();
  }

  Future<void> start(List<ContentItem> items) async {
    if (items.isEmpty) return;
    if (ref.read(sessionProvider).running) {
      await ref.read(sessionProvider.notifier).stop();
    }
    await _subscription?.cancel();
    _generation++;
    _items = List.of(items);
    _ready = false;
    _advancing = false;
    final handler = ref.read(audioHandlerProvider);
    stopAfterCurrent = handler.sleepTimer is SleepAtEndOfItem;
    state = const QueueRun(running: true);
    _subscription = handler.playbackState.listen((event) {
      if (!state.running) return;
      if (handler.mediaItem.value?.id != _items[state.index].id) {
        if (_ready) {
          state = const QueueRun();
          _subscription?.cancel();
        }
        return;
      }
      if (event.processingState == AudioProcessingState.ready) _ready = true;
      if (event.processingState == AudioProcessingState.error) {
        state = QueueRun(index: state.index, error: 'Nagranie jest niedostępne. Spróbuj ponownie.');
        return;
      }
      if (_ready && event.processingState == AudioProcessingState.completed && !_advancing) {
        _advancing = true;
        _ready = false;
        if (stopAfterCurrent || state.index + 1 >= _items.length) {
          state = QueueRun(index: state.index);
          _subscription?.cancel();
          return;
        }
        state = QueueRun(running: true, index: state.index + 1);
        unawaited(_play(_generation));
      }
    });
    await _play(_generation);
  }

  Future<void> _play(int generation) async {
    final item = _items[state.index];
    if (!ref.read(canPlayProvider(item))) {
      state = QueueRun(index: state.index, error: 'Dostęp do tej zabawy wymaga odblokowania.');
      return;
    }
    try {
      await ref.read(playbackControllerProvider).start(item, album: 'Twoja kolejka', fromStart: true);
    } on Object {
      if (ref.mounted && generation == _generation) {
        state = QueueRun(
          index: state.index,
          error: 'Nie udało się odtworzyć. Sprawdź połączenie lub pobierz nagranie.',
        );
      }
    } finally {
      if (generation == _generation) _advancing = false;
    }
  }

  Future<void> stop() async {
    _generation++;
    await _subscription?.cancel();
    state = const QueueRun();
    await ref.read(audioHandlerProvider).stop();
  }
}

final queueRunnerProvider = NotifierProvider<QueueRunner, QueueRun>(QueueRunner.new);
