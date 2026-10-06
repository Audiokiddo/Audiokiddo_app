import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart';
import 'shop.dart';

/// For a family whose subscription ended: no guilt, what is new since then, one way back.
/// On Start with a button to the plans; in the Shop above the offer, without it.
class WinBackCard extends ConsumerWidget {
  const WinBackCard({super.key, this.withButton = true});

  final bool withButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final since = ref.watch(lapsedSubscriptionProvider);
    final catalog = ref.watch(catalogProvider).value;
    if (since == null || catalog == null) return const SizedBox.shrink();
    final fresh = releasedSince(catalog, since);
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AkBrand.peach, borderRadius: BorderRadius.circular(22)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SzopSticker(SzopPose.prosi, height: 72),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wracacie? Wszystko na Was czeka',
                  style: text.titleMedium?.copyWith(color: AkBrand.cocoa, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  fresh.isEmpty
                      ? 'Plan, ulubione i postępy zostały. Abonament otworzy znowu wszystkie zabawy.'
                      : 'Od Waszej przerwy doszło ${fresh.length} ${fresh.length == 1 ? 'nowa zabawa' : 'nowych zabaw'}: '
                            '${fresh.take(2).map((i) => '„${i.title}”').join(', ')}${fresh.length > 2 ? ' i inne' : ''}.',
                  style: text.bodyMedium?.copyWith(color: AkBrand.cocoa),
                ),
                if (withButton) ...[
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AkBrand.cocoa, foregroundColor: Colors.white),
                    onPressed: () => context.push('/abonament'),
                    child: const Text('Wróć do abonamentu'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
