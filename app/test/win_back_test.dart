import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/purchases/win_back.dart';
import 'package:flutter_test/flutter_test.dart';

Entitlement _sub(DateTime until) => Entitlement(
  scope: Scopes.allContent,
  status: EntitlementStatus.active,
  source: EntitlementSource.appStore,
  validUntil: until,
);

void main() {
  final now = DateTime(2026, 10, 7);

  test('the invitation back is for families whose subscription ended', () {
    expect(subscriptionEndedAt(const [], now), isNull, reason: 'never subscribed');
    expect(subscriptionEndedAt([_sub(DateTime(2026, 11, 1))], now), isNull, reason: 'still subscribed');
    expect(
      subscriptionEndedAt([_sub(DateTime(2026, 8, 1)), _sub(DateTime(2026, 9, 1))], now),
      DateTime(2026, 9, 1),
    );
    expect(
      subscriptionEndedAt([_sub(DateTime(2026, 9, 1)), _sub(DateTime(2026, 12, 1))], now),
      isNull,
      reason: 'renewed',
    );
  });
}
