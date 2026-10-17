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

  test('catalog update does not play the previous file and queues the new version', () async {
    await manager.download(itemWith());
    await complete(content);
    final updated = itemWith(sha: 'ab' * 32);
    expect(await manager.localAudioPath(updated), isNull);
    expect(await phase(updated), DownloadPhase.none);
    await manager.download(updated);
    expect(transfer.enqueued, contains('ak-${'ab' * 32}'));
  });

}
