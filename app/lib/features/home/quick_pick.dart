import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/content_cover.dart';
import '../catalog/widgets/labels.dart';
import '../family/family.dart';
import '../games/game_controller.dart';
import '../player/playback_controller.dart';
import '../player/player_providers.dart';
import 'today.dart';

/// "Mam chwilę": three taps (where, how long, mood) and one activity to start. Parents
/// should not have to browse a catalogue in a waiting room.
enum PickPlace { home, car, out, bed }

enum PickMood { move, calm }

const pickMinutes = [5, 10, 20];

/// Best matches first (at most [limit]). Only what the family may play, at the child's age;
/// no answering games in the car (nobody should reach for the phone) or in bed.
List<ContentItem> quickPick(
  Catalog catalog, {
  required PickPlace place,
  required int minutes,
  required PickMood mood,
  required int age,
  required bool Function(ContentItem) canPlay,
  Set<String> playedToday = const {},
  int limit = 3,
}) {
  final situation = switch (place) {
    PickPlace.home => Situation.wDomu,
    PickPlace.car => Situation.podroz,
    PickPlace.out => Situation.czekanie,
    PickPlace.bed => Situation.przedSnem,
  };
  double score(ContentItem i) {
    var s = 0.0;
    if (i.situations.contains(situation)) s += 5;
    final over = i.durationSec - minutes * 60;
    s += over <= 0 ? 3 : -over / 60;
    final calm = i.situations.contains(Situation.przedSnem) || i.kind == ContentKind.song;
    if (mood == PickMood.calm && calm) s += 2;
    if (mood == PickMood.move && (i.kind == ContentKind.interactiveGame || i.skills.contains('ruch'))) s += 2;
    // Asking again means "something else": today's activities drop well down.
    if (playedToday.contains(i.id)) s -= 4;
    return s;
  }

  final noGames = place == PickPlace.car || place == PickPlace.bed;
  final candidates = [
    for (final i in catalog.items)
      if (i.ageMin <= age &&
          canPlay(i) &&
          (i.audio.isNotEmpty || i.script != null) &&
          !(noGames && i.kind == ContentKind.interactiveGame))
        i,
  ]..sort((a, b) => score(b).compareTo(score(a)));
  return candidates.take(limit).toList();
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
  late PickPlace _place;
  late PickMood _mood;
  int _minutes = 10;

  @override
  void initState() {
    super.initState();
    // A guess from the time of day; one tap changes it.
    final part = dayPartOf(ref.read(clockProvider)());
    _place = switch (part) {
      DayPart.evening => PickPlace.bed,
      DayPart.afternoon => PickPlace.car,
      _ => PickPlace.home,
    };
    _mood = part == DayPart.evening ? PickMood.calm : PickMood.move;
  }

  /// Closes the sheet, then acts from the screen below.
  void _go(Future<Object?> Function() action) {
    Navigator.of(context).pop();
    unawaited(action());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final catalog = ref.watch(catalogProvider).value;
    final family = ref.watch(familyProvider).value;
    final child = family?.active;
    final now = ref.watch(clockProvider)();
    final playedToday = {
      for (final r in child == null ? const <ActivityResult>[] : family!.resultsOf(child.id))
        if (r.at.year == now.year && r.at.month == now.month && r.at.day == now.day) r.itemId,
    };
    final picks = catalog == null
        ? const <ContentItem>[]
        : quickPick(
            catalog,
            place: _place,
            minutes: _minutes,
            mood: _mood,
            age: child?.age ?? 6,
            canPlay: (i) => ref.watch(canPlayProvider(i)),
            playedToday: playedToday,
          );

    Widget group<T>(
      String label,
      List<T> values,
      T selected,
      String Function(T) name,
      void Function(T) pick,
    ) => Padding(
      padding: const EdgeInsets.only(top: AkSpace.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.titleMedium),
          const SizedBox(height: AkSpace.xs),
          Wrap(
            spacing: AkSpace.s,
            runSpacing: AkSpace.s,
            children: [
              for (final v in values)
                ChoiceChip(
                  label: Text(name(v)),
                  selected: v == selected,
                  showCheckmark: false,
                  labelStyle: selectableChipLabel(context, selected: v == selected),
                  onSelected: (_) => setState(() => pick(v)),
                ),
            ],
          ),
        ],
      ),
    );

    final top = picks.firstOrNull;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AkSpace.l, 0, AkSpace.l, AkSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ref.watch(currentMediaProvider).value case final media?)
              Padding(
                padding: const EdgeInsets.only(bottom: AkSpace.m),
                child: Material(
                  color: AkBrand.sun,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    leading: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF211C35), size: 36),
                    title: Text(
                      'Dokończ: ${media.title}',
                      style: const TextStyle(color: Color(0xFF211C35), fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'albo wybierz niżej coś innego',
                      style: TextStyle(color: Color(0xFF211C35)),
                    ),
                    trailing: IconButton(
                      tooltip: 'Zakończ tę zabawę',
                      color: const Color(0xFF211C35),
                      onPressed: () => ref.read(audioHandlerProvider).endSession(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                    onTap: () => _go(
                      () => widget.host.push(media.id.startsWith(gameMediaPrefix) ? '/gra' : '/odtwarzacz'),
                    ),
                  ),
                ),
              ),
            Text(l10n.pickTitle, style: text.headlineSmall),
            group(
              l10n.pickWhere,
              PickPlace.values,
              _place,
              (p) => switch (p) {
                PickPlace.home => l10n.pickHome,
                PickPlace.car => l10n.pickCar,
                PickPlace.out => l10n.pickOut,
                PickPlace.bed => l10n.pickBed,
              },
              (p) => _place = p,
            ),
            group(l10n.pickHowLong, pickMinutes, _minutes, l10n.tripMinutes, (m) => _minutes = m),
            group(
              l10n.pickMood,
              PickMood.values,
              _mood,
              (m) => switch (m) {
                PickMood.move => l10n.pickMove,
                PickMood.calm => l10n.pickCalm,
              },
              (m) => _mood = m,
            ),
            const SizedBox(height: AkSpace.l),
            if (top == null)
              Text(l10n.pickNothing, style: text.bodyLarge)
            else ...[
              Text(l10n.pickResult, style: text.labelLarge?.copyWith(color: context.palette.inkMuted)),
              const SizedBox(height: AkSpace.s),
              Row(
                children: [
                  ContentCover(item: top, pack: catalog!.pack(top.packId ?? ''), size: 72),
                  const SizedBox(width: AkSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(top.title, style: text.titleLarge),
                        Text(
                          '${l10n.duration(top.durationSec)} · ${l10n.kind(top.kind)}',
                          style: text.bodyMedium?.copyWith(color: context.palette.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AkSpace.m),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _go(() => startItem(widget.host, top)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.pickStart),
                ),
              ),
              if (picks.length > 1) ...[
                const SizedBox(height: AkSpace.s),
                Text(l10n.pickOr, style: text.labelLarge?.copyWith(color: context.palette.inkMuted)),
                for (final alt in picks.skip(1))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(alt.title),
                    subtitle: Text(l10n.duration(alt.durationSec)),
                    trailing: const Icon(Icons.play_circle_outline_rounded),
                    onTap: () => _go(() => startItem(widget.host, alt)),
                  ),
              ],
            ],
            // A whole ride or the evening ritual is one tap further.
            if (_place == PickPlace.car || _place == PickPlace.bed)
              TextButton.icon(
                onPressed: () =>
                    _go(() => widget.host.push(_place == PickPlace.car ? '/podroz' : '/dobranoc')),
                icon: Icon(_place == PickPlace.car ? Icons.directions_car_rounded : Icons.bedtime_rounded),
                label: Text(_place == PickPlace.car ? l10n.pickWholeTrip : l10n.pickWholeRitual),
              ),
          ],
        ),
      ),
    );
  }
}
