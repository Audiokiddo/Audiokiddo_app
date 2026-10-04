import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/motion.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/seasonal.dart';
import '../catalog/widgets/content_cover.dart';
import '../home/quick_pick.dart';
import '../personal/personal_repository.dart';
import '../purchases/preview_player.dart';
import '../../l10n/app_localizations.dart';
import '../catalog/widgets/labels.dart';
import 'discovery_model.dart';

const referencePurple = Color(0xFF342650);
const referenceMint = Color(0xFFBCE8E3);
const referenceLilac = Color(0xFFDBCCF0);
Color categoryColor(PlayCategory c) => switch (c) {
  PlayCategory.adventure => referenceMint,
  PlayCategory.detective => referenceLilac,
  PlayCategory.songs => AkBrand.sun,
  PlayCategory.movement => referenceMint,
  PlayCategory.creative => referenceLilac,
  PlayCategory.calm => referencePurple,
};
IconData categoryIcon(PlayCategory c) => switch (c) {
  PlayCategory.adventure => Icons.flag_rounded,
  PlayCategory.detective => Icons.search_rounded,
  PlayCategory.songs => Icons.music_note_rounded,
  PlayCategory.movement => Icons.directions_run_rounded,
  PlayCategory.creative => Icons.brush_rounded,
  PlayCategory.calm => Icons.bedtime_rounded,
};
PlayCategory itemCategory(ContentItem i) =>
    PlayCategory.values.where((c) => c.matches(i)).firstOrNull ?? PlayCategory.adventure;

class ArtScene extends StatelessWidget {
  const ArtScene({super.key, required this.category, this.seed = 0});
  final PlayCategory category;
  final int seed;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(painter: _Scene(category, seed), child: const SizedBox.expand()),
  );
}

class _Scene extends CustomPainter {
  _Scene(this.category, this.seed);
  final PlayCategory category;
  final int seed;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 200, size.height / 180);
    final night = category == PlayCategory.calm;
    final p = Paint();
    c.drawRect(const Rect.fromLTWH(0, 0, 200, 180), p..color = categoryColor(category));
    if (category == PlayCategory.adventure || night) {
      c.drawCircle(Offset(150, 38), 22, p..color = AkBrand.sun);
      if (night) c.drawCircle(const Offset(159, 29), 22, p..color = referencePurple);
      for (var k = 0; k < 3; k++) {
        final path = Path()
          ..moveTo(-20, 180)
          ..lineTo(-20, 120 + k * 17);
        for (var x = -20.0; x <= 220; x += 10) {
          path.lineTo(x, 112 + k * 20 + math.sin(x / 37 + k + seed) * 24);
        }
        path
          ..lineTo(220, 180)
          ..close();
        c.drawPath(
          path,
          p
            ..color = (night
                ? [const Color(0xFF7861AC), const Color(0xFF655692), const Color(0xFF4C4375)]
                : [const Color(0xFF6BB9AB), const Color(0xFF308D83), const Color(0xFF205D59)])[k],
        );
      }
      if (!night) {
        for (final x in [25.0, 172.0]) {
          c.drawPath(
            Path()
              ..moveTo(x, 65)
              ..lineTo(x - 24, 137)
              ..lineTo(x + 24, 137)
              ..close(),
            p..color = const Color(0xFF184F49),
          );
          c.drawRect(Rect.fromLTWH(x - 2, 118, 4, 38), p..color = const Color(0xFF184F49));
        }
        c.drawPath(
          Path()
            ..moveTo(86, 180)
            ..quadraticBezierTo(130, 134, 96, 120)
            ..quadraticBezierTo(88, 107, 108, 91)
            ..quadraticBezierTo(108, 124, 118, 133)
            ..lineTo(144, 180)
            ..close(),
          p..color = const Color(0xFFFFDA7A),
        );
      }
    } else {
      for (var k = 0; k < 4; k++) {
        c.drawCircle(
          Offset(20 + k * 62.0, 167 + (k.isOdd ? 8 : 0)),
          42,
          p..color = Color.lerp(categoryColor(category), Colors.white, .2 + k * .06)!,
        );
      }
      final icon = categoryIcon(category);
      final painter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: 85,
            color: referencePurple,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      c.save();
      c.translate(102, 82);
      c.rotate(-.16);
      painter.paint(c, Offset(-painter.width / 2, -painter.height / 2));
      c.restore();
      painter.dispose();
    }
    for (final point in [const Offset(31, 29), const Offset(170, 90), const Offset(76, 48)]) {
      c.drawPath(
        Path()
          ..moveTo(point.dx, point.dy - 5)
          ..lineTo(point.dx + 2, point.dy - 1)
          ..lineTo(point.dx + 6, point.dy)
          ..lineTo(point.dx + 2, point.dy + 2)
          ..lineTo(point.dx, point.dy + 6)
          ..lineTo(point.dx - 2, point.dy + 2)
          ..lineTo(point.dx - 5, point.dy)
          ..lineTo(point.dx - 2, point.dy - 1)
          ..close(),
        p..color = night ? AkBrand.sun : Colors.white.withValues(alpha: .7),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_Scene old) => old.category != category || old.seed != seed;
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, required this.onTap});
  final PlayCategory category;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(child: ArtScene(category: category)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, categoryColor(category)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 90, 12, 14),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                category.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: category == PlayCategory.calm ? Colors.white : const Color(0xFF211C35),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class TwoColumns extends StatelessWidget {
  const TwoColumns({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i += 2)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: 10),
                Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
              ],
            ),
          ),
        ),
    ],
  );
}

