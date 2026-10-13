import 'dart:convert';

import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/family/family.dart';
import 'package:ak_core/ak_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

void main() {
  testWidgets('Profil dziecka: a tap on another child makes them the active one', (tester) async {
    final db = memoryDatabase();
    addTearDown(db.close);
    ChildProfile kid(String id, String name, int age) => ChildProfile(
      id: id,
      name: name,
      age: age,
      startedOn: DateTime(2026, 9, 1),
      goals: const {DevGoal.imagination},
      dailyMinutes: 10,
    );
    await db.writeValue('family_children', jsonEncode([kid('z', 'Zosia', 6).toJson(), kid('s', 'Staś', 4).toJson()]));
    await db.writeValue('family_active', 'z');
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(db), child: const AudioKiddoApp()));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/profil');
    await tester.pumpAndSettle();
    expect(find.text('Zosia'), findsWidgets);
    await tester.tap(find.text('Staś'));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    expect(container.read(familyProvider).value!.active!.name, 'Staś');
    expect(find.text('4 lat'), findsOneWidget);
  });
}
