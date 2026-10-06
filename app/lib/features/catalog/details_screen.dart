import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../purchases/preview_player.dart';
import 'widgets/item_art.dart';
import '../purchases/shop.dart';
import '../../core/format.dart';
import '../downloads/download_button.dart';
import '../games/game_controller.dart';
import '../discovery/reference_widgets.dart';
import '../games/microphone.dart';
import '../games/speech.dart';
import '../parental_gate/parental_gate.dart';
import '../pdf/case_files_card.dart';
import '../pdf/pdf_screen.dart';
import '../personal/personal_repository.dart';
import '../player/playback_controller.dart';
import 'catalog_providers.dart';
import 'widgets/catalog_loader.dart';
import '../discovery/discovery_model.dart';
import '../discovery/queue_controller.dart';
import '../home/quick_pick.dart' show startItem;
import 'widgets/labels.dart';
import '../../core/router.dart';
import '../insights/events.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key, required this.itemId, this.autoplay = false});

  final String itemId;

  /// Opened from the home-screen widget (`?graj=1`): starts at once when the family can play it.
  final bool autoplay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [_FavoriteButton(itemId: itemId)]),
      body: CatalogLoader(
        builder: (context, catalog) {
          final item = catalog.item(itemId);
          if (item == null) return Center(child: Text(AppLocalizations.of(context).notFound));
          final content = _DetailsContent(item: item, pack: item.packId == null ? null : catalog.pack(item.packId!));
          return autoplay ? _AutoPlay(item: item, child: content) : content;
        },
      ),
    );
  }
}

/// Starts [item] once, right after the screen appears (from the widget's one-tap start).
class _AutoPlay extends ConsumerStatefulWidget {
  const _AutoPlay({required this.item, required this.child});

  final ContentItem item;
  final Widget child;

  @override
  ConsumerState<_AutoPlay> createState() => _AutoPlayState();
}

