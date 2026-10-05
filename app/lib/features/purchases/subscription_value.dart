import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import 'offer_catalog.dart';
import 'shop.dart';
import 'store_gateway.dart';

/// Why the subscription pays off, in numbers from the store: the packs bought one by one today,
/// and a year with one new pack every month. Shown in the Shop under the subscription.
class SubscriptionValue extends StatelessWidget {
  const SubscriptionValue({super.key, required this.catalog, required this.byId});

  final Catalog catalog;
  final Map<String, StoreProduct> byId;

  @override
  Widget build(BuildContext context) {
    final yearly = byId[ProductIds.yearly];
    final monthly = byId[ProductIds.monthly];
    final packPrices = [for (final p in catalog.packs) ?byId[p.storeProductId]?.rawPrice];
    if (yearly?.rawPrice == null || packPrices.length != catalog.packs.length) return const SizedBox.shrink();
    final currency = yearly!.currencyCode;
    final today = packPrices.fold(0.0, (a, b) => a + b);
    final average = today / packPrices.length;
    final afterYear = today + 12 * average;
    final perMonth = yearly.rawPrice! / 12;
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    Widget row(String label, String value, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: text.bodyMedium?.copyWith(color: ink)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: (strong ? text.titleMedium : text.bodyMedium)?.copyWith(
              color: ink,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dlaczego abonament się opłaca',
            style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          row('Dzisiejsze ${catalog.packs.length} pakiety kupione osobno', formatMoney(today, currency)),
          row(
            'Po roku, z nowym pakietem co miesiąc (${catalog.packs.length + 12} pakietów)',
            'ok. ${formatMoney(afterYear, currency)}',
          ),
          const Divider(color: ink, height: 20),
          row('Abonament roczny', '${yearly.price} / rok'),
          row('czyli miesięcznie', formatMoney(perMonth, currency), strong: true),
          if (monthly != null) row('Abonament miesięczny', '${monthly.price} / mies.'),
          const SizedBox(height: 8),
          Text(
            'W abonamencie masz wszystkie pakiety od razu i jeden nowy pakiet co miesiąc, '
            'na wszystkie dzieci w rodzinie. Możesz zrezygnować w każdej chwili.',
            style: text.bodySmall?.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}
