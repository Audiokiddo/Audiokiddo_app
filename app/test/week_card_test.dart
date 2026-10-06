import 'dart:convert';
import 'dart:io';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/widgets/ambient_motion.dart';
import 'package:audiokiddo/features/family/week_card.dart';
import 'package:audiokiddo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = parseCatalog(jsonDecode(File('assets/mock/catalog.json').readAsStringSync()) as Map<String, Object?>)
      .catalog;
  final now = DateTime(2026, 9, 28, 18);
  final shop = catalog.item('magiczny-sklep')!;
  final sound = catalog.items.firstWhere((i) => i.id != shop.id && i.kind != ContentKind.interactiveGame);

  ActivityResult played(ContentItem item, int daysAgo) => ActivityResult(
    childId: 'z',
    itemId: item.id,
    at: now.subtract(Duration(days: daysAgo, hours: 1)),
    seconds: item.durationSec,
  );

  test('summary counts only the last seven days and finds the favourite', () {
    final summary = weekSummary(
      name: 'Zosia',
      results: [played(shop, 1), played(shop, 2), played(sound, 3), played(sound, 20)],
      catalog: catalog,
      position: const PlanPosition(completedDays: 3, currentDay: 4, todayDone: false),
      now: now,
    );
    expect(summary.activities, 3, reason: 'the old result is left out');
    expect(summary.favorite, shop.title);
    expect(summary.notes, 3);
    expect(summary.isEmpty, isFalse);
  });

  testWidgets('card renders without overflow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ambientMotionProvider.overrideWithValue(false)],
        child: MaterialApp(
          locale: const Locale('pl'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Center(
            child: WeekCard(
              summary: WeekSummary(
                name: 'Zosia',
                notes: 5,
                activities: 12,
                minutes: 84,
                correct: 23,
                scored: 30,
                favorite: shop.title,
                topSkill: 'wyobraźnia',
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Zosia w tym tygodniu'), findsOneWidget);
    expect(find.textContaining('Zapytajcie, o czym była'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
