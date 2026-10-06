import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/app.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/family_sharing/parent_cloud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';
import 'screens_test.dart' show mainScroll;

class FakeCloud implements ParentCloud {
  FamilyStatus status = const FamilyStatus(canInvite: true);
  bool letters = false;
  String? joined;

  @override
  Future<FamilyStatus> familyStatus() async => status;
  @override
  Future<String> familyInvite() async => 'K7PX2M';
  @override
  Future<void> familyJoin(String code) async {
    if (code != 'ABC123') throw const FamilyException('Ten kod nie działa albo wygasł. Poproś o nowy.');
    joined = code;
    status = const FamilyStatus(role: FamilyRole.member, partner: 'ma•••@example.com');
  }

  @override
  Future<void> familyLeave() async => status = const FamilyStatus(canInvite: true);
  @override
  Future<bool> lettersOn() async => letters;
  @override
  Future<void> setLetters(bool on) async => letters = on;
  @override
  Future<Map<String, List<String>>> experiments() async => const {};
}

Future<void> pumpWith(WidgetTester tester, List<Override> extra, {List<Entitlement> entitlements = const []}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final db = memoryDatabase();
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(db),
        entitlementsProvider.overrideWithValue(entitlements),
        leaseStateProvider.overrideWithValue(LeaseState.valid),
        ...extra,
      ],
      child: const AudioKiddoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('A/B variants are stable per install and spread over the variants', () {
    const tests = {
      'paywall_cta': ['proba', 'oszczednosc'],
    };
    expect(assignVariants('install-1', tests), assignVariants('install-1', tests));
    final seen = {for (var i = 0; i < 40; i++) assignVariants('install-$i', tests)['paywall_cta']};
    expect(seen, {'proba', 'oszczednosc'});
    expect(
      parseExperiments({
        'x': ['a'],
        'y': ['a', 'b'],
      }),
      {
        'y': ['a', 'b'],
      },
      reason: 'a test needs two variants',
    );
  });

  testWidgets('second parent: invite with a code, or join with one', (tester) async {
    final cloud = FakeCloud();
    await pumpWith(tester, [parentCloudProvider.overrideWithValue(cloud)]);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/rodzina');
    await tester.pumpAndSettle();
    expect(find.text('Jedna rodzina, dwa telefony'), findsOneWidget);
    await tester.tap(find.text('Utwórz kod zaproszenia'));
    await tester.pumpAndSettle();
    expect(find.text('K7PX2M'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz999');
    await tester.scrollUntilVisible(
      find.text('Dołącz'),
      100,
      scrollable: find
          .ancestor(of: find.text('Masz kod od drugiego rodzica?'), matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(find.text('Dołącz'));
    await tester.pumpAndSettle();
    expect(find.text('Ten kod nie działa albo wygasł. Poproś o nowy.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // the message goes away
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ABC123');
    await tester.tap(find.text('Dołącz'));
    await tester.pumpAndSettle();
    expect(cloud.joined, 'ABC123');
    expect(find.text('Korzystasz z abonamentu rodziny'), findsOneWidget);
  });

  testWidgets('a plan for one child explains the second parent and leads to the plans', (tester) async {
    final cloud = FakeCloud()..status = const FamilyStatus();
    await pumpWith(tester, [parentCloudProvider.overrideWithValue(cloud)]);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/rodzina');
    await tester.pumpAndSettle();
    expect(find.text('Drugi rodzic jest w planach dla 2 i 3–5 dzieci'), findsOneWidget);
    expect(find.text('Zobacz plany'), findsOneWidget);
  });

  testWidgets('the saving in the button when the A/B test says so', (tester) async {
    await pumpWith(tester, [
      experimentsProvider.overrideWithValue(const {'paywall_cta': 'oszczednosc'}),
    ]);
    await tester.tap(find.text('Sklep').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Zacznij za darmo i oszczędzaj 60'), findsOneWidget);
  });

  testWidgets('after a subscription ended: what is new since, and the way back', (tester) async {
    await pumpWith(
      tester,
      const [],
      entitlements: [
        Entitlement(
          scope: Scopes.allContent,
          status: EntitlementStatus.expired,
          source: EntitlementSource.appStore,
          validUntil: DateTime(2026, 1, 1),
        ),
      ],
    );
    await tester.scrollUntilVisible(find.text('Wracacie? Wszystko na Was czeka'), 200, scrollable: mainScroll);
    expect(find.text('Wróć do abonamentu'), findsOneWidget);
  });

  testWidgets('O nas: a Polish brand made by Nela and Dawid, shown next to the offer too', (tester) async {
    await pumpWith(tester, const []);
    await tester.tap(find.text('Sklep').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Polska rodzinna marka · zabawy nagrywają Nela i Dawid'),
      200,
      scrollable: mainScroll,
    );
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/o-nas');
    await tester.pumpAndSettle();
    expect(find.text('Cześć, jesteśmy Nela i Dawid'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nasze głosy'),
      200,
      scrollable: find.ancestor(of: find.text('Cześć, jesteśmy Nela i Dawid'), matching: find.byType(Scrollable)).first,
    );
    expect(find.text('Nasze głosy'), findsOneWidget);
  });
}
