import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'download_manager.dart';
import 'download_providers.dart';

/// Download / progress / downloaded / retry control for one item (details screen).
class DownloadControl extends ConsumerWidget {
  const DownloadControl({super.key, required this.item});

  final ContentItem item;

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(downloadManagerProvider).download(item);
    if (result is DownloadNotEnoughSpace && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notEnoughSpace(formatBytes(result.neededBytes), formatBytes(result.freeBytes)))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(downloadStatusProvider(item)).value ?? ItemDownloadStatus.none;
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final manager = ref.read(downloadManagerProvider);

    return switch (status.phase) {
      DownloadPhase.none => OutlinedButton.icon(
        onPressed: () => _download(context, ref),
        icon: const Icon(Icons.download_rounded),
        label: Text(l10n.download(formatBytes(item.downloadBytes))),
      ),
      DownloadPhase.queued || DownloadPhase.downloading || DownloadPhase.verifying => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(switch (status.phase) {
              DownloadPhase.queued => l10n.downloadQueued,
              DownloadPhase.verifying => l10n.verifying,
              _ => l10n.downloading((status.progress * 100).round()),
            }, style: text.bodyMedium),
          ),
          const SizedBox(height: AkSpace.s),
          LinearProgressIndicator(
            value: status.phase == DownloadPhase.downloading ? status.progress : null,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => manager.remove(item), child: Text(l10n.cancelDownload)),
          ),
        ],
      ),
      DownloadPhase.ready => Row(
        children: [
          Icon(Icons.offline_pin_rounded, color: palette.primary),
          const SizedBox(width: AkSpace.s),
          Expanded(child: Text(l10n.downloaded, style: text.bodyMedium)),
          TextButton(onPressed: () => manager.remove(item), child: Text(l10n.removeDownload)),
        ],
      ),
      DownloadPhase.failed => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.downloadFailed, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: AkSpace.s),
          OutlinedButton.icon(
            onPressed: () async {
              await manager.remove(item);
              if (context.mounted) await _download(context, ref);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.retryDownload),
          ),
        ],
      ),
    };
  }
}
