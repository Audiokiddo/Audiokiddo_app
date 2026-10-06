import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/parent_voice/parent_voice.dart';
import 'package:audiokiddo/features/session/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

/// Records what the session plays; catalog items last until [stop] or [finishItem].
class FakeSessionAudio implements SessionAudio {
  final log = <String>[];
  Completer<void>? _item;

  @override
  Future<void> playItem(ContentItem item, {Duration fadeOut = Duration.zero}) {
    log.add(fadeOut > Duration.zero ? 'item:${item.id}:fade' : 'item:${item.id}');
    return (_item = Completer<void>()).future;
  }

  void finishItem() => _item?.complete();

  @override
  Future<void> sayLine(String line) async => log.add('line:$line');

  @override
  Future<void> playClip(String path) async => log.add('clip:$path');

  @override
  Future<void> stop() async {
    final item = _item;
    _item = null;
    if (item != null && !item.isCompleted) item.complete();
  }
}

Catalog loadCatalog() =>
    parseCatalog(jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>).catalog;

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  final catalog = loadCatalog();
  bool all(ContentItem _) => true;

  group('trip', () {
    test('fills the ride with listening, never with games that need the phone', () {
      final steps = buildTrip(catalog, minutes: 30, age: 6, canPlay: all);
      final items = [
        for (final s in steps)
          if (s is ItemStep) s.item,
      ];
      expect(items, isNotEmpty);
      expect(items.where((i) => i.kind == ContentKind.interactiveGame), isEmpty);
      expect((steps.first as LineStep).line, 'trip_start');
      expect((steps[steps.length - 2] as LineStep).line, 'trip_end');
      expect((steps.last as ParentStep).clip, ParentClip.praise);
      final seconds = items.fold(0, (a, i) => a + i.durationSec);
      expect(seconds, lessThanOrEqualTo(30 * 60 + items.last.durationSec));
    });

    test('long rides get "look out of the window" breaks', () {
      final steps = buildTrip(catalog, minutes: 90, age: 8, canPlay: all);
      final breaks = [
        for (final s in steps)
          if (s is LineStep && windowLines.contains(s.line)) s,
      ];
      final seconds = [
        for (final s in steps)
          if (s is ItemStep) s.item.durationSec,
      ].fold(0, (a, b) => a + b);
      if (seconds >= 20 * 60) expect(breaks, isNotEmpty);
      for (final b in breaks) {
        expect(b.pauseAfter, const Duration(seconds: 40));
      }
    });

    test('only what the family may play, downloaded travel items first', () {
      final free = buildTrip(catalog, minutes: 30, age: 6, canPlay: (i) => i.isFree);
      expect(
        [
          for (final s in free)
            if (s is ItemStep) s.item,
        ].every((i) => i.isFree),
        isTrue,
      );

      final travel = catalog.items.firstWhere(
        (i) =>
            i.situations.contains(Situation.podroz) &&
            i.kind != ContentKind.interactiveGame &&
            i.kind != ContentKind.song,
      );
      final steps = buildTrip(catalog, minutes: 15, age: 8, canPlay: all, downloaded: {travel.id});
      expect((steps[1] as ItemStep).item.id, travel.id);
    });
  });

  test('bedtime: breaths, a quiet activity, a lullaby, goodnight', () {
    final steps = buildBedtime(catalog, age: 5, canPlay: all);
    expect((steps.first as LineStep).line, 'bedtime_start');
    final items = [
      for (final s in steps)
        if (s is ItemStep) s.item,
    ];
    expect(items.where((i) => i.kind == ContentKind.song), hasLength(lessThanOrEqualTo(1)));
    expect(items.where((i) => i.kind == ContentKind.interactiveGame), isEmpty);
    for (final s in steps.whereType<ItemStep>()) {
      expect(s.fadeOut, s.item.kind == ContentKind.song ? bedtimeFade : Duration.zero, reason: 'the lullaby fades');
    }
    final last = steps.last as ParentStep;
    expect(last.clip, ParentClip.goodnight);
    expect(last.fallbackLine, 'goodnight');
  });

  group('session controller', () {
    late FakeSessionAudio audio;
    late FakeParentVoiceStore voice;
    late ProviderContainer container;
    final item = loadCatalog().items.first;

    setUp(() {
      audio = FakeSessionAudio();
      voice = FakeParentVoiceStore();
      container = ProviderContainer(
        overrides: [
          sessionAudioProvider.overrideWithValue(audio),
          parentVoiceStoreProvider.overrideWithValue(voice),
          sessionTimeScaleProvider.overrideWithValue(0.001),
        ],
      );
      addTearDown(container.dispose);
    });

    test('plays the steps in order; goodnight falls back to Kiddo', () async {
      final session = container.read(sessionProvider.notifier);
      final done = session.start(SessionKind.bedtime, [
        const LineStep('bedtime_start'),
        ItemStep(item),
        const ParentStep(ParentClip.goodnight, fallbackLine: 'goodnight'),
      ], childId: 'z');
      await settle();
      expect(container.read(sessionProvider).current, isA<ItemStep>());
      expect(container.read(sessionProvider).secondsLeft, item.durationSec);
      audio.finishItem();
      await done;
      expect(audio.log, ['line:bedtime_start', 'item:${item.id}', 'line:goodnight']);
      expect(container.read(sessionProvider).finished, isTrue);
    });

    test('the parent\'s own goodnight replaces Kiddo\'s', () async {
      voice.clipsByChild['z'] = {ParentClip.goodnight: '/fake/z_goodnight.m4a'};
      await container.read(sessionProvider.notifier).start(SessionKind.bedtime, [
        const ParentStep(ParentClip.goodnight, fallbackLine: 'goodnight'),
      ], childId: 'z');
      expect(audio.log.last, 'clip:/fake/z_goodnight.m4a');
    });

    test('skip moves on, stop ends everything', () async {
      final session = container.read(sessionProvider.notifier);
      unawaited(session.start(SessionKind.trip, [ItemStep(item), ItemStep(item), const LineStep('trip_end')]));
      await settle();
      await session.skip();
      await settle();
      expect(container.read(sessionProvider).index, 1);
      await session.stop();
      await settle();
      expect(audio.log.where((l) => l.startsWith('line:')), isEmpty);
      expect(container.read(sessionProvider).kind, isNull);
    });

    // The countdown scaled to 250 ms, long enough to look at it mid-way.
    ProviderContainer slowContainer() {
      final slow = ProviderContainer(
        overrides: [
          sessionAudioProvider.overrideWithValue(audio),
          parentVoiceStoreProvider.overrideWithValue(voice),
          sessionTimeScaleProvider.overrideWithValue(0.05),
        ],
      );
      addTearDown(slow.dispose);
      return slow;
    }

    int played() => audio.log.where((l) => l.startsWith('item:')).length;

    test('the next recording counts down first; the first one starts at once', () async {
      final slow = slowContainer();
      final session = slow.read(sessionProvider.notifier);
      final done = session.start(SessionKind.trip, [const LineStep('trip_start'), ItemStep(item), ItemStep(item)]);
      await settle();
      expect(slow.read(sessionProvider).countdown, isNull);
      expect(audio.log, ['line:trip_start', 'item:${item.id}']);
      audio.finishItem();
      await settle();
      final waiting = slow.read(sessionProvider);
      expect(waiting.index, 2);
      expect(waiting.countdown, inInclusiveRange(1, autoNextDelay.inSeconds));
      expect(played(), 1);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(slow.read(sessionProvider).countdown, isNull);
      expect(played(), 2, reason: 'plays on by itself');
      audio.finishItem();
      await done;
    });

    test('a held countdown waits for the parent, then plays on', () async {
      final slow = slowContainer();
      final session = slow.read(sessionProvider.notifier);
      final done = session.start(SessionKind.trip, [ItemStep(item), ItemStep(item)]);
      await settle();
      audio.finishItem();
      await settle();
      expect(slow.read(sessionProvider).countdown, isNotNull);
      session.hold();
      expect(slow.read(sessionProvider).held, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(slow.read(sessionProvider).held, isTrue);
      expect(played(), 1);
      session.resume();
      await settle();
      expect(slow.read(sessionProvider).countdown, isNull);
      expect(played(), 2);
      audio.finishItem();
      await done;
    });
  });

  testWidgets('evening hero offers "Dobranoc", which runs the ritual', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = memoryDatabase();
    addTearDown(db.close);
    final zosia = ChildProfile(
      id: 'z',
      name: 'Zosia',
      age: 4,
      startedOn: DateTime(2026, 9, 1),
      goals: const {DevGoal.calm},
      dailyMinutes: 10,
    );
    await db.writeValue('family_children', jsonEncode([zosia.toJson()]));
    final audio = FakeSessionAudio();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 9, 28, 20)),
          sessionAudioProvider.overrideWithValue(audio),
          sessionTimeScaleProvider.overrideWithValue(0.001),
        ],
        child: const AudioKiddoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // "Na dobranoc" from Start's quick situations.
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/dobranoc');
    await tester.pumpAndSettle();
    expect(find.text('Trzy spokojne oddechy z Szop’enem'), findsOneWidget);
    expect(find.text('„Dobranoc” od Szop’ena'), findsOneWidget);
    expect(find.text('Nagraj swoje „dobranoc”'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Zaczynamy'), 200);
    await tester.tap(find.text('Zaczynamy'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('DOBRANOC'), findsOneWidget);
    expect(audio.log.first, 'line:bedtime_start');

    await tester.tap(find.byTooltip('Zakończ'));
    await tester.pumpAndSettle();
  });
}
