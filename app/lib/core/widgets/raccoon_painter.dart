import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'golden_painter.dart';

/// Articulated vector interpretation of the approved raccoon reference sheets.
/// No decoded textures, filters, or offscreen layers are required.
class RaccoonPainter extends CustomPainter {
  const RaccoonPainter({
    this.mood = KiddoMood.idle,
    this.outfit = GoldenOutfit.day,
    this.phase = 0,
    this.animated = false,
    this.wave = false,
    this.cheeky = false,
  });
  final KiddoMood mood;
  final GoldenOutfit outfit;
  final double phase;
  final bool animated, wave, cheeky;
  static const fur = Color(0xFF9D9084), cream = Color(0xFFEADCC9), dark = Color(0xFF574239);
  void shape(Canvas c, Path p, Color color) => c.drawPath(p, Paint()..color = color);
  void oval(Canvas c, double x, double y, double w, double h, Color color) =>
      c.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
  void line(Canvas c, Path p, {double width = 2.4, Color color = dark}) => c.drawPath(
    p,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 200, size.height / 230);
    final t = phase * math.pi * 2;
    final motion = animated ? 1.0 : 0.0;
    final sleepy = mood == KiddoMood.sleepy;
    final beat = animated && cheeky
        ? math.pow(math.sin(math.pi * ((phase - .3) / .3).clamp(0.0, 1.0)), 2).toDouble()
        : 0.0;
    oval(c, 32, 215, 138, 8, const Color(0x18574239));
    c.translate(0, math.sin(t) * 1.2 * motion);
    // Tail has its own pivot. Stripes are clipped to its silhouette.
    c.save();
    c.translate(145, 173);
    c.rotate(math.sin(t * 2) * .08 * motion);
    final tail = Path()
      ..moveTo(-7, 22)
      ..cubicTo(22, 35, 55, 9, 43, -36)
      ..cubicTo(37, -63, 12, -66, 8, -48)
      ..cubicTo(0, -25, 34, -10, -7, 5)
      ..close();
    shape(c, tail, fur);
    c.save();
    c.clipPath(tail);
    for (final y in [-53.0, -24.0, 6.0]) {
      shape(
        c,
        Path()
          ..moveTo(-12, y)
          ..lineTo(53, y + 10)
          ..lineTo(55, y + 26)
          ..lineTo(-12, y + 15)
          ..close(),
        dark,
      );
    }
    c.restore();
    c.restore();
    oval(c, 51, 115, 101, 101, fur);
    oval(c, 72, 140, 60, 68, cream);
    oval(c, 49, 204, 40, 16, dark);
    oval(c, 113, 204, 40, 16, dark);
    // Forearms stay separate from the torso.
    c.save();
    c.translate(58, 147);
    c.rotate(.12);
    oval(c, -17, -7, 29, 53, fur);
    oval(c, -16, 29, 24, 19, dark);
    c.restore();
    c.save();
    c.translate(140, 146);
    c.rotate(wave ? -1.5 + math.sin(t * 3) * .15 * motion : -.12 - beat * .2);
    oval(c, -9, -7, 28, 52, fur);
    oval(c, -6, 28, 25, 19, dark);
    line(
      c,
      Path()
        ..moveTo(2, 39)
        ..lineTo(2, 44),
      width: 1.2,
    );
    c.restore();
    // Tiny employee badge; child costumes use a scarf and nightcap instead.
    if (outfit == GoldenOutfit.official) {
      shape(
        c,
        Path()..addRRect(
          RRect.fromRectAndRadius(const Rect.fromLTWH(112, 143, 22, 26), const Radius.circular(4)),
        ),
        const Color(0xFFF47760),
      );
      line(
        c,
        Path()
          ..moveTo(122, 143)
          ..lineTo(122, 148),
        color: cream,
        width: 4,
      );
      for (var i = 0; i < 3; i++) {
        line(
          c,
          Path()
            ..moveTo(117 + i * 5, 157 - (i == 1 ? 3 : 0))
            ..lineTo(117 + i * 5, 162 + (i == 1 ? 2 : 0)),
          color: cream,
          width: 2,
        );
      }
    } else if (outfit == GoldenOutfit.adventure) {
      shape(
        c,
        Path()
          ..moveTo(62, 126)
          ..lineTo(137, 126)
          ..lineTo(99, 150)
          ..close(),
        const Color(0xFF247F83),
      );
    }
    c.save();
    c.translate(100, 100);
    c.rotate(
      mood == KiddoMood.listening
          ? -.10
          : cheeky
          ? -.04 - beat * .045
          : 0,
    );
    c.translate(-100, -100);
    // Rounded triangular ears, animated independently.
    for (final right in [false, true]) {
      c.save();
      if (right) {
        c.translate(200, 0);
        c.scale(-1, 1);
      }
      c.translate(47, 46);
      c.rotate(math.sin(t * 2 + (right ? 1 : 0)) * .025 * motion);
      shape(
        c,
        Path()
          ..moveTo(-17, 20)
          ..quadraticBezierTo(-36, -31, -19, -35)
          ..quadraticBezierTo(7, -34, 24, 7)
          ..close(),
        cream,
      );
      shape(
        c,
        Path()
          ..moveTo(-13, 8)
          ..quadraticBezierTo(-26, -25, -17, -26)
          ..quadraticBezierTo(2, -24, 12, 4)
          ..close(),
        dark,
      );
      c.restore();
    }
    final head = Path()
      ..moveTo(35, 53)
      ..quadraticBezierTo(54, 24, 88, 29)
      ..lineTo(96, 21)
      ..lineTo(96, 29)
      ..lineTo(110, 23)
      ..lineTo(107, 31)
      ..quadraticBezierTo(143, 26, 164, 56)
      ..lineTo(174, 88)
      ..lineTo(185, 96)
      ..lineTo(173, 101)
      ..lineTo(180, 108)
      ..quadraticBezierTo(143, 140, 100, 138)
      ..quadraticBezierTo(52, 138, 20, 108)
      ..lineTo(27, 101)
      ..lineTo(15, 96)
      ..lineTo(26, 87)
      ..close();
    shape(c, head, fur);
    // Ivory face rim and two distinct dark eye masks.
    shape(
      c,
      Path()
        ..moveTo(25, 88)
        ..quadraticBezierTo(49, 73, 57, 53)
        ..quadraticBezierTo(80, 44, 100, 73)
        ..quadraticBezierTo(121, 43, 145, 53)
        ..quadraticBezierTo(153, 77, 176, 89)
        ..lineTo(169, 99)
        ..lineTo(176, 106)
        ..quadraticBezierTo(143, 138, 100, 137)
        ..quadraticBezierTo(54, 138, 24, 106)
        ..lineTo(31, 98)
        ..close(),
      cream,
    );
    for (final right in [false, true]) {
      c.save();
      if (right) {
        c.translate(200, 0);
        c.scale(-1, 1);
      }
      shape(
        c,
        Path()
          ..moveTo(36, 87)
          ..quadraticBezierTo(56, 75, 60, 63)
          ..quadraticBezierTo(82, 55, 96, 83)
          ..quadraticBezierTo(95, 106, 70.0, 111)
          ..quadraticBezierTo(47, 112, 35, 101)
          ..lineTo(40, 97)
          ..close(),
        dark,
      );
      c.restore();
    }
    final blink = animated && phase > .88 && phase < .925;
    for (final right in [false, true]) {
      final x = right ? 123.0 : 70.0;
      if (sleepy || blink) {
        line(
          c,
          Path()
            ..moveTo(x - 13, 87)
            ..quadraticBezierTo(x, 94, x + 13, 86),
          color: cream,
          width: 3,
        );
      } else {
        oval(c, x - 14, 72, 29, 27, const Color(0xFFFFFCF7));
        final gaze = cheeky
            ? 5 - beat * 3
            : mood == KiddoMood.listening
            ? -4.0
            : 1.0;
        oval(c, x - 4 + gaze, 77, 10, cheeky ? 16 : 18, const Color(0xFF25201E));
        oval(c, x + 2 + gaze, 79, 3, 4, Colors.white);
        if (cheeky) {
          shape(
            c,
            Path()
              ..moveTo(x - 16, 70)
              ..lineTo(x + 16, 70)
              ..lineTo(x + 16, right ? 76 - beat * 3 : 81)
              ..lineTo(x - 16, right ? 79 - beat * 3 : 83)
              ..close(),
            dark,
          );
        }
      }
      final y = cheeky ? (right ? 57 - beat * 4 : 66.0) : 65.0;
      line(
        c,
        Path()
          ..moveTo(x - 13, y)
          ..quadraticBezierTo(x, y + (right ? -8 : -1), x + 12, y + (cheeky && !right ? -7 : -2)),
        color: cheeky ? dark : cream,
        width: cheeky ? 4 : 5,
      );
    }
    oval(c, 93, 100, 16, 10, const Color(0xFF282526));
    if (mood == KiddoMood.talking || (mood == KiddoMood.happy && !cheeky) || sleepy) {
      final opening = sleepy
          ? 14.0
          : mood == KiddoMood.happy
          ? 16.0
          : 8 + math.sin(t * 8).abs() * 9 * motion;
      oval(c, 91, 114, 23, opening, dark);
      oval(c, 96, 118 + opening * .35, 13, opening * .35, const Color(0xFFDA7D7D));
    } else {
      line(
        c,
        Path()
          ..moveTo(cheeky ? 91 : 83, cheeky ? 119 : 114)
          ..quadraticBezierTo(105, cheeky ? 124 : 128, 123, cheeky ? 112 - beat * 2 : 111),
        width: 2.5,
      );
      if (cheeky) {
        line(
          c,
          Path()
            ..moveTo(120, 109)
            ..quadraticBezierTo(125, 108, 127, 114),
          width: 2,
        );
      }
    }
    if (outfit == GoldenOutfit.pajamas) {
      shape(
        c,
        Path()
          ..moveTo(62, 35)
          ..quadraticBezierTo(94, -2, 142, 20)
          ..lineTo(165, 51)
          ..quadraticBezierTo(122, 30, 62, 35)
          ..close(),
        const Color(0xFF9082BD),
      );
      line(
        c,
        Path()
          ..moveTo(63, 35)
          ..quadraticBezierTo(100, 24, 141, 35),
        color: const Color(0xFFD9D0EF),
        width: 8,
      );
      oval(c, 154, 43, 14, 14, cream);
    }
    c.restore();
    c.restore();
  }

  @override
  bool shouldRepaint(RaccoonPainter old) =>
      old.mood != mood ||
      old.outfit != outfit ||
      old.phase != phase ||
      old.animated != animated ||
      old.wave != wave ||
      old.cheeky != cheeky;
}
