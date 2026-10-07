import 'package:audiokiddo_studio/screens/kpi_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _sample = <String, dynamic>{
  'ceo': {
    'weekly_returning_families': 823,
    'wrf_trend': [
      {'week': '2026-09-21', 'families': 700},
      {'week': '2026-09-28', 'families': 823},
    ],
    'new_activated': 42,
    'true_activation': 55.5,
    'd7': 31.0,
    'active_subscribers': 10,
    'mrr': 200,
    'funnel': {'new_families': 100, 'first_play': 76, 'first_done': 61, 'activated': 42, 'paywall': 21, 'paid': 6},
    'cohorts': [
      {'week': '2026-09-21', 'activated': 20, 'd7': 35.0},
    ],
  },
  'product': {
    'games': [
      {'item': 'zgubiona-gwiazdka', 'starts': 40, 'families': 20, 'completion': 80.0, 'replay7': 45.0, 'exits': 3},
    ],
    'dropoff': {
      'zgubiona-gwiazdka': [
        [0, 1],
        [390, 9],
      ],
    },
    'searches': [
      {'query': 'dinozaury', 'count': 7, 'no_results': 7},
    ],
  },
  'growth': [
    {'source': 'tiktok', 'new_families': 50, 'activated': 20, 'paid': 4, 'activation': 40.0, 'paid_rate': 8.0},
  ],
  'economics': {
    'spend_total': 300,
    'new_paying_total': 12,
    'cac_total': 25.0,
    'channels': [
      {'channel': 'meta', 'spend': 300, 'new_paying_app': 4, 'cac_app': 75.0},
    ],
  },
  'signals': {
    'cancel_reasons': {'price': 3},
    'referral_channels': {'whatsapp': 5},
    'referral_families': 4,
  },
  'monetization': {'free_to_paywall': 30.0, 'checkout': {'started': 5, 'done': 3, 'failed': {'canceled': 2}}},
  'data_health': {'events': 1200, 'with_age_group': 97.5, 'versions': {'0.2.0 ios': 30}},
};

Finder get _vertical =>
    find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

void main() {
  testWidgets('the four annex dashboards show the numbers', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final asked = <(int, String?)>[];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: KpiScreen(
              loader: (days, age) async {
                asked.add((days, age));
                return _sample;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Weekly Returning Families'), findsOneWidget);
    expect(find.text('823'), findsOneWidget);
    expect(find.textContaining('700 → 823'), findsOneWidget, reason: 'the weekly trend');
    await tester.scrollUntilVisible(find.text('Za drogo'), 300, scrollable: _vertical);
    expect(find.text('Za drogo'), findsOneWidget, reason: 'why parents leave');
    expect(find.text('20.00 zł'), findsOneWidget, reason: 'ARPU = MRR / subscribers');

    await tester.tap(find.text('3–5'));
    await tester.pumpAndSettle();
    expect(asked.last, (30, '3-5'));

    await tester.tap(find.text('Produkt'));
    await tester.pumpAndSettle();
    expect(find.text('Mapa wyjść: w której minucie dzieci kończą słuchanie'), findsOneWidget);
    expect(find.text('6:30'), findsOneWidget, reason: 'exits in the half minute from 6:30');
    expect(find.text('Bez wyników: 7'), findsOneWidget);

    await tester.tap(find.text('Growth'));
    await tester.pumpAndSettle();
    expect(find.text('TikTok'), findsWidgets);
    expect(find.text('25.0 zł'), findsOneWidget, reason: 'CAC from the ad spend');
    expect(find.text('Zapisz wydatek'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Kanał: whatsapp'), 300, scrollable: _vertical);
    expect(find.text('Kanał: whatsapp'), findsOneWidget);

    await tester.tap(find.text('Tech i dane'));
    await tester.pumpAndSettle();
    expect(find.text('Nieudane: anulowane przez rodzica'), findsOneWidget);
  });
}
