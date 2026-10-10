import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'ambient_motion.dart';

/// Slowly drifting music notes, stars and dots behind a screen, like the doodles in
/// children's apps. Decorative: invisible to screen readers, still when motion is reduced.
class FloatingDoodles extends ConsumerStatefulWidget {
  const FloatingDoodles({super.key, this.count = 14, this.color, this.opacity = 0.35, this.seed = 1});

  final int count;
  final Color? color;
  final double opacity;
  final int seed;

  @override
  ConsumerState<FloatingDoodles> createState() => _FloatingDoodlesState();
}

class _FloatingDoodlesState extends ConsumerState<FloatingDoodles> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  late final List<_Doodle> _doodles;

  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.seed);
    _doodles = [
      for (var i = 0; i < widget.count; i++)
        _Doodle(
          kind: _DoodleKind.values[random.nextInt(_DoodleKind.values.length)],
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: 10 + random.nextDouble() * 16,
          speed: 0.008 + random.nextDouble() * 0.018,
          sway: random.nextDouble() * math.pi * 2,
          spin: (random.nextDouble() - 0.5) * 0.6,
        ),
    ];
    _ticker = createTicker((elapsed) => setState(() => _elapsed = elapsed));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || !ref.read(ambientMotionProvider);
    if (reduce && _ticker.isActive) _ticker.stop();
    if (!reduce && !_ticker.isActive) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _DoodlePainter(
            _doodles,
            _elapsed.inMilliseconds / 1000,
            (widget.color ?? AkBrand.ink).withValues(alpha: widget.opacity),
          ),
        ),
      ),
    ),
  );
}

enum _DoodleKind { note, doubleNote, star, dot }

class _Doodle {
  const _Doodle({
    required this.kind,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.sway,
    required this.spin,
  });

  final _DoodleKind kind;
  final double x;
  final double y;
  final double size;
  final double speed;
  final double sway;
  final double spin;
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.doodles, this.t, this.color);

  final List<_Doodle> doodles;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final d in doodles) {
      // Drift upwards and wrap around; sway sideways.
      final y = ((d.y - t * d.speed) % 1.0 + 1.0) % 1.0;
      final x = d.x + math.sin(t * 0.6 + d.sway) * 0.02;
      final c = Offset(x * size.width, y * size.height);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(math.sin(t * 0.5 + d.sway) * 0.3 + d.spin);
      final s = d.size;
      stroke.strokeWidth = s * 0.12;
      switch (d.kind) {
        case _DoodleKind.note:
          canvas.drawOval(Rect.fromCenter(center: Offset(0, s * 0.35), width: s * 0.55, height: s * 0.4), fill);
          canvas.drawLine(Offset(s * 0.25, s * 0.3), Offset(s * 0.25, -s * 0.45), stroke);
          canvas.drawLine(Offset(s * 0.25, -s * 0.45), Offset(s * 0.5, -s * 0.2), stroke);
        case _DoodleKind.doubleNote:
          canvas.drawOval(Rect.fromCenter(center: Offset(-s * 0.3, s * 0.35), width: s * 0.45, height: s * 0.34), fill);
          canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.3, s * 0.25), width: s * 0.45, height: s * 0.34), fill);
          canvas.drawLine(Offset(-s * 0.1, s * 0.3), Offset(-s * 0.1, -s * 0.4), stroke);
          canvas.drawLine(Offset(s * 0.5, s * 0.2), Offset(s * 0.5, -s * 0.5), stroke);
          canvas.drawLine(Offset(-s * 0.1, -s * 0.4), Offset(s * 0.5, -s * 0.5), stroke..strokeWidth = s * 0.16);
        case _DoodleKind.star:
          final path = Path();
          for (var i = 0; i < 10; i++) {
            final r = i.isEven ? s * 0.5 : s * 0.22;
            final a = i * math.pi / 5 - math.pi / 2;
            final p = Offset(math.cos(a) * r, math.sin(a) * r);
            i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
          }
          canvas.drawPath(path..close(), stroke..strokeJoin = StrokeJoin.round);
        case _DoodleKind.dot:
          canvas.drawCircle(Offset.zero, s * 0.18, fill);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => old.t != t || old.color != color;
}

/// A one-shot burst of confetti from the centre (celebrations). Restart with a new [key].
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.pieces = 70});

  final int pieces;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final List<_Piece> _pieces;

  static const _colors = [AkBrand.sun, AkBrand.orange, AkBrand.teal, AkBrand.lavender, Colors.white];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _pieces = [
      for (var i = 0; i < widget.pieces; i++)
        _Piece(
          angle: random.nextDouble() * math.pi * 2,
          speed: 0.35 + random.nextDouble() * 0.65,
          color: _colors[random.nextInt(_colors.length)],
          spin: (random.nextDouble() - 0.5) * 12,
          size: 6 + random.nextDouble() * 8,
          round: random.nextBool(),
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) =>
            CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _controller.value)),
      ),
    ),
  );
}

class _Piece {
  const _Piece({
    required this.angle,
    required this.speed,
    required this.color,
    required this.spin,
    required this.size,
    required this.round,
  });

  final double angle;
  final double speed;
  final Color color;
  final double spin;
  final double size;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.42);
    final reach = size.shortestSide * 0.75;
    for (final p in pieces) {
      final out = Curves.easeOutCubic.transform(math.min(1, t * 1.6)) * p.speed * reach;
      final fall = t * t * size.height * 0.45;
      final pos = origin + Offset(math.cos(p.angle) * out, math.sin(p.angle) * out * 0.8 + fall);
      final paint = Paint()..color = p.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.45), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
