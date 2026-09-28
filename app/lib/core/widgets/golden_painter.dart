import 'dart:math' as math;

import 'package:flutter/material.dart';

enum GoldenOutfit { day, adventure, pajamas }

enum KiddoMood { idle, talking, listening, happy, sleepy }

GoldenOutfit goldenOutfitAt(DateTime time) => switch (time.hour) {
  >= 5 && < 11 => GoldenOutfit.day,
  >= 11 && < 19 => GoldenOutfit.adventure,
  _ => GoldenOutfit.pajamas,
};

/// Original, articulated AudioKiddo golden retriever. The same painter is used to
/// export widget artwork, so the mobile widgets never acquire a different mascot.
class GoldenPainter extends CustomPainter {
  const GoldenPainter({
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
  static const ink = Color(0xFF50321F);
  static const fur = Color(0xFFE7AD51);
  static const light = Color(0xFFFFD68A);
  static const ear = Color(0xFFC58637);
  static const muzzle = Color(0xFFFFE2A3);
  static const teal = Color(0xFF247F83);

  void _shape(Canvas c, Path path, Color color, {double line = 2.1}) {
    c.drawPath(path, Paint()..color = color);
    if (line > 0) {
      c.drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = line
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _oval(Canvas c, Rect r, Color color, {double line = 2.1}) =>
      _shape(c, Path()..addOval(r), color, line: line);
  void _stroke(Canvas c, Path path, {Color color = ink, double width = 2.2}) => c.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 230);
    final t = phase * math.pi * 2;
    final sleepy = mood == KiddoMood.sleepy;
    final motion = animated ? 1.0 : 0.0;
    final breath = math.sin(t) * 1.4 * motion;
    final wag = math.sin(t * 4) * (mood == KiddoMood.happy || wave ? .24 : .10) * motion;
    canvas.drawOval(const Rect.fromLTWH(39, 215, 122, 9), Paint()..color = const Color(0x1850321F));
    canvas.translate(0, breath);

    // Tail: an independent pivot, behind the body, never a whole-image wobble.
    canvas.save();
    canvas.translate(143, 166);
    canvas.rotate(wag);
    _shape(
      canvas,
      Path()
        ..moveTo(-5, 22)
        ..cubicTo(21, 28, 45, 5, 38, -19)
        ..quadraticBezierTo(34, -7, 25, -10)
        ..quadraticBezierTo(32, 10, 10, 12)
        ..close(),
      fur,
    );
    _stroke(
      canvas,
      Path()
        ..moveTo(26, -7)
        ..quadraticBezierTo(33, 6, 22, 15),
      color: light,
      width: 5,
    );
    canvas.restore();

    final clothes = outfit == GoldenOutfit.pajamas ? const Color(0xFF9082BD) : teal;
    _shape(
      canvas,
      Path()
        ..moveTo(68, 122)
        ..cubicTo(48, 140, 45, 186, 58, 205)
        ..quadraticBezierTo(100, 225, 143, 204)
        ..cubicTo(156, 178, 149, 141, 132, 122)
        ..close(),
      outfit == GoldenOutfit.adventure ? const Color(0xFF9B9259) : clothes,
    );
    // A little round belly gives him the confident, comfortably fed silhouette.
    _oval(
      canvas,
      const Rect.fromLTWH(77, 150, 47, 48),
      outfit == GoldenOutfit.adventure ? const Color(0xFFD8C08A) : clothes,
      line: 0,
    );
    if (outfit == GoldenOutfit.adventure) {
      for (final x in [60.0, 128.0]) {
        _shape(
          canvas,
          Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, 160, 16, 22), const Radius.circular(3))),
          const Color(0xFFC3AC71),
          line: 1.5,
        );
        _stroke(
          canvas,
          Path()
            ..moveTo(x + 2, 166)
            ..lineTo(x + 14, 166),
          width: 1.4,
        );
      }
      _stroke(
        canvas,
        Path()
          ..moveTo(101, 147)
          ..lineTo(101, 200),
        width: 1.5,
      );
    } else if (outfit == GoldenOutfit.pajamas) {
      for (final p in [
        const Offset(70, 159),
        const Offset(116, 173),
        const Offset(88, 193),
        const Offset(131, 194),
      ]) {
        _star(canvas, p, 4.3);
      }
      _stroke(
        canvas,
        Path()
          ..moveTo(100, 150)
          ..lineTo(100, 204),
        color: const Color(0xFF625784),
        width: 1.3,
      );
    } else {
      // Small embroidered paw; no borrowed character insignia.
      _oval(canvas, const Rect.fromLTWH(88, 165, 18, 14), muzzle, line: 0);
      for (final p in [const Offset(87, 160), const Offset(96, 156), const Offset(105, 160)]) {
        _oval(canvas, Rect.fromCenter(center: p, width: 6, height: 7), muzzle, line: 0);
      }
    }
    // Front paws, with the right foreleg free to wave.
    _shape(
      canvas,
      Path()
        ..moveTo(58, 146)
        ..cubicTo(43, 155, 41, 185, 48, 195)
        ..quadraticBezierTo(59, 205, 66, 194)
        ..lineTo(69, 164)
        ..close(),
      fur,
    );
    canvas.save();
    canvas.translate(138, 153);
    if (wave) canvas.rotate(-.65 + math.sin(t * 3) * .18 * motion);
    _shape(
      canvas,
      Path()
        ..moveTo(-4, -8)
        ..cubicTo(10, -3, 20, 22, 14, 36)
        ..quadraticBezierTo(7, 46, -3, 35)
        ..lineTo(-8, 12)
        ..close(),
      fur,
    );
    _stroke(
      canvas,
      Path()
        ..moveTo(4, 33)
        ..lineTo(5, 38),
      width: 1.2,
    );
    canvas.restore();
    for (final x in [57.0, 111.0]) {
      _oval(canvas, Rect.fromLTWH(x, 202, 37, 17), light);
      for (final dx in [10.0, 19.0]) {
        _stroke(
          canvas,
          Path()
            ..moveTo(x + dx, 211)
            ..lineTo(x + dx, 216),
          width: 1.3,
        );
      }
    }

