import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../catalog_providers.dart';
import 'content_cover.dart';
import 'labels.dart';

String itemRoute(ContentItem item) => '/zabawa/${item.id}';

String _semanticLabel(AppLocalizations l10n, ContentItem item, bool canPlay) => [
  item.title,
  l10n.duration(item.durationSec),
  l10n.ageFrom(item.ageMin),
  if (item.isFree) l10n.free else if (!canPlay) l10n.locked,
].join(', ');

/// Vertical card for horizontal shelves.
class ItemCard extends ConsumerWidget {
  const ItemCard({super.key, required this.item, required this.catalog, this.width = 148});

  final ContentItem item;
  final Catalog catalog;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canPlay = ref.watch(canPlayProvider(item));
    final palette = context.palette;
    return Semantics(
      button: true,
      label: _semanticLabel(l10n, item, canPlay),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AkRadius.card),
        onTap: () => context.push(itemRoute(item)),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ContentCover(
                item: item,
                pack: item.packId == null ? null : catalog.pack(item.packId!),
                size: width,
                locked: !canPlay,
              ),
              const SizedBox(height: AkSpace.s),
              Flexible(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  l10n.duration(item.durationSec),
                  l10n.ageFrom(item.ageMin),
                  if (item.isFree) l10n.free,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Height of a shelf of [ItemCard]s; grows with the system text size.
double itemCardShelfHeight(BuildContext context, {double cardWidth = 148}) =>
    cardWidth + AkSpace.s + MediaQuery.textScalerOf(context).scale(66);

/// Row for the library list.
class ItemTile extends ConsumerWidget {
  const ItemTile({super.key, required this.item, required this.catalog});

  final ContentItem item;
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canPlay = ref.watch(canPlayProvider(item));
    final pack = item.packId == null ? null : catalog.pack(item.packId!);
    final palette = context.palette;
    return Semantics(
      button: true,
      label: _semanticLabel(l10n, item, canPlay),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push(itemRoute(item)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AkSpace.m, vertical: AkSpace.s),
          child: Row(
            children: [
              ContentCover(item: item, pack: pack, size: 72, locked: !canPlay),
              const SizedBox(width: AkSpace.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack?.title ?? l10n.kind(item.kind),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: palette.inkMuted),
                    ),
                    Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      [
                        l10n.duration(item.durationSec),
                        l10n.ageFrom(item.ageMin),
                        if (item.isFree) l10n.free,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AkSpace.m, AkSpace.l, AkSpace.m, AkSpace.s),
    child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
  );
}
