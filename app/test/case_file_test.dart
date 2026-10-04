import 'dart:convert';
import 'dart:io';

import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/features/pdf/case_file.dart';
import 'package:audiokiddo/features/pdf/case_file_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, List<CaseTask>> loadCaseFiles() =>
    parseCaseFiles(jsonDecode(File('assets/case_files.json').readAsStringSync()) as Map<String, Object?>);

Future<void> pumpCard(WidgetTester tester, CaseTask task) => tester.pumpWidget(
  MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Scaffold(body: SingleChildScrollView(child: CaseTaskCard(task: task))),
  ),
);

void main() {
  test('every Detektyw case file has tasks with valid answers', () {
    final catalog = jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>;
    final withPdf = [
      for (final i in (catalog['items']! as List).cast<Map<String, Object?>>())
        if ((i['pdf'] as List?)?.any((p) => '${(p as Map)['path']}'.startsWith('pdf/detektyw/')) ?? false)
          i['id']! as String,
    ];
    final files = loadCaseFiles();
    expect(withPdf, hasLength(5));
    expect(files.keys.toSet(), withPdf.toSet());
    for (final tasks in files.values) {
      expect(tasks, isNotEmpty);
      for (final t in tasks) {
        expect(t.page, greaterThan(1), reason: 'page 1 is the cover');
        switch (t.kind) {
          case CaseTaskKind.choice:
            expect(t.answerIndex, inInclusiveRange(0, t.options.length - 1), reason: t.prompt);
          case CaseTaskKind.code:
            expect(t.accepted, isNotEmpty, reason: t.prompt);
          case CaseTaskKind.open:
            break;
        }
      }
    }
  });

  test('Złodziej naszyjnika keeps the agreed answers', () {
    final tasks = loadCaseFiles()['zlodziej-naszyjnika']!;
    expect(tasks.map((t) => t.solution).toList(), [
      '41',
      'Figlarz',
      'Z',
      '7895',
      'POD LAMPĄ JEST KLUCZ',
      'Osoba 2',
      'SALA PODUSZKOWA',
      '',
    ]);
  });

  test('typed answers ignore case, spaces and Polish letters', () {
    const task = CaseTask(page: 2, prompt: '?', kind: CaseTaskKind.code, accepted: ['POD LAMPĄ JEST KLUCZ']);
    expect(task.isCorrectCode('pod lampa jest klucz'), isTrue);
    expect(task.isCorrectCode(' Pod lampą, jest klucz! '), isTrue);
    expect(task.isCorrectCode('pod lampą'), isFalse);
    expect(task.isCorrectCode(''), isFalse);
  });

  testWidgets('a choice: wrong asks to try again, right says good choice', (tester) async {
    await pumpCard(
      tester,
      const CaseTask(page: 2, prompt: 'Wynik?', kind: CaseTaskKind.choice, options: ['38', '42', '41'], answerIndex: 2),
    );
    await tester.tap(find.text('42'));
    await tester.pump();
    expect(find.text('Spróbuj jeszcze raz'), findsOneWidget);
    await tester.tap(find.text('41'));
    await tester.pump();
    expect(find.text('Dobry wybór!'), findsOneWidget);
    expect(find.text('Spróbuj jeszcze raz'), findsNothing);
  });

  testWidgets('a code: two misses offer the answer', (tester) async {
    await pumpCard(tester, const CaseTask(page: 5, prompt: 'Kod?', kind: CaseTaskKind.code, accepted: ['7895']));
    for (final guess in ['1234', '5555']) {
      await tester.enterText(find.byType(TextField), guess);
      await tester.tap(find.text('Sprawdź'));
      await tester.pump();
    }
    expect(find.text('Spróbuj jeszcze raz'), findsOneWidget);
    await tester.tap(find.text('Pokaż odpowiedź'));
    await tester.pump();
    expect(find.text('Odpowiedź: 7895'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '7895');
    await tester.tap(find.text('Sprawdź'));
    await tester.pump();
    expect(find.text('Dobry wybór!'), findsOneWidget);
  });

  testWidgets('an open task is not graded', (tester) async {
    await pumpCard(tester, const CaseTask(page: 9, prompt: 'Kolory?', kind: CaseTaskKind.open));
    expect(find.textContaining('Sprawdźcie z Maxem i Milą'), findsOneWidget);
    expect(find.text('Sprawdź'), findsNothing);
  });
}
