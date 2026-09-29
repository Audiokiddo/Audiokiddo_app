// Run explicitly: flutter test tool/render_golden_test.dart
// Exports our native vector artwork, not screenshots or third-party image edits.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audiokiddo/core/widgets/golden_painter.dart';

Future<void> export(String file, GoldenPainter painter, {int width = 600, int height = 690}) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), Size(width.toDouble(), height.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final output = File(file);
  await output.parent.create(recursive: true);
  await output.writeAsBytes(data!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export Golden artwork and motion frames', () async {
    for (final outfit in GoldenOutfit.values) {
      final name = 'golden_${outfit.name}';
      final painter = GoldenPainter(
        outfit: outfit,
        cheeky: outfit == GoldenOutfit.official,
        mood: outfit == GoldenOutfit.pajamas ? KiddoMood.sleepy : KiddoMood.idle,
      );
      await export('android/app/src/main/res/drawable-nodpi/$name.png', painter, width: 240, height: 276);
      await export('ios/AudioKiddoWidget/Assets.xcassets/$name.imageset/$name.png', painter);
      await File('ios/AudioKiddoWidget/Assets.xcassets/$name.imageset/Contents.json').writeAsString(
        '{"images":[{"filename":"$name.png","idiom":"universal"}],"info":{"author":"xcode","version":1}}',
      );
      await export('../docs/golden/$name.png', painter);
    }
    for (var i = 0; i < 40; i++) {
      await export(
        '../docs/golden/frames/golden_${i.toString().padLeft(3, '0')}.png',
        GoldenPainter(outfit: GoldenOutfit.official, phase: i / 40, animated: true, wave: true, cheeky: true),
        width: 400,
        height: 460,
      );
    }
  });
}
