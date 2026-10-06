import 'package:audiokiddo_studio/crm/ads_growth.dart';
import 'package:audiokiddo_studio/crm/ads_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final overview = <String, dynamic>{
  'configured': {'meta': true, 'meta_pixel': true, 'google_ads': false, 'ga4': true, 'agent': true},
  'sources': [
    {'source': 'meta', 'ok': true, 'message': '3 kampanii i zestawów', 'updated_at': '2026-10-06T05:00:00Z'},
    {
      'source': 'meta_pixel',
      'ok': false,
      'message': 'Pixel milczy od 70 h',
      'updated_at': '2026-10-06T05:00:00Z',
    },
    {
      'source': 'agent',
      'ok': true,
      'message': 'Rodzice 3–6 działa najlepiej.',
      'updated_at': '2026-10-06T05:01:00Z',
    },
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

final growth = <String, dynamic>{
  'verdicts': [
    {
      'ad_id': 'x1',
      'platform': 'meta',
      'name': 'Korek, wersja A',
      'impressions': 5000,
      'clicks': 150,
      'ctr': 3,
      'spend': 50,
      'conversions': 2,
      'cpa': 25,
      'verdict': 'zwyciezca',
      'note': '97% szans',
    },
  ],
  'creatives': [
    {
      'id': 'k1',
      'platform': 'google_ads',
      'format': 'rsa',
      'angle': 'Auto bez tabletu',
      'moment': 'Mikołajki',
      'status': 'draft',
      'why': 'Konkurencja nie mówi o aucie.',
      'problems': ['1 nagłówków dłuższych niż 30 znaków pominięto.'],
      'content': {
        'headlines': ['Zabawy do auta bez ekranu', '7 dni za darmo', 'Dziecko słucha i odpowiada'],
        'descriptions': ['Audiozabawy dla dzieci 3–9 lat.', 'Działa offline.'],
        'final_url': 'https://audiokiddo.pl/',
      },
    },
    {
      'id': 'k2',
      'platform': 'meta',
      'format': 'meta_video',
      'angle': 'Wieczór',
      'status': 'draft',
      'why': '',
      'problems': [],
      'content': {
        'primary_text': 'Wieczór bez bajki na ekranie.',
        'headline': 'Kołysanka cichnie sama',
        'hook_script': '0–3 s: telefon ekranem w dół',
      },
    },
  ],
  'research': [
    {'created_at': '2026-10-05T05:30:00Z', 'summary': '## Konkurencja\nNajdłużej: audiobooki z lektorem.'},
  ],
  'moments': [
    {'name': 'Wszystkich Świętych: wyjazdy', 'days_to_start': 16},
  ],
  'groups': [
    {'group_id': 'g1', 'campaign_name': 'Szukaj', 'name': 'Auto'},
  ],
  'competitors': [
    {
      'page': 'Bajkowo',
      'page_id': '123',
      'active_ads': 4,
      'longest': [
        {'days': 66, 'title': 'Słuchaj', 'text': 'Bajki na dobranoc', 'reach': 12000},
      ],
    },
  ],
  'competitor_ads': 4,
  'settings': {
    'enabled': true,
    'search_terms': ['bajki dla dzieci'],
    'competitor_pages': [],
    'competitor_sites': [],
    'keyword_seeds': [],
  },
  'keywords': [
    {
      'keyword': 'zabawy w aucie dla dzieci',
      'monthly_searches': 880,
      'competition': 'LOW',
      'cpc_low': .45,
      'cpc_high': 1.9,
      'trend': [
        {'month': '2026-07', 'searches': 2400},
      ],
      'use_for': 'both',
      'source': 'google_ads',
    },
  ],
  'wasted': [
    {'term': 'bajki na youtube', 'campaign_id': '1', 'campaign_name': 'Szukaj', 'clicks': 15, 'cost': 23},
  ],
  'terms': [
    {
      'term': 'bajki na youtube',
      'campaign_name': 'Szukaj',
      'clicks': 15,
      'cost': 23,
      'conversions': 0,
      'google_status': 'none',
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
        overrides: [
          adsOverviewProvider.overrideWith((ref) async => overview),
          adsGrowthProvider.overrideWith((ref) async => growth),
        ],
        child: const MaterialApp(home: Scaffold(body: CampaignsTab())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Pixel milczy'), findsOneWidget);
    expect(
      find.textContaining('Niepołączone. Sekrety: GOOGLE_CLIENT_ID'),
      findsOneWidget,
      reason: 'names, never values',
    );
    expect(find.text('Do decyzji: 1'), findsOneWidget);
    expect(find.text('Zatwierdzam i wprowadź'), findsOneWidget);
    expect(find.text('Inna kwota'), findsOneWidget);
    expect(find.text('Budżet: 60,00 zł dziennie'), findsOneWidget);
    expect(find.text('Rodzice 3–6').evaluate().isNotEmpty, isTrue);
    expect(find.text('facebook / paid'), findsOneWidget);
    expect(find.text('Wstrzymać „Test karuzeli”'), findsOneWidget);
    expect(find.textContaining('wprowadzone · od agenta'), findsOneWidget);
  });

  testWidgets('Kampanie: creatives to approve, competitors, keywords', (tester) async {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adsOverviewProvider.overrideWith((ref) async => overview),
          adsGrowthProvider.overrideWith((ref) async => growth),
        ],
        child: const MaterialApp(home: Scaffold(body: CampaignsTab())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kreacje (2)'), findsOneWidget);
    await tester.tap(find.text('Kreacje (2)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Najdłużej: audiobooki'), findsOneWidget);
    expect(find.textContaining('Wszystkich Świętych: wyjazdy: za 16 dni'), findsOneWidget);
    expect(find.text('Zatwierdzam bez tworzenia'), findsOneWidget);
    expect(find.text('Zatwierdzam (zadanie z briefem)'), findsOneWidget);
    expect(find.textContaining('pominięto'), findsOneWidget);
    expect(find.text('Zwycięzca'), findsOneWidget);
    // A headline over 30 characters is flagged while typing.
    await tester.enterText(
      find.widgetWithText(TextField, 'Nagłówki (3–15)'),
      'Ten nagłówek jest zdecydowanie za długi na Google\nKrótki',
    );
    await tester.pump();
    expect(find.text('1 za długie: Google je pominie'), findsOneWidget);

    await tester.tap(find.text('Konkurencja'));
    await tester.pumpAndSettle();
    expect(find.text('Bajkowo'), findsOneWidget);
    expect(find.textContaining('4 z ostatnich 45 dni'), findsOneWidget);

    await tester.tap(find.text('Słowa kluczowe'));
    await tester.pumpAndSettle();
    expect(find.text('zabawy w aucie dla dzieci'), findsOneWidget);
    expect(find.text('880'), findsOneWidget);
    expect(find.text('lip'), findsOneWidget);
    expect(find.text('Wyklucz'), findsOneWidget);
  });
}
