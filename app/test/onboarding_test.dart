import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/core/router.dart';
import 'package:audiokiddo/features/account/account_service.dart';
import 'package:audiokiddo/features/account/session_gate.dart';
import 'package:audiokiddo/features/family/family.dart';
import 'package:audiokiddo/features/kids_mode/kids_mode_controller.dart';
import 'package:audiokiddo/features/onboarding/onboarding_controller.dart';
import 'package:audiokiddo/features/welcome/welcome_controller.dart';
import 'package:audiokiddo/features/account/account_data.dart';
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

  test('without a signed-in parent only the sign-in screen opens', () {
    final db = memoryDatabase();
    addTearDown(db.close);
    final kids = KidsModeController(db);
    final onboarding = OnboardingController(db, done: true);
    final gate = SessionGate(const SignedOutAccountService(), required: true);
    addTearDown(gate.dispose);
    for (final location in [
      '/',
      '/biblioteka',
      '/zabawa/magiczny-sklep',
      '/odtwarzacz',
      '/dziecko',
      '/konto',
    ]) {
      expect(appRedirect(kids, onboarding, location, session: gate), '/logowanie', reason: location);
    }
    expect(appRedirect(kids, onboarding, '/logowanie', session: gate), isNull);
    final open = SessionGate(const SignedOutAccountService());
    addTearDown(open.dispose);
    expect(
      appRedirect(kids, onboarding, '/biblioteka', session: open),
      isNull,
      reason: 'tests and builds without accounts',
    );
  });

  test('after the first sign-in the family welcome comes once, then Start', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final kids = KidsModeController(db);
    final onboarding = OnboardingController(db, done: true);
    final welcome = WelcomeController(db, done: false);
    expect(appRedirect(kids, onboarding, '/', welcome: welcome), '/witaj');
    expect(appRedirect(kids, onboarding, '/witaj', welcome: welcome), isNull);
    await welcome.complete();
    expect(welcome.tourPending, isTrue, reason: 'Szop’en’s tour follows the welcome');
    expect(appRedirect(kids, onboarding, '/witaj', welcome: welcome), '/');
    final restarted = WelcomeController(db, done: false);
    await restarted.load();
    expect(restarted.done, isTrue);
    expect(restarted.tourPending, isFalse);
  });

  test('a different account on the phone gets its own welcome', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await claimFamilyData(db, 'a');
    await WelcomeController(db).complete();
    await claimFamilyData(db, 'b');
    final welcome = WelcomeController(db);
    await welcome.load();
    expect(welcome.done, isFalse);
  });

  testWidgets('first run: hello, sign-in, then fanfare, the child, reminders and the tour', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = memoryDatabase();
    addTearDown(db.close);
    final kids = KidsModeController(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...testOverrides(db, onboardingDone: false, welcomeDone: false, kidsMode: kids)],
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
    await tester.tap(find.text('Zaczynamy'));
    await tester.pumpAndSettle();

    // The family welcome: free plays, then the look of the app.
    expect(find.text('Ta-da! Witajcie w AudioKiddo'), findsOneWidget);
    expect(find.textContaining('po jednej z każdego pakietu'), findsOneWidget);
    await tester.ensureVisible(find.text('Odbieram!'));
    await tester.tap(find.text('Odbieram!'));
    await tester.pumpAndSettle();
    expect(find.text('Jak ma wyglądać aplikacja?'), findsNothing, reason: 'the look is automatic');
    expect(find.text('Pomiń'), findsNothing, reason: 'the age is needed');

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
    await tester.ensureVisible(find.text('Nie teraz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nie teraz'));
    await tester.pumpAndSettle();
    // Szop’en's tour over Start, skippable.
    expect(find.text('Cześć, jestem Szop’en!'), findsOneWidget);
    await tester.tap(find.text('Dalej').last);
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsWidgets);
    await tester.tap(find.text('Pomiń'));
    await tester.pumpAndSettle();
    expect(find.text('Cześć, jestem Szop’en!'), findsNothing);
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
