import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../player/player_providers.dart';
import 'catalog_providers.dart';
import 'widgets/catalog_loader.dart';
import 'widgets/content_cover.dart';
import 'widgets/labels.dart';

/// Until real recordings are delivered every item plays this tone (Etap 1 background-audio check).
const devToneAsset = 'assets/dev/test_tone_90s.m4a';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: CatalogLoader(
        builder: (context, catalog) {
          final item = catalog.item(itemId);
          if (item == null) return Center(child: Text(AppLocalizations.of(context).notFound));
          return _DetailsContent(item: item, pack: item.packId == null ? null : catalog.pack(item.packId!));
        },
      ),
    );
  }
}

class _DetailsContent extends ConsumerWidget {
  const _DetailsContent({required this.item, this.pack});

  final ContentItem item;
  final Pack? pack;

  Future<void> _listen(BuildContext context, WidgetRef ref) async {
    final handler = ref.read(audioHandlerProvider);
    await handler.playAsset(
      MediaItem(id: item.id, title: item.title, album: pack?.title ?? 'AudioKiddo'),
      devToneAsset,
    );
    if (context.mounted) await context.push('/odtwarzacz');
  }

  void _unlock(BuildContext context) {
    // TODO(Etap 3): paywall behind the parental gate.
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).unlockComingSoon)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final canPlay = ref.watch(canPlayProvider(item));
    final players = l10n.playerCount(item);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.xl),
      children: [
        Center(
          child: ContentCover(item: item, pack: pack, size: 220, locked: !canPlay),
        ),
        const SizedBox(height: AkSpace.l),
        Text(pack?.title ?? l10n.kind(item.kind), style: text.labelLarge?.copyWith(color: palette.inkMuted)),
        Text(item.title, style: text.headlineMedium),
        if (item.subtitle != null) Text(item.subtitle!, style: text.titleMedium),
        const SizedBox(height: AkSpace.m),
        Wrap(
          spacing: AkSpace.s,
          runSpacing: AkSpace.s,
          children: [
            _Meta(icon: Icons.schedule_rounded, label: l10n.duration(item.durationSec)),
            _Meta(icon: Icons.child_care_rounded, label: l10n.ageFrom(item.ageMin)),
            if (players != null) _Meta(icon: Icons.group_rounded, label: players),
            if (item.isFree) _Meta(icon: Icons.card_giftcard_rounded, label: l10n.free),
          ],
        ),
        const SizedBox(height: AkSpace.l),
        if (canPlay)
          FilledButton.icon(
            onPressed: () => _listen(context, ref),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.listen),
          )
        else
          FilledButton.icon(
            onPressed: () => _unlock(context),
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(l10n.unlock),
          ),
        const SizedBox(height: AkSpace.l),
        _Section(
          title: l10n.detailsForParent,
          child: Text(item.parentDescription, style: text.bodyLarge),
        ),
        if (item.skills.isNotEmpty)
          _Section(
            title: l10n.detailsPractises,
            child: Wrap(
              spacing: AkSpace.s,
              runSpacing: AkSpace.s,
              children: [for (final s in item.skills) Chip(label: Text(s))],
            ),
          ),
        if (item.requirements.isNotEmpty)
          _Section(
            title: l10n.detailsYouNeed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in item.requirements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AkSpace.xs),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 20, color: palette.primary),
                        const SizedBox(width: AkSpace.s),
                        Expanded(child: Text(l10n.requirement(r))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(avatar: Icon(icon, size: 18), label: Text(label));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AkSpace.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(height: AkSpace.s),
        child,
      ],
    ),
  );
}
