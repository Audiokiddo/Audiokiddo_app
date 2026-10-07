import 'package:audiokiddo/features/account/account_data.dart';
import 'package:audiokiddo/l10n/app_localizations_pl.dart';
import 'package:audiokiddo/features/account/session_gate.dart';
import 'package:go_router/go_router.dart';
import 'package:audiokiddo/app.dart';

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

  /// Addresses that already have an account (sign-in step one).
  final knownEmails = <String>{};

  @override
  Future<bool?> accountExists(String email) async => offline ? null : knownEmails.contains(email.trim());

  @override
  AccountUser? get current => _user;

  @override
  Stream<AccountUser?> get changes => _changes.stream;

  /// E-mails with an account (registered, or signed in before); deleting removes it.
  final accounts = <String>{'rodzic@example.com'};

  @override
  Future<void> sendCode(String email) async {
    if (offline) throw const AccountException(AccountError.offline);
    if (!accounts.contains(email.trim().toLowerCase())) throw const AccountException(AccountError.noAccount);
    sentTo.add(email);
  }

  @override
  Future<bool> signUp(String email, String password) async {
    if (password.length < minPasswordLength) throw const AccountException(AccountError.weakPassword);
    if (accounts.contains(email.trim().toLowerCase())) {
      throw const AccountException(AccountError.accountExists);
    }
    sentTo.add(email);
    return true;
  }

  @override
  Future<void> verifySignUp(String email, String code) async {
    if (code != '123456') throw const AccountException(AccountError.wrongCode);
    accounts.add(email.trim().toLowerCase());
    _user = AccountUser(id: 'u-$email', email: email);
    _changes.add(_user);
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    if (code != '123456') throw const AccountException(AccountError.wrongCode);
    _user = AccountUser(id: 'u1', email: email);
    _changes.add(_user);
  }

  @override
  bool get appleAvailable => true;

  @override
  bool get googleAvailable => true;

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

  /// What redeemCode / claimOrder answer next; every call is recorded in [claims].
  ClaimResult claimResult = const ClaimResult(ClaimStatus.notFound);
  final claims = <String>[];

  Future<ClaimResult> _claim(String what) async {
    if (offline) throw const AccountException(AccountError.offline);
    claims.add(what);
    if (claimResult.granted) {
      _entitlements = [
        ..._entitlements,
        for (final scope in claimResult.scopes)
          Entitlement(scope: scope, status: EntitlementStatus.active, source: EntitlementSource.manual),
      ];
    }
    return claimResult;
  }

  @override
  Future<ClaimResult> redeemCode(String code) => _claim('code:$code');

  @override
  Future<ClaimResult> claimOrder(String order, String email) => _claim('order:$order:$email');

  String? password;

  @override
  Future<void> signInWithPassword(String email, String pass) async {
    if (pass != password) throw const AccountException(AccountError.wrongPassword);
    await verifyCode(email, '123456');
  }

  @override
  Future<void> setPassword(String pass) async {
    if (pass.length < minPasswordLength) throw const AccountException(AccountError.weakPassword);
    password = pass;
  }

  @override
  Future<ReferralInfo> referralInfo() async =>
      const ReferralInfo(code: 'POLEC-ABCDEF', friends: 2, rewards: 1);

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
    accounts.remove(_user?.email.toLowerCase());
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

  @override
  Future<Uri?> signedFileUrl(String path) async => Uri.parse('https://files.test/$path');
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

  testWidgets('signing out locks the app on the sign-in screen until the parent signs in', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = memoryDatabase();
    addTearDown(db.close);
    final account = FakeAccountService();
    await account.verifyCode('rodzic@example.com', '123456');
    final gate = SessionGate(account, required: true);
    addTearDown(gate.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(db),
          accountServiceProvider.overrideWithValue(account),
          sessionGateProvider.overrideWithValue(gate),
        ],
        child: const AudioKiddoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Co dziś robimy?'), findsOneWidget);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/konto');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Wyloguj się'), 200);
    await Scrollable.ensureVisible(tester.element(find.text('Wyloguj się')), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wyloguj się'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wyloguj się').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Zaloguj się lub załóż konto'),
      findsOneWidget,
      reason: 'the sign-in screen asks the e-mail',
    );
    expect(find.textContaining('Kontynuuj bez konta'), findsNothing);
    // A back gesture or a deep link cannot leave it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/biblioteka');
    await tester.pumpAndSettle();
    expect(find.text('Zaloguj się lub załóż konto'), findsOneWidget);

    // A new address: registration with a password, the consent first, then the code confirms it.
    await tester.enterText(find.byType(TextField).first, 'nowy@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('Załóż konto rodzica'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Załóż konto'));
    await tester.pumpAndSettle();
    // Checked in the order of the fields: the password above, the consent below it.
    expect(
      find.text('Hasło musi mieć co najmniej 8 znaków.'),
      findsOneWidget,
      reason: 'a password is required',
    );
    await tester.enterText(find.byType(TextField).at(1), 'nowehaslo1');
    await tester.tap(find.widgetWithText(FilledButton, 'Załóż konto'));
    await tester.pumpAndSettle();
    expect(find.text('Zaznacz zgodę na regulamin i politykę prywatności.'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.widgetWithText(FilledButton, 'Załóż konto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.widgetWithText(FilledButton, AppLocalizationsPl().accountVerify));
    await tester.pumpAndSettle();
    expect(find.text('Co dziś robimy?'), findsOneWidget, reason: 'signed in: the app opens');
  });

  test('another account on the phone does not see the previous family', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    await db.writeValue('family_children', '[{"id":"z","name":"Zosia"}]');
    await db.writeValue('diplomas_z', '{"detektyw":"2026-10-01"}');
    await db.writeValue('theme_mode', 'dark');
    expect(await claimFamilyData(db, 'A'), isFalse, reason: 'the first account adopts what is there');
    expect(await db.readValue('family_children'), isNotNull);
    expect(await claimFamilyData(db, 'A'), isFalse, reason: 'the same account keeps everything');
    expect(await claimFamilyData(db, 'B'), isTrue);
    expect(await db.readValue('family_children'), isNull);
    expect(await db.readValue('diplomas_z'), isNull);
    expect(await db.readValue('theme_mode'), 'dark', reason: 'device settings stay');
  });

  testWidgets('sign in with a password; a forgotten one leads to the code', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = memoryDatabase();
    addTearDown(db.close);
    final account = FakeAccountService()
      ..password = 'tajnehaslo1'
      ..knownEmails.add('rodzic@example.com');
    final gate = SessionGate(account, required: true);
    addTearDown(gate.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(db),
          accountServiceProvider.overrideWithValue(account),
          sessionGateProvider.overrideWithValue(gate),
        ],
        child: const AudioKiddoApp(),
      ),
    );
    await tester.pumpAndSettle();
    // First the e-mail only; a known address then asks for its password.
    await tester.enterText(find.byType(TextField).first, 'rodzic@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('rodzic@example.com'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'zle-haslo');
    await tester.tap(find.widgetWithText(FilledButton, 'Zaloguj'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nieprawidłowy e-mail albo hasło'), findsOneWidget);

    await tester.tap(find.text('Nie pamiętam hasła'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ustawisz nowe hasło w Więcej'), findsOneWidget);
    expect(find.text('Zaloguj się kodem'), findsOneWidget);

    await tester.tap(find.text('Wróć do logowania hasłem'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'tajnehaslo1');
    await tester.tap(find.widgetWithText(FilledButton, 'Zaloguj'));
    await tester.pumpAndSettle();
    expect(find.text('Co dziś robimy?'), findsOneWidget);
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

      await tester.scrollUntilVisible(find.text('Usuń konto'), 200);
      await tester.tap(find.text('Usuń konto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('nie anuluje subskrypcji'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Usuń konto'));
      await tester.pumpAndSettle();
      expect(account.deleted, isTrue);
      expect(find.text('Kontynuuj z e-mailem'), findsOneWidget);
      // Gone for good: a code to the same e-mail says there is no account any more.
      await tester.tap(find.text('Kontynuuj z e-mailem'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'rodzic@example.com');
      await tester.tap(find.text('Wyślij kod'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nie ma konta z tym adresem'), findsOneWidget);
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