    // Neckerchief stays recognisable across all costumes.
    _shape(
      canvas,
      Path()
        ..moveTo(64, 125)
        ..quadraticBezierTo(100, 146, 137, 125)
        ..lineTo(112, 152)
        ..lineTo(98, 145)
        ..lineTo(86, 151)
        ..close(),
      outfit == GoldenOutfit.day ? const Color(0xFFF6CB56) : teal,
    );
    _oval(canvas, const Rect.fromLTWH(97, 141, 11, 11), const Color(0xFFFFD87D), line: 1.5);

    // Articulated head and floppy ears.
    canvas.save();
    canvas.translate(100, 97);
    final tilt = mood == KiddoMood.listening
        ? -.10
        : cheeky
        ? .035
        : 0.0;
    canvas.rotate(tilt + (mood == KiddoMood.talking ? math.sin(t * 2) * .025 * motion : 0));
    canvas.translate(-100, -97);
    for (final right in [false, true]) {
      canvas.save();
      if (right) {
        canvas.translate(200, 0);
        canvas.scale(-1, 1);
      }
      canvas.translate(54, 63);
      canvas.rotate(math.sin(t * 2) * .025 * motion);
      _shape(
        canvas,
        Path()
          ..moveTo(9, -13)
          ..cubicTo(-15, -21, -31, 9, -27, 39)
          ..quadraticBezierTo(-26, 66, -10, 69)
          ..quadraticBezierTo(5, 73, 12, 43)
          ..quadraticBezierTo(17, 16, 9, -13)
          ..close(),
        ear,
      );
      _stroke(
        canvas,
        Path()
          ..moveTo(-9, 5)
          ..quadraticBezierTo(-18, 32, -10, 52),
        color: const Color(0xFFDFA64F),
        width: 5,
      );
      canvas.restore();
    }
    _shape(
      canvas,
      Path()
        ..moveTo(51, 47)
        ..cubicTo(59, 26, 87, 27, 95, 29)
        ..lineTo(90, 19)
        ..quadraticBezierTo(112, 16, 119, 32)
        ..lineTo(130, 27)
        ..lineTo(132, 38)
        ..cubicTo(154, 42, 158, 68, 154, 92)
        ..lineTo(162, 103)
        ..lineTo(151, 105)
        ..lineTo(155, 114)
        ..lineTo(143, 113)
        ..cubicTo(135, 140, 70, 144, 53, 115)
        ..lineTo(43, 119)
        ..lineTo(46, 108)
        ..lineTo(37, 105)
        ..lineTo(46, 95)
        ..cubicTo(40, 74, 42, 58, 51, 47)
        ..close(),
      fur,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(59, 48)
        ..quadraticBezierTo(80, 34, 96, 39)
        ..quadraticBezierTo(112, 29, 132, 46)
        ..quadraticBezierTo(109, 38, 102, 56)
        ..quadraticBezierTo(78, 46, 59, 48)
        ..close(),
      light,
      line: 0,
    );

