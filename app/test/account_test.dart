import 'dart:async';

import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/storage/storage_providers.dart';
import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/features/access/access_controller.dart';
import 'package:audiokiddo/features/account/account_screen.dart';
import 'package:audiokiddo/features/account/account_service.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/purchases/purchase_controller.dart';
import 'package:audiokiddo/features/purchases/store_gateway.dart';
import 'package:audiokiddo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'access_and_progress_test.dart' show paidItem;
import 'helpers.dart';

/// In-memory server: code 123456 signs in; shop orders appear after syncWebPurchases.
class FakeAccountService implements AccountService {
  FakeAccountService({this.shopScopes = const []});

  final List<String> shopScopes;
  final _changes = StreamController<AccountUser?>.broadcast();
  final sentTo = <String>[];
  AccountUser? _user;
  List<Entitlement> _entitlements = [];
  bool offline = false;
  bool deleted = false;

  @override
  AccountUser? get current => _user;

  @override
  Stream<AccountUser?> get changes => _changes.stream;

  @override
  Future<void> sendCode(String email) async {
    if (offline) throw const AccountException(AccountError.offline);
    sentTo.add(email);
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    if (code != '123456') throw const AccountException(AccountError.wrongCode);
    _user = AccountUser(id: 'u1', email: email);
    _changes.add(_user);
  }

  @override
  bool get appleAvailable => true;

  bool appleCanceled = false;

  @override
  Future<void> signInWithApple() async {
    if (appleCanceled) throw const AccountException(AccountError.canceled);
    _user = const AccountUser(id: 'u2', email: 'abc@privaterelay.appleid.com');
    _changes.add(_user);
  }

  @override
  Future<void> signInWithGoogle() async => throw const AccountException(AccountError.notConfigured);

  @override
  Future<int> syncWebPurchases() async {
    _entitlements = [
      for (final s in shopScopes)
        Entitlement(scope: s, status: EntitlementStatus.active, source: EntitlementSource.woocommerce),
    ];
    return shopScopes.length;
  }

  @override
  Future<List<Entitlement>> entitlements() async {
    if (offline) throw const AccountException(AccountError.offline);
    return _user == null ? const [] : _entitlements;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _changes.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    deleted = true;
    _entitlements = [];
    await signOut();
  }

  final verified = <Map<String, Object?>>[];
  ServerVerdict verdict = ServerVerdict.verified;

  @override
  Future<String?> purchaseAccountId() async => current?.id ?? 'anon-1';

  @override
  Future<ServerVerdict> verifyStorePurchase(Map<String, Object?> body) async {
    verified.add(body);
    return verdict;
  }
}

