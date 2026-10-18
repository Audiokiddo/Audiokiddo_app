import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../alerts/alerts.dart';
import 'catalog_providers.dart';
import 'widgets/item_art.dart';
import 'widgets/item_views.dart';

const monthNames = [
  'Styczeń', 'Luty', 'Marzec', 'Kwiecień', 'Maj', 'Czerwiec',
  'Lipiec', 'Sierpień', 'Wrzesień', 'Październik', 'Listopad', 'Grudzień',
];

/// The plays of [month] with a release date in it, in order: those out already and those
/// still waiting for their premiere.
List<ContentItem> premieresOf(Catalog full, DateTime month) => [
  for (final i in full.items)
    if (i.releasedOn case final d? when d.year == month.year && d.month == month.month) i,
]..sort((a, b) => a.releasedOn!.compareTo(b.releasedOn!));

/// "Nowości" on Start: this month's premieres as cards. Plays already out are uncovered, in
/// colour; the ones still to come lie face down in black and white with their date, and turn
/// over on their day. The next month can be peeked at too.
class NewsMonth extends ConsumerStatefulWidget {
  const NewsMonth({super.key});

  @override
  ConsumerState<NewsMonth> createState() => _NewsMonthState();
}

class _NewsMonthState extends ConsumerState<NewsMonth> {
  int _offset = 0;

  @override
  Widget build(BuildContext context) {
    final full = ref.watch(fullCatalogProvider).value;
    final today = ref.watch(calendarDayProvider);
    if (full == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final month = DateTime(today.year, today.month + _offset);
    final plays = premieresOf(full, month);
    final waiting = plays.where((i) => i.releasedOn!.isAfter(today) || !isReady(i)).length;
    final alertsOn = ref.watch(alertsOptInProvider).value ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nowości', style: text.headlineLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            for (final offset in [0, 1])
              Padding(
                padding: EdgeInsets.zero,
                child: ChoiceChip(
                  label: Text(monthNames[DateTime(today.year, today.month + offset).month - 1]),
                  selected: _offset == offset,
                  labelStyle: selectableChipLabel(context, selected: _offset == offset),
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _offset = offset),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          plays.isEmpty
              ? 'Premiery na ${monthNames[month.month - 1].toLowerCase()} pokażemy tutaj, gdy tylko będą gotowe.'
              : waiting == 0
              ? '${plays.length == 1 ? 'Nowa zabawa' : 'Nowe zabawy'} w tym miesiącu: wszystkie już odkryte.'
              : 'Odkryte: ${plays.length - waiting}, czeka na premierę: $waiting. Karty odwracają się w dniu premiery.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 12),
        if (plays.isNotEmpty)
          SizedBox(
            // The cover plus title and date, which grow with the phone's text size.
            height: 186 + 84 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: plays.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _PremiereCard(item: plays[i], today: today),
            ),
          ),
        if (waiting > 0 && !alertsOn)
          TextButton.icon(
            onPressed: () async {
              final ok = await ref.read(alertsOptInProvider.notifier).set(true);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Powiadomienia są wyłączone w ustawieniach telefonu.')),
                );
              }
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Powiadom mnie o premierach'),
          ),
      ],
    );
  }
}

/// One premiere: face up in colour once it is out (turning over the first days), face down in
/// black and white with its date until then.
class _PremiereCard extends StatelessWidget {
  const _PremiereCard({required this.item, required this.today});

  final ContentItem item;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final out = !item.releasedOn!.isAfter(today) && isReady(item);
    final fresh = out && today.difference(item.releasedOn!).inDays < 7;
    final text = Theme.of(context).textTheme;
    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox.square(dimension: 170, child: ItemArt(item: item)),
    );
    final face = out
        ? cover
        : Stack(
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0, 0, 0, 1, 0,
                ]),
                child: cover,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
            ],
          );
    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: out
            ? () => context.push(itemRoute(item))
            : () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Premiera ${dayAndMonth(item.releasedOn!)}. Karta odwróci się tego dnia.')),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A play out this week turns over as the card appears.
            fresh
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: math.pi, end: 0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, angle, child) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: child,
                    ),
                    child: face,
                  )
                : face,
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              out
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
