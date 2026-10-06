import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../about/about_screen.dart';
import '../family/family.dart';
import '../family_sharing/parent_cloud.dart';
import 'offer_catalog.dart';
import 'purchase_controller.dart';
import 'shop.dart';
import 'store_gateway.dart';

/// The subscription, said simply: monthly or yearly (with how much the year saves), a plan
/// for the number of children (the second +5 zł, the family +10 zł), crossed-out prices next
/// to the real ones and one big button. The main offer everywhere: Shop, the subscription
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
  SubscriptionPlan? _plan;

  StoreProduct? _product(SubscriptionPlan plan, {required bool yearly}) =>
      widget.byId[plan.productId(yearly: yearly)];

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
          Text('Abonament AudioKiddo', style: text.titleLarge?.copyWith(color: _ink, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Wszystkie zabawy teraz i jeden nowy pakiet co miesiąc.', style: text.bodyMedium?.copyWith(color: _ink)),
        ],
      );
    }
    // The plan for the children the family already has, unless the parent picked one.
    final children = ref.watch(familyProvider).value?.children.length ?? 1;
    final seats = ref.watch(childSeatsProvider);
    final suggested = SubscriptionPlan.forChildren(children < 1 ? 1 : children);
    final plan = _plan ?? (plans.contains(suggested) ? suggested : plans.first);
    final hasYearly = _product(plan, yearly: true) != null;
    final yearly = _yearly && hasYearly;
    final product = _product(plan, yearly: yearly) ?? _product(plan, yearly: !yearly)!;
    final currency = product.currencyCode ?? 'PLN';
    String money(double v) => formatMoney(v, currency);
    final trial = product.freeTrialDays;
    final saving = _saving(plan);
    final current = seats == null ? null : SubscriptionPlan.values.where((p) => p.children == seats).firstOrNull;
    final lapsed = ref.watch(lapsedSubscriptionProvider);

    // A year of packs bought one by one: today's packs plus a new one every month.
    final packPrices = [for (final p in widget.catalog.packs) ?widget.byId[p.storeProductId]?.rawPrice];
    final packsYear = packPrices.isEmpty ? null : packPrices.fold(0.0, (a, b) => a + b) * (1 + 12 / packPrices.length);

    final String buttonLabel;
    if (current == plan) {
      buttonLabel = 'To Twój plan';
    } else if (seats != null) {
      buttonLabel = 'Przechodzę na „${plan.label}” · ${product.price}';
    } else if (lapsed != null && product.comebackPrice != null) {
      buttonLabel = 'Wracam: najpierw ${product.comebackPrice}';
    } else if (trial != null && ref.watch(experimentsProvider)['paywall_cta'] == 'oszczednosc' && yearly && saving != null) {
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
        Text('Abonament AudioKiddo', style: text.titleLarge?.copyWith(color: _ink, fontWeight: FontWeight.w900)),
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
                Expanded(child: Text(line, style: text.bodyMedium?.copyWith(color: _ink))),
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
        for (final p in plans)
          _PlanTile(
            plan: p,
            selected: p == plan,
            current: p == current,
            yearly: yearly,
            monthly: _product(p, yearly: false),
            yearlyProduct: _product(p, yearly: true),
            extra: _extra(p, plans, money),
            percent: _percent(p),
            money: money,
            onTap: () => setState(() => _plan = p),
          ),
        if (plans.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              _rule(plans, money),
              style: text.bodySmall?.copyWith(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
        if (!widget.compact && yearly && packsYear != null && plan == SubscriptionPlan.solo) ...[
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
                  TextSpan(text: product.price, style: const TextStyle(fontWeight: FontWeight.w900)),
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
          onPressed: busy != null || current == plan ? null : () => buyWithGate(context, ref, product),
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
              if (trial != null && seats == null) 'Potem ${product.price} za ${yearly ? 'rok' : 'miesiąc'}.',
              if (seats != null && current != plan) 'Sklep przeliczy to, co już zapłaciłeś.',
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

  /// "+5 zł miesięcznie" against the one-child plan.
  String? _extra(SubscriptionPlan p, List<SubscriptionPlan> plans, String Function(double) money) {
    final base = _product(SubscriptionPlan.solo, yearly: false)?.rawPrice;
    final own = _product(p, yearly: false)?.rawPrice;
    if (p == SubscriptionPlan.solo || base == null || own == null || own <= base) return null;
    return '+${_round(own - base, money)} miesięcznie';
  }

  /// The rule a parent remembers: the second child +5 zł, the whole family +10 zł.
  String _rule(List<SubscriptionPlan> plans, String Function(double) money) {
    final base = _product(SubscriptionPlan.solo, yearly: false)?.rawPrice;
    String? diff(SubscriptionPlan p) {
      final own = _product(p, yearly: false)?.rawPrice;
      return base == null || own == null ? null : _round(own - base, money);
    }

    final duo = plans.contains(SubscriptionPlan.duo) ? diff(SubscriptionPlan.duo) : null;
    final family = plans.contains(SubscriptionPlan.family) ? diff(SubscriptionPlan.family) : null;
    final rule = [
      if (duo != null) 'Drugie dziecko +$duo',
      if (family != null) 'cała rodzina (do 5 dzieci) +$family',
    ].join(', ').replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase());
    return '$rule miesięcznie. W planach dla 2+ dzieci także konto drugiego rodzica.';
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
    decoration: BoxDecoration(color: AkBrand.sun, borderRadius: BorderRadius.circular(24)),
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
          if (saving != null)
            Positioned(
              right: 8,
              top: -24,
              child: _Cloud(text: saving!),
            ),
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

/// One plan: who it covers, what it adds, the price (the year crossed out against 12 months).
class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.current,
    required this.yearly,
    required this.monthly,
    required this.yearlyProduct,
    required this.extra,
    required this.percent,
    required this.money,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected, current, yearly;
  final StoreProduct? monthly, yearlyProduct;
  final String? extra;
  final int? percent;
  final String Function(double) money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final y = yearlyProduct?.rawPrice;
    final m = monthly?.rawPrice;
    final showYear = yearly && yearlyProduct != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.white.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? _ink : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: _ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(plan.label, style: text.titleMedium?.copyWith(color: _ink, fontWeight: FontWeight.w900)),
                          if (current)
                            Text('Twój plan', style: text.labelSmall?.copyWith(color: _ink, fontWeight: FontWeight.w800)),
                          if (!current && extra != null)
                            Text(extra!, style: text.labelMedium?.copyWith(color: _ink.withValues(alpha: .7))),
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
        ),
      ),
    );
  }
}
