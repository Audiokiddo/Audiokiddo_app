import 'dart:async';
import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/szop.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/content_cover.dart';
import '../catalog/widgets/labels.dart';
import '../discovery/queue_controller.dart';
import '../family/family.dart' hide progressProvider;
import '../games/game_controller.dart';
import '../insights/events.dart';
import '../personal/personal_repository.dart';
import '../player/bottom_dock.dart' show resumeCardProvider;
import '../player/playback_controller.dart';

/// "Co teraz?": how much time you have, and Szop’en draws a run of plays that fits it.
const pickMinutes = [15, 30, 45, 60];

/// A run of plays for [minutes] at the child's [age]: audio plays only (the ones that keep a
/// child busy and make parents happy), plays the family has not heard first, shuffled by
/// [seed] ("Wylosuj inne"). In the [car] nothing that needs paper, a printout, room to move
/// or the phone's microphone. [skip] is the unfinished play shown separately.
List<ContentItem> pickPlaylist(
  Catalog catalog, {
  required int minutes,
  required int age,
  required bool Function(ContentItem) canPlay,
  bool car = false,
  Set<String> heard = const {},
  int seed = 0,
  String? skip,
}) {
  final candidates = [
    for (final i in catalog.items)
      if (i.kind == ContentKind.audioGame &&
          i.audio.isNotEmpty &&
          i.ageMin <= age &&
          (i.ageMax == null || age <= i.ageMax!) &&
          i.id != skip &&
          canPlay(i) &&
          !(car && i.requirements.isNotEmpty))
        i,
  ];
  final random = math.Random(seed);
  final fresh = [
    for (final i in candidates)
      if (!heard.contains(i.id)) i,
  ]..shuffle(random);
  final known = [
    for (final i in candidates)
      if (heard.contains(i.id)) i,
  ]..shuffle(random);
  // A minute over is fine (nobody stops a play halfway); more is not.
  final budget = minutes * 60 + 60;
  var total = 0;
  final run = <ContentItem>[];
  for (final i in [...fresh, ...known]) {
    if (total + i.durationSec > budget) continue;
    run.add(i);
    total += i.durationSec;
  }
  return run;
}

/// Starts [item] the same way the details screen does (game screen or player). [context]
/// must outlive the sheet that asked for it (the screen that opened the sheet).
Future<void> startItem(BuildContext context, ContentItem item) async {
  final container = ProviderScope.containerOf(context, listen: false);
  if (item.kind == ContentKind.interactiveGame) {
    unawaited(container.read(gameControllerProvider.notifier).start(item));
    await context.push('/gra');
    return;
  }
  try {
    await container.read(playbackControllerProvider).start(item, album: 'AudioKiddo');
    if (context.mounted) await context.push('/odtwarzacz');
  } on Exception {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).playbackUnavailable)));
    }
  }
}

Future<void> showQuickPick(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  // Above the tab bar, not inside the tab.
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _QuickPickSheet(host: context),
);

class _QuickPickSheet extends ConsumerStatefulWidget {
  const _QuickPickSheet({required this.host});

  /// The screen under the sheet: it starts playback after the sheet is gone.
  final BuildContext host;

  @override
  ConsumerState<_QuickPickSheet> createState() => _QuickPickSheetState();
}

class _QuickPickSheetState extends ConsumerState<_QuickPickSheet> {
  int _minutes = 30;
  bool _car = false;
  int _seed = DateTime.now().millisecondsSinceEpoch;

  /// Closes the sheet, then acts from the screen below.
  void _go(Future<Object?> Function() action, {int plays = 1}) {
    ref.read(eventSinkProvider).track(AppEvent.quickPick, props: {'minutes': _minutes, 'car': _car, 'plays': plays});
    Navigator.of(context).pop();
    unawaited(action());
  }

