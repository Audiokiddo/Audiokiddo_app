import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/kiddo_voice.dart';
import '../../core/storage/storage_providers.dart';
import '../alerts/alerts.dart';
import '../family/birthday.dart';
import 'catalog_providers.dart';
import 'widgets/item_art.dart';
import 'widgets/item_views.dart';

const monthNames = [
  'Styczeń',
  'Luty',
  'Marzec',
  'Kwiecień',
  'Maj',
  'Czerwiec',
  'Lipiec',
  'Sierpień',
  'Wrzesień',
  'Październik',
  'Listopad',
  'Grudzień',
];

/// The plays of [month] with a release date in it, in order: those out already and those
/// still waiting for their premiere.
List<ContentItem> premieresOf(Catalog full, DateTime month) => [
  for (final i in full.items)
    if (i.releasedOn case final d? when d.year == month.year && d.month == month.month) i,
]..sort((a, b) => a.releasedOn!.compareTo(b.releasedOn!));

/// "Nowości" on Start: this month's premieres as cards. Plays already out are uncovered, in
/// colour; the ones still to come lie face down in black and white with their date, and turn
/// over on their day, when the child uncovers them with a finger. The next month can be peeked at too.
class NewsMonth extends ConsumerStatefulWidget {
  const NewsMonth({super.key});

  @override
  ConsumerState<NewsMonth> createState() => _NewsMonthState();
}

class _NewsMonthState extends ConsumerState<NewsMonth> {
  @override
  Widget build(BuildContext context) {
    final full = ref.watch(fullCatalogProvider).value;
    final today = ref.watch(calendarDayProvider);
    if (full == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    // This month and the next in one row, no month tabs and no counts (Nela, 2026-10-18).
    final plays = [...premieresOf(full, today), ...premieresOf(full, DateTime(today.year, today.month + 1))];
    if (plays.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nowości', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        // As tall as the tallest card, so no empty band under them (2026-10-18).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, item) in plays.indexed) ...[
                if (i > 0) const SizedBox(width: 12),
                _PremiereCard(item: item, today: today),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Premieres the child has turned over with a finger, kept on the phone.
class UncoveredController extends AsyncNotifier<Set<String>> {
  static const _key = 'uncovered_premieres';

  @override
  Future<Set<String>> build() async => {
    ...?(await ref.read(databaseProvider).readValue(_key))?.split(',').where((s) => s.isNotEmpty),
  };

  Future<void> uncover(String id) async {
    final next = {...?state.value, id};
    state = AsyncData(next);
    await ref.read(databaseProvider).writeValue(_key, next.join(','));
  }
}

final uncoveredProvider = AsyncNotifierProvider<UncoveredController, Set<String>>(UncoveredController.new);

/// One premiere: face down in black and white with its date until its day; on its day (and
/// for two weeks) a bright back saying "Odkryj!" that the child turns over with a finger, with
/// a sound, like a window of an Advent calendar (parent review, 2026-10-18); then in colour.
class _PremiereCard extends ConsumerStatefulWidget {
  const _PremiereCard({required this.item, required this.today});

  final ContentItem item;
  final DateTime today;

  @override
  ConsumerState<_PremiereCard> createState() => _PremiereCardState();
}

class _PremiereCardState extends ConsumerState<_PremiereCard> with SingleTickerProviderStateMixin {
  late final _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  Future<void> _uncover() async {
    ref.read(kiddoVoiceProvider).effect('fanfare');
    await _flip.forward();
    await ref.read(uncoveredProvider.notifier).uncover(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final today = widget.today;
    final gift = ref.watch(birthdayPremiereProvider) == item.id;
    final out = (!item.releasedOn!.isAfter(today) && isReady(item)) || gift;
    final uncovered = ref.watch(uncoveredProvider).value;
    // Waits for a finger: out within the last two weeks (or the birthday gift), not yet turned.
    final toUncover =
        out &&
        uncovered != null &&
        !uncovered.contains(item.id) &&
        (gift || today.difference(item.releasedOn!).inDays < 14);
    final text = Theme.of(context).textTheme;
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox.square(dimension: 170, child: ItemArt(item: item)),
    );
    final Widget face;
    if (out) {
      face = cover;
    } else {
      face = Stack(
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: cover,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(10),
                // Shrinks with very large text instead of overflowing the card.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 36),
                      const SizedBox(height: 6),
                      Text(
                        dayAndMonth(item.releasedOn!),
                        style: text.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    final back = Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC94D), Color(0xFFFF8A5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(10),
      // Shrinks with very large text instead of overflowing the card.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF211C35), size: 44),
            const SizedBox(height: 6),
            Text(
              gift ? 'Prezent!' : 'Odkryj!',
              style: text.headlineSmall?.copyWith(color: const Color(0xFF211C35), fontWeight: FontWeight.w900),
            ),
            Text('Dotknij karty', style: text.bodySmall?.copyWith(color: const Color(0xFF211C35))),
          ],
        ),
      ),
    );
    // Turning over: the back for the first half, then the cover.
    final card = toUncover
        ? AnimatedBuilder(
            animation: _flip,
            builder: (context, _) {
              final angle = math.pi * Curves.easeInOut.transform(_flip.value);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: angle < math.pi / 2
                    ? back
                    : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: face),
              );
            },
          )
        : face;
    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: toUncover
            ? (_flip.isAnimating ? null : _uncover)
            : out
            ? () => context.push(itemRoute(item))
            : () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Premiera ${dayAndMonth(item.releasedOn!)}. Karta odwróci się tego dnia.')),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(button: true, label: toUncover ? 'Odkryj nową zabawę: ${item.title}' : null, child: card),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              gift
                  ? 'Urodzinowy prezent: wcześniej!'
                  : out
                  ? 'Premiera ${dayAndMonth(item.releasedOn!)}'
                  : item.releasedOn!.isAfter(today)
                  ? 'Odkryjemy ${dayAndMonth(item.releasedOn!)}'
                  : 'Już wkrótce',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
