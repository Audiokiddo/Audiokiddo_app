import 'package:audiokiddo_studio/crm/ads_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final overview = <String, dynamic>{
  'configured': {'meta': true, 'meta_pixel': true, 'google_ads': false, 'ga4': true, 'agent': true},
  'sources': [
    {'source': 'meta', 'ok': true, 'message': '3 kampanii i zestawów', 'updated_at': '2026-10-06T05:00:00Z'},
    {'source': 'meta_pixel', 'ok': false, 'message': 'Pixel milczy od 70 h', 'updated_at': '2026-10-06T05:00:00Z'},
    {'source': 'agent', 'ok': true, 'message': 'Rodzice 3–6 działa najlepiej.', 'updated_at': '2026-10-06T05:01:00Z'},
  ],
  'settings': {'enabled': true, 'max_daily': 150, 'max_change': .5, 'target_cpa': 40},
  'summary': {
    'totals': {
      'meta': {'spend': 280, 'conversions': 7, 'cpa': 40, 'roas': 1.4, 'revenue': 392},
      'google_ads': {'spend': 0, 'conversions': 0},
    },
    'campaigns': [
      {
        'platform': 'meta',
        'id': 'c1',
        'kind': 'campaign',
        'name': 'Rodzice 3–6',
        'status': 'active',
        'daily_budget': 40,
        'last_7': {'spend': 280, 'conversions': 7, 'cpa': 40},
        'prev_7': {'cpa': 52},
      },
    ],
    'site_sources_7d': [
      {'source': 'facebook / paid', 'sessions': 420, 'purchases': 5, 'revenue': 249.95},
    ],
  },
  'actions': [
    {
      'id': 'a1',
      'platform': 'meta',
      'entity_id': 'c1',
      'entity_name': 'Rodzice 3–6',
      'action': 'set_budget',
      'params': {'daily_budget': 60},
      'title': 'Więcej budżetu dla Rodziców 3–6',
      'reason': 'CPA 40 zł, tydzień wcześniej 52 zł.',
      'expected': 'Ok. 3 zakupy więcej tygodniowo.',
      'priority': 1,
      'status': 'pending',
      'source': 'ai',
      'created_at': '2026-10-06T05:01:00Z',
    },
    {
      'id': 'a0',
      'platform': 'meta',
      'action': 'pause',
      'params': {},
      'title': 'Wstrzymać „Test karuzeli”',
      'status': 'applied',
      'source': 'ai',
      'created_at': '2026-10-01T05:01:00Z',
      'decided_at': '2026-10-01T08:12:00Z',
    },
  ],
};

void main() {
  testWidgets('Kampanie: sources, proposals with approval, campaigns and history', (tester) async {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [adsOverviewProvider.overrideWith((ref) async => overview)],
        child: const MaterialApp(home: Scaffold(body: CampaignsTab())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Pixel milczy'), findsOneWidget);
    expect(find.textContaining('Niepołączone. Sekrety: GOOGLE_CLIENT_ID'), findsOneWidget, reason: 'names, never values');
    expect(find.text('Do decyzji: 1'), findsOneWidget);
    expect(find.text('Zatwierdzam i wprowadź'), findsOneWidget);
    expect(find.text('Inna kwota'), findsOneWidget);
    expect(find.text('Budżet: 60,00 zł dziennie'), findsOneWidget);
    expect(find.text('Rodzice 3–6').evaluate().isNotEmpty, isTrue);
    expect(find.text('facebook / paid'), findsOneWidget);
    expect(find.text('Wstrzymać „Test karuzeli”'), findsOneWidget);
    expect(find.textContaining('wprowadzone · od agenta'), findsOneWidget);
  });
}
