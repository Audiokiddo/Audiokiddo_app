import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import 'ambient_motion.dart';

/// What Kiddo is doing; each mood has its own motion.
enum KiddoMood {
  /// Breathing and blinking.
  idle,

  /// Mouth moves, as if Kiddo were the narrator.
  talking,

  /// Head tilted, headphone cups pulse: "I'm listening to you".
  listening,

  /// A springy jump with sparkles.
  happy,

  /// Eyes closed, slow breathing (bedtime).
  sleepy,
}

/// AudioKiddo's mascot: a round, sunny character with headphones and the three "spark"
/// strokes from the logo. Drawn in code, so it is sharp at any size and costs no assets.
///
/// Purely decorative for screen readers; the screen around it says what happens.
class Kiddo extends ConsumerStatefulWidget {
  const Kiddo({super.key, this.size = 160, this.mood = KiddoMood.idle, this.wave = false});

  final double size;
  final KiddoMood mood;

  /// Raises a hand and waves (greetings).
  final bool wave;

  @override
  ConsumerState<Kiddo> createState() => _KiddoState();
}

class _KiddoState extends ConsumerState<Kiddo> with TickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
    value: 0.5,
  );
  late final _talk = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  late final _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  late final _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  final _random = math.Random();
  Timer? _blinkTimer;

  bool get _ambient => ref.read(ambientMotionProvider);

  @override
  void initState() {
    super.initState();
    if (_ambient) {
      _breath.repeat(reverse: true);
      _scheduleBlink();
    }
    _applyMood(null);
  }

  @override
  void didUpdateWidget(Kiddo old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood || old.wave != widget.wave) _applyMood(old.mood);
  }

  void _applyMood(KiddoMood? previous) {
    if (widget.mood == KiddoMood.talking && _ambient) {
      _talk.repeat(reverse: true);
    } else {
      _talk.animateTo(0, duration: const Duration(milliseconds: 120));
    }
    if (widget.mood == KiddoMood.happy && previous != KiddoMood.happy) _jump.forward(from: 0);
    _breath.duration = Duration(milliseconds: widget.mood == KiddoMood.sleepy ? 4200 : 2400);
    if (_breath.isAnimating) _breath.repeat(reverse: true);
    if (widget.wave && _ambient) {
      _wave.repeat(reverse: true);
    } else {
      _wave.animateTo(0);
    }
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 1800 + _random.nextInt(3200)), () async {
      if (!mounted) return;
      if (widget.mood != KiddoMood.sleepy) {
        await _blink.forward(from: 0);
        if (mounted) await _blink.reverse();
      }
      if (mounted) _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath.dispose();
    _talk.dispose();
    _blink.dispose();
    _jump.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size * 1.15,
          child: AnimatedBuilder(
            animation: Listenable.merge([_breath, _talk, _blink, _jump, _wave]),
            builder: (context, _) => CustomPaint(
              painter: _KiddoPainter(
                mood: widget.mood,
                breath: reduceMotion ? 0.5 : Curves.easeInOut.transform(_breath.value),
                mouthOpen: _talk.value,
                blink: _blink.value,
                jump: reduceMotion ? 0 : _jumpHeight(_jump.value),
                wave: widget.wave ? _wave.value : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Up fast, down with a little bounce.
  static double _jumpHeight(double t) {
    if (t == 0 || t == 1) return 0;
    if (t < 0.4) return Curves.easeOut.transform(t / 0.4);
    return 1 - Curves.bounceOut.transform((t - 0.4) / 0.6);
  }
}

class _KiddoPainter extends CustomPainter {
  _KiddoPainter({
    required this.mood,
    required this.breath,
    required this.mouthOpen,
    required this.blink,
    required this.jump,
    required this.wave,
  });

  final KiddoMood mood;
  final double breath;
  final double mouthOpen;
  final double blink;
  final double jump;
  final double? wave;

  static const _body = AkBrand.sun;
  static const _bodyShade = Color(0xFFF2A900);
  static const _band = Color(0xFF4A3228);
  static const _cup = AkBrand.teal;
  static const _ink = AkBrand.ink;
  static const _cheek = Color(0xFFFF8A65);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final unit = w / 100;
    final ground = size.height - 4 * unit;
    final lift = jump * 22 * unit;
    final squash = 1 + (breath - 0.5) * 0.04;
    final bodyW = 70 * unit / squash;
    final bodyH = 66 * unit * squash;
    final center = Offset(w / 2, ground - bodyH / 2 - lift);

    // Shadow shrinks while Kiddo is in the air.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, ground), width: bodyW * (0.8 - jump * 0.35), height: 6 * unit),
      Paint()..color = Colors.black.withValues(alpha: 0.12 - jump * 0.06),
    );

    canvas.save();
    final tilt = mood == KiddoMood.listening ? -0.12 : 0.0;
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.translate(-center.dx, -center.dy);

    if (mood == KiddoMood.happy && jump > 0.05) _sparkles(canvas, center, unit);

    // Feet peek out under the body.
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(side * bodyW * 0.2, bodyH * 0.47),
          width: 17 * unit,
          height: 9 * unit,
        ),
        Paint()..color = _band,
      );
    }

    // Body.
    final bodyRect = Rect.fromCenter(center: center, width: bodyW, height: bodyH);
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [Color(0xFFFFD75E), _body, _bodyShade],
          stops: [0, 0.6, 1],
        ).createShader(bodyRect),
    );

    // Headphone band and cups.
    final band = Rect.fromCenter(
      center: center.translate(0, -bodyH * 0.05),
      width: bodyW * 1.08,
      height: bodyH * 1.05,
    );
    canvas.drawArc(
      band,
      math.pi * 1.08,
      math.pi * 0.84,
      false,
      Paint()
        ..color = _band
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * unit
        ..strokeCap = StrokeCap.round,
    );
    final pulse = mood == KiddoMood.listening ? breath : 0.0;
    for (final side in [-1.0, 1.0]) {
      final cup = center.translate(side * bodyW * 0.5, -bodyH * 0.02);
      if (pulse > 0) {
        for (var i = 1; i <= 2; i++) {
          canvas.drawCircle(
            cup,
            (11 + i * 6 + pulse * 5) * unit,
            Paint()
              ..color = _cup.withValues(alpha: (0.35 - i * 0.12) * (1 - pulse * 0.5))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * unit,
          );
        }
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: cup, width: 13 * unit, height: 20 * unit),
          Radius.circular(6 * unit),
        ),
        Paint()..color = _cup,
      );
    }

    // Waving arm in front, raised beside the head.
    if (wave != null) {
      final angle = -0.35 - wave! * 0.75;
      final shoulder = center + Offset(bodyW * 0.44, bodyH * 0.2);
      final hand = shoulder + Offset(math.cos(angle) * 24 * unit, math.sin(angle) * 24 * unit);
      canvas.drawLine(
        shoulder,
        hand,
        Paint()
          ..color = _bodyShade
          ..strokeWidth = 8 * unit
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(hand, 7 * unit, Paint()..color = const Color(0xFFFFD75E));
    }

    // Spark strokes from the logo.
    final spark = Paint()
      ..color = _ink
      ..strokeWidth = 2.6 * unit
      ..strokeCap = StrokeCap.round;
    final top = center.translate(bodyW * 0.52, -bodyH * 0.6);
    canvas.drawLine(top, top.translate(1 * unit, -9 * unit), spark);
    canvas.drawLine(top.translate(5 * unit, 2 * unit), top.translate(11 * unit, -5 * unit), spark);
    canvas.drawLine(top.translate(7 * unit, 7 * unit), top.translate(15 * unit, 5 * unit), spark);

    // Face.
    final eyeY = center.dy - bodyH * 0.06;
    final eyeDx = bodyW * 0.17;
    final open = mood == KiddoMood.sleepy ? 0.0 : 1 - blink;
    for (final side in [-1.0, 1.0]) {
      final eye = Offset(center.dx + side * eyeDx, eyeY);
      if (open < 0.15) {
        canvas.drawArc(
          Rect.fromCenter(center: eye, width: 10 * unit, height: 7 * unit),
          0.2,
          math.pi - 0.4,
          false,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4 * unit
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: eye, width: 11 * unit, height: 13 * unit * open),
          Paint()..color = Colors.white,
        );
        final look = mood == KiddoMood.listening ? Offset(-1.5 * unit, -1 * unit) : Offset.zero;
        canvas.drawOval(
          Rect.fromCenter(
            center: eye + look + Offset(0, 1 * unit),
            width: 6.5 * unit,
            height: 8 * unit * open,
          ),
          Paint()..color = _ink,
        );
        canvas.drawCircle(
          eye + look + Offset(-1.2 * unit, -1.2 * unit),
          1.3 * unit,
          Paint()..color = Colors.white,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + side * bodyW * 0.28, eyeY + 9 * unit),
          width: 9 * unit,
          height: 5 * unit,
        ),
        Paint()..color = _cheek.withValues(alpha: 0.55),
      );
    }

    // Mouth: a smile, open when talking or happy.
    final mouthCenter = Offset(center.dx, eyeY + 13 * unit);
    final opening = switch (mood) {
      KiddoMood.talking => 0.25 + mouthOpen * 0.75,
      KiddoMood.happy => 0.9,
      _ => 0.0,
    };
    if (opening > 0.05) {
      final mouth = Path()
        ..moveTo(mouthCenter.dx - 7 * unit, mouthCenter.dy - 1 * unit)
        ..quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy - 2 * unit,
          mouthCenter.dx + 7 * unit,
          mouthCenter.dy - 1 * unit,
        )
        ..quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy + 12 * unit * opening,
          mouthCenter.dx - 7 * unit,
          mouthCenter.dy - 1 * unit,
        )
        ..close();
      canvas.drawPath(mouth, Paint()..color = const Color(0xFF7A2E1F));
      canvas.drawCircle(
        mouthCenter.translate(0, 5 * unit * opening),
        3 * unit * opening,
        Paint()..color = const Color(0xFFFF7A6B),
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(center: mouthCenter.translate(0, -3 * unit), width: 13 * unit, height: 9 * unit),
        0.35,
        math.pi - 0.7,
        false,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 * unit
          ..strokeCap = StrokeCap.round,
      );
    }

    if (mood == KiddoMood.sleepy) _zzz(canvas, center.translate(bodyW * 0.45, -bodyH * 0.55), unit);
    canvas.restore();
  }

  void _sparkles(Canvas canvas, Offset center, double unit) {
    final paint = Paint()..color = AkBrand.orange;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + jump;
      final r = (44 + jump * 12) * unit;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r * 0.8);
      _star(canvas, p, (3 + jump * 2) * unit, i.isEven ? paint : (Paint()..color = AkBrand.teal));
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final radius = i.isEven ? r : r * 0.4;
      final a = i * math.pi / 4 - math.pi / 2;
      final p = c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  void _zzz(Canvas canvas, Offset at, double unit) {
    final style = TextStyle(
      color: _ink.withValues(alpha: 0.7),
      fontSize: 9 * unit,
      fontWeight: FontWeight.w700,
    );
    for (var i = 0; i < 3; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'z',
          style: style.copyWith(fontSize: (7 + i * 3) * unit),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at + Offset(i * 6 * unit, -i * 8 * unit - breath * 3 * unit));
    }
  }

  @override
  bool shouldRepaint(_KiddoPainter old) =>
      old.mood != mood ||
      old.breath != breath ||
      old.mouthOpen != mouthOpen ||
      old.blink != blink ||
      old.jump != jump ||
      old.wave != wave;
}
