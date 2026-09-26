import 'package:ak_core/ak_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/storage_providers.dart';
import '../content/content_urls.dart';
import 'download_manager.dart';
import 'file_transfer.dart';

final fileTransferProvider = Provider<FileTransfer>((ref) => BackgroundFileTransfer());

final contentUrlResolverProvider = Provider<ContentUrlResolver>((ref) => defaultContentUrlResolver());

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  final manager = DownloadManager(
    db: ref.watch(databaseProvider),
    transfer: ref.watch(fileTransferProvider),
    urls: ref.watch(contentUrlResolverProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
});

final downloadStatusProvider = StreamProvider.family<ItemDownloadStatus, ContentItem>(
  (ref, item) => ref.watch(downloadManagerProvider).watch(item),
);

final downloadSummaryProvider = StreamProvider<({int bytes, List<String> itemIds})>(
  (ref) => ref.watch(downloadManagerProvider).watchSummary(),
);

final freeBytesProvider = FutureProvider<int?>((ref) => ref.watch(downloadManagerProvider).freeBytes());
