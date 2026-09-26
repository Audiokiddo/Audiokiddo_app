import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum TransferEventKind { progress, complete, failed, notFound, canceled, retrying }

class TransferEvent {
  const TransferEvent(this.taskId, this.kind, {this.progress = 0, this.error});

  final String taskId;
  final TransferEventKind kind;

  /// 0..1 for [TransferEventKind.progress].
  final double progress;
  final String? error;
}

/// Thin seam over the platform downloader so the download logic can be tested without it.
abstract interface class FileTransfer {
  Future<void> start();
  Stream<TransferEvent> get events;

  /// Absolute directory where downloaded files are stored.
  Future<String> directory();
  Future<bool> enqueue({required String taskId, required Uri url, required String fileName});
  Future<void> cancel(Iterable<String> taskIds);
}

/// background_downloader: survives app suspension, retries, resumes interrupted downloads.
class BackgroundFileTransfer implements FileTransfer {
  static const _subdirectory = 'content';
  final _downloader = FileDownloader();
  final _events = StreamController<TransferEvent>.broadcast();
  StreamSubscription<TaskUpdate>? _subscription;

  @override
  Stream<TransferEvent> get events => _events.stream;

  @override
  Future<void> start() async {
    _subscription ??= _downloader.updates.listen(_onUpdate);
    await _downloader.start(autoCleanDatabase: true);
  }

  @override
  Future<String> directory() async => p.join((await getApplicationSupportDirectory()).path, _subdirectory);

  @override
  Future<bool> enqueue({required String taskId, required Uri url, required String fileName}) =>
      _downloader.enqueue(
        DownloadTask(
          taskId: taskId,
          url: url.toString(),
          filename: fileName,
          directory: _subdirectory,
          baseDirectory: BaseDirectory.applicationSupport,
          updates: Updates.statusAndProgress,
          retries: 3,
          allowPause: true,
        ),
      );

  @override
  Future<void> cancel(Iterable<String> taskIds) async {
    await _downloader.cancelTasksWithIds(taskIds.toList());
  }

  void _onUpdate(TaskUpdate update) {
    final id = update.task.taskId;
    switch (update) {
      case TaskProgressUpdate(:final progress) when progress >= 0:
        _events.add(TransferEvent(id, TransferEventKind.progress, progress: progress));
      case TaskProgressUpdate():
        break; // negative values encode status changes, handled below
      case TaskStatusUpdate(:final status, :final exception):
        final kind = switch (status) {
          TaskStatus.complete => TransferEventKind.complete,
          TaskStatus.notFound => TransferEventKind.notFound,
          TaskStatus.failed => TransferEventKind.failed,
          TaskStatus.canceled => TransferEventKind.canceled,
          TaskStatus.waitingToRetry => TransferEventKind.retrying,
          _ => null,
        };
        if (kind != null) _events.add(TransferEvent(id, kind, error: exception?.description));
    }
  }
}
