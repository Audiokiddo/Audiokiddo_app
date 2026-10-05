import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/content_cover.dart';
import '../family/family.dart' hide progressProvider;
import '../home/quick_pick.dart' show startItem;
import '../insights/events.dart';
import '../personal/personal_repository.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import 'shop.dart';
import 'store_gateway.dart';

/// Promised to subscribers: everything now, and one new pack every month.
const subscriptionPromise = 'Wszystkie zabawy teraz i jeden nowy pakiet co miesiąc';

/// The next free audio play the family has not heard yet, for the child's [age].
ContentItem? nextFreePlay(
  Catalog catalog, {
  required String after,
  required Set<String> heard,
  required int age,
}) => catalog.items
    .where(
      (i) =>
          i.isFree &&
          i.kind == ContentKind.audioGame &&
          i.id != after &&
          !heard.contains(i.id) &&
          i.ageMin <= age,
    )
    .firstOrNull;

/// What a year of the subscription is worth against buying packs one by one: every pack
/// today plus twelve new ones (one a month) at the average pack price.
({double packsToday, double yearValue, double saving, double vsMonthly})? subscriptionSavings({
  required List<StoreProduct> packs,
  required StoreProduct? yearly,
  required StoreProduct? monthly,
}) {
  final prices = [for (final p in packs) ?p.rawPrice];
  final year = yearly?.rawPrice;
  if (prices.isEmpty || year == null) return null;
  final today = prices.fold(0.0, (s, p) => s + p);
  final value = today + 12 * today / prices.length;
  final month = monthly?.rawPrice;
  return (
    packsToday: today,
    yearValue: value,
    saving: value - year,
    vsMonthly: month == null ? 0 : month * 12 - year,
  );
}

/// The family's played and finished plays.
Set<String> heardIds(WidgetRef ref) => {
  ...?ref.read(recentProvider).value,
  for (final r in ref.read(familyProvider).value?.results ?? const <ActivityResult>[]) r.itemId,
};

/// Whether there is anything to say after [item]: another free play, or an offer.
bool hasAfterFreePlay(WidgetRef ref, ContentItem item) {
  if (!item.isFree) return false;
  final catalog = ref.read(catalogProvider).value;
  if (catalog == null) return false;
  final age = ref.read(familyProvider).value?.active?.age ?? 6;
  if (nextFreePlay(catalog, after: item.id, heard: heardIds(ref), age: age) != null) return true;
  return catalog.items.any((i) => !ref.read(canPlayProvider(i)));
}

/// Its own window after a free play: the next free play first, while there is one, then the
/// subscription (with how much it saves and the new pack every month) or this pack forever.
Future<void> showAfterFreePlay(BuildContext context, ContentItem item) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .92),
  builder: (sheet) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AfterFreePlayOffer(item: item, host: context),
    ),
  ),
);

/// After a free play. Both buy buttons ask for an adult first (buyWithGate).
class AfterFreePlayOffer extends ConsumerStatefulWidget {
  const AfterFreePlayOffer({super.key, required this.item, this.host});

  final ContentItem item;

  /// The screen under the window: starts the next play after the window is gone.
  final BuildContext? host;

  @override
  ConsumerState<AfterFreePlayOffer> createState() => _AfterFreePlayOfferState();
}

