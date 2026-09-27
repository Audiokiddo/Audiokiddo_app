import 'package:ak_core/ak_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/widgets/catalog_loader.dart';
import '../catalog/widgets/item_views.dart';
import '../downloads/download_providers.dart';
import '../parental_gate/parental_gate.dart';
import 'personal_repository.dart';

class MineScreen extends StatelessWidget {
  const MineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.navMine,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: l10n.accountTitle,
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () async {
              if (await showParentalGate(context) && context.mounted) await context.push('/konto');
            },
          ),
          if (kDebugMode)
            IconButton(
              tooltip: l10n.devTools,
              icon: const Icon(Icons.build_rounded),
              onPressed: () => context.push('/moje/narzedzia'),
            ),
        ],
      ),
      body: CatalogLoader(builder: (context, catalog) => _MineContent(catalog: catalog)),
    );
  }
}

class _MineContent extends ConsumerWidget {
  const _MineContent({required this.catalog});

  final Catalog catalog;

  List<ContentItem> _items(List<String>? ids) => [
    for (final id in ids ?? const <String>[]) ?catalog.item(id),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recent = _items(ref.watch(recentProvider).value);
    final favorites = _items(ref.watch(favoritesOrderedProvider).value);
    final summary = ref.watch(downloadSummaryProvider).value;
    final downloaded = _items(summary?.itemIds);
    final free = ref.watch(freeBytesProvider).value;

    return ListView(
      padding: const EdgeInsets.only(bottom: AkSpace.xl),
      children: [
        SectionHeader(l10n.mineRecent),
        if (recent.isEmpty) _Empty(l10n.mineEmptyRecent) else _Row(items: recent, catalog: catalog),
        SectionHeader(l10n.mineFavorites),
        if (favorites.isEmpty) _Empty(l10n.mineEmptyFavorites) else _Row(items: favorites, catalog: catalog),
        SectionHeader(l10n.mineDownloads),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
          child: Text(
            free == null
                ? l10n.storageUsed(formatBytes(summary?.bytes ?? 0))
                : l10n.storageUsage(formatBytes(summary?.bytes ?? 0), formatBytes(free)),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.palette.inkMuted),
          ),
        ),
        if (downloaded.isEmpty)
          _Empty(l10n.mineEmptyDownloads)
        else ...[
          for (final item in downloaded) ItemTile(item: item, catalog: catalog),
          Padding(
            padding: const EdgeInsets.all(AkSpace.m),
            child: OutlinedButton.icon(
              onPressed: () => _confirmRemoveAll(context, ref),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l10n.deleteAllDownloads),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmRemoveAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.deleteAllConfirmTitle),
        content: Text(l10n.deleteAllConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(downloadManagerProvider).removeAll();
      ref.invalidate(freeBytesProvider);
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.items, required this.catalog});

  final List<ContentItem> items;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: itemCardShelfHeight(context, cardWidth: 128),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: AkSpace.m),
      itemBuilder: (context, i) => ItemCard(item: items[i], catalog: catalog, width: 128),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AkSpace.m, vertical: AkSpace.s),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.palette.inkMuted),
    ),
  );
}
