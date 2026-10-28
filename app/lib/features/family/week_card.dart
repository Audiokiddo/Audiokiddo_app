import 'dart:io';
import 'dart:ui' as ui;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/kiddo.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_widget_sync.dart';

/// The last seven days of one child, for the card the parent sends to grandparents.
@immutable
class WeekSummary {
  const WeekSummary({
    required this.name,
    required this.notes,
    required this.activities,
    required this.minutes,
    required this.correct,
    required this.scored,
    this.favorite,
    this.topSkill,
  });

  final String name;
  final int notes;
  final int activities;
  final int minutes;
  final int correct;
  final int scored;

  /// The activity finished most often (ties: the latest one).
  final String? favorite;
  final String? topSkill;

  bool get isEmpty => activities == 0;
}

WeekSummary weekSummary({
  required String name,
  required List<ActivityResult> results,
  required Catalog catalog,
  required PlanPosition? position,
  required DateTime now,
}) {
  final since = now.subtract(const Duration(days: 7));
  final week = [
    for (final r in results)
      if (r.at.isAfter(since)) r,
  ];
  final progress = summarizeProgress(week, catalog, now);
  final counts = <String, int>{};
  for (final r in week.where((r) => r.completed)) {
    counts[r.itemId] = (counts[r.itemId] ?? 0) + 1;
  }
  String? favorite;
  var best = 0;
  for (final r in week.reversed.where((r) => r.completed)) {
    if (counts[r.itemId]! > best) {
      best = counts[r.itemId]!;
      favorite = catalog.item(r.itemId)?.title;
    }
  }
  final skills = progress.skillPractice.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return WeekSummary(
    name: name,
    notes: position == null ? 0 : weekNotes(currentDay: position.currentDay, completedDays: position.completedDays),
    activities: progress.activities,
    minutes: progress.activities > 0 && progress.minutes == 0 ? 1 : progress.minutes,
    correct: progress.correct,
    scored: progress.scored,
    favorite: favorite,
    topSkill: skills.isEmpty ? null : skills.first.key,
  );
}

/// A warm, printable-looking card: Kiddo, the week's melody, a few numbers and a question
/// grandparents can ask on the phone. Fixed width, so the shared image looks the same everywhere.
class WeekCard extends StatelessWidget {
  const WeekCard({super.key, required this.summary});

  final WeekSummary summary;

  static const width = 360.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    const ink = AkBrand.cocoa;
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: text.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: ink.withValues(alpha: 0.75)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE3B3), Color(0xFFFFB38A)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.weekCardKicker.toUpperCase(),
                          style: text.labelSmall?.copyWith(color: ink, letterSpacing: 1.4, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.weekCardTitle(summary.name),
                          style: text.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w800, height: 1.1),
                        ),
                      ],
                    ),
                  ),
                  const Kiddo(size: 78, mood: KiddoMood.happy),
                ],
              ),
              const SizedBox(height: 14),
              // The week's melody: seven notes, filled for the days played.
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 30,
                        color: i < summary.notes ? AkBrand.terracotta : ink.withValues(alpha: 0.18),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  stat('${summary.notes}/7', l10n.weekCardNotes),
                  stat('${summary.activities}', l10n.weekCardActivities(summary.activities)),
                  stat('${summary.minutes}', l10n.weekCardMinutes(summary.minutes)),
                  if (summary.scored > 0) stat('${summary.correct}', l10n.weekCardCorrect(summary.correct)),
                ],
              ),
              const SizedBox(height: 18),
              if (summary.favorite case final favorite?)
                Text(l10n.weekCardFavorite(favorite), style: text.bodyMedium?.copyWith(color: ink)),
              if (summary.topSkill case final skill?)
                Text(l10n.weekCardSkill(skill), style: text.bodyMedium?.copyWith(color: ink)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  summary.favorite == null ? l10n.weekCardAskGeneric : l10n.weekCardAsk(summary.favorite!),
                  style: text.bodyMedium?.copyWith(color: ink, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Preview and send: the card is drawn to a PNG and handed to the system share sheet
/// (Messages, WhatsApp, Messenger). The image never passes through our servers.
Future<void> showWeekCard(BuildContext context, WeekSummary summary) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => _WeekCardSheet(summary: summary),
);

class _WeekCardSheet extends StatefulWidget {
  const _WeekCardSheet({required this.summary});

  final WeekSummary summary;

  @override
  State<_WeekCardSheet> createState() => _WeekCardSheetState();
}

class _WeekCardSheetState extends State<_WeekCardSheet> {
  final _card = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final origin = context.findRenderObject() as RenderBox?;
    setState(() => _busy = true);
    try {
      final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(p.join((await getTemporaryDirectory()).path, 'audiokiddo-tydzien.png'));
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: l10n.weekCardShareText(widget.summary.name),
          // iPad shows the share sheet next to this rectangle.
          sharePositionOrigin: origin == null ? null : origin.localToGlobal(Offset.zero) & origin.size,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AkSpace.m, 0, AkSpace.m, AkSpace.m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.weekCardSheetTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AkSpace.s),
            Text(
              l10n.weekCardSheetBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.palette.inkMuted),
            ),
            const SizedBox(height: AkSpace.m),
            FittedBox(
              child: RepaintBoundary(
                key: _card,
                child: WeekCard(summary: widget.summary),
              ),
            ),
            const SizedBox(height: AkSpace.m),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _share,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(l10n.weekCardSend),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
