import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/diploma/diploma.dart';
import 'package:audiokiddo/features/discovery/reference_widgets.dart';
import 'package:audiokiddo/features/family/family.dart';
import 'package:audiokiddo/features/purchases/preview_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

/// The app on a fixed day (seasons and "new" depend on the date).
Future<ProviderContainer> pumpOn(WidgetTester tester, DateTime day) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final db = memoryDatabase();
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(db),
        clockProvider.overrideWithValue(() => day),
        entitlementsProvider.overrideWithValue(const []),
        leaseStateProvider.overrideWithValue(LeaseState.valid),
      ],
      child: const AudioKiddoApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
}

/// Brings [finder] to the middle of the screen (clear of bars), then taps it.
Future<void> tapCentered(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: .4);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder get scroll =>
    find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last;

void main() {
  final catalog = parseCatalog(
    jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>,
  ).catalog;

  test('a pack is finished when every play in it was completed', () {
    final detective = catalog.itemsInPack('detektyw');
    ActivityResult done(String id, {bool completed = true}) =>
        ActivityResult(childId: 'c', itemId: id, at: DateTime(2026, 10), seconds: 60, completed: completed);
    expect(completedPacks([for (final i in detective) done(i.id)], catalog), {'detektyw'});
    expect(completedPacks([for (final i in detective.skip(1)) done(i.id)], catalog), isEmpty);
    expect(
      completedPacks([for (final i in detective) done(i.id, completed: i != detective.first)], catalog),
      isEmpty,
      reason: 'started is not finished',
    );
  });

  test('every pack has a reward line; unknown packs get the general one', () {
    for (final p in catalog.packs) {
      expect(File('assets/audio/kiddo/${bonusLine(p.id)}.m4a').existsSync(), isTrue, reason: p.id);
      expect(bonusTranscript(p.id), isNotEmpty);
    }
    expect(bonusLine('nowy-pakiet'), 'bonus_inne');
    expect(File('assets/audio/kiddo/diploma.m4a').existsSync(), isTrue);
    expect(File('assets/audio/kiddo/fanfare.m4a').existsSync(), isTrue);
  });

  test('every paid recording has a free preview file', () {
    for (final item in catalog.items) {
      if (item.isFree || item.audio.isEmpty) continue;
      expect(item.preview, isNotNull, reason: item.id);
      expect(item.preview!.path, startsWith('previews/'));
    }
  });

  testWidgets('finishing a pack: Start offers the diploma, which is handed over once', (tester) async {
    final container = await pumpOn(tester, DateTime(2026, 10, 2));
    final family = container.read(familyProvider.notifier);
    await family.saveChild(ChildProfile(id: 'z', name: 'Zosia', age: 7, startedOn: DateTime(2026, 9)));
    for (final item in catalog.itemsInPack('detektyw')) {
      await family.record(itemId: item.id, seconds: item.durationSec);
    }
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pakiet Detektyw ukończony'), 200, scrollable: scroll);
    await tapCentered(tester, find.text('Wręcz dyplom'));
    expect(find.text('DYPLOM'), findsOneWidget);
    expect(find.text('Zosia'), findsOneWidget);
    await tapCentered(tester, find.text('Odbierz nagrodę: sekretna wiadomość'));
    expect(find.textContaining('literę K'), findsOneWidget, reason: 'the reward is also shown as text');
    await tapCentered(tester, find.text('Gotowe'));
    expect(find.text('Pakiet Detektyw ukończony'), findsNothing, reason: 'handed over');
    expect((await container.read(diplomasProvider('z').future)).keys, ['detektyw']);
  });

  testWidgets('autumn on Start: the seasonal row and what is new', (tester) async {
    await pumpOn(tester, DateTime(2026, 10, 2));
    await tester.scrollUntilVisible(find.text('Nowości'), 200, scrollable: scroll);
    expect(find.text('NOWE'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Jesienne wieczory'), 200, scrollable: scroll);
    expect(find.text('Wakacje w drodze'), findsNothing);
  });

  testWidgets('in July the holiday row shows and nothing is new any more', (tester) async {
    await pumpOn(tester, DateTime(2027, 7, 1));
    await tester.scrollUntilVisible(find.text('Wakacje w drodze'), 200, scrollable: scroll);
    expect(find.text('Nowości'), findsNothing);
    expect(find.text('Jesienne wieczory'), findsNothing);
  });

  testWidgets('a locked play can be previewed from the pack page', (tester) async {
    final container = await pumpOn(tester, DateTime(2026, 10, 2));
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/pakiet/wyobraznia');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Zaginiony skarb'), 200, scrollable: scroll);
    Finder inRow(IconData icon) => find.descendant(
      of: find.ancestor(of: find.text('Zaginiony skarb'), matching: find.byType(AudioRow)),
      matching: find.widgetWithIcon(IconButton, icon),
    );
    await tapCentered(tester, inRow(Icons.headphones_rounded));
    final audio = container.read(previewAudioProvider) as FakePreviewAudio;
    expect(audio.played.single.path, endsWith('previews/wyobraznia/zaginiony-skarb.m4a'));
    expect(container.read(previewControllerProvider).itemId, 'zaginiony-skarb');
    await tapCentered(tester, inRow(Icons.stop_rounded));
    expect(container.read(previewControllerProvider).itemId, isNull);
  });
}
