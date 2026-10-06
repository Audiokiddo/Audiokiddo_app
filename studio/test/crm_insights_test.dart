import 'package:audiokiddo_studio/crm/crm_insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the trend shows twelve weeks and the change against last week', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final weeks = [
      for (var i = 0; i < 12; i++)
        {
          'week': '2026-${(7 + i ~/ 4).toString().padLeft(2, '0')}-${(1 + i % 4 * 7).toString().padLeft(2, '0')}',
          'active': i == 11 ? 30 : 20,
          'accounts': i,
          'plays': 0,
          'paywall_views': 0,
          'purchases': 0,
          'revenue': i * 10,
        },
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [crmTrendProvider.overrideWith((ref) async => weeks)],
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: TrendCard()))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ten tydzień: 30 (+50%)'), findsOneWidget);
    await tester.tap(find.text('Przychód (szac.)'));
    await tester.pumpAndSettle();
    expect(find.text('ten tydzień: 110 zł (+10%)'), findsOneWidget);
  });

  test('scopes read like a parent would say them', () {
    expect(scopeLabel('all_content'), 'Abonament: wszystko');
    expect(scopeLabel('children:1'), 'Plan: 1 dziecko');
    expect(scopeLabel('children:5'), 'Plan: 5 dzieci');
    expect(scopeLabel('pack:detektyw'), 'Pakiet detektyw');
  });
}
