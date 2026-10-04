import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../catalog/catalog_providers.dart';
import 'download_manager.dart';
import 'download_providers.dart';

/// Downloads every play in [items] the family can play, one after another; reports lack of
/// space once.
Future<void> downloadAll(BuildContext context, WidgetRef ref, List<ContentItem> items) async {
  final manager = ref.read(downloadManagerProvider);
  final messenger = ScaffoldMessenger.of(context);
  for (final item in items) {
    final status = ref.read(downloadStatusProvider(item)).value ?? ItemDownloadStatus.none;
    if (status.phase == DownloadPhase.ready || status.isActive) continue;
    final result = await manager.download(item);
    if (result is DownloadNotEnoughSpace) {
      messenger.showSnackBar(
        SnackBar(content: Text('Brakuje miejsca w telefonie: potrzeba ${formatBytes(result.neededBytes)}.')),
      );
      return;
    }
  }
}

/// "Pobierz cały pakiet": every play the family can play, for listening without the internet.
/// Shows how many are on the phone already, or progress while they come.
class PackDownloadButton extends ConsumerWidget {
  const PackDownloadButton({super.key, required this.items, this.label = 'Pobierz cały pakiet'});

  final List<ContentItem> items;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playable = [
      for (final i in items)
        if (ref.watch(canPlayProvider(i)) && i.downloadBytes > 0) i,
    ];
    if (playable.isEmpty) return const SizedBox.shrink();
    final statuses = [
      for (final i in playable) ref.watch(downloadStatusProvider(i)).value ?? ItemDownloadStatus.none,
    ];
    final ready = statuses.where((s) => s.phase == DownloadPhase.ready).length;
    final active = statuses.where((s) => s.isActive).toList();
    final missingBytes = [
      for (final (n, i) in playable.indexed)
        if (statuses[n].phase != DownloadPhase.ready) i.downloadBytes,
    ].fold(0, (a, b) => a + b);
    if (ready == playable.length) {
      return Row(
        children: [
          const Icon(Icons.offline_pin_rounded, color: AkBrand.tealDeep),
          const SizedBox(width: 8),
          Expanded(child: Text('Wszystko pobrane, działa bez internetu (${playable.length})')),
        ],
      );
    }
    if (active.isNotEmpty) {
      final progress = (ready + active.fold(0.0, (a, s) => a + s.progress)) / playable.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pobieranie: $ready z ${playable.length}'),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress, minHeight: 6, borderRadius: BorderRadius.circular(4)),
        ],
      );
    }
    return OutlinedButton.icon(
      onPressed: () => downloadAll(context, ref, playable),
      icon: const Icon(Icons.download_rounded),
      label: Text(
        '$label (${playable.length - ready}, ${formatBytes(missingBytes)})',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// One play's download state as a small round button: download, progress, or done.
class ItemDownloadIcon extends ConsumerWidget {
  const ItemDownloadIcon({super.key, required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(downloadStatusProvider(item)).value ?? ItemDownloadStatus.none;
    if (status.phase == DownloadPhase.ready) {
      return IconButton(
        tooltip: 'Pobrane: ${item.title}. Usuń z telefonu',
        onPressed: () => ref.read(downloadManagerProvider).remove(item),
        icon: const Icon(Icons.offline_pin_rounded, color: AkBrand.tealDeep),
      );
    }
    if (status.isActive) {
      return SizedBox.square(
        dimension: 48,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: CircularProgressIndicator(
            value: status.progress > 0 ? status.progress : null,
            strokeWidth: 3,
          ),
        ),
      );
    }
    return IconButton(
      tooltip: 'Pobierz ${item.title} (${formatBytes(item.downloadBytes)})',
      onPressed: () => downloadAll(context, ref, [item]),
      icon: Icon(status.phase == DownloadPhase.failed ? Icons.refresh_rounded : Icons.download_rounded),
    );
  }
}
