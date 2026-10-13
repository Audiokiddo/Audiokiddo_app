import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/core/theme/app_theme.dart';
import 'package:audiokiddo/features/access/access_controller.dart';
import 'package:audiokiddo/features/purchases/manage_subscription.dart';
import 'package:audiokiddo/features/purchases/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _Backend implements EntitlementBackend {
  _Backend(this.entitlements);

  final List<Entitlement> entitlements;

  @override
  Future<List<Entitlement>> fetch() async => entitlements;
}

Entitlement _sub(EntitlementSource source, {int days = 10}) => Entitlement(
  scope: Scopes.allContent,
  status: EntitlementStatus.active,
  source: source,
  validUntil: DateTime.now().add(Duration(days: days)),
);

Future<void> _pump(WidgetTester tester, List<Entitlement> entitlements) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final db = memoryDatabase();
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [...testOverrides(db), entitlementBackendProvider.overrideWithValue(_Backend(entitlements))],
      child: MaterialApp(theme: buildTheme(Brightness.light), home: const SubscriptionScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('the subscription is the store one that ends last; codes cannot be cancelled in the store', () {
    final now = DateTime.now();
    final short = _sub(EntitlementSource.manual, days: 3);
    final long = _sub(EntitlementSource.appStore, days: 20);
    expect(currentSubscription([short, long], now), long);
    expect(currentSubscription(const [], now), isNull);
    expect(cancellableInStore(long), isTrue);
    expect(cancellableInStore(short), isFalse);
  });

  testWidgets('cancelling asks why first, then confirms with the end date; staying is one tap', (tester) async {
    await _pump(tester, [_sub(EntitlementSource.appStore)]);
    expect(find.text('Abonament AudioKiddo'), findsOneWidget);
    expect(find.text('Aktywny'), findsOneWidget);
    expect(find.text('Przywróć poprzednie zakupy'), findsOneWidget);

    await tester.tap(find.text('Anuluj subskrypcję'));
    await tester.pumpAndSettle();
    expect(find.text('Dlaczego chcesz zrezygnować?'), findsOneWidget);
    for (final r in CancelReason.values) {
      expect(find.text(r.label), findsOneWidget);
    }

    await tester.tap(find.text(CancelReason.notUsing.label));
    await tester.pumpAndSettle();
    expect(find.text('Potwierdź anulowanie'), findsOneWidget);
    expect(find.textContaining('wszystkie zabawy zostaną otwarte do'), findsOneWidget);

    await tester.tap(find.text('Zostaw subskrypcję'));
    await tester.pumpAndSettle();
    expect(find.text('Potwierdź anulowanie'), findsNothing);
    expect(find.text('Abonament AudioKiddo'), findsOneWidget);
  });

  testWidgets('a reason we can fix gets an answer before the confirmation', (tester) async {
    await _pump(tester, [_sub(EntitlementSource.googlePlay)]);
    await tester.tap(find.text('Anuluj subskrypcję'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CancelReason.price.label));
    await tester.pumpAndSettle();
    expect(find.textContaining('22,50 zł miesięcznie'), findsOneWidget);
    await tester.tap(find.text('Zostaję'));
    await tester.pumpAndSettle();
    expect(find.text('Potwierdź anulowanie'), findsNothing);
  });

  testWidgets('access from a code shows its date and no cancel row', (tester) async {
    await _pump(tester, [_sub(EntitlementSource.manual)]);
    expect(find.textContaining('Nie odnawia się sam'), findsOneWidget);
    expect(find.text('Anuluj subskrypcję'), findsNothing);
  });

  testWidgets('without a subscription the screen says so', (tester) async {
    await _pump(tester, const []);
    expect(find.text('Nie masz teraz abonamentu'), findsOneWidget);
    expect(find.text('Anuluj subskrypcję'), findsNothing);
  });
}
