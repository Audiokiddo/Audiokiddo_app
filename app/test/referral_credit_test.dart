import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/features/access/access_controller.dart';
import 'package:audiokiddo/features/account/access_screen.dart';
import 'package:audiokiddo/features/account/account_service.dart';
import 'package:audiokiddo/features/referral/referral_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'account_test.dart' show FakeAccountService;
import 'helpers.dart';

void main() {
  test('zloty amounts read the Polish way', () {
    expect(formatZloty(3000), '30 zł');
    expect(formatZloty(2001), '20,01 zł');
    expect(formatZloty(5), '0,05 zł');
  });

  test('a friend\'s code answer carries the credit and its own wording', () {
    final ok = ClaimResult.fromJson({'status': 'ok', 'scopes': [], 'credit': 3000, 'referral': true});
    expect(ok.granted, isTrue);
    expect(claimMessage(ok, forOrder: false), contains('Masz 30 zł do wykorzystania'));

    final guest = ClaimResult.fromJson({'status': 'account_required', 'referral': true});
    expect(guest.status, ClaimStatus.accountRequired);
    expect(guest.granted, isFalse);
    expect(claimMessage(guest, forOrder: false), contains('Załóż konto'));

    final limit = ClaimResult.fromJson({'status': 'used_up', 'referral': true});
    expect(claimMessage(limit, forOrder: false), contains('3 osoby w tym roku'));

    final twice = ClaimResult.fromJson({'status': 'already', 'referral': true});
    expect(twice.granted, isFalse, reason: 'a second friend\'s code adds nothing');
    expect(claimMessage(twice, forOrder: false), contains('jeden na konto'));

    // Gift codes keep their answers.
    expect(
      claimMessage(const ClaimResult(ClaimStatus.usedUp), forOrder: false),
      'Ten kod został już wykorzystany.',
    );
    expect(const ClaimResult(ClaimStatus.already).granted, isTrue);
  });

  test('the referral info and credit offers are read from the server', () {
    final info = ReferralInfo.fromJson({
      'code': 'POLEC-ABCDEF',
      'friends': 4,
      'rewards': 3,
      'left_this_year': 0,
      'balance': 9000,
    })!;
    expect((info.leftThisYear, info.balance), (0, 9000));
    expect(ReferralInfo.fromJson({'code': 'POLEC-ABCDEF'})!.leftThisYear, referralsPerYear);

    final credit = CreditInfo.fromJson({
      'balance': 3000,
      'offers': [
        {'scope': 'all_content', 'title': 'Miesiąc całej biblioteki', 'price': 2999},
        {'scope': 42},
      ],
    })!;
    expect(credit.offers.single.price, 2999);
    expect(SpendResult.fromJson({'status': 'owned', 'balance': 1}).status, SpendStatus.owned);
  });

  testWidgets('credit buys a play after a confirmation and the balance goes down', (tester) async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final account = FakeAccountService()..credit = 3000;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...testOverrides(db), accountServiceProvider.overrideWithValue(account)],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const Scaffold(body: SingleChildScrollView(child: CreditSection())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Masz 30 zł do wykorzystania w aplikacji.'), findsOneWidget);
    expect(find.text('Miesiąc całej biblioteki'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Wykorzystaj').last);
    await tester.pumpAndSettle();
    expect(find.text('Wykorzystać 9,99 zł ze środków za polecenia?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Wykorzystaj').last);
    await tester.pumpAndSettle();

    expect(account.credit, 2001);
    expect(find.textContaining('„Magiczny sklep” jest już Wasze'), findsOneWidget);
    expect(find.text('Masz 20,01 zł do wykorzystania w aplikacji.'), findsOneWidget);
    expect(find.text('brakuje 9,98 zł'), findsOneWidget, reason: 'the month costs more than what is left');
    final container = ProviderScope.containerOf(tester.element(find.byType(CreditSection)));
    expect(container.read(accessProvider).hasValue, isTrue);
  });
}
