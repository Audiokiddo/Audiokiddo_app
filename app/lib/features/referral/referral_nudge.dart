import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/theme/tokens.dart';
import '../family/family.dart';
import '../catalog/catalog_providers.dart' show clockProvider;
import 'referral_screen.dart';

const _hiddenKey = 'referral_nudge_hidden_until';

/// Until when the parent hid the nudge (null: not hidden).
final referralNudgeHiddenProvider = FutureProvider<DateTime?>(
  (ref) async => DateTime.tryParse(await ref.watch(databaseProvider).readValue(_hiddenKey) ?? ''),
);

/// From the second finished play on, unless the parent hid it and that time has not passed.
bool showReferralNudge({required int finishedPlays, required DateTime? hiddenUntil, required DateTime now}) =>
    finishedPlays >= 2 && !(hiddenUntil?.isAfter(now) ?? false);

/// After a finished play, when the family is happy: one quiet line to recommend AudioKiddo.
/// From the second finished play on, closable for 30 days. Opens the referral screen, whose
/// sharing is behind the parental gate.
class ReferralNudge extends ConsumerWidget {
  const ReferralNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finished = ref.watch(familyProvider).value?.results.length ?? 0;
    final hidden = ref.watch(referralNudgeHiddenProvider);
    final now = ref.watch(clockProvider)();
    if (!hidden.hasValue || !showReferralNudge(finishedPlays: finished, hiddenUntil: hidden.value, now: now)) {
      return const SizedBox.shrink();
    }
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/polec'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: AkBrand.sun),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Spodobało się? Poleć znajomym: oni mają $referralFriendGift, Ty $referralParentGift.',
                    style: text.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Nie teraz',
                  onPressed: () async {
                    await ref
                        .read(databaseProvider)
                        .writeValue(_hiddenKey, now.add(const Duration(days: 30)).toIso8601String());
                    ref.invalidate(referralNudgeHiddenProvider);
                  },
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
