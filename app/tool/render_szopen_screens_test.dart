// Review-only renders of real application widgets, with the bundled test catalog.
import 'dart:io';
import 'dart:convert';

import 'package:audiokiddo/features/player/player_screen.dart';

import 'package:audio_service/audio_service.dart';
import 'package:audiokiddo/features/player/audio_handler.dart';
import 'package:audiokiddo/features/player/player_providers.dart';
import 'package:audiokiddo/features/player/playback_controller.dart';

import 'dart:ui' as ui;

import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/core/widgets/golden_hello.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../test/helpers.dart';

void main() {
  testWidgets('export Szopen app preview', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final font = FontLoader('Poppins')..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final db = memoryDatabase();
    await db.writeValue(
      'family_children',
      jsonEncode([
        {
          'id': 'preview',
          'name': 'Zosia',
          'age': 5,
          'started_on': '2026-10-02',
          'goals': [],
          'situations': [],
          'daily_minutes': 20,
        },
      ]),
    );
    await db.writeValue('family_active', 'preview');
    await db.writeValue(
      'discovery_v1',
      jsonEncode({
        'queue': ['magiczny-sklep'],
        'routines': [
          {
            'id': 'demo',
            'name': 'Spokojny obiad',
            'items': ['magiczny-sklep'],
          },
        ],
        'quiet': true,
      }),
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(
            db,
            media: const MediaItem(
              id: 'magiczny-sklep',
              title: 'Magiczny sklep',
              album: 'AudioKiddo',
              duration: Duration(minutes: 6),
            ),
          ),
          audioHandlerProvider.overrideWithValue(_PreviewAudio()),
          playbackStateProvider.overrideWith((ref) => Stream.value(PlaybackState())),
          positionProvider.overrideWith((ref) => Stream.value(Duration.zero)),
          sleepTimerProvider.overrideWith((ref) => Stream<SleepTimer?>.value(null)),
        ],
        child: RepaintBoundary(key: key, child: const AudioKiddoApp()),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../docs/redesign-reference/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('start');
    final context = tester.element(find.byType(Scaffold).first);
    final router = GoRouter.of(context);
    showGoldenHello(context);
    await tester.pumpAndSettle();
    await capture('szopen-spotkanie');
    router.pop();
    for (final route in <String, String>{
      'biblioteka': '/biblioteka',
      'kategoria': '/biblioteka?kategoria=adventure',
      'ratunku': '/ratunku',
      'profil': '/profil',
      'rutyny': '/rutyny',
      'kolejka': '/kolejka',
      'pobrane': '/pobrane',
      'wiecej': '/moje',
      'szczegoly': '/zabawa/magiczny-sklep',
      'odtwarzacz': '/odtwarzacz',
    }.entries) {
      router.go(route.value);
      await tester.pumpAndSettle();
      await capture(route.key);
      expect(tester.takeException(), isNull, reason: route.value);
      if (route.key == 'ratunku') {
        await tester.scrollUntilVisible(
          find.text('Pokaż propozycje'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Pokaż propozycje'));
        await tester.pumpAndSettle();
        await capture('propozycje');
      }
    }
    final playerContext = tester.element(find.byType(Scaffold).first);
    showSleepPicker(playerContext);
    await tester.pumpAndSettle();
    await capture('timer-snu');
    Navigator.of(tester.element(find.text('Ustaw timer'))).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(960, 1704);
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}

// No platform audio is created for this visual preview.
class _PreviewAudio implements AkAudioHandler {
  @override
  SleepTimer? get sleepTimer => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
