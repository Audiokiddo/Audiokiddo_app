import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import '../insights/events.dart';

/// A promotion set in Studio (Mikołajki, Dzień Dziecka…), shown only while it runs.
@immutable
class Promotion {
  const Promotion({
    required this.id,
    required this.title,
    required this.body,
    required this.endsAt,
    this.badge,
    this.target,
  });

  final String id;
  final String title;
  final String body;
  final DateTime endsAt;
  final String? badge;

  /// A pack id, 'subscription', 'bundle' or null.
  final String? target;

  static Promotion? fromJson(Map<String, dynamic> j) {
    final ends = DateTime.tryParse('${j['ends_at']}');
    if (j['id'] is! String || j['title'] is! String || ends == null) return null;
    return Promotion(
      id: j['id'] as String,
      title: j['title'] as String,
      body: (j['body'] as String?) ?? '',
      endsAt: ends.toLocal(),
      badge: j['badge'] as String?,
      target: j['target'] as String?,
    );
  }
}

abstract interface class PromotionSource {
  Future<List<Promotion>> running();
}

class NoPromotions implements PromotionSource {
  const NoPromotions();

  @override
  Future<List<Promotion>> running() async => const [];
}

class SupabasePromotions implements PromotionSource {
  const SupabasePromotions(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Promotion>> running() async {
    try {
      // The table's policy returns only promotions running right now.
      final rows = await _client.from('promotions').select().order('ends_at').timeout(const Duration(seconds: 5));
      return [for (final r in rows) ?Promotion.fromJson(r)];
    } on Object {
      return const [];
    }
  }
}

final promotionSourceProvider = Provider<PromotionSource>((ref) => const NoPromotions());

final promotionsProvider = FutureProvider<List<Promotion>>((ref) => ref.watch(promotionSourceProvider).running());

/// "do 6 grudnia" or "jeszcze dziś".
String promotionDeadline(DateTime ends, DateTime now) {
  const months = [
    'stycznia',
    'lutego',
    'marca',
    'kwietnia',
    'maja',
    'czerwca',
    'lipca',
    'sierpnia',
    'września',
    'października',
    'listopada',
    'grudnia',
  ];
  if (ends.year == now.year && ends.month == now.month && ends.day == now.day) return 'tylko do dziś';
  return 'do ${ends.day} ${months[ends.month - 1]}';
}

/// The first running promotion as a banner (Start, Shop, a pack page when [target] matches).
class PromotionBanner extends ConsumerWidget {
  const PromotionBanner({super.key, this.target});

  /// Show only promotions for this pack (or general ones); null shows the first of any.
  final String? target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(promotionsProvider).value ?? const <Promotion>[];
    final promo = list.where((p) => target == null || p.target == null || p.target == target).firstOrNull;
    if (promo == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    final deadline = promotionDeadline(promo.endsAt, ref.watch(clockProvider)());
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: AkBrand.sun,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref.read(eventSinkProvider).track(AppEvent.promoTap, props: {'promo': promo.id});
            final t = promo.target;
            context.push(t == null || t == 'subscription' || t == 'bundle' ? '/abonament' : '/pakiet/$t');
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              children: [
                const SzopSticker(SzopPose.klaszcze, height: 56),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (promo.badge != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                promo.badge!,
                                style: text.labelSmall?.copyWith(color: AkBrand.sun, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              promo.title,
                              maxLines: 2,
                              style: text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      if (promo.body.isNotEmpty) Text(promo.body, style: text.bodySmall?.copyWith(color: ink)),
                      Text(
                        deadline,
                        style: text.labelSmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