Future<void> pumpAccount(WidgetTester tester, FakeAccountService account) async {
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
        home: const AccountScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('server purchase verifier', () {
    Future<(VerificationResult, FakeAccountService)> run(
      TargetPlatform platform,
      ServerVerdict verdict,
    ) async {
      final account = FakeAccountService()..verdict = verdict;
      final container = ProviderContainer(overrides: [accountServiceProvider.overrideWithValue(account)]);
      addTearDown(container.dispose);
      final verifier = container.read(Provider((ref) => ServerPurchaseVerifier(ref, platform: platform)));
      final result = await verifier.verify(
        const StorePurchase(
          productId: 'pl.audiokiddo.sub.yearly',
          status: PurchaseStatus.purchased,
          verificationData: 'jws-or-token',
        ),
      );
      return (result, account);
    }

    test('iOS sends the signed transaction, Android the product and token', () async {
      final (ios, a) = await run(TargetPlatform.iOS, ServerVerdict.verified);
      expect(ios, VerificationResult.verified);
      expect(a.verified.single, {'platform': 'ios', 'signedTransaction': 'jws-or-token'});
      final (_, b) = await run(TargetPlatform.android, ServerVerdict.verified);
      expect(b.verified.single, {
        'platform': 'android',
        'productId': 'pl.audiokiddo.sub.yearly',
        'purchaseToken': 'jws-or-token',
      });
    });

    test('rejected stays rejected; pending and server trouble wait for a retry', () async {
      expect((await run(TargetPlatform.iOS, ServerVerdict.rejected)).$1, VerificationResult.rejected);
      expect((await run(TargetPlatform.iOS, ServerVerdict.pending)).$1, VerificationResult.retryLater);
      expect((await run(TargetPlatform.iOS, ServerVerdict.retry)).$1, VerificationResult.retryLater);
    });
  });

  group('server rows', () {
    test('map to entitlements; unknown values are skipped', () {
      final e = entitlementFromRow({
        'scope': 'pack:detektyw',
        'status': 'billing_retry',
        'source': 'woocommerce',
        'valid_until': '2026-10-01T00:00:00Z',
      })!;
      expect(e.scope, 'pack:detektyw');
      expect(e.status, EntitlementStatus.billingRetry);
      expect(e.source, EntitlementSource.woocommerce);
      expect(e.validUntil, DateTime.utc(2026, 10));
      expect(entitlementFromRow({'scope': 'x', 'status': 'new_status', 'source': 'manual'}), isNull);
    });
  });

  group('access from the account', () {
    late ProviderContainer container;
    late FakeAccountService account;

    setUp(() {
      final db = memoryDatabase();
      account = FakeAccountService(shopScopes: [Scopes.pack('detektyw')]);
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          accountServiceProvider.overrideWithValue(account),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });
    });

    ItemAccess detektyw() => container.read(itemAccessProvider(paidItem('a', pack: 'detektyw')));

    test('shop pack unlocks after sign-in and locks again after sign-out', () async {
      await container.read(accessProvider.future);
      await container.read(accessProvider.notifier).refresh();
      expect(detektyw(), ItemAccess.locked);

      await account.verifyCode('rodzic@example.com', '123456');
      await account.syncWebPurchases();
      await container.read(accessProvider.notifier).refresh();
      expect(detektyw(), ItemAccess.playable);

      await account.signOut();
      await container.read(accessProvider.notifier).refresh();
      expect(detektyw(), ItemAccess.locked);
    });

    test('offline keeps the access the device already has', () async {
      await account.verifyCode('rodzic@example.com', '123456');
      await account.syncWebPurchases();
      await container.read(accessProvider.future);
      await container.read(accessProvider.notifier).refresh();
      account.offline = true;
      await container.read(accessProvider.notifier).refresh();
      expect(detektyw(), ItemAccess.playable);
    });
  });

  group('account screen', () {
    testWidgets('sign in with an e-mail code shows the shop pack', (tester) async {
      final account = FakeAccountService(shopScopes: [Scopes.pack('detektyw')]);
      await pumpAccount(tester, account);
      await tester.tap(find.text('Kontynuuj z e-mailem'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zly-adres');
      await tester.tap(find.text('Wyślij kod'));
      await tester.pumpAndSettle();
      expect(find.text('Sprawdź adres e-mail.'), findsOneWidget);
      expect(account.sentTo, isEmpty);

      await tester.enterText(find.byType(TextField), ' Rodzic@Example.com ');
      await tester.tap(find.text('Wyślij kod'));
      await tester.pumpAndSettle();
      expect(account.sentTo, ['Rodzic@Example.com']);
      expect(find.textContaining('Wysłaliśmy kod'), findsOneWidget);
      expect(find.text('Nowy kod za 60 s'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '000000');
      await tester.tap(find.widgetWithText(FilledButton, 'Zaloguj się'));
      await tester.pumpAndSettle();
      expect(find.text('Kod jest nieprawidłowy albo wygasł. Wyślij nowy.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Zaloguj się'));
      await tester.pumpAndSettle();
      expect(find.text('Rodzic@Example.com'), findsOneWidget, reason: 'the sheet closed, account shown');
      expect(find.text('Pakiet Detektyw'), findsOneWidget);

      // The resend countdown timer must not outlive the test.
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('offline sending shows a clear message', (tester) async {
      final account = FakeAccountService()..offline = true;
      await pumpAccount(tester, account);
      await tester.tap(find.text('Kontynuuj z e-mailem'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'rodzic@example.com');
      await tester.tap(find.text('Wyślij kod'));
      await tester.pumpAndSettle();
      expect(find.text('Brak połączenia z internetem.'), findsOneWidget);
    });

    testWidgets('deleting the account asks first and signs out', (tester) async {
      final account = FakeAccountService();
      await account.verifyCode('rodzic@example.com', '123456');
      await pumpAccount(tester, account);
      expect(find.text('Na tym koncie nie ma jeszcze zakupów.'), findsOneWidget);

      await tester.tap(find.text('Usuń konto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('nie anuluje subskrypcji'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Usuń konto'));
      await tester.pumpAndSettle();
      expect(account.deleted, isTrue);
      expect(find.text('Kontynuuj z e-mailem'), findsOneWidget);
    });

    testWidgets('Apple, Google and e-mail are offered; a closed Apple sheet shows nothing', (tester) async {
      final account = FakeAccountService()..appleCanceled = true;
      await pumpAccount(tester, account);
      expect(find.text('Kontynuuj z Apple'), findsOneWidget);
      expect(find.text('Kontynuuj z Google'), findsOneWidget);
      await tester.tap(find.text('Kontynuuj z Apple'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(find.text('Kontynuuj z Google'));
      await tester.pumpAndSettle();
      expect(find.textContaining('dostępne wkrótce'), findsOneWidget);

      account.appleCanceled = false;
      await tester.tap(find.text('Kontynuuj z Apple'));
      await tester.pumpAndSettle();
      expect(find.text('abc@privaterelay.appleid.com'), findsOneWidget);
    });
  });
}