class _AfterFreePlayOfferState extends ConsumerState<AfterFreePlayOffer> {
  bool _tracked = false;
  late final Set<String> _heard = heardIds(ref);

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final catalog = ref.watch(catalogProvider).value;
    if (!item.isFree || catalog == null) return const SizedBox.shrink();
    final age = ref.watch(familyProvider).value?.active?.age ?? 6;
    final next = nextFreePlay(catalog, after: item.id, heard: _heard, age: age);
    final pack = item.packId == null ? null : catalog.pack(item.packId!);
    final scopes = ref.watch(activeScopesProvider);
    final lockedInPack = pack == null || ownsPack(scopes, pack.id)
        ? const <ContentItem>[]
        : catalog.itemsInPack(pack.id).where((i) => !ref.watch(canPlayProvider(i))).toList();
    final anyLocked = catalog.items.any((i) => !ref.watch(canPlayProvider(i)));
    if (next == null && !anyLocked) return const SizedBox.shrink();
    if (!_tracked && anyLocked) {
      _tracked = true;
      ref
          .read(eventSinkProvider)
          .track(AppEvent.paywallView, itemId: item.id, props: {'from': 'after_free_play'});
    }
    final packIds = {for (final p in catalog.packs) ?p.storeProductId};
    final ids = {...packIds, ProductIds.yearly, ProductIds.monthly};
    final products = ref.watch(storeProductsProvider(productsKey(ids))).value ?? const <StoreProduct>[];
    final byId = {for (final p in products) p.id: p};
    final packProduct = byId[pack?.storeProductId];
    final yearly = byId[ProductIds.yearly];
    final monthly = byId[ProductIds.monthly];
    final savings = subscriptionSavings(
      packs: [for (final id in packIds) ?byId[id]],
      yearly: yearly,
      monthly: monthly,
    );
    String money(double v) => formatMoney(v, yearly?.currencyCode ?? 'PLN');
    final busy = ref.watch(purchaseControllerProvider).busyProductId;
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);

    void playNext() {
      Navigator.of(context).maybePop();
      final host = widget.host ?? context;
      if (host.mounted) startItem(host, next!);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .4, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: const SzopSticker(SzopPose.klaszcze, height: 72),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                next != null ? 'Brawo! Lecimy dalej?' : 'Spodobało się? To dopiero początek.',
                style: text.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        // While there are free plays left: the next one, one tap.
        if (next != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AkBrand.teal.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Następna darmowa zabawa',
                  style: text.labelLarge?.copyWith(color: AkBrand.tealDeep, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ContentCover(item: next, pack: catalog.pack(next.packId ?? ''), size: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            next.title,
                            style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${(next.durationSec / 60).ceil()} min · za darmo',
                            style: text.bodySmall?.copyWith(color: ink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: playNext,
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Text('Włącz następną'),
                ),
              ],
            ),
          ),
        ],
        if (anyLocked) ...[
          const SizedBox(height: 14),
          if (next != null)
            Text(
              'A gdy darmowe się skończą:',
              style: text.bodyMedium?.copyWith(color: ink, fontWeight: FontWeight.w700),
            )
          else if (lockedInPack.isNotEmpty)
            Text(
              'W pakiecie ${pack!.title} czeka jeszcze ${playsCount(lockedInPack.length)}. '
              'Darmowe zabawy już za Wami.',
              style: text.bodyMedium?.copyWith(color: ink),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Abonament: najwięcej za najmniej',
                        style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (savings != null && savings.saving > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '−${money(savings.saving)}',
                          style: text.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final line in [
                  subscriptionPromise,
                  'Nowy pakiet w cenie abonamentu, bez dopłat',
                  if (yearly?.rawPrice != null) 'Rocznie tylko ${money(yearly!.rawPrice! / 12)} miesięcznie',
                  if (yearly?.freeTrialDays != null) 'Pierwsze ${yearly!.freeTrialDays} dni za darmo',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18, color: ink),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(line, style: text.bodyMedium?.copyWith(color: ink)),
                        ),
                      ],
                    ),
                  ),
                if (savings != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CompareRow('Pakiety osobno dziś', money(savings.packsToday)),
                        _CompareRow(
                          'Do tego 12 nowych pakietów w roku',
                          money(savings.yearValue - savings.packsToday),
                        ),
                        _CompareRow('Razem kupując osobno', money(savings.yearValue), strong: true),
                        if (yearly != null) _CompareRow('Abonament roczny', yearly.price, strong: true),
                        const Divider(height: 14),
                        _CompareRow('Oszczędzacie w pierwszym roku', money(savings.saving), strong: true),
                        if (savings.vsMonthly > 0)
                          _CompareRow('Rocznie zamiast co miesiąc', '−${money(savings.vsMonthly)}'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (yearly != null)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ink,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: busy != null ? null : () => buyWithGate(context, ref, yearly),
                    child: busy == yearly.id
                        ? const _Spinner(color: Colors.white)
                        : Text('Rocznie ${yearly.price}'),
                  ),
                if (monthly != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ink,
                      side: const BorderSide(color: ink),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: busy != null ? null : () => buyWithGate(context, ref, monthly),
                    child: busy == monthly.id
                        ? const _Spinner(color: ink)
                        : Text('Miesięcznie ${monthly.price}'),
                  ),
                ],
                if (yearly == null && monthly == null)
                  Text(subscriptionPromise, style: text.bodySmall?.copyWith(color: ink)),
              ],
            ),
          ),
          if (pack != null && lockedInPack.isNotEmpty) ...[
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
                  ? const _Spinner(color: AkBrand.tealDeep)
                  : Text(
                      packProduct == null
                          ? 'Zobacz pakiet ${pack.title}'
                          : 'Odblokuj pakiet ${pack.title} · ${packProduct.price}',
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ],
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: const Color(0xFF211C35), fontWeight: strong ? FontWeight.w800 : FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color));
}
