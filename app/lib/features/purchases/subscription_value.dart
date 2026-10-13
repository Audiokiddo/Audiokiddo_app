import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../about/about_screen.dart';
import '../family_sharing/parent_cloud.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import 'shop.dart';
import 'store_gateway.dart';

/// The subscription, said simply: one library for the whole family, monthly or yearly (with how
/// much the year saves), crossed-out prices next to the real ones and one big button. The main offer everywhere: Shop, the subscription
/// page, pack pages, the window after a free play.
class SubscriptionOffer extends ConsumerStatefulWidget {
  const SubscriptionOffer({super.key, required this.catalog, required this.byId, this.compact = false});

  final Catalog catalog;
  final Map<String, StoreProduct> byId;

  /// In the window after a free play: fewer lines.
  final bool compact;

  @override
  ConsumerState<SubscriptionOffer> createState() => _SubscriptionOfferState();
}

const _ink = Color(0xFF211C35);

class _SubscriptionOfferState extends ConsumerState<SubscriptionOffer> {
  // A/B test "paywall_period": which period is picked at first (yearly unless the test says).
  late bool _yearly = ref.read(experimentsProvider)['paywall_period'] != 'miesiecznie';

  StoreProduct? _product(SubscriptionPlan plan, {required bool yearly}) => widget.byId[plan.productId(yearly: yearly)];

  /// What a year costs when paid monthly, minus the yearly price.
  double? _saving(SubscriptionPlan plan) {
    final m = _product(plan, yearly: false)?.rawPrice;
    final y = _product(plan, yearly: true)?.rawPrice;
    return m == null || y == null || m * 12 <= y ? null : m * 12 - y;
  }

  int? _percent(SubscriptionPlan plan) {
    final m = _product(plan, yearly: false)?.rawPrice;
    final s = _saving(plan);
    return m == null || s == null ? null : (s / (m * 12) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final busy = ref.watch(purchaseControllerProvider).busyProductId;
    final plans = [
      for (final p in SubscriptionPlan.values)
        if (_product(p, yearly: true) != null || _product(p, yearly: false) != null) p,
    ];
    if (plans.isEmpty) {
      return _Card(
        children: [
          Text(
            'Abonament AudioKiddo',
            style: text.titleLarge?.copyWith(color: _ink, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text('Wszystkie zabawy teraz i jeden nowy pakiet co miesiąc.', style: text.bodyMedium?.copyWith(color: _ink)),
        ],
      );
    }
    final plan = plans.first;
    final hasYearly = _product(plan, yearly: true) != null;
    final yearly = _yearly && hasYearly;
    final product = _product(plan, yearly: yearly) ?? _product(plan, yearly: !yearly)!;
    final currency = product.currencyCode ?? 'PLN';
    String money(double v) => formatMoney(v, currency);
    final trial = product.freeTrialDays;
    final saving = _saving(plan);
    final lapsed = ref.watch(lapsedSubscriptionProvider);

    // A year of packs bought one by one: today's packs plus a new one every month.
    final packPrices = [for (final p in widget.catalog.packs) ?widget.byId[p.storeProductId]?.rawPrice];
    final packsYear = packPrices.isEmpty ? null : packPrices.fold(0.0, (a, b) => a + b) * (1 + 12 / packPrices.length);

    final String buttonLabel;
    if (lapsed != null && product.comebackPrice != null) {
      buttonLabel = 'Wracam: najpierw ${product.comebackPrice}';
    } else if (trial != null &&
        ref.watch(experimentsProvider)['paywall_cta'] == 'oszczednosc' &&
        yearly &&
        saving != null) {
      // A/B test "paywall_cta": the saving in the button instead of the trial.
      buttonLabel = 'Zacznij za darmo i oszczędzaj ${_round(saving, money)}';
    } else if (trial != null) {
      buttonLabel = 'Wypróbuj $trial dni za darmo';
    } else {
      buttonLabel = 'Wybieram ${yearly ? 'rocznie' : 'miesięcznie'} · ${product.price}';
    }

    return _Card(
      children: [
        // Shrinks a little on the narrowest phones instead of overflowing.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'NAJLEPIEJ SIĘ OPŁACA',
                style: text.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Abonament AudioKiddo',
          style: text.titleLarge?.copyWith(color: _ink, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        for (final line in [
          'Wszystkie zabawy od razu',
          'Nowy pakiet co miesiąc, bez dopłat',
          if (!widget.compact) 'Każde dziecko ze swoim planem i postępami',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: _ink),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(line, style: text.bodyMedium?.copyWith(color: _ink)),
                ),
              ],
            ),
          ),
        if (plans.any((p) => _product(p, yearly: true) != null && _product(p, yearly: false) != null)) ...[
          const SizedBox(height: 14),
          _PeriodSwitch(
            yearly: yearly,
            saving: saving == null ? null : 'oszczędzasz ${_round(saving, money)}',
            onChanged: (v) => setState(() => _yearly = v),
          ),
        ],
        const SizedBox(height: 12),
        _PlanTile(
          plan: plan,
          yearly: yearly,
          monthly: _product(plan, yearly: false),
          yearlyProduct: _product(plan, yearly: true),
          percent: _percent(plan),
          money: money,
        ),
        if (!widget.compact && yearly && packsYear != null && true) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Text.rich(
              TextSpan(
                style: text.bodyMedium?.copyWith(color: _ink),
                children: [
                  const TextSpan(text: 'Pakiety osobno przez rok: '),
                  TextSpan(
                    text: 'ok. ${money(packsYear)}',
                    style: const TextStyle(decoration: TextDecoration.lineThrough, decorationThickness: 2),
                  ),
                  const TextSpan(text: '  →  '),
                  TextSpan(
                    text: product.price,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _ink,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
          ),
          onPressed: busy != null ? null : () => buyWithGate(context, ref, product),
          child: busy == product.id
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : FittedBox(fit: BoxFit.scaleDown, child: Text(buttonLabel)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              if (trial != null) 'Potem ${product.price} za ${yearly ? 'rok' : 'miesiąc'}.',
              'Zrezygnujesz w dowolnej chwili.',
            ].join(' '),
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: _ink),
          ),
        ),
        // Who the money goes to: a Polish couple who make every play themselves.
        const SizedBox(height: 10),
        const PolishBrandLine(color: _ink, center: true),
      ],
    );
  }

  /// 5.00 → "5 zł", 4.5 → "4,50 zł".
  static String _round(double v, String Function(double) money) {
    final rounded = (v * 100).round() / 100;
    final s = money(rounded);
    return rounded == rounded.roundToDouble() ? s.replaceAll(RegExp(r',00'), '') : s;
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    // Lavender, not the sun: the yellow belongs to the "carry on" card above the bottom bar.
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF1E9F8), Color(0xFFDCCBEB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

/// Miesięcznie | Rocznie, with a little cloud over the year: how much it saves.
class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.yearly, required this.onChanged, this.saving});

