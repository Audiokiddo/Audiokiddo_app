import 'package:audiokiddo/features/referral/referral_nudge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 7);

  test('the referral nudge waits for the second finished play', () {
    expect(showReferralNudge(finishedPlays: 1, hiddenUntil: null, now: now), isFalse);
    expect(showReferralNudge(finishedPlays: 2, hiddenUntil: null, now: now), isTrue);
  });

  test('"Nie teraz" hides it for the chosen time only', () {
    expect(
      showReferralNudge(finishedPlays: 5, hiddenUntil: now.add(const Duration(days: 3)), now: now),
      isFalse,
    );
    expect(
      showReferralNudge(finishedPlays: 5, hiddenUntil: now.subtract(const Duration(days: 1)), now: now),
      isTrue,
    );
  });
}