class RefSection extends StatelessWidget {
  const RefSection(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(action!, style: const TextStyle(fontSize: 12)),
          ),
      ],
    ),
  );
}

class AudioRow extends ConsumerWidget {
  const AudioRow({super.key, required this.item, this.subtitle, this.trailing});
  final ContentItem item;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playable = ref.watch(canPlayProvider(item));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          InkWell(
            // The title next to it opens the same page and carries the label for VoiceOver.
            excludeFromSemantics: true,
            onTap: () => context.push('/zabawa/${item.id}'),
            child: ContentCover(
              item: item,
              size: 64,
              locked: !playable,
              fresh: ref.watch(isNewItemProvider(item)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => context.push('/zabawa/${item.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    subtitle ??
                        '${(item.durationSec / 60).ceil()} min · ${item.ageMin}${item.ageMax == null ? '+' : '–${item.ageMax}'} lat',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  ListenedBar(item: item),
                ],
              ),
            ),
          ),
          trailing ??
              (playable
                  ? IconButton.filled(
                      tooltip: 'Odtwórz ${item.title}',
                      onPressed: () => startItem(context, item),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                    )
                  : item.preview != null
                  ? PreviewButton(item: item)
                  : IconButton.outlined(
                      tooltip: 'Zobacz dostęp do ${item.title}',
                      onPressed: () => context.push('/zabawa/${item.id}'),
                      icon: const Icon(Icons.lock_outline_rounded, size: 22),
                    )),
        ],
      ),
    );
  }
}

/// How much of a play the family has heard: a thin bar and "Słuchane 4 z 12 min" (or "Do końca").
/// Nothing for plays never started.
class ListenedBar extends ConsumerWidget {
  const ListenedBar({super.key, required this.item, this.compact = false});

  final ContentItem item;

