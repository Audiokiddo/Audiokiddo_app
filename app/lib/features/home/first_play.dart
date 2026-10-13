import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/item_art.dart';
import '../family/family.dart' hide progressProvider;
import '../personal/personal_repository.dart';
import 'quick_pick.dart';

/// The play a new family starts with: Studio can name it with a shelf "pierwsza"; otherwise
/// a free play that needs nothing to prepare and suits [age]. Up to 4 the shortest and
/// simplest (made for the youngest); older children get the one made closest to their age.
ContentItem? firstPlay(Catalog catalog, {int? age}) {
  final shelf = catalog.shelves.where((s) => s.id == 'pierwsza').firstOrNull;
  final named = shelf == null ? null : [for (final id in shelf.itemIds) ?catalog.item(id)].firstOrNull;
  if (named != null) return named;
  final years = age ?? 3;
  final candidates = [
    for (final i in catalog.items)
      if (i.isFree && i.kind == ContentKind.audioGame && i.requirements.isEmpty && i.ageMin <= (years <= 4 ? 3 : years))
        i,
  ]..sort((a, b) => years <= 4
      ? a.durationSec.compareTo(b.durationSec)
      : (years - a.ageMin).compareTo(years - b.ageMin) != 0
      ? (years - a.ageMin).compareTo(years - b.ageMin)
      : a.durationSec.compareTo(b.durationSec));
  return candidates.firstOrNull;
}

/// Until the first play is finished: one big card at the top of Start with that play and one
/// sentence on how to use it. The fastest way to the moment "it really kept my child busy".
class FirstPlayCard extends ConsumerWidget {
  const FirstPlayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final family = ref.watch(familyProvider).value;
    final recent = ref.watch(recentProvider).value;
    if (catalog == null || family == null || recent == null) return const SizedBox.shrink();
    if (family.results.any((r) => r.completed) || recent.isNotEmpty) return const SizedBox.shrink();
    final item = firstPlay(catalog, age: family.active?.age);
    if (item == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zacznij tutaj',
              style: text.labelLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox.square(
                  dimension: 88,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ItemArt(item: item),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${(item.durationSec / 60).ceil()} min · za darmo · nic nie trzeba szykować',
                        style: text.bodySmall?.copyWith(color: ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Pierwszy raz posłuchajcie razem i sprawdźcie głośność. Telefon połóżcie ekranem do dołu. '
              'Dziecko odpowiada na głos, rusza się i wymyśla. Potem zobaczycie, ile da radę samo.',
              style: text.bodyMedium?.copyWith(color: ink, height: 1.35),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AkBrand.tealDeep,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () => startItem(context, item),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: const Text('Włącz pierwszą zabawę'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
