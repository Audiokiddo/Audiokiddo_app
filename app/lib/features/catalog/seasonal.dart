import 'package:ak_core/ak_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'catalog_providers.dart';

/// The catalog's seasonal collection for today (autumn evenings, holidays on the road…).
final seasonalShelfProvider = Provider<Shelf?>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  final now = ref.watch(clockProvider)();
  return catalog?.shelves.where((s) => s.seasonal && s.inSeasonAt(now) && s.itemIds.isNotEmpty).firstOrNull;
});

/// Items released in the last [newForDays] days, newest first.
final newItemsProvider = Provider<List<ContentItem>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  final now = ref.watch(clockProvider)();
  if (catalog == null) return const [];
  return [
    for (final i in catalog.items)
      if (isNewAt(i.releasedOn, now)) i,
  ]..sort((a, b) => b.releasedOn!.compareTo(a.releasedOn!));
});

/// Whether [item] carries the "Nowe" badge today.
final isNewItemProvider = Provider.family<bool, ContentItem>(
  (ref, item) => isNewAt(item.releasedOn, ref.watch(clockProvider)()),
);
