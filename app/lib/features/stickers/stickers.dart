import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../catalog/catalog_providers.dart' show clockProvider;
import '../family/family.dart';

/// Szop’en stickers a child collects by finishing plays: a reason to ask for "one more" and
/// to come back. Counted from the child's own results on the phone; nothing is sent.
const stickerAlbum = <(SzopPose, String)>[
  (SzopPose.zadowolony, 'Szop’en Zadowolony'),
  (SzopPose.nasluchuje, 'Szop’en Słuchacz'),
  (SzopPose.klaszcze, 'Szop’en Bijący Brawo'),
  (SzopPose.zdziwiony, 'Szop’en Zdziwiony'),
  (SzopPose.chytry, 'Szop’en Detektyw'),
  (SzopPose.prosi, 'Szop’en Proszący o Jeszcze'),
  (SzopPose.znudzony, 'Szop’en Na Kanapie'),
  (SzopPose.zmeczony, 'Szop’en Po Wielkiej Przygodzie'),
  (SzopPose.zestresowany, 'Szop’en Przed Zagadką'),
  (SzopPose.placze, 'Szop’en Wzruszony'),
];

/// After how many finished plays each sticker comes: quick at first, then rarer.
const stickerMilestones = [1, 2, 3, 5, 8, 12, 16, 20, 25, 30];

class StickerProgress {
  const StickerProgress({required this.finished, required this.justEarned});

  final int finished;

  /// The last finished play (in the last minutes) brought a sticker.
  final bool justEarned;

  int get unlocked => stickerMilestones.where((m) => m <= finished).length;
  bool get complete => unlocked == stickerAlbum.length;

  /// Plays still to finish for the next sticker, null when the album is full.
  int? get toNext => complete ? null : stickerMilestones[unlocked] - finished;
}

StickerProgress stickerProgress(List<ActivityResult> results, DateTime now) {
  final done = results.where((r) => r.completed).toList()..sort((a, b) => a.at.compareTo(b.at));
  final last = done.lastOrNull;
  return StickerProgress(
    finished: done.length,
    justEarned:
        last != null && stickerMilestones.contains(done.length) && now.difference(last.at) < const Duration(minutes: 10),
  );
}

final stickerProgressProvider = Provider<StickerProgress?>((ref) {
  final family = ref.watch(familyProvider).value;
  final child = family?.active;
  if (family == null || child == null) return null;
  return stickerProgress(family.resultsOf(child.id), ref.watch(clockProvider)());
});

/// "Nowa naklejka!" after the play that earned it.
class NewStickerCard extends ConsumerWidget {
  const NewStickerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(stickerProgressProvider);
    if (p == null || !p.justEarned) return const SizedBox.shrink();
    final (pose, name) = stickerAlbum[p.unlocked - 1];
    final text = Theme.of(context).textTheme;
    const ink = Color(0xFF211C35);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: AkBrand.sun,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push('/naklejki'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .3, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) => Transform.scale(scale: v, child: child),
                  child: SzopSticker(pose, height: 72),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nowa naklejka!', style: text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800)),
                      Text(name, style: text.bodyMedium?.copyWith(color: ink)),
                      Text(
                        '${p.unlocked} z ${stickerAlbum.length} w albumie',
                        style: text.bodySmall?.copyWith(color: ink),
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

/// The album: earned stickers in colour, the rest as shadows with how many plays to go.
class StickerAlbumScreen extends ConsumerWidget {
  const StickerAlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(stickerProgressProvider) ?? const StickerProgress(finished: 0, justEarned: false);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Album naklejek')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            p.complete
                ? 'Cały album! Szop’en jest pod wrażeniem.'
                : p.toNext == 1
                ? 'Jeszcze 1 zabawa do kolejnej naklejki.'
                : 'Jeszcze ${p.toNext} zabawy do kolejnej naklejki.',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text('Naklejka za ukończone zabawy: ${p.unlocked} z ${stickerAlbum.length}.', style: text.bodyMedium),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .85,
            children: [
              for (var i = 0; i < stickerAlbum.length; i++)
                _Slot(
                  pose: stickerAlbum[i].$1,
                  name: stickerAlbum[i].$2,
                  earned: i < p.unlocked,
                  after: stickerMilestones[i],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.pose, required this.name, required this.earned, required this.after});

  final SzopPose pose;
  final String name;
  final bool earned;
  final int after;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sticker = SzopSticker(pose, height: 96);
    return Semantics(
      label: earned ? 'Naklejka: $name' : 'Naklejka do zdobycia po $after zabawach',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: earned ? context.palette.surface : context.palette.surface.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: earned ? akSoftShadow(context) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            earned
                ? sticker
                : Opacity(
                    opacity: .25,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                      child: sticker,
                    ),
                  ),
            const SizedBox(height: 8),
            Text(
              earned ? name : 'Po $after zabawach',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(fontWeight: earned ? FontWeight.w700 : FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}
