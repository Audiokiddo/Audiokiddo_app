import 'package:audiokiddo_studio/crm/crm_calendar.dart';
import 'package:audiokiddo_studio/crm/crm_quality.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('alerts: the urgent first, "Przyjąłem" on each', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertsProvider.overrideWith(
            (ref) async => [
              {'id': '1', 'level': 'critical', 'title': 'Zakupy się nie kończą', 'detail': 'Sprawdź.', 'first_seen': '2026-10-07T05:00:00Z'},
              {'id': '2', 'level': 'info', 'title': '2 zamówienia czekają', 'detail': 'Przypomnij.', 'first_seen': '2026-10-06T05:00:00Z', 'acknowledged_at': '2026-10-07T06:00:00Z'},
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: AlertsCard()))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Do uwagi (2)'), findsOneWidget);
    expect(find.text('Przyjąłem'), findsOneWidget);
    expect(find.text('przyjęte'), findsOneWidget);
  });

  testWidgets('calendar: items on their days, a drag moves one to another day', (tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    (Map<String, dynamic>, String?)? moved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalendarMonth(
              today: DateTime(2026, 10, 7),
              items: [
                {'id': 'a', 'title': 'Premiera: Kosmos', 'area': 'release', 'due': '2026-10-10'},
                {'id': 'b', 'title': 'Rolka o aucie', 'area': 'reel', 'due': null},
              ],
              onTap: (_) {},
              onMove: (item, day) => moved = (item, day),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Październik 2026'), findsOneWidget);
    expect(find.text('Bez daty (1)'), findsOneWidget);
    final start = tester.getCenter(find.text('Rolka o aucie'));
    final end = tester.getCenter(find.text('15'));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(moved?.$1['id'], 'b');
    expect(moved?.$2, '2026-10-15');
  });
}
