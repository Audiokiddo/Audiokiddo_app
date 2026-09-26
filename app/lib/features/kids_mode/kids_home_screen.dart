import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/catalog_loader.dart';
import '../catalog/widgets/content_cover.dart';
import '../downloads/download_providers.dart';
import '../parental_gate/parental_gate.dart';
import '../player/playback_controller.dart';
import 'kids_mode_controller.dart';

/// Kids mode: big covers of what the child may play. No prices, locks, links or settings.
class KidsHomeScreen extends ConsumerWidget {
  const KidsHomeScreen({super.key});

  Future<void> _exit(BuildContext context, WidgetRef ref) async {
    if (await showParentalGate(context)) await ref.read(kidsModeProvider).exit();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.palette.surfaceMuted,
      appBar: AppBar(
        backgroundColor: context.palette.surfaceMuted,
        automaticallyImplyLeading: false,
        title: Text(l10n.kidsTitle),
        actions: [
          IconButton(
            tooltip: l10n.kidsParentButton,
            icon: const Icon(Icons.lock_person_rounded),
            onPressed: () => _exit(context, ref),
          ),
        ],
      ),
      body: CatalogLoader(builder: (context, catalog) => _KidsGrid(catalog: catalog)),
    );
  }
}

/// Content shown in kids mode for the given settings (public for tests).
List<ContentItem> kidsItems(
  Catalog catalog,
  KidsModeSettings settings, {
  required bool Function(ContentItem) canPlay,
  required Set<String> downloaded,
}) => [
  for (final item in catalog.items)
    if (item.ageMin <= settings.age &&
        item.kind != ContentKind.interactiveGame &&
        canPlay(item) &&
        (!settings.onlyDownloaded || downloaded.contains(item.id)))
      item,
];

class _KidsGrid extends ConsumerWidget {
  const _KidsGrid({required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(kidsModeProvider).settings;
    final downloaded = {...?ref.watch(downloadSummaryProvider).value?.itemIds};
    final items = kidsItems(
      catalog,
      settings,
      canPlay: (item) => ref.watch(canPlayProvider(item)),
      downloaded: downloaded,
    );

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AkSpace.l),
          child: Text(
            l10n.kidsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AkSpace.m),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: AkSpace.m,
        crossAxisSpacing: AkSpace.m,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _KidsTile(item: items[i], pack: catalog.pack(items[i].packId ?? '')),
    );
  }
}

class _KidsTile extends ConsumerWidget {
  const _KidsTile({required this.item, this.pack});

  final ContentItem item;
  final Pack? pack;

  Future<void> _play(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(playbackControllerProvider).start(item, album: pack?.title ?? 'AudioKiddo');
      if (context.mounted) await context.push('/dziecko/graj');
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).kidsCannotPlay)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: item.title,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AkRadius.card),
        onTap: () => _play(context, ref),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => ContentCover(item: item, pack: pack, size: c.biggest.shortestSide),
              ),
            ),
            const SizedBox(height: AkSpace.xs),
            Text(
              item.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}
