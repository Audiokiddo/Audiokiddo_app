import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/core/widgets/back_to_start.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<int> swipe(WidgetTester tester, {required bool enabled, required double distance}) async {
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: BackToStart(
            enabled: enabled,
            onBack: () => backs++,
            child: const Center(child: Text('Sklep')),
          ),
        ),
      ),
    );
    await tester.dragFrom(const Offset(8, 300), Offset(distance, 0));
    await tester.pumpAndSettle();
    return backs;
  }

  testWidgets('a swipe from the left edge of a tab goes to Start', (tester) async {
    expect(await swipe(tester, enabled: true, distance: 300), 1);
  });

  testWidgets('a short swipe springs back', (tester) async {
    expect(await swipe(tester, enabled: true, distance: 40), 0);
    expect(tester.getCenter(find.text('Sklep')).dx, 400, reason: 'back in place');
  });

  testWidgets('on Start itself nothing happens', (tester) async {
    expect(await swipe(tester, enabled: false, distance: 300), 0);
  });
}
