import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/motion.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/content_cover.dart';
import '../home/quick_pick.dart';
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
            onTap: () => context.push('/zabawa/${item.id}'),
            child: ContentCover(item: item, size: 64, locked: !playable),
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