  Future<void> _playAll(List<ContentItem> run) async {
    await ref.read(queueRunnerProvider.notifier).start(run);
    if (widget.host.mounted) await widget.host.push('/odtwarzacz');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final palette = context.palette;
    final catalog = ref.watch(catalogProvider).value;
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final age = child?.age ?? 6;
    final resume = ref.watch(resumeCardProvider);
    final heard = {
      ...?ref.watch(recentProvider).value,
      for (final r in family?.results ?? const <ActivityResult>[]) r.itemId,
    };
    final run = catalog == null
        ? const <ContentItem>[]
        : pickPlaylist(
            catalog,
            minutes: _minutes,
            age: age,
            car: _car,
            heard: heard,
            seed: _seed,
            skip: resume?.item?.id ?? resume?.mediaId,
            canPlay: (i) => ref.watch(canPlayProvider(i)),
          );
    final total = run.fold(0, (s, i) => s + i.durationSec) ~/ 60;
    // What a subscription would add to the draw (same age and car rules).
    final lockedMore = catalog == null
        ? 0
        : pickPlaylist(
            catalog,
            minutes: 100000,
            age: age,
            car: _car,
            canPlay: (_) => true,
          ).where((i) => !ref.watch(canPlayProvider(i))).length;
    const ink = Color(0xFF211C35);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SzopSticker(SzopPose.chytry, height: 64),
                const SizedBox(width: AkSpace.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Co teraz?', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        child == null || child.name.isEmpty
                            ? 'Losuję zabawy dla $age-latka'
                            : 'Losuję zabawy dla: ${child.name}, $age l.',
                        style: text.bodyMedium?.copyWith(color: palette.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Last time's unfinished play comes first.
            if (resume != null) ...[
              const SizedBox(height: AkSpace.m),
              Material(
                color: AkBrand.sun,
                borderRadius: BorderRadius.circular(18),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  leading: const Icon(Icons.history_rounded, color: ink, size: 32),
                  title: Text(
                    resume.loaded ? 'Wróćcie do: ${resume.title}' : 'Do dokończenia: ${resume.title}',
                    style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text('Ostatnim razem nie dosłuchaliście do końca', style: TextStyle(color: ink)),
                  trailing: const Icon(Icons.play_circle_fill_rounded, color: ink, size: 34),
                  onTap: () => _go(
                    () => resume.loaded
                        ? widget.host.push(resume.mediaId!.startsWith(gameMediaPrefix) ? '/gra' : '/odtwarzacz')
                        : startItem(widget.host, resume.item!),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AkSpace.m),
            Text('Ile macie czasu?', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AkSpace.xs),
            Wrap(
              spacing: AkSpace.s,
              runSpacing: AkSpace.s,
              children: [
                for (final m in pickMinutes)
                  ChoiceChip(
                    label: Text('$m min'),
                    selected: m == _minutes,
                    showCheckmark: false,
                    labelStyle: selectableChipLabel(context, selected: m == _minutes),
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
              ],
            ),
            const SizedBox(height: AkSpace.s),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.directions_car_rounded, color: _car ? AkBrand.orange : palette.inkMuted),
              title: const Text('Jedziemy autem'),
              subtitle: const Text('Bez zabaw z kartką, wydrukiem, ruchem i mikrofonem'),
              value: _car,
              onChanged: (v) => setState(() => _car = v),
            ),
            const SizedBox(height: AkSpace.s),
            Row(
              children: [
                Expanded(
                  child: Text(
                    run.isEmpty ? 'Kolejność zabaw' : 'Kolejność zabaw · razem $total min',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _seed++),
                  icon: const Icon(Icons.casino_rounded),
                  label: const Text('Wylosuj inne'),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(a),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey((_seed, _minutes, _car, run.length)),
                children: [
                  if (run.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AkSpace.m),
                      child: Text(l10n.pickNothing, style: text.bodyLarge),
                    ),
                  for (final (n, item) in run.indexed)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text('${n + 1}.', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          ),
                          ContentCover(item: item, pack: catalog!.pack(item.packId ?? ''), size: 48),
                        ],
                      ),
                      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        heard.contains(item.id)
                            ? l10n.duration(item.durationSec)
                            : '${l10n.duration(item.durationSec)} · nowa dla Was',
                      ),
                      trailing: const Icon(Icons.play_circle_outline_rounded),
                      onTap: () => _go(() => startItem(widget.host, item)),
                    ),
                ],
              ),
            ),
            if (lockedMore > 0)
              Padding(
                padding: const EdgeInsets.only(top: AkSpace.xs),
                child: TextButton.icon(
                  onPressed: () => _go(() async => widget.host.push('/abonament')),
                  icon: const Icon(Icons.lock_open_rounded),
                  label: Text('Z abonamentem Szop’en ma do wyboru $lockedMore zabaw więcej'),
                ),
              ),
            if (run.isNotEmpty) ...[
              const SizedBox(height: AkSpace.m),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                onPressed: () => _go(() => _playAll(run), plays: run.length),
                icon: const Icon(Icons.play_arrow_rounded, size: 30),
                label: Text(run.length == 1 ? 'Włącz' : 'Włącz po kolei (${run.length})'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