    final blink = animated && phase > .90 && phase < .96;
    for (final right in [false, true]) {
      final x = right ? 119.0 : 78.0;
      if (sleepy || blink) {
        _stroke(
          canvas,
          Path()
            ..moveTo(x - 10, 76)
            ..quadraticBezierTo(x, 84, x + 10, 76),
          width: 3,
        );
      } else {
        _oval(
          canvas,
          Rect.fromCenter(center: Offset(x, 74), width: 28, height: 31),
          const Color(0xFFFFFBEE),
          line: 1.8,
        );
        final pupilX =
            x +
            (cheeky
                ? 3
                : mood == KiddoMood.listening
                ? -3
                : 1);
        _oval(canvas, Rect.fromCenter(center: Offset(pupilX, 78), width: 12, height: 17), ink, line: 0);
        _oval(
          canvas,
          Rect.fromCenter(center: Offset(pupilX + 2, 74), width: 4, height: 5),
          Colors.white,
          line: 0,
        );
        if (cheeky) {
          _shape(
            canvas,
            Path()
              ..moveTo(x - 14, 62)
              ..quadraticBezierTo(x, 57, x + 14, 63)
              ..lineTo(x + 13, right ? 71 : 68)
              ..lineTo(x - 13, right ? 69 : 66)
              ..close(),
            fur,
            line: 0,
          );
          _stroke(
            canvas,
            Path()
              ..moveTo(x - 12, right ? 69 : 66)
              ..lineTo(x + 12, right ? 71 : 68),
            width: 1.8,
          );
        }
      }
      final brow = right && cheeky ? 49.0 : 54.0;
      _stroke(
        canvas,
        Path()
          ..moveTo(x - 11, brow)
          ..quadraticBezierTo(x, brow - 5, x + 10, brow + 1),
        width: 4,
      );
    }
    // Wide two-lobed retriever muzzle, charcoal nose and crooked smile.
    _shape(
      canvas,
      Path()
        ..moveTo(100, 90)
        ..cubicTo(73, 78, 53, 92, 63, 112)
        ..quadraticBezierTo(71, 125, 99, 118)
        ..quadraticBezierTo(126, 127, 138, 112)
        ..cubicTo(149, 94, 128, 78, 100, 90)
        ..close(),
      muzzle,
      line: 1.7,
    );
    final opening = mood == KiddoMood.talking
        ? (animated ? .5 + .5 * math.sin(t * 9) : .6)
        : mood == KiddoMood.happy
        ? .85
        : .15;
    _shape(
      canvas,
      Path()
        ..moveTo(79, 111)
        ..quadraticBezierTo(101, 120, 128, 108)
        ..quadraticBezierTo(114, 133 + opening * 9, 99, 132 + opening * 9)
        ..quadraticBezierTo(83, 128 + opening * 6, 79, 111)
        ..close(),
      ink,
      line: 1.3,
    );
    if (opening > .3) {
      _oval(canvas, Rect.fromLTWH(96, 128, 19, 7 + opening * 3), const Color(0xFFE58A7F), line: 0);
    }
    _shape(
      canvas,
      Path()
        ..moveTo(83, 90)
        ..quadraticBezierTo(100, 84, 117, 90)
        ..quadraticBezierTo(118, 101, 102, 107)
        ..quadraticBezierTo(87, 104, 83, 90)
        ..close(),
      const Color(0xFF352820),
      line: 1.5,
    );
    _stroke(
      canvas,
      Path()
        ..moveTo(90, 92)
        ..quadraticBezierTo(99, 89, 106, 92),
      color: const Color(0xFF766255),
      width: 2.5,
    );
    _stroke(
      canvas,
      Path()
        ..moveTo(101, 106)
        ..lineTo(101, 112),
      width: 1.4,
    );
    for (final p in [
      const Offset(74, 102),
      const Offset(80, 106),
      const Offset(126, 102),
      const Offset(120, 107),
    ]) {
      canvas.drawCircle(p, 1.2, Paint()..color = ear);
    }
    if (outfit == GoldenOutfit.pajamas) {
      _shape(
        canvas,
        Path()
          ..moveTo(54, 45)
          ..cubicTo(67, 0, 131, 0, 156, 43)
          ..quadraticBezierTo(169, 52, 166, 68)
          ..quadraticBezierTo(157, 55, 144, 51)
          ..quadraticBezierTo(109, 30, 54, 45)
          ..close(),
        const Color(0xFF9082BD),
      );
      _shape(
        canvas,
        Path()
          ..moveTo(54, 41)
          ..quadraticBezierTo(102, 24, 148, 45)
          ..lineTo(145, 55)
          ..quadraticBezierTo(102, 37, 55, 52)
          ..close(),
        const Color(0xFFD9D0EF),
        line: 1.7,
      );
      _oval(canvas, const Rect.fromLTWH(157, 61, 17, 17), const Color(0xFFD9D0EF), line: 1.7);
      _star(canvas, const Offset(104, 18), 5);
    }
    canvas.restore();
    canvas.restore();
  }

  void _star(Canvas c, Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5 - math.pi / 2, r = i.isEven ? radius : radius * .43;
      final x = center.dx + math.cos(a) * r, y = center.dy + math.sin(a) * r;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    _shape(c, path..close(), const Color(0xFFFFE2A3), line: 0);
  }

  @override
  bool shouldRepaint(GoldenPainter old) =>
      old.mood != mood ||
      old.outfit != outfit ||
      old.phase != phase ||
      old.animated != animated ||
      old.wave != wave ||
      old.cheeky != cheeky;
}
