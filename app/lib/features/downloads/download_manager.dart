import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:ak_core/ak_core.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/platform/device_storage.dart';
import '../../core/storage/database.dart';
import '../content/content_urls.dart';
import 'file_transfer.dart';
import 'verify.dart';

/// Free space kept for the system and other apps on top of the download itself.
const downloadSpaceMargin = 50 * 1024 * 1024;

enum DownloadPhase { none, queued, downloading, verifying, ready, failed }

class ItemDownloadStatus {
  const ItemDownloadStatus(this.phase, {this.progress = 0, this.bytes = 0, this.error});

  static const none = ItemDownloadStatus(DownloadPhase.none);

  final DownloadPhase phase;

  /// 0..1 while downloading, weighted by file size.
  final double progress;
  final int bytes;
  final String? error;

  bool get isActive =>
      phase == DownloadPhase.queued || phase == DownloadPhase.downloading || phase == DownloadPhase.verifying;
}

sealed class DownloadRequest {
  const DownloadRequest();
}

class DownloadStarted extends DownloadRequest {
  const DownloadStarted();
}

class DownloadNotEnoughSpace extends DownloadRequest {
  const DownloadNotEnoughSpace({required this.neededBytes, required this.freeBytes});

  final int neededBytes;
  final int freeBytes;
}

/// Downloads every file of a catalog item, verifies it and records the result locally.
///
/// A file is only `ready` after its size and SHA-256 match the catalog; anything else
/// is deleted and marked `failed`, so an incomplete file never plays as complete.
class DownloadManager {
  DownloadManager({
    required this._db,
    required this._transfer,
    required this._urls,
    this._storage = const DeviceStorage(),
  });

  final AppDatabase _db;
  final FileTransfer _transfer;
  final ContentUrlResolver _urls;
  final DeviceStorage _storage;

  final _progress = <String, double>{}; // by asset path
  final _progressChanged = StreamController<void>.broadcast();
  StreamSubscription<TransferEvent>? _subscription;
  Future<void>? _started;

  Future<void> start() => _started ??= _start();

  Future<void> _start() async {
    _subscription = _transfer.events.listen(_onEvent);
    await _transfer.start();
    await _reconcile();
  }

  /// Fixes state left behind by a crash or a deleted file.
  Future<void> _reconcile() async {
    final dir = await _transfer.directory();
    for (final row in await _db.select(_db.downloads).get()) {
      final path = p.join(dir, row.fileName);
      switch (row.state) {
        case DownloadState.ready when !await File(path).exists():
          await _deleteRows([row.assetPath]);
        case DownloadState.verifying:
          await _verify(row, path);
        default:
          break;
      }
    }
  }

  Future<DownloadRequest> download(ContentItem item) async {
    await start();
    final existing = {for (final r in await _rowsFor(item.id)) r.assetPath: r};
    final missing = [
      for (final asset in _assetsOf(item))
        if (existing[asset.path]?.state != DownloadState.ready) asset,
    ];
    if (missing.isEmpty) return const DownloadStarted();

    final needed = missing.fold(0, (sum, a) => sum + a.bytes);
    final free = await _storage.freeBytes();
    if (free != null && free < needed + downloadSpaceMargin) {
      return DownloadNotEnoughSpace(neededBytes: needed, freeBytes: free);
    }

    for (final asset in missing) {
      final fileName = _fileName(asset);
      await _db
          .into(_db.downloads)
          .insertOnConflictUpdate(
            DownloadsCompanion.insert(
              assetPath: asset.path,
              itemId: item.id,
              sha256: asset.sha256,
              bytes: asset.bytes,
              fileName: fileName,
              state: DownloadState.queued,
              updatedAt: DateTime.now(),
            ),
          );
      final url = await _urls.urlFor(asset);
      final queued = await _transfer.enqueue(taskId: _taskId(asset), url: url, fileName: fileName);
      if (!queued) await _setState(asset.path, DownloadState.failed, error: 'enqueue');
    }
    return const DownloadStarted();
  }

  /// Cancels running transfers and removes the item's files.
  Future<void> remove(ContentItem item) async {
    final rows = await _rowsFor(item.id);
    await _transfer.cancel(rows.map((r) => _taskIdFor(r.sha256)));
    final dir = await _transfer.directory();
    for (final row in rows) {
      await _deleteFile(p.join(dir, row.fileName));
      _progress.remove(row.assetPath);
    }
    await _deleteRows(rows.map((r) => r.assetPath));
    _progressChanged.add(null);
  }

  Future<void> removeAll() async {
    final rows = await _db.select(_db.downloads).get();
    await _transfer.cancel(rows.map((r) => _taskIdFor(r.sha256)));
    final dir = await _transfer.directory();
    for (final row in rows) {
      await _deleteFile(p.join(dir, row.fileName));
    }
    await _db.delete(_db.downloads).go();
    _progress.clear();
    _progressChanged.add(null);
  }

  /// Local file of a plain-audio item when it is downloaded and verified, otherwise null.
  Future<String?> localAudioPath(ContentItem item) async =>
      item.audio.isEmpty ? null : localFilePath(item.audio.first);

  /// Local copy of any verified asset (audio, PDF, game segment), otherwise null.
  Future<String?> localFilePath(AssetRef asset) async {
    final row = await (_db.select(
      _db.downloads,
    )..where((t) => t.assetPath.equals(asset.path))).getSingleOrNull();
    if (row == null || row.state != DownloadState.ready) return null;
    final path = p.join(await _transfer.directory(), row.fileName);
    return await File(path).exists() ? path : null;
  }

