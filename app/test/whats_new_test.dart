import 'package:audiokiddo/features/about/whats_new.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('"Co nowego" shows one card per page and moves on with a swipe', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => const WhatsNewScreen())]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text(whatsNew.first.title), findsOneWidget);
    expect(find.bySemanticsLabel('Karta 1 z ${whatsNew.length}'), findsOneWidget);
    await tester.drag(find.text(whatsNew.first.title), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text(whatsNew[1].title), findsOneWidget);
  });
}
