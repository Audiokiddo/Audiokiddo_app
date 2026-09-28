import 'dart:math' as math;

import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Drawn cover until real artwork is delivered (TODO(Dawid)): a gradient in the pack colour,
/// a pattern of notes, stars and dots that differs per item, and the pack's symbol on a
/// light disc. Games without a pack get a warm coral, songs a lavender.
class ContentCover extends StatelessWidget {
  const ContentCover({super.key, required this.item, this.pack, this.size = 120, this.locked = false});

  final ContentItem item;
  final Pack? pack;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final base = pack != null
        ? AkPalette.packColor(pack!.colorToken)
        : switch (item.kind) {
            ContentKind.interactiveGame => AkBrand.coral,
            ContentKind.song => AkBrand.lavender,
            _ => AkBrand.sun,
          };
    final light = Color.lerp(base, Colors.white, 0.35)!;
    final deep = Color.lerp(base, AkBrand.cocoa, 0.12)!;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.17),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [light, deep],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CoverPattern(
                      seed: item.id.codeUnits.fold(7, (h, c) => (h * 31 + c) & 0x7fffffff),
                      color: Colors.white,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: size * 0.56,
                    height: size * 0.56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.55),
                      boxShadow: [BoxShadow(color: deep.withValues(alpha: 0.35), blurRadius: size * 0.12)],
                    ),
                    child: Icon(_icon, size: size * 0.32, color: AkBrand.ink.withValues(alpha: 0.88)),
                  ),
                ),
                if (locked)
                  Positioned(
                    right: size * 0.07,
                    top: size * 0.07,
                    child: CircleAvatar(
                      radius: size * 0.12,
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      child: Icon(Icons.lock_rounded, size: size * 0.13, color: AkBrand.ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch ((item.kind, item.packId)) {
    (ContentKind.song, _) => Icons.music_note_rounded,
    (ContentKind.interactiveGame, _) => Icons.graphic_eq_rounded,
    (_, 'wyobraznia') => Icons.auto_awesome_rounded,
    (_, 'slowa-i-wiedza') => Icons.lightbulb_rounded,
    (_, 'detektyw') => Icons.search_rounded,
    _ => Icons.headphones_rounded,
  };
}

/// Scattered notes, stars and dots; [seed] keeps each item's pattern the same every time.
class _CoverPattern extends CustomPainter {
  _CoverPattern({required this.seed, required this.color});

  final int seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final s = size.shortestSide;
    final paint = Paint()..color = color.withValues(alpha: 0.28);
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final c = Offset(random.nextDouble() * size.width, random.nextDouble() * size.height);
      final r = s * (0.03 + random.nextDouble() * 0.05);
      switch (random.nextInt(3)) {
        case 0:
          canvas.drawCircle(c, r * 0.6, paint);
        case 1:
          _star(canvas, c, r, stroke);
        default:
          _note(canvas, c, r, paint, stroke);
      }
    }
    // A soft wave across the bottom, like sound.
    final wave = Path()..moveTo(0, size.height * 0.82);
    for (var x = 0.0; x <= size.width; x += size.width / 24) {
      wave.lineTo(x, size.height * 0.82 + math.sin(x / size.width * math.pi * 4 + seed) * s * 0.03);
    }
    canvas.drawPath(wave, stroke..strokeWidth = s * 0.012);
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final radius = k.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + k * math.pi / 5;
      final p = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  void _note(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    canvas
      ..drawOval(Rect.fromCenter(center: c, width: r * 1.3, height: r), fill)
      ..drawLine(c + Offset(r * 0.6, 0), c + Offset(r * 0.6, -r * 2.2), stroke);
  }

  @override
  bool shouldRepaint(_CoverPattern old) => old.seed != seed || old.color != color;
}
