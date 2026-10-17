import 'dart:io';
import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/storage/database.dart';
import 'package:audiokiddo/features/content/content_urls.dart';
import 'package:audiokiddo/features/downloads/download_manager.dart';
import 'package:audiokiddo/features/downloads/file_transfer.dart';
import 'package:audiokiddo/features/downloads/verify.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'helpers.dart';

final content = List<int>.generate(4096, (i) => i % 251);
final contentSha = sha256.convert(content).toString();

ContentItem itemWith({int? bytes, String? sha}) => ContentItem(
  id: 'magiczny-sklep',
  kind: ContentKind.audioGame,
  title: 'Magiczny sklep',
  parentDescription: '',
  ageMin: 3,
  durationSec: 360,
  access: ContentAccess.free,
  audio: [
    AssetRef(
      path: 'audio/wyobraznia/magiczny-sklep.m4a',
      bytes: bytes ?? content.length,
      sha256: sha ?? contentSha,
    ),
  ],
);

void main() {
  late Directory dir;
  late AppDatabase db;
  late FakeTransfer transfer;
  late DownloadManager manager;

  DownloadManager build({
    int? free,
    ContentUrlResolver urls = const BaseUrlResolver('http://dev'),
    Duration timeout = const Duration(seconds: 15),
  }) => DownloadManager(
    db: db,
    transfer: transfer,
    urls: urls,
    requestTimeout: timeout,
    storage: FakeStorage(free),
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ak_downloads');
    db = memoryDatabase();
    transfer = FakeTransfer(dir);
    manager = build();
    await manager.start();
  });

  tearDown(() async {
    await manager.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<DownloadPhase> phase(ContentItem item) async => (await manager.watch(item).first).phase;

  /// Simulates the platform writing the file and reporting completion.
  Future<void> complete(List<int> bytes) async {
    await File(p.join(dir.path, '$contentSha.m4a')).writeAsBytes(bytes);
    transfer.emit(TransferEvent('ak-$contentSha', TransferEventKind.complete));
    for (var i = 0; i < 50 && await phase(itemWith()) == DownloadPhase.verifying || i == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test('download is queued with the dev URL and a content-addressed file name', () async {
    final result = await manager.download(itemWith());
    expect(result, isA<DownloadStarted>());
    expect(transfer.enqueued['ak-$contentSha'], Uri.parse('http://dev/audio/wyobraznia/magiczny-sklep.m4a'));
    expect(await phase(itemWith()), DownloadPhase.queued);
  });

  test('progress is reported while downloading', () async {
    await manager.download(itemWith());
    transfer.emit(TransferEvent('ak-$contentSha', TransferEventKind.progress, progress: 0.4));
    await pumpEventQueue();
    final status = await manager.watch(itemWith()).first;
    expect(status.phase, DownloadPhase.downloading);
    expect(status.progress, closeTo(0.4, 0.001));
  });

  test('verified file becomes ready and plays locally', () async {
    await manager.download(itemWith());
    await complete(content);
    expect(await phase(itemWith()), DownloadPhase.ready);
    expect(await manager.localAudioPath(itemWith()), p.join(dir.path, '$contentSha.m4a'));
  });

  test('corrupted file is never marked ready and is deleted', () async {
    await manager.download(itemWith());
    await complete([...content.take(4000), ...List.filled(96, 0)]);
    final status = await manager.watch(itemWith()).first;
    expect(status.phase, DownloadPhase.failed);
    expect(status.error, 'checksum');
    expect(File(p.join(dir.path, '$contentSha.m4a')).existsSync(), isFalse);
    expect(await manager.localAudioPath(itemWith()), isNull);
  });

  test('truncated file (interrupted download) fails verification', () async {
    await manager.download(itemWith());
    await complete(content.take(1000).toList());
    expect(await phase(itemWith()), DownloadPhase.failed);
  });

  test('network failure marks the item failed', () async {
    await manager.download(itemWith());
    transfer.emit(TransferEvent('ak-$contentSha', TransferEventKind.failed));
    await pumpEventQueue();
    expect(await phase(itemWith()), DownloadPhase.failed);
  });

  test('not enough free space refuses to start', () async {
    await manager.dispose();
    manager = build(free: 10 * 1024 * 1024);
    final result = await manager.download(itemWith());
    expect(result, isA<DownloadNotEnoughSpace>());
    expect(transfer.enqueued, isEmpty);
  });

  test('remove cancels, deletes files and rows', () async {
    await manager.download(itemWith());
    await complete(content);
    await manager.remove(itemWith());
    expect(transfer.canceled, contains('ak-$contentSha'));
    expect(await phase(itemWith()), DownloadPhase.none);
    expect(dir.listSync(), isEmpty);
  });

  test('on start, a ready row whose file vanished is cleaned up', () async {
    await manager.download(itemWith());
    await complete(content);
    await File(p.join(dir.path, '$contentSha.m4a')).delete();
    await manager.dispose();
    manager = build();
    await manager.start();
    expect(await phase(itemWith()), DownloadPhase.none);
  });

  test('summary counts only verified downloads', () async {
    await manager.download(itemWith());
    expect((await manager.watchSummary().first).bytes, 0);
    await complete(content);
    final summary = await manager.watchSummary().first;
    expect(summary.bytes, content.length);
    expect(summary.itemIds, ['magiczny-sklep']);
  });

  test('catalog update does not play the previous file and queues the new version', () async {
    await manager.download(itemWith());
    await complete(content);
    final updated = itemWith(sha: 'ab' * 32);
    expect(await manager.localAudioPath(updated), isNull);
    expect(await phase(updated), DownloadPhase.none);
    await manager.download(updated);
    expect(transfer.enqueued, contains('ak-${'ab' * 32}'));
  });

  ContentItem sharedItem() => ContentItem(
    id: 'second',
    kind: ContentKind.audioGame,
    title: 'Second',
    parentDescription: '',
    ageMin: 3,
    durationSec: 360,
    access: ContentAccess.free,
    audio: [AssetRef(path: 'audio/second.m4a', bytes: content.length, sha256: contentSha)],
  );

  test('identical files at different paths both finish downloading', () async {
    await manager.download(itemWith());
    await manager.download(sharedItem());
    await complete(content);
    await manager.watch(sharedItem()).firstWhere((s) => s.phase == DownloadPhase.ready);
    expect(await phase(itemWith()), DownloadPhase.ready);
    expect(await manager.localAudioPath(sharedItem()), isNotNull);
  });

  test('concurrent requests sharing a file complete together', () async {
    await Future.wait([manager.download(itemWith()), manager.download(sharedItem())]);
    await complete(content);
    await manager.watch(sharedItem()).firstWhere((s) => s.phase == DownloadPhase.ready);
    expect(await manager.localAudioPath(itemWith()), isNotNull);
    expect(await manager.localAudioPath(sharedItem()), isNotNull);
  });

  test('a file deleted after startup can be downloaded again', () async {
    await manager.download(itemWith());
    await complete(content);
    await File(p.join(dir.path, '$contentSha.m4a')).delete();
    await manager.download(itemWith());
    expect(await phase(itemWith()), DownloadPhase.queued);
    await complete(content);
    expect(await manager.localAudioPath(itemWith()), isNotNull);
  });

  test('removing one item preserves the shared file of another', () async {
    await manager.download(itemWith());
    await complete(content);
    await manager.download(sharedItem());
    await manager.remove(itemWith());
    expect(await manager.localAudioPath(sharedItem()), isNotNull);
    expect(await phase(sharedItem()), DownloadPhase.ready);
    expect(transfer.canceled, isEmpty);
  });

  test('shared downloads are counted once in occupied disk space', () async {
    await manager.download(itemWith());
    await complete(content);
    await manager.download(sharedItem());
    final summary = await manager.watchSummary().first;
    expect(summary.bytes, content.length);
    expect(summary.itemIds, containsAll(['magiczny-sklep', 'second']));
  });

  test('platform cancellation leaves a retryable download', () async {
    await manager.download(itemWith());
    transfer.emit(TransferEvent('ak-$contentSha', TransferEventKind.canceled));
    await manager.watch(itemWith()).firstWhere((s) => s.phase == DownloadPhase.failed);
    await manager.download(itemWith());
    expect(await phase(itemWith()), DownloadPhase.queued);
    await complete(content);
    expect(await phase(itemWith()), DownloadPhase.ready);
  });

  test('enqueue exception marks failed and a second attempt succeeds', () async {
    await manager.dispose();
    transfer = _UnreliableTransfer(dir)..enqueueFailures = 1;
    manager = build();
    await manager.download(itemWith());
    expect(await phase(itemWith()), DownloadPhase.failed);
    await manager.download(itemWith());
    await complete(content);
    expect(await phase(itemWith()), DownloadPhase.ready);
  });

  test('startup can retry after a transient platform failure', () async {
    await manager.dispose();
    final unreliable = _UnreliableTransfer(dir)..startFailures = 1;
    transfer = unreliable;
    manager = build();
    await expectLater(manager.start(), throwsException);
    await manager.start();
    expect(unreliable.starts, 2);
    await manager.download(itemWith());
    await complete(content);
    expect(await phase(itemWith()), DownloadPhase.ready);
  });

  test('a stalled URL lookup times out and does not block the next download', () async {
    await manager.dispose();
    final resolver = _StalledResolver();
    manager = build(urls: resolver, timeout: const Duration(milliseconds: 25));
    await manager.download(itemWith());
    expect(await phase(itemWith()), DownloadPhase.failed);
    resolver.stalled = false;
    await manager.download(itemWith());
    await complete(content);
    expect(await phase(itemWith()), DownloadPhase.ready);
  });

  test('verifyFile checks size and hash', () async {
    final file = File(p.join(dir.path, 'x.bin'))..writeAsBytesSync(content);
    expect(await verifyFile(file.path, bytes: content.length, sha256Hex: contentSha), isTrue);
    expect(await verifyFile(file.path, bytes: content.length + 1, sha256Hex: contentSha), isFalse);
    expect(await verifyFile(file.path, bytes: content.length, sha256Hex: 'ab' * 32), isFalse);
    expect(await verifyFile(p.join(dir.path, 'missing'), bytes: 1, sha256Hex: contentSha), isFalse);
  });

  test('rows written by the manager use the download table', () async {
    await manager.download(itemWith());
    final rows = await db.select(db.downloads).get();
    expect(rows.single.state, DownloadState.queued);
    expect(rows.single.fileName, '$contentSha.m4a');
    expect(await (db.select(db.downloads)..where((t) => t.itemId.equals('x'))).get(), isEmpty);
  });
}

class _UnreliableTransfer extends FakeTransfer {
  _UnreliableTransfer(super.dir);
  int enqueueFailures = 0;
  int startFailures = 0;
  int starts = 0;
  @override
  Future<void> start() async {
    starts++;
    if (startFailures-- > 0) throw Exception('platform temporarily unavailable');
  }

  @override
  Future<bool> enqueue({required String taskId, required Uri url, required String fileName}) async {
    if (enqueueFailures-- > 0) throw Exception('enqueue failed');
    return super.enqueue(taskId: taskId, url: url, fileName: fileName);
  }
}

class _StalledResolver implements ContentUrlResolver {
  bool stalled = true;
  @override
  Future<Uri> urlFor(AssetRef asset) =>
      stalled ? Completer<Uri>().future : Future.value(Uri.parse('http://dev/${asset.path}'));
}