  final bool yearly;
  final String? saving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget segment(String label, bool value) => Expanded(
      child: Semantics(
        selected: yearly == value,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: yearly == value ? _ink : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: text.titleSmall?.copyWith(
                color: yearly == value ? Colors.white : _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: saving == null ? 0 : 22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(children: [segment('Miesięcznie', false), segment('Rocznie', true)]),
          ),
          if (saving != null) Positioned(right: 8, top: -24, child: _Cloud(text: saving!)),
        ],
      ),
    );
  }
}

/// A speech-bubble cloud pointing down at "Rocznie".
class _Cloud extends StatelessWidget {
  const _Cloud({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AkBrand.terracotta,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 22),
        child: CustomPaint(size: const Size(12, 6), painter: _TailPainter(AkBrand.terracotta)),
      ),
    ],
  );
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close(),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

/// The plan and its price (the year crossed out against 12 months).
class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.yearly,
    required this.monthly,
    required this.yearlyProduct,
    required this.percent,
    required this.money,
  });

  final SubscriptionPlan plan;
  final bool yearly;
  final StoreProduct? monthly, yearlyProduct;
  final int? percent;
  final String Function(double) money;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final y = yearlyProduct?.rawPrice;
    final m = monthly?.rawPrice;
    final showYear = yearly && yearlyProduct != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ink, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            plan.label,
                            style: text.titleMedium?.copyWith(color: _ink, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (showYear)
                        Text.rich(
                          TextSpan(
                            style: text.bodyMedium?.copyWith(color: _ink),
                            children: [
                              if (m != null) ...[
                                TextSpan(
                                  text: money(m * 12),
                                  style: TextStyle(
                                    color: _ink.withValues(alpha: .55),
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 2,
                                  ),
                                ),
                                const TextSpan(text: '  '),
                              ],
                              TextSpan(
                                text: '${yearlyProduct!.price} / rok',
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                              if (y != null) TextSpan(text: '\n= ${money(y / 12)} miesięcznie'),
                            ],
                          ),
                        )
                      else if (monthly != null)
                        Text(
                          '${monthly!.price} / miesiąc',
                          style: text.bodyMedium?.copyWith(color: _ink, fontWeight: FontWeight.w900),
                        ),
                    ],
                  ),
                ),
                if (showYear && percent != null && percent! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AkBrand.terracotta, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '-$percent%',
                      style: text.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
              ],
            ),
      ),
    );
  }
}
