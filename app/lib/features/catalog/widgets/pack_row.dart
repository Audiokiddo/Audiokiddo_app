import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../library_filter.dart';

/// Pack cards in their colours; a tap filters the library to the pack.
class PackRow extends StatelessWidget {
  const PackRow({super.key, required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SizedBox(
      // Room for a two-line title and the count at any text size.
      height: 40 + MediaQuery.textScalerOf(context).scale(88),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AkSpace.m),
        itemCount: catalog.packs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AkSpace.s),
        itemBuilder: (context, i) {
          final pack = catalog.packs[i];
          final count = catalog.itemsInPack(pack.id).length;
          return Material(
            color: AkPalette.packColor(pack.colorToken),
            borderRadius: BorderRadius.circular(AkRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AkRadius.card),
              onTap: () => context.go(LibraryFilter(packId: pack.id).toLocation()),
              child: SizedBox(
                width: 190,
                child: Padding(
                  padding: const EdgeInsets.all(AkSpace.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pack.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge?.copyWith(color: AkBrand.ink, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${l10n.itemsCount(count)} · ${l10n.ageFrom(pack.ageMin)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(color: AkBrand.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