  /// Under a cover in a row: the bar only.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider(item.id)).value;
    if (p == null || (p.positionMs <= 0 && !p.completed)) return const SizedBox.shrink();
    final total = p.durationMs > 0 ? p.durationMs : item.durationSec * 1000;
    final value = p.completed ? 1.0 : (p.positionMs / total).clamp(0.0, 1.0);
    final heard = (p.positionMs / 60000).ceil();
    final minutes = (total / 60000).ceil();
    final label = p.completed ? 'Wysłuchane do końca' : 'Słuchane $heard z $minutes min';
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 4,
        color: AkBrand.teal,
        backgroundColor: AkBrand.teal.withValues(alpha: .18),
      ),
    );
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: compact
            ? bar
            : Row(
                children: [
                  SizedBox(width: 72, child: bar),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.palette.inkMuted),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Content on a fixed light colour (mint, lilac, sun): always the light theme inside, so text
/// stays dark and readable when the app itself is dark.
class LightSurface extends StatelessWidget {
  const LightSurface({super.key, required this.child});

  final Widget child;

  static final _theme = buildTheme(Brightness.light);

  @override
  Widget build(BuildContext context) => Theme(
    data: _theme,
    child: DefaultTextStyle.merge(
      style: TextStyle(color: AkPalette.light.ink),
      child: child,
    ),
  );
}

/// The three facts a parent decides by, as in the mockup: how long, for what age, what is
/// needed (or that nothing is).
class MetaStrip extends StatelessWidget {
  const MetaStrip({super.key, required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final minutes = (item.durationSec / 60).ceil();
    final age = item.ageMax == null ? '${item.ageMin}+ lat' : '${item.ageMin}–${item.ageMax} lat';
    final needs = item.requirements.where((r) => r != Requirement.mikrofon).map(l10n.requirement).toList();
    Widget cell(IconData icon, Color color, String value, String label) => Expanded(
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: const Color(0xFF211C35)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 2,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.1),
                ),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cell(Icons.schedule_rounded, referenceMint, '$minutes', minutes == 1 ? 'minuta' : 'minut'),
          cell(Icons.groups_rounded, referenceLilac, age, 'wiek'),
          cell(
            needs.isEmpty ? Icons.check_rounded : Icons.content_cut_rounded,
            AkBrand.sun,
            needs.isEmpty ? 'Nic' : needs.join(' + '),
            'potrzebne',
          ),
        ],
      ),
    );
  }
}

/// Plays like [item]: the same kind of play or the same pack, for the same age.
List<ContentItem> similarPlays(Catalog catalog, ContentItem item, {int limit = 8}) {
  final category = itemCategory(item);
  int score(ContentItem i) =>
      (i.packId != null && i.packId == item.packId ? 2 : 0) +
      (category.matches(i) ? 3 : 0) +
      i.situations.where(item.situations.contains).length;
  final candidates = [
    for (final i in catalog.items)
      if (i.id != item.id &&
          (i.audio.isNotEmpty || i.script != null) &&
          i.ageMin <= (item.ageMax ?? item.ageMin + 3) &&
          score(i) >= 2)
        i,
  ]..sort((a, b) => score(b).compareTo(score(a)));
  return candidates.take(limit).toList();
}

/// "Podobne zabawy": a row of covers under a play.
class SimilarPlays extends ConsumerWidget {
  const SimilarPlays({super.key, required this.item, this.title = 'Podobne zabawy'});

  final ContentItem item;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    if (catalog == null) return const SizedBox.shrink();
    final items = similarPlays(catalog, item);
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RefSection(title),
        CoverRow(items: items),
      ],
    );
  }
}

/// What to play next, in the player: the rest of this pack first, then every other pack, then
/// songs and games, each as its own row so a parent sees where a play comes from.
class PlaysByPack extends ConsumerWidget {
  const PlaysByPack({super.key, required this.item, required this.title});

  final ContentItem item;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    if (catalog == null) return const SizedBox.shrink();
    bool listed(ContentItem i) => i.id != item.id && (i.audio.isNotEmpty || i.script != null);
    final packs = [
      ...catalog.packs.where((p) => p.id == item.packId),
      ...catalog.packs.where((p) => p.id != item.packId),
    ];
    final loose = catalog.items.where((i) => i.packId == null && listed(i)).toList();
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RefSection(title),
        for (final pack in packs)
          if (catalog.itemsInPack(pack.id).where(listed).toList() case final items when items.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                pack.id == item.packId ? 'Dalej w pakiecie ${pack.title}' : 'Pakiet ${pack.title}',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            CoverRow(items: items, size: 96),
            const SizedBox(height: 14),
          ],
        if (loose.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Piosenki i gry', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          ),
          CoverRow(items: loose, size: 96),
        ],
      ],
    );
  }
}

/// A horizontal row of covers with titles, each opening its play.
class CoverRow extends ConsumerWidget {
  const CoverRow({super.key, required this.items, this.size = 112});

  final List<ContentItem> items;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: size + 8 + MediaQuery.textScalerOf(context).scale(40),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          return SizedBox(
            width: size,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/zabawa/${item.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContentCover(
                    item: item,
                    size: size,
                    locked: !ref.watch(canPlayProvider(item)),
                    fresh: ref.watch(isNewItemProvider(item)),
                  ),
                  ListenedBar(item: item, compact: true),
                  const SizedBox(height: 6),
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