class _AutoPlayState extends ConsumerState<_AutoPlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(canPlayProvider(widget.item))) unawaited(startItem(context, widget.item));
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _DetailsContent extends ConsumerWidget {
  const _DetailsContent({required this.item, this.pack});

  final ContentItem item;
  final Pack? pack;

  Future<void> _listen(BuildContext context, WidgetRef ref, {bool fromStart = false}) async {
    if (item.kind == ContentKind.interactiveGame) {
      unawaited(ref.read(gameControllerProvider.notifier).start(item, resume: !fromStart));
      await context.push('/gra');
      ref.invalidate(gameResumeProvider(item));
      return;
    }
    try {
      await ref
          .read(playbackControllerProvider)
          .start(item, album: pack?.title ?? AppLocalizations.of(context).kind(item.kind), fromStart: fromStart);
      if (context.mounted) await context.push('/odtwarzacz');
    } on Exception {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).playbackUnavailable)));
      }
    }
  }

  // The offer itself asks for an adult before any purchase (buyWithGate).
  Future<void> _unlock(BuildContext context, WidgetRef ref) async {
    ref.read(eventSinkProvider).track(AppEvent.paywallView, itemId: item.id);
    await context.push('/oferta?zabawa=${item.id}');
  }

  Future<void> _openPdf(BuildContext context, AssetRef asset) async {
    await Navigator.of(context).push(
      swipeRoute<void>(
        builder: (_) => PdfScreen(asset: asset, title: item.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final access = ref.watch(itemAccessProvider(item));
    final canPlay = access == ItemAccess.playable;
    final isGame = item.kind == ContentKind.interactiveGame;
    final gameSaved = isGame && (ref.watch(gameResumeProvider(item)).value ?? false);
    final resumeAt = resumePosition(ref.watch(progressProvider(item.id)).value);
    final players = l10n.playerCount(item);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.xl),
      children: [
        ItemHeaderArt(item: item),
        const SizedBox(height: AkSpace.l),
        Text(pack?.title ?? l10n.kind(item.kind), style: text.labelLarge?.copyWith(color: palette.inkMuted)),
        Text(item.title, style: text.headlineMedium),
        if (item.subtitle != null) Text(item.subtitle!, style: text.titleMedium),
        const SizedBox(height: AkSpace.m),
        MetaStrip(item: item),
        if (players != null || item.isFree) ...[
          const SizedBox(height: AkSpace.s),
          Wrap(
            spacing: AkSpace.s,
            runSpacing: AkSpace.s,
            children: [
              if (players != null) _Meta(icon: Icons.group_rounded, label: players),
              if (item.isFree) _Meta(icon: Icons.card_giftcard_rounded, label: l10n.free),
            ],
          ),
        ],
        const SizedBox(height: AkSpace.m),
        Text(item.parentDescription, style: text.bodyMedium),
        const SizedBox(height: AkSpace.l),
        ...switch (access) {
          ItemAccess.playable => [
            if (gameSaved) ...[
              FilledButton.icon(
                onPressed: () => _listen(context, ref),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.resumeGame),
              ),
              TextButton(onPressed: () => _listen(context, ref, fromStart: true), child: Text(l10n.startOver)),
            ] else if (!isGame && resumeAt > Duration.zero) ...[
              FilledButton.icon(
                onPressed: () => _listen(context, ref),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.resumeFrom(formatClock(resumeAt))),
              ),
              TextButton(onPressed: () => _listen(context, ref, fromStart: true), child: Text(l10n.startOver)),
            ] else
              FilledButton.icon(
                onPressed: () => _listen(context, ref),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(item.kind == ContentKind.interactiveGame ? l10n.playGame : l10n.listen),
              ),
            const SizedBox(height: AkSpace.m),
            DownloadControl(item: item),
            if (!isGame)
              TextButton.icon(
                onPressed: ref.watch(queueRunnerProvider).running
                    ? null
                    : () async {
                        await ref.read(discoveryProvider.notifier).add(item.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Dodano do kolejki'),
                              action: SnackBarAction(label: 'Otwórz', onPressed: () => context.push('/kolejka')),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Dodaj do kolejki'),
              ),
          ],
          ItemAccess.needsRefresh => [
            FilledButton.icon(onPressed: null, icon: const Icon(Icons.wifi_off_rounded), label: Text(l10n.listen)),
            const SizedBox(height: AkSpace.s),
            Text(l10n.needsRefresh, style: text.bodyMedium),
          ],
          ItemAccess.locked => [
            if (item.preview != null) ...[PreviewButton(item: item, wide: true), const SizedBox(height: AkSpace.s)],
            FilledButton.icon(
              onPressed: () => _unlock(context, ref),
              icon: const Icon(Icons.lock_open_rounded),
              label: Text(l10n.unlock),
            ),
            if (pack != null)
              TextButton(
                onPressed: () => openPack(context, pack!.id),
                child: Text('Zobacz cały pakiet ${pack!.title}'),
              ),
          ],
        },
        const SizedBox(height: AkSpace.l),
        // Detektyw: the case file right under the play button, with Szop’en saying what is in it.
        if (item.pdf.isNotEmpty && canPlay && pack?.id == 'detektyw') ...[
          CaseFileCard(item: item),
          const SizedBox(height: AkSpace.l),
        ],
        if (item.skills.isNotEmpty)
          _Section(
            title: l10n.detailsPractises,
            child: Wrap(
              spacing: AkSpace.s,
              runSpacing: AkSpace.s,
              children: [for (final s in item.skills) Chip(label: Text(s))],
            ),
          ),
        if (item.script case final script? when scriptListensToSound(script))
          _Section(
            title: AppLocalizations.of(context).micTitle,
            child: _MicrophoneCard(words: scriptListensToWords(script)),
          ),
        if (item.pdf.isNotEmpty && canPlay && pack?.id != 'detektyw')
          _Section(
            title: l10n.pdfSection,
            child: OutlinedButton.icon(
              onPressed: () => _openPdf(context, item.pdf.first),
              icon: const Icon(Icons.print_rounded),
              label: Text(l10n.pdfOpen),
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
        SimilarPlays(item: item),
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

/// Parent zone: lets games hear claps and voice. The system prompt appears only after the
/// parental gate (ARCHITECTURE §12).
class _MicrophoneCard extends ConsumerWidget {
  const _MicrophoneCard({required this.words});

  /// The game can also be answered with words.
  final bool words;

  Future<void> _enable(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await showParentalGate(context)) return;
    final granted = await ref.read(microphoneSettingsProvider.notifier).enable(words: words);
    ref.invalidate(speechReadyProvider);
    if (!granted) messenger.showSnackBar(SnackBar(content: Text(l10n.micDenied)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(microphoneSettingsProvider).value ?? false;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(on ? l10n.micOnBody : l10n.micOffBody, style: text.bodyMedium),
        if (words) ...[
          const SizedBox(height: AkSpace.xs),
          Text(switch ((on, ref.watch(speechReadyProvider).value)) {
            _ when !ref.watch(speechInputProvider).supported =>
              'W tej zabawie można odpowiadać słowami, ale na tym telefonie dziecko odpowie klaśnięciem.',
            (true, true) => 'W tej zabawie dziecko może też odpowiadać słowami. Rozpoznaje je sam telefon.',
            (true, _) =>
              'W tej zabawie dziecko może odpowiadać słowami, ale ten telefon ich teraz nie rozpozna '
                  '(brak zgody na rozpoznawanie mowy albo polskiego bez internetu). Zabawa zapyta wtedy '
                  'o klaśnięcia.',
            _ =>
              'W tej zabawie dziecko może też odpowiadać słowami, np. „w lewo”. Słowa rozpoznaje sam '
                  'telefon, bez internetu.',
          }, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
          if (on && ref.watch(speechInputProvider).supported && ref.watch(speechReadyProvider).value == false)
            TextButton(onPressed: () => _enable(context, ref), child: const Text('Pozwól rozpoznawać słowa')),
          if (ref.watch(speechInputProvider).supported)
            TextButton.icon(
              onPressed: () => context.push('/mowa'),
              icon: const Icon(Icons.record_voice_over_rounded),
              label: const Text('Sprawdź, czy telefon rozumie słowa'),
            ),
        ],
        if (!on) ...[
          const SizedBox(height: AkSpace.xs),
          Text(l10n.micWithout, style: text.bodySmall?.copyWith(color: context.palette.inkMuted)),
        ],
        const SizedBox(height: AkSpace.s),
        on
            ? TextButton(
                onPressed: () => ref.read(microphoneSettingsProvider.notifier).disable(),
                child: Text(l10n.micDisable),
              )
            : OutlinedButton.icon(
                onPressed: () => _enable(context, ref),
                icon: const Icon(Icons.mic_rounded),
                label: Text(l10n.micEnable),
              ),
      ],
    );
  }
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

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorite = ref.watch(favoritesProvider).value?.contains(itemId) ?? false;
    return IconButton(
      tooltip: favorite ? l10n.favoriteRemove : l10n.favoriteAdd,
      isSelected: favorite,
      icon: const Icon(Icons.favorite_border_rounded),
      selectedIcon: Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.error),
      onPressed: () => ref.read(personalRepositoryProvider).setFavorite(itemId, favorite: !favorite),
    );
  }
}
