import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'ambient_motion.dart';
import 'kiddo.dart';

/// A little road-trip gag for parents: the family car bumps along, a parent drives, Kiddo
/// leans out of the back seat with [line]. Decorative; the words are also real text.
class CarScene extends ConsumerStatefulWidget {
  const CarScene({super.key, required this.line, this.height = 210});

  final String line;
  final double height;

  @override
  ConsumerState<CarScene> createState() => _CarSceneState();
}

class _CarSceneState extends ConsumerState<CarScene> with SingleTickerProviderStateMixin {
  late final _drive = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (ref.read(ambientMotionProvider)) _drive.repeat();
  }

  @override
  void dispose() {
    _drive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _drive,
                builder: (context, _) => CustomPaint(painter: _CarPainter(_drive.value)),
              ),
            ),
          ),
          // Kiddo in the back window, bobbing with the bumps.
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.height * 0.36,
            child: Align(
              alignment: const Alignment(-0.32, 0),
              child: AnimatedBuilder(
                animation: _drive,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -math.sin(_drive.value * math.pi * 2) * 2),
                  child: child,
                ),
                child: const Kiddo(size: 58, mood: KiddoMood.talking),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: AkSpace.m,
            right: AkSpace.m,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AkSpace.m, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x22000000))],
              ),
              child: Text(
                widget.line,
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(color: AkBrand.ink, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarPainter extends CustomPainter {
  _CarPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roadY = h * 0.86;

    // Road with dashes rushing past.
    canvas.drawRect(Rect.fromLTWH(0, roadY, w, h - roadY), Paint()..color = const Color(0xFF5B5F6B));
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 4;
    for (var x = -t * 80; x < w; x += 80) {
      canvas.drawLine(Offset(x, roadY + (h - roadY) / 2), Offset(x + 40, roadY + (h - roadY) / 2), dash);
    }

    final bump = math.sin(t * math.pi * 2) * 2.5;
    final carW = math.min(w * 0.72, 300.0);
    final left = (w - carW) / 2;
    final bodyTop = h * 0.5 + bump;
    final bodyBottom = roadY - 16 + bump;

    // Roof and windows.
    final roof = RRect.fromRectAndCorners(
      Rect.fromLTRB(left + carW * 0.12, h * 0.3 + bump, left + carW * 0.8, bodyTop + 4),
      topLeft: const Radius.circular(26),
      topRight: const Radius.circular(18),
    );
    canvas.drawRRect(roof, Paint()..color = AkBrand.orange);
    final glass = Paint()..color = const Color(0xFFCFEFF1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left + carW * 0.17, h * 0.34 + bump, left + carW * 0.44, bodyTop),
        const Radius.circular(10),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left + carW * 0.47, h * 0.34 + bump, left + carW * 0.75, bodyTop),
        const Radius.circular(10),
      ),
      glass,
    );

    // The driver: a tired silhouette with a coffee-cup steam curl. Parents will understand.
    final head = Offset(left + carW * 0.63, h * 0.43 + bump);
    canvas.drawCircle(head, 13, Paint()..color = const Color(0xFFE9B08F));
    canvas.drawArc(
      Rect.fromCircle(center: head.translate(0, -3), radius: 14),
      math.pi,
      math.pi,
      true,
      Paint()..color = const Color(0xFF4A3228),
    );
    final eye = Paint()
      ..color = AkBrand.ink
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(head.translate(-6, 2), head.translate(-2, 2), eye);
    canvas.drawLine(head.translate(3, 2), head.translate(7, 2), eye);

    // Body and wheels.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, bodyTop, left + carW, bodyBottom),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFFE8452C),
    );
    canvas.drawRect(
      Rect.fromLTRB(left + carW * 0.9, bodyTop + 12, left + carW, bodyTop + 22),
      Paint()..color = AkBrand.sun,
    );
    for (final wx in [left + carW * 0.22, left + carW * 0.78]) {
      final c = Offset(wx, roadY - 14);
      canvas.drawCircle(c, 20, Paint()..color = AkBrand.ink);
      canvas.drawCircle(c, 9, Paint()..color = const Color(0xFFB9C4BF));
      final spoke = Paint()
        ..color = AkBrand.ink
        ..strokeWidth = 3;
      for (var i = 0; i < 3; i++) {
        final a = t * math.pi * 2 + i * math.pi / 1.5;
        canvas.drawLine(c, c + Offset(math.cos(a) * 9, math.sin(a) * 9), spoke);
      }
    }
  }

  @override
  bool shouldRepaint(_CarPainter old) => old.t != t;
}
