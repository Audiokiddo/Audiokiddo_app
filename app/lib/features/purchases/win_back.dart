import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../insights/events.dart';
import '../parental_gate/parental_gate.dart';
import 'shop.dart';

/// When the family's subscription ended (and none is active now): the moment to invite them
/// back with what is new since. Null while subscribed or never subscribed.
DateTime? subscriptionEndedAt(List<Entitlement> entitlements, DateTime now) {
  final all = entitlements.where((e) => e.scope == Scopes.allContent).toList();
  if (all.any((e) => e.isActiveAt(now))) return null;
  final ended = [
    for (final e in all)
      if (e.validUntil case final until? when until.isBefore(now)) until,
  ]..sort();
  return ended.lastOrNull;
}

/// Plays released after [since] (the reason to come back).
List<ContentItem> newSince(Catalog catalog, DateTime since, DateTime now) => [
  for (final i in catalog.items)
    if (i.releasedOn case final r? when r.isAfter(since) && !r.isAfter(now)) i,
];

const _hiddenKey = 'win_back_hidden_until';

final _winBackHiddenProvider = FutureProvider<DateTime?>(
  (ref) async => DateTime.tryParse(await ref.watch(databaseProvider).readValue(_hiddenKey) ?? ''),
);

/// One card on Start for a family whose subscription ended, closable for two weeks.
/// The offer opens behind the parental gate.
class WinBackCard extends ConsumerWidget {
  const WinBackCard({super.key, required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final ended = subscriptionEndedAt(ref.watch(entitlementsProvider), now);
    final hidden = ref.watch(_winBackHiddenProvider);
    if (ended == null || !hidden.hasValue || (hidden.value?.isAfter(now) ?? false)) return const SizedBox.shrink();
    final fresh = newSince(catalog, ended, now);
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            const SzopSticker(SzopPose.prosi, height: 64),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wracacie?', style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800)),
                  Text(
                    fresh.isEmpty
                        ? 'Cała biblioteka czeka, a Szop’en trzyma Wam miejsce na kanapie.'
                        : 'Od Waszej przerwy doszło ${playsCount(fresh.length)}, m.in. „${fresh.first.title}”.',
                    style: text.bodySmall?.copyWith(color: ink),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      foregroundColor: ink,
                    ),
                    onPressed: () async {
                      if (!await showParentalGate(context) || !context.mounted) return;
                      ref.read(eventSinkProvider).track(AppEvent.paywallView, props: {'from': 'win_back'});
                      await context.push('/oferta');
                    },
                    child: const Text('Zobacz ofertę'),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Nie teraz',
              onPressed: () async {
                await ref
                    .read(databaseProvider)
                    .writeValue(_hiddenKey, now.add(const Duration(days: 14)).toIso8601String());
                ref.invalidate(_winBackHiddenProvider);
              },
              icon: const Icon(Icons.close_rounded, size: 20, color: ink),
            ),
          ],
        ),
      ),
    );
  }
}
