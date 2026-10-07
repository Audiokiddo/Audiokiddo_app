import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/features/account/access_screen.dart';
import 'package:audiokiddo/features/access/access_controller.dart';
import 'package:audiokiddo/features/account/account_service.dart';
import 'package:audiokiddo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'account_test.dart' show FakeAccountService;
import 'helpers.dart';

Future<ProviderContainer> pumpAccess(WidgetTester tester, FakeAccountService account) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final db = memoryDatabase();
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...testOverrides(db), accountServiceProvider.overrideWithValue(account)],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('pl'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AccessScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(AccessScreen)));
}

/// Scrolls [finder] into view (the form is longer than the screen), then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 120, scrollable: find.byType(Scrollable).first);
  await Scrollable.ensureVisible(tester.element(finder), alignment: .3);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> typeInto(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await tester.scrollUntilVisible(field, 120, scrollable: find.byType(Scrollable).first);
  await tester.enterText(field, text);
}

void main() {
  test('the server answer is read into a status and the scopes', () {
    expect(
      ClaimResult.fromJson({
        'status': 'ok',
        'scopes': ['pack:detektyw'],
      }).scopes,
      ['pack:detektyw'],
    );
    expect(ClaimResult.fromJson({'status': 'invalid'}).status, ClaimStatus.notFound);
    expect(ClaimResult.fromJson({'status': 'not_found'}).status, ClaimStatus.notFound);
    expect(ClaimResult.fromJson({'status': 'used_up'}).status, ClaimStatus.usedUp);
    expect(ClaimResult.fromJson({'status': 'rate_limited'}).status, ClaimStatus.rateLimited);
    expect(ClaimResult.fromJson({'status': 'something new'}).status, ClaimStatus.format);
    expect(ClaimResult.fromJson('nonsense').status, ClaimStatus.format);
    expect(const ClaimResult(ClaimStatus.already).granted, isTrue);
    expect(const ClaimResult(ClaimStatus.taken).granted, isFalse);
  });

  test('what was added is named, not shown as ids', () {
    expect(describeScopes([Scopes.allContent], null), 'wszystkie pakiety');
    expect(describeScopes(['pack:detektyw', 'pack:wyobraznia'], null), 'pakiet detektyw, pakiet wyobraznia');
    expect(describeScopes([], null), 'dostęp');
  });

  group('access screen', () {
    testWidgets('a code unlocks the pack and says so; the access list is refreshed', (tester) async {
      final account = FakeAccountService()
        ..claimResult = const ClaimResult(ClaimStatus.ok, ['pack:detektyw']);
      final container = await pumpAccess(tester, account);
      await typeInto(tester, 'Kod', 'ak-7k3m-9qxd');
      await tapVisible(tester, find.text('Odbierz dostęp'));
      expect(account.claims, ['code:AK-7K3M-9QXD'], reason: 'typed in capitals');
      expect(find.textContaining('Gotowe. Dodano: pakiet Detektyw'), findsOneWidget);
      expect(
        find.text('Zaloguj się, żeby dostęp nie zginął'),
        findsOneWidget,
        reason: 'a guest account is told',
      );
      expect(container.read(accessProvider).value, isNotNull);
    });

    testWidgets('every refusal has its own plain answer', (tester) async {
      final account = FakeAccountService();
      await pumpAccess(tester, account);
      final cases = {
        ClaimStatus.notFound: 'Nie znamy takiego kodu',
        ClaimStatus.expired: 'Ten kod już wygasł',
        ClaimStatus.usedUp: 'Ten kod został już wykorzystany',
        ClaimStatus.rateLimited: 'Za dużo prób',
        ClaimStatus.format: 'Kod wygląda tak: AK-XXXX-XXXX',
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        account.claimResult = ClaimResult(key);
        await typeInto(tester, 'Kod', 'AKABCD2345');
        await tapVisible(tester, find.text('Odbierz dostęp'));
        expect(find.textContaining(value), findsOneWidget, reason: '$key');
      }
    });

    testWidgets('an order needs its number and e-mail; a wrong pair never says which is wrong', (
      tester,
    ) async {
      final account = FakeAccountService()..claimResult = const ClaimResult(ClaimStatus.notFound);
      await pumpAccess(tester, account);
      await typeInto(tester, 'Numer zamówienia', '7421');
      await typeInto(tester, 'E-mail z zamówienia', 'kupujacy@example.com');
      await tapVisible(tester, find.text('Dodaj zamówienie'));
      expect(account.claims, ['order:7421:kupujacy@example.com']);
      expect(
        find.textContaining('Nie znaleźliśmy zamówienia z tym numerem i adresem e-mail'),
        findsOneWidget,
      );

      account.claimResult = const ClaimResult(ClaimStatus.taken);
      await tapVisible(tester, find.text('Dodaj zamówienie'));
      expect(find.textContaining('przypisane do innego konta'), findsOneWidget);
    });

    testWidgets('offline shows the usual message and keeps what was typed', (tester) async {
      final account = FakeAccountService()..offline = true;
      await pumpAccess(tester, account);
      await typeInto(tester, 'Kod', 'AKABCD2345');
      await tapVisible(tester, find.text('Odbierz dostęp'));
      expect(find.textContaining('internet', findRichText: true), findsWidgets);
      expect(find.text('AKABCD2345'), findsOneWidget, reason: 'the code stays for another try');
    });
  });
}
