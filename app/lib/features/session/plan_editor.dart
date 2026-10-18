import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../catalog/widgets/content_cover.dart';
import '../player/player_providers.dart';
import 'plan.dart';
import 'session.dart';

/// Whole minutes the running session still has (the play now only by what is left of it).
/// Changes once a minute, so what watches it does not rebuild every second.
final planMinutesLeftProvider = Provider<int>((ref) {
  final session = ref.watch(sessionProvider);
  if (!session.running) return 0;
  final position = ref.watch(positionProvider).value ?? Duration.zero;
  final seconds = planSecondsLeft(
    session.steps,
    index: session.index,
    position: position,
    started: session.countdown == null,
  );
  return (seconds + 59) ~/ 60;
});

/// The plays of a plan: how long is left, what is ahead in order, and the means to change it.
/// Used before the start (a ride, a dinner) and in a sheet while it runs.
class PlanEditor extends StatelessWidget {
  const PlanEditor({
    super.key,
    required this.plays,
    required this.minutesLeft,
    required this.candidates,
    required this.onRemove,
    required this.onReorder,
    required this.onReplace,
    required this.onAdd,
    this.color,
    this.heading = 'Zostało',
  });

  /// The plays ahead, in order.
  final List<ContentItem> plays;
  final int minutesLeft;

  /// What may be added or swapped in (not already in the plan), best first.
  final List<ContentItem> candidates;
  final void Function(int pos) onRemove;
  final void Function(int oldPos, int newPos) onReorder;
  /// [nth] tells apart a play that comes again later in the plan (0 = its first time).
  final void Function(String itemId, ContentItem item, {int nth}) onReplace;
  final void Function(List<ContentItem> items) onAdd;

  /// Text colour (the running screen is dark).
  final Color? color;
  final String heading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fg = color ?? context.palette.ink;
    final muted = fg.withValues(alpha: .7);

    Future<ContentItem?> choose(String title) => showModalBottomSheet<ContentItem>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => _Chooser(title: title, candidates: candidates),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                minutesLeft <= 0 ? 'Plan jest pusty' : '$heading ${minutesLabel(minutesLeft * 60)}',
                style: text.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              playsLabel(plays.length),
              style: text.labelLarge?.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (plays.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Dodaj czas albo zabawę poniżej.', style: text.bodyMedium?.copyWith(color: muted)),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: plays.length,
            onReorderItem: onReorder,
            itemBuilder: (context, pos) {
              final item = plays[pos];
              // A ride may play the same one again later: its key and swap say which time.
              final nth = playOccurrence(plays, pos);
              return Padding(
                key: ValueKey('plan-${item.id}-$nth'),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text('${pos + 1}', style: text.labelLarge?.copyWith(color: muted)),
                    ),
                    ContentCover(item: item, size: 46),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(color: fg),
                          ),
                          Text(
                            '${(item.durationSec / 60).ceil()} min',
                            style: text.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Zamień „${item.title}”',
                      visualDensity: VisualDensity.compact,
                      onPressed: candidates.isEmpty
                          ? null
                          : () async {
                              final picked = await choose('Zamień na…');
                              if (picked != null && context.mounted) onReplace(item.id, picked, nth: nth);
                            },
                      icon: Icon(Icons.swap_horiz_rounded, color: fg),
                    ),
                    IconButton(
                      tooltip: 'Usuń „${item.title}”',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onRemove(pos),
                      icon: Icon(Icons.close_rounded, color: fg),
                    ),
                    ReorderableDragStartListener(
                      index: pos,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.drag_handle_rounded, color: muted),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 10),
        Text('Dodaj czas', style: text.labelLarge?.copyWith(color: muted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in const [5, 10, 15])
              ActionChip(
                label: Text('+$m min'),
                onPressed: candidates.isEmpty ? null : () => onAdd(playsForMinutes(candidates, m)),
              ),
            ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Wybierz zabawę'),
              onPressed: candidates.isEmpty
                  ? null
                  : () async {
                      final picked = await choose('Dodaj zabawę');
                      if (picked != null && context.mounted) onAdd([picked]);
                    },
            ),
          ],
        ),
        if (candidates.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Nie ma już innych zabaw, które pasują.',
              style: text.bodySmall?.copyWith(color: muted),
            ),
          ),
      ],
    );
  }
}

/// A list of plays to pick one from (swap or add).
class _Chooser extends StatelessWidget {
  const _Chooser({required this.title, required this.candidates});

  final String title;
  final List<ContentItem> candidates;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: text.titleLarge),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                itemCount: candidates.length,
                itemBuilder: (context, i) {
                  final item = candidates[i];
                  return InkWell(
                    onTap: () => Navigator.pop(context, item),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          ContentCover(item: item, size: 52),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: text.titleSmall),
                                Text(
                                  '${(item.durationSec / 60).ceil()} min · ${item.ageMin}${item.ageMax == null ? '+' : '–${item.ageMax}'} lat',
                                  style: text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.add_circle_outline_rounded),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
