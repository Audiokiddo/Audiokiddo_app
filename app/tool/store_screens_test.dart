// Raw screens of the real app for the store screenshots (docs/sklepy/zrzuty). A sample family:
// Zosia, 5, some plays finished (stickers in the album) and the Detektyw pack bought.
//   cd app && flutter test tool/store_screens_test.dart
//   python3 ../tool/store_frames.py        # adds the captions and the store sizes
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ak_core/ak_core.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/player/audio_handler.dart';
import 'package:audiokiddo/features/player/playback_controller.dart';
import 'package:audiokiddo/features/player/player_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../test/helpers.dart';
import '../test/queue_runner_test.dart' show QueueAudio;

/// (name, logical size, pixel ratio): the phone shots go into a frame, the tablet ones too.
const devices = [('phone', Size(430, 932), 3.0), ('tablet', Size(1032, 1376), 2.0)];

const screens = <(String, String)>[
  ('1-start', '/'),
  ('2-odtwarzacz', '/odtwarzacz'),
  ('3-biblioteka', '/biblioteka'),
  ('4-sytuacje', '/ratunku'),
  ('5-podroz', '/podroz'),
  ('6-naklejki', '/naklejki'),
  ('7-pakiet', '/pakiet/detektyw'),
  ('8-pobrane', '/pobrane'),
];

void main() {
  for (final (device, size, ratio) in devices) {
    testWidgets('store screens: $device', (tester) async {
      tester.view.physicalSize = size * ratio;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      for (final (family, file) in [
        ('Poppins', 'assets/fonts/Poppins-Regular.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(family)..addFont(rootBundle.load(file))).load();
      }
      final db = memoryDatabase();
      final now = DateTime.now();
      await db.writeValue(
        'family_children',
        jsonEncode([
          {
            'id': 'z',
            'name': 'Zosia',
            'age': 5,
            'started_on': '2026-09-20',
            'goals': ['imagination', 'calm'],
            'situations': [],
            'daily_minutes': 20,
          },
        ]),
      );
      await db.writeValue('family_active', 'z');
      await db.writeValue(
        'family_results',
        jsonEncode([
          for (final (i, id) in [
            'magiczny-sklep',
            'co-to-za-dzwiek',
            'zlodziej-naszyjnika',
            'zgubiona-gwiazdka',
            'znikajace-dzwonki',
            'magiczny-sklep',
          ].indexed)
            {
              'child': 'z',
              'item': id,
              'at': now.subtract(Duration(days: 6 - i)).toIso8601String(),
              'seconds': 600,
              'completed': true,
              'answers': 0,
            },
        ]),
      );
      for (final (name, route) in screens) {
        final playing = name == '2-odtwarzacz';
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...testOverrides(
                db,
                media: !playing
                    ? null
                    : const MediaItem(
                        id: 'zlodziej-naszyjnika',
                        title: 'Złodziej naszyjnika',
                        album: 'Detektyw',
                        duration: Duration(minutes: 18),
                      ),
              ),
              audioHandlerProvider.overrideWithValue(QueueAudio()),
              playbackStateProvider.overrideWith(
                (ref) =>
                    Stream.value(PlaybackState(playing: true, processingState: AudioProcessingState.ready)),
              ),
              positionProvider.overrideWith((ref) => Stream.value(const Duration(minutes: 6, seconds: 12))),
              sleepTimerProvider.overrideWith((ref) => Stream<SleepTimer?>.value(null)),
              entitlementsProvider.overrideWithValue([
                Entitlement(
                  scope: Scopes.pack('detektyw'),
                  status: EntitlementStatus.active,
                  source: EntitlementSource.woocommerce,
                ),
              ]),
              leaseStateProvider.overrideWithValue(LeaseState.valid),
            ],
            child: RepaintBoundary(
              key: ValueKey(name),
              child: KeyedSubtree(key: key, child: const AudioKiddoApp()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
        router.go(route);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
          await Future.wait([
            for (final a in manifest.listAssets())
              if ((a.startsWith('assets/szop/') || a.startsWith('assets/covers/')) &&
                  (a.endsWith('.png') || a.endsWith('.jpg') || a.endsWith('.webp')))
                precacheImage(AssetImage(a), key.currentContext!),
          ]);
        });
        await tester.pump(const Duration(milliseconds: 600));
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(ValueKey(name)));
          final image = await boundary.toImage(pixelRatio: ratio);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('../docs/sklepy/zrzuty/surowe/$device-$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull, reason: '$route on $device');
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
