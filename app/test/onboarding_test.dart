import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/core/router.dart';
import 'package:audiokiddo/features/kids_mode/kids_mode_controller.dart';
import 'package:audiokiddo/features/onboarding/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('welcome comes first, then kids mode rules apply', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final kids = KidsModeController(db);
    final onboarding = OnboardingController(db);
    expect(appRedirect(kids, onboarding, '/'), '/powitanie');
    expect(appRedirect(kids, onboarding, '/dziecko'), '/powitanie');
    await onboarding.complete();
    expect(appRedirect(kids, onboarding, '/powitanie'), '/');
    await kids.enter(age: 3, onlyDownloaded: false);
    expect(appRedirect(kids, onboarding, '/powitanie'), '/dziecko');

    final restarted = OnboardingController(db);
    await restarted.load();
    expect(restarted.done, isTrue);
  });

  testWidgets('first run: welcome, how it works, optional age and account, then Start', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = memoryDatabase();
    addTearDown(db.close);
    final kids = KidsModeController(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...testOverrides(db, onboardingDone: false, kidsMode: kids)],
        child: const AudioKiddoApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Kiddo's magic way in: volume, hello, the magic word (touch the orb), access granted.
    expect(find.text('Podgłośnij!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('ABRAKADABRA!'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Magiczna kula. Dotknij, aby wejść.'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Dostęp przyznany!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Cześć! Tu AudioKiddo.'), findsOneWidget);
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('Jak to działa'), findsOneWidget);
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dla dzieci od 6 lat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('Konto rodzica'), findsOneWidget);
    expect(find.text('Kontynuuj z e-mailem'), findsOneWidget);
    await tester.tap(find.text('Zacznij bez konta'));
    await tester.pumpAndSettle();
    expect(find.text('Czas na zabawę!'), findsOneWidget);
    expect(kids.settings.age, 6, reason: 'age becomes the kids mode default');
    expect(kids.active, isFalse);
  });
}
