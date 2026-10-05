import 'dart:convert';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

/// Every main screen on the smallest iPhone (SE, 320×568 pt) and a large-text dark phone,
/// plus an iPad: no overflow, nothing thrown. Catches cut-off text the simulators miss.
const devices = <String, (Size, double, double, Brightness)>{
  'iPhone SE 1st gen, text 100%': (Size(640, 1136), 2, 1.0, Brightness.light),
  'iPhone SE 3rd gen, text 135%, dark': (Size(750, 1334), 2, 1.35, Brightness.dark),
  'iPad, text 100%': (Size(2048, 2732), 2, 1.0, Brightness.light),
};

const routes = [
  '/',
  '/plan',
  '/plan/postep',
  '/plan/glos',
  '/biblioteka',
  '/zabawa/magiczny-sklep',
  '/oferta?zabawa=zaginiony-skarb',
  '/sklep',
  '/pakiet/wyobraznia',
  '/podroz',
  '/dobranoc',
  '/sesja',
  '/moje',
  '/ratunku',
  '/rutyny',
  '/kolejka',
  '/profil',
  '/pobrane',
  '/ulubione',
];

Future<void> pumpDevice(
  WidgetTester tester,
  (Size, double, double, Brightness) device, {
  bool onboardingDone = true,
  bool welcomeDone = true,
}) async {
  final (size, ratio, text, brightness) = device;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = ratio;
  tester.platformDispatcher.textScaleFactorTestValue = text;
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final db = memoryDatabase();
  addTearDown(db.close);
  final child = ChildProfile(
    id: 'z',
    name: 'Zosia',
    age: 6,
    startedOn: DateTime(2026, 9, 1),
    goals: const {DevGoal.imagination, DevGoal.calm},
    dailyMinutes: 10,
  );
  await db.writeValue('family_children', jsonEncode([child.toJson()]));
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(db, onboardingDone: onboardingDone, welcomeDone: welcomeDone),
      child: const AudioKiddoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final MapEntry(key: name, value: device) in devices.entries) {
    testWidgets('$name: main screens fit', (tester) async {
      await pumpDevice(tester, device);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      for (final route in routes) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$route on $name');
      }
    });

    testWidgets('$name: welcome pages fit', (tester) async {
      await pumpDevice(tester, device, onboardingDone: false);
      await tester.ensureVisible(find.text('Zaczynamy'));
      await tester.tap(find.text('Zaczynamy'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nie teraz'));
      await tester.pumpAndSettle();
      for (var page = 0; page < 2; page++) {
        expect(tester.takeException(), isNull, reason: 'welcome page ${page + 1} on $name');
        await tester.drag(find.byType(PageView), const Offset(-600, 0));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('$name: family welcome and Szop’en’s tour fit', (tester) async {
      await pumpDevice(tester, device, welcomeDone: false);
      expect(find.text('Ta-da! Witajcie w AudioKiddo'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'fanfare on $name');
      await tester.scrollUntilVisible(find.text('Odbieram!'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Odbieram!'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'theme on $name');
      final next = find.widgetWithText(FilledButton, 'Dalej');
      await tester.scrollUntilVisible(next, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(next);
      await tester.pumpAndSettle();
      // The child exists already: reminders next, then the tour over Start.
      expect(tester.takeException(), isNull, reason: 'reminders on $name');
      await tester.ensureVisible(find.text('Nie teraz'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nie teraz'));
      await tester.pumpAndSettle();
      for (var stop = 0; stop < 7; stop++) {
        expect(tester.takeException(), isNull, reason: 'tour stop ${stop + 1} on $name');
        await tester.tap(find.byType(FilledButton).last);
        await tester.pumpAndSettle();
      }
      expect(find.text('Gotowe!'), findsNothing);
    });
  }
}
