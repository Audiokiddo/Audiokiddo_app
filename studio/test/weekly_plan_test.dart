import 'package:audiokiddo_studio/crm/weekly_plan.dart';
import 'package:audiokiddo_studio/state/studio_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'studio_test.dart' show FakeIo, loaded;

Map<String, dynamic> play(String id, String released, {bool audio = true}) => {
  'id': id,
  'title': 'Zabawa $id',
  'released': released,
  'audio': [
    if (audio) {'path': 'audio/x/$id.m4a'},
  ],
};

void main() {
  // Saturday 18.10.2026: its week starts on Monday 12.10.
  final today = DateTime(2026, 10, 18);

  test('weeks start on Monday and hold the plays that premiere in them', () {
    final weeks = planWeeks(
      [
        play('a', '2026-10-12'),
        play('b', '2026-10-18'),
        play('c', '2026-10-19', audio: false),
        play('old', '2026-10-01'),
      ],
      today,
      weeks: 3,
    );
    expect(weeks.map((w) => w.monday), [
      DateTime(2026, 10, 12),
      DateTime(2026, 10, 19),
      DateTime(2026, 10, 26),
    ]);
    expect(weeks[0].plays.map((p) => p['id']), ['a', 'b']);
    expect(weeks[0].missing, 0);
    expect(weeks[1].plays.map((p) => p['id']), ['c']);
    expect(weeks[1].missing, 1);
    expect(hasRecording(weeks[1].plays.single), isFalse);
    expect(weeks[2].missing, 2);
  });

  testWidgets('the card counts empty places and plays without a recording', (tester) async {
    final container = await tester.runAsync(() => loaded(FakeIo())) as ProviderContainer;
    addTearDown(container.dispose);
    container
        .read(studioProvider.notifier)
        .importCatalog(
          '{"schema_version":1,"version":1,"packs":[],"shelves":[],"items":['
          '{"id":"a","title":"A","released":"2026-10-13","audio":[{"path":"a.m4a"}]},'
          '{"id":"b","title":"B","released":"2026-10-14","audio":[]}]}',
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: WeeklyPlanCard(today: today)),
          ),
        ),
      ),
    );
    expect(find.text('Wolnych miejsc: 18 · Bez nagrania: 1'), findsOneWidget);
    expect(find.text('B (bez nagrania)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // the draft's autosave
  });
}
