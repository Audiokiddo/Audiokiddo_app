import 'package:audiokiddo_studio/crm/task_board.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const columns = [
    (status: 'todo', label: 'Do zrobienia', deep: Colors.purple, soft: Color(0xFFEDE7F6)),
    (status: 'doing', label: 'W toku', deep: Colors.orange, soft: Color(0xFFFFF3E0)),
    (status: 'done', label: 'Zrobione', deep: Colors.teal, soft: Color(0xFFE0F2F1)),
  ];
  final tasks = [
    for (var i = 0; i < 30; i++) {'id': '$i', 'title': 'Zadanie $i', 'status': 'todo', 'priority': 2},
  ];

  Future<void> pump(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskBoard(
            columns: columns,
            tasks: tasks,
            onMove: (_, _) {},
            cardFor: (t) => Card(child: SizedBox(height: 90, child: Text('${t['title']}'))),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a long column scrolls down to the last task', (tester) async {
    await pump(tester, const Size(1400, 800));
    expect(find.text('Zadanie 29'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Zadanie 29')).dy, greaterThan(800), reason: 'below the fold');
    // A mouse wheel over the column.
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(tester.getCenter(find.text('Zadanie 0'))));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 4000)));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Zadanie 29')).dy, lessThan(800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide screens fill the width; a smaller scale fits more tasks', (tester) async {
    await pump(tester, const Size(1800, 900));
    final todo = tester.getSize(find.text('Do zrobienia').first);
    expect(todo, isNotNull);
    int visible() => tasks.where((t) {
      final f = find.text('${t['title']}');
      return tester.getTopLeft(f).dy < 900;
    }).length;
    final before = visible();
    await tester.drag(find.byType(Slider).last, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(visible(), greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the width slider makes tasks narrower, so more sit side by side', (tester) async {
    await pump(tester, const Size(1800, 900));
    double cardWidth() => tester.getSize(find.text('Zadanie 0')).width;
    final before = tester.getSize(find.byType(Card).first).width;
    await tester.drag(find.byType(Slider).first, const Offset(-300, 0));
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byType(Card).first).width;
    expect(after, lessThan(before), reason: 'narrower tasks');
    expect(cardWidth(), greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phone shows the board without overflow', (tester) async {
    await pump(tester, const Size(390, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('Do zrobienia'), findsOneWidget);
    // A swipe scrolls the column (cards move only after holding them).
    await tester.drag(find.text('Zadanie 1'), const Offset(0, -2500));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Zadanie 29')).dy, lessThan(800));
  });

  test('the board keeps to the next two weeks, urgent and near first', () {
    final today = DateTime(2026, 10, 8);
    expect(dueSoon({'due': '2026-10-01'}, today), isTrue, reason: 'overdue');
    expect(dueSoon({'due': '2026-10-22'}, today), isTrue);
    expect(dueSoon({'due': '2026-10-23'}, today), isFalse);
    expect(dueSoon({'due': null}, today), isTrue, reason: 'undated');
    final sorted = [
      {'title': 'c', 'priority': 2, 'due': '2026-10-09'},
      {'title': 'd', 'priority': 1, 'due': null},
      {'title': 'b', 'priority': 1, 'due': '2026-10-20'},
      {'title': 'a', 'priority': 1, 'due': '2026-10-10'},
    ]..sort(byUrgency);
    expect([for (final t in sorted) t['title']], ['a', 'b', 'd', 'c']);
  });
}
