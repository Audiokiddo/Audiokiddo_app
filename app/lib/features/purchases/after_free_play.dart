import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../insights/events.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import 'shop.dart';
import 'store_gateway.dart';

/// Promised to subscribers: everything now, and one new pack every month.
const subscriptionPromise = 'Wszystkie zabawy teraz i jeden nowy pakiet co miesiąc';

/// After a free play from a pack the family does not have: the rest of that pack, or the
/// subscription. Both buy buttons ask for an adult first (buyWithGate).
class AfterFreePlayOffer extends ConsumerStatefulWidget {
  const AfterFreePlayOffer({super.key, required this.item});

  final ContentItem item;

  @override
  ConsumerState<AfterFreePlayOffer> createState() => _AfterFreePlayOfferState();
}

class _AfterFreePlayOfferState extends ConsumerState<AfterFreePlayOffer> {
  bool _tracked = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final catalog = ref.watch(catalogProvider).value;
    final pack = item.packId == null ? null : catalog?.pack(item.packId!);
    final scopes = ref.watch(activeScopesProvider);
    if (!item.isFree || pack == null || catalog == null || ownsPack(scopes, pack.id)) {
      return const SizedBox.shrink();
    }
    final locked = catalog.itemsInPack(pack.id).where((i) => !ref.watch(canPlayProvider(i))).toList();
    if (locked.isEmpty) return const SizedBox.shrink();
    if (!_tracked) {
      _tracked = true;
      ref
          .read(eventSinkProvider)
          .track(AppEvent.paywallView, itemId: item.id, props: {'from': 'after_free_play'});
    }
    final ids = {?pack.storeProductId, ProductIds.yearly, ProductIds.monthly};
    final products = ref.watch(storeProductsProvider(productsKey(ids))).value ?? const <StoreProduct>[];
    final byId = {for (final p in products) p.id: p};
    final packProduct = byId[pack.storeProductId];
    final yearly = byId[ProductIds.yearly];
    final monthly = byId[ProductIds.monthly];
    final busy = ref.watch(purchaseControllerProvider).busyProductId;
    final minutes = locked.fold(0, (s, i) => s + i.durationSec) ~/ 60;
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SzopSticker(SzopPose.klaszcze, height: 64),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spodobało się? To dopiero początek.',
                        style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'W pakiecie ${pack.title} czeka jeszcze ${playsCount(locked.length)}, razem $minutes min zabawy bez ekranu.',
                        style: text.bodyMedium?.copyWith(color: ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Najlepiej w abonamencie',
                    style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '$subscriptionPromise.${yearly?.freeTrialDays == null ? '' : ' Pierwsze ${yearly!.freeTrialDays} dni za darmo.'}',
                    style: text.bodySmall?.copyWith(color: ink),
                  ),
                  if (yearly?.rawPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Przy płatności rocznej tylko ${formatMoney(yearly!.rawPrice! / 12, yearly.currencyCode)} miesięcznie.',
                        style: text.bodySmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (yearly != null)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: busy != null ? null : () => buyWithGate(context, ref, yearly),
                      child: Text('Rocznie ${yearly.price}'),
                    ),
                  if (monthly != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: const BorderSide(color: ink),
                      ),
                      onPressed: busy != null ? null : () => buyWithGate(context, ref, monthly),
                      child: Text('Miesięcznie ${monthly.price}'),
                    ),
                  ],
                  if (yearly == null && monthly == null)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ink,
                        side: const BorderSide(color: ink),
                      ),
                      onPressed: () => openPack(context, pack.id),
                      child: const Text('Zobacz ofertę'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('Albo tylko ten pakiet, na zawsze:', style: text.bodySmall?.copyWith(color: ink)),
            const SizedBox(height: 6),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AkBrand.tealDeep,
                side: const BorderSide(color: AkBrand.tealDeep),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: packProduct == null
                  ? () => openPack(context, pack.id)
                  : busy != null
                  ? null
                  : () => buyWithGate(context, ref, packProduct),
              child: busy == packProduct?.id
                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      packProduct == null
                          ? 'Zobacz pakiet ${pack.title}'
                          : 'Odblokuj pakiet ${pack.title} · ${packProduct.price}',
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
