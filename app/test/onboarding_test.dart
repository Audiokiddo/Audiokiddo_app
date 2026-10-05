import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/core/router.dart';
import 'package:audiokiddo/features/account/session_gate.dart';
import 'package:audiokiddo/features/family/family.dart';
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

  test('after signing out only the sign-in screen opens, until sign-in or skipping', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final kids = KidsModeController(db);
    final onboarding = OnboardingController(db, done: true);
    final session = SessionGate(db);
    expect(appRedirect(kids, onboarding, '/biblioteka', session: session), isNull);
    await session.markSignedOut();
    for (final location in ['/', '/biblioteka', '/zabawa/magiczny-sklep', '/odtwarzacz', '/dziecko']) {
      expect(appRedirect(kids, onboarding, location, session: session), '/logowanie', reason: location);
    }
    expect(appRedirect(kids, onboarding, '/logowanie', session: session), isNull);
    final restarted = SessionGate(db);
    await restarted.load();
    expect(restarted.signedOut, isTrue, reason: 'stays after a restart');
    await session.clear();
    expect(appRedirect(kids, onboarding, '/logowanie', session: session), '/');
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
    expect(find.text('Więcej\nniż\nsłuchanie.'), findsOneWidget);
    await tester.ensureVisible(find.text('Zaczynamy'));
    await tester.tap(find.text('Zaczynamy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nie teraz'));
    await tester.pumpAndSettle();
    expect(find.text('Cześć! Tu AudioKiddo.'), findsOneWidget);
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('Jak to działa'), findsOneWidget);
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('Konto rodzica'), findsOneWidget);
    expect(find.text('Kontynuuj z e-mailem'), findsOneWidget);
    await tester.tap(find.text('Zacznij bez konta'));
    await tester.pumpAndSettle();

    // The short parent quiz, for two children.
    Future<void> next() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Dalej'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Zaczynamy'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Zosia');
    await next();
    expect(find.text('Ile lat ma Zosia?'), findsOneWidget);
    await tester.tap(find.text('6'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Słownictwo i mowa'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('W podróży'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('10 min dziennie'));
    await tester.pumpAndSettle();
    await next();
    expect(find.textContaining('Plan dla: Zosia'), findsOneWidget);
    await tester.tap(find.text('Dodaj kolejne dziecko'));
    await tester.pumpAndSettle();
    await next(); // no name: "Twoje dziecko"
    expect(find.text('Ile lat ma Twoje dziecko?'), findsOneWidget);
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Wyciszenie przed snem'));
    await tester.pumpAndSettle();
    await next();
    await next();
    await tester.tap(find.text('5 min dziennie'));
    await tester.pumpAndSettle();
    await next();
    await tester.tap(find.text('Gotowe'));
    await tester.pumpAndSettle();

    // Reminders: offered, not forced.
    expect(find.text('Włącz przypomnienia'), findsOneWidget);
    await tester.tap(find.text('Nie teraz'));
    await tester.pumpAndSettle();
    expect(find.text('Co dziś robimy?'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.text('Co dziś robimy?')));
    final family = container.read(familyProvider).value!;
    expect(
      [for (final c in family.children) (c.name, c.age, c.dailyMinutes)],
      [('Zosia', 6, 10), ('', 3, 5)],
    );
    expect(kids.settings.age, 6, reason: 'age becomes the kids mode default');
    expect(kids.active, isFalse);
  });
}