  Stream<ItemDownloadStatus> watch(ContentItem item) {
    final expected = _assetsOf(item).length;
    late StreamController<ItemDownloadStatus> controller;
    StreamSubscription<List<Download>>? rowsSub;
    StreamSubscription<void>? progressSub;
    var rows = <Download>[];
    void emit() => controller.add(_aggregate(rows, expected));
    controller = StreamController<ItemDownloadStatus>(
      onListen: () {
        rowsSub = (_db.select(_db.downloads)..where((t) => t.itemId.equals(item.id))).watch().listen((r) {
          rows = r;
          emit();
        });
        progressSub = _progressChanged.stream.listen((_) => emit());
      },
      onCancel: () async {
        await rowsSub?.cancel();
        await progressSub?.cancel();
      },
    );
    return controller.stream;
  }

  /// Bytes of verified downloads, and the list of downloaded item ids (newest first).
  Stream<({int bytes, List<String> itemIds})> watchSummary() {
    final query = _db.select(_db.downloads)
      ..where((t) => t.state.equalsValue(DownloadState.ready))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch().map(
      (rows) => (
        bytes: rows.fold(0, (sum, r) => sum + r.bytes),
        itemIds: {for (final r in rows) r.itemId}.toList(),
      ),
    );
  }

  Future<int?> freeBytes() => _storage.freeBytes();

  ItemDownloadStatus _aggregate(List<Download> rows, int expected) {
    if (rows.isEmpty) return ItemDownloadStatus.none;
    final total = rows.fold(0, (sum, r) => sum + r.bytes);
    final failed = rows.where((r) => r.state == DownloadState.failed).firstOrNull;
    if (failed != null) return ItemDownloadStatus(DownloadPhase.failed, bytes: total, error: failed.error);
    if (rows.length >= expected && rows.every((r) => r.state == DownloadState.ready)) {
      return ItemDownloadStatus(DownloadPhase.ready, progress: 1, bytes: total);
    }
    if (rows.any((r) => r.state == DownloadState.verifying)) {
      return ItemDownloadStatus(DownloadPhase.verifying, progress: 1, bytes: total);
    }
    final done = rows.fold<double>(0, (sum, r) {
      final fraction = r.state == DownloadState.ready ? 1.0 : (_progress[r.assetPath] ?? 0);
      return sum + fraction * r.bytes;
    });
    final started = rows.any((r) => r.state == DownloadState.running || _progress.containsKey(r.assetPath));
    return ItemDownloadStatus(
      started ? DownloadPhase.downloading : DownloadPhase.queued,
      progress: total == 0 ? 0 : done / total,
      bytes: total,
    );
  }

  Future<void> _onEvent(TransferEvent event) async {
    final row = await (_db.select(
      _db.downloads,
    )..where((t) => t.sha256.equals(_shaFromTaskId(event.taskId)))).getSingleOrNull();
    if (row == null) return;
    switch (event.kind) {
      case TransferEventKind.progress:
        _progress[row.assetPath] = event.progress;
        if (row.state == DownloadState.queued) await _setState(row.assetPath, DownloadState.running);
        _progressChanged.add(null);
      case TransferEventKind.retrying:
        break;
      case TransferEventKind.complete:
        _progress.remove(row.assetPath);
        await _verify(row, p.join(await _transfer.directory(), row.fileName));
      case TransferEventKind.failed || TransferEventKind.notFound:
        _progress.remove(row.assetPath);
        await _deleteFile(p.join(await _transfer.directory(), row.fileName));
        await _setState(row.assetPath, DownloadState.failed, error: event.kind.name);
      case TransferEventKind.canceled:
        _progress.remove(row.assetPath);
        _progressChanged.add(null);
    }
  }

  Future<void> _verify(Download row, String path) async {
    await _setState(row.assetPath, DownloadState.verifying);
    final bytes = row.bytes, sha = row.sha256;
    final ok = await Isolate.run(() => verifyFile(path, bytes: bytes, sha256Hex: sha));
    if (ok) {
      await _storage.excludeFromBackup(path);
      await _setState(row.assetPath, DownloadState.ready);
    } else {
      await _deleteFile(path);
      await _setState(row.assetPath, DownloadState.failed, error: 'checksum');
    }
  }

  Future<List<Download>> _rowsFor(String itemId) =>
      (_db.select(_db.downloads)..where((t) => t.itemId.equals(itemId))).get();

  Future<void> _setState(String assetPath, DownloadState state, {String? error}) =>
      (_db.update(_db.downloads)..where((t) => t.assetPath.equals(assetPath))).write(
        DownloadsCompanion(state: Value(state), error: Value(error), updatedAt: Value(DateTime.now())),
      );

  Future<void> _deleteRows(Iterable<String> assetPaths) =>
      (_db.delete(_db.downloads)..where((t) => t.assetPath.isIn(assetPaths))).go();

  static Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  /// Everything needed offline: recordings, game segments and printable case files.
  static List<AssetRef> _assetsOf(ContentItem item) => [
    ...item.audio,
    ...item.pdf,
    ...?item.script?.assets.values,
  ];

  static String _fileName(AssetRef asset) => '${asset.sha256}${p.extension(asset.path)}';
  static String _taskId(AssetRef asset) => _taskIdFor(asset.sha256);
  static String _taskIdFor(String sha) => 'ak-$sha';
  static String _shaFromTaskId(String taskId) => taskId.startsWith('ak-') ? taskId.substring(3) : taskId;

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _progressChanged.close();
  }
}
