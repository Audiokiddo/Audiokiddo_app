import 'dart:async';
import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audiokiddo/core/storage/storage_providers.dart';
import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/home/launch_greeting.dart';
import 'package:audiokiddo/features/session/session.dart';
import 'package:audiokiddo/features/session/plan.dart';
import 'package:audiokiddo/features/session/plan_editor.dart';
import 'package:audiokiddo/features/kids_mode/kids_mode_controller.dart';
import 'helpers.dart';
import 'session_test.dart' show FakeSessionAudio, loadCatalog, settle;

class ClosingAudio extends FakeSessionAudio {
  final closing = Completer<void>();
  @override
  Future<void> sayLine(String line) {
    log.add('line:$line');
    return closing.future;
  }
}
void main() {
  final items = loadCatalog().items.where((i) => i.audio.isNotEmpty).take(4).toList();
  testWidgets('AUDIT: skip dismisses curtain while catalog is loading', (tester) async {
    final db = memoryDatabase();
    LaunchGreeting.shown = false;
    await tester.pumpWidget(ProviderScope(overrides: [
      databaseProvider.overrideWithValue(db),
      kidsModeProvider.overrideWithValue(KidsModeController(db)),
      catalogProvider.overrideWith((ref) => Completer<Catalog>().future),
    ], child: MaterialApp(theme: buildTheme(Brightness.light), home: const Scaffold(body: LaunchGreeting()))));
    await tester.pumpAndSettle();
    expect(find.byType(LaunchCurtain), findsOneWidget);
    await tester.tapAt(const Offset(100, 300));
    await tester.pump(const Duration(milliseconds: 300));
    final stillVisible = find.byType(LaunchCurtain).evaluate().isNotEmpty;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
    expect(stillVisible, false, reason: 'tap must skip the curtain even if catalog has not loaded');
  });
  test('AUDIT: adding time during closing speech plays newly added item', () async {
    final db = memoryDatabase();
    final audio = ClosingAudio();
    final c = ProviderContainer(overrides: [...testOverrides(db), sessionAudioProvider.overrideWithValue(audio)]);
    final ctrl = c.read(sessionProvider.notifier);
    final run = ctrl.start(SessionKind.trip, [ItemStep(items[0]), const LineStep('trip_end')]);
    await settle();
    audio.finishItem();
    await settle();
    expect(c.read(sessionProvider).index, 1);
    ctrl.addPlays([items[1]]);
    audio.closing.complete();
    await run;
    final log = [...audio.log];
    c.dispose();
    await db.close();
    expect(log, contains('item:${items[1].id}'));
  });
  testWidgets('AUDIT: replacement chooser cannot change another item after playback advances', (tester) async {
    final db = memoryDatabase();
    final audio = FakeSessionAudio();
    final c = ProviderContainer(overrides: [...testOverrides(db), sessionAudioProvider.overrideWithValue(audio)]);
    final ctrl = c.read(sessionProvider.notifier);
    final run = ctrl.start(SessionKind.dinner, [for(final i in items.take(3)) ItemStep(i)]);
    await tester.pump();
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(theme: buildTheme(Brightness.light), home: Scaffold(body: Consumer(builder: (context, ref, _) {
      final state = ref.watch(sessionProvider);
      return SingleChildScrollView(child: PlanEditor(plays: playsFrom(state.steps, ctrl.editFrom), minutesLeft: 10,
        candidates: [items[3]], onRemove: ctrl.removePlay, onReorder: ctrl.reorderPlays, onReplace: ctrl.replacePlay, onAdd: ctrl.addPlays));
    })))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zamień „${items[1].title}”'));
    await tester.pumpAndSettle();
    unawaited(ctrl.skip());
    await tester.pump();
    await tester.pump();
    expect(c.read(sessionProvider).index, 1);
    await tester.tap(find.text(items[3].title));
    await tester.pumpAndSettle();
    final ids = playsFrom(c.read(sessionProvider).steps, 0).map((i)=>i.id).toList();
    unawaited(ctrl.stop());
    await tester.pumpAndSettle();
    await run;
    await tester.pumpWidget(const SizedBox());
    c.dispose(); await tester.runAsync(db.close);
    expect(ids, contains(items[2].id), reason: 'C must not be replaced when the user selected B');
  });
}
