import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import 'shop.dart';
import 'store_gateway.dart';

/// The subscription, said simply: what you get, one crossed-out price next to the real one,
/// how much you save, one big button (yearly, the best deal) and a quiet monthly option.
/// The main offer everywhere: Shop, pack pages, the window after a free play.
class SubscriptionOffer extends ConsumerWidget {
  const SubscriptionOffer({super.key, required this.catalog, required this.byId, this.compact = false});

  final Catalog catalog;
  final Map<String, StoreProduct> byId;

  /// In the window after a free play: fewer lines.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearly = byId[ProductIds.yearly];
    final monthly = byId[ProductIds.monthly];
    final busy = ref.watch(purchaseControllerProvider).busyProductId;
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    final currency = yearly?.currencyCode ?? monthly?.currencyCode ?? 'PLN';
    String money(double v) => formatMoney(v, currency);
    final perMonth = yearly?.rawPrice == null ? null : yearly!.rawPrice! / 12;
    final saveYear = yearly?.rawPrice != null && monthly?.rawPrice != null
        ? monthly!.rawPrice! * 12 - yearly!.rawPrice!
        : null;
    // A year of packs bought one by one: today's packs plus a new one every month.
    final packPrices = [for (final p in catalog.packs) ?byId[p.storeProductId]?.rawPrice];
    final packsYear = packPrices.isEmpty
        ? null
        : packPrices.fold(0.0, (a, b) => a + b) * (1 + 12 / packPrices.length);
    final trial = yearly?.freeTrialDays ?? monthly?.freeTrialDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'NAJLEPIEJ SIĘ OPŁACA',
                  style: text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Abonament AudioKiddo',
            style: text.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          for (final line in [
            'Wszystkie zabawy od razu',
            'Nowy pakiet co miesiąc, bez dopłat',
            if (!compact) 'Dla wszystkich dzieci w rodzinie',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 18, color: ink),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(line, style: text.bodyMedium?.copyWith(color: ink)),
                  ),
                ],
              ),
            ),
          if (perMonth != null) ...[
            const SizedBox(height: 10),
            // The price: monthly crossed out, the yearly price per month big.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 10,
              children: [
                if (monthly != null)
                  Text(
                    monthly.price,
                    style: text.titleMedium?.copyWith(
                      color: ink.withValues(alpha: .6),
                      decoration: TextDecoration.lineThrough,
                      decorationThickness: 2,
                    ),
                  ),
                Text(
                  '${money(perMonth)} / mies.',
                  style: text.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Text('przy płatności raz w roku (${yearly!.price})', style: text.bodySmall?.copyWith(color: ink)),
          ],
          if (saveYear != null && saveYear > 0 || packsYear != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (packsYear != null && yearly != null)
                    Text.rich(
                      TextSpan(
                        style: text.bodyMedium?.copyWith(color: ink),
                        children: [
                          const TextSpan(text: 'Pakiety osobno przez rok: '),
                          TextSpan(
                            text: 'ok. ${money(packsYear)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 2,
                            ),
                          ),
                          const TextSpan(text: '  →  '),
                          TextSpan(
                            text: yearly.price,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  if (saveYear != null && saveYear > 0)
                    Text(
                      'Rocznie oszczędzasz ${money(saveYear)} względem płacenia co miesiąc.',
                      style: text.bodyMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (yearly != null)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ink,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: busy != null ? null : () => buyWithGate(context, ref, yearly),
              child: busy == yearly.id
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      trial != null ? 'Wypróbuj $trial dni za darmo' : 'Wybieram rocznie · ${yearly.price}',
                    ),
            ),
          if (trial != null && yearly != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Potem ${yearly.price} za rok. Zrezygnujesz w dowolnej chwili.',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: ink),
              ),
            ),
          if (monthly != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: ink),
              onPressed: busy != null ? null : () => buyWithGate(context, ref, monthly),
              child: busy == monthly.id
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('albo miesięcznie ${monthly.price}'),
            ),
          if (yearly == null && monthly == null)
            Text(
              'Wszystkie zabawy teraz i jeden nowy pakiet co miesiąc.',
              style: text.bodyMedium?.copyWith(color: ink),
            ),
        ],
      ),
    );
  }
}
