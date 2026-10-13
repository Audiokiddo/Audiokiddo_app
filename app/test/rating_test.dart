import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/rating/rating.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityResult _done(String item, DateTime at) =>
    ActivityResult(childId: 'z', itemId: item, at: at, seconds: 300, completed: true);

void main() {
  final now = DateTime(2026, 10, 13, 18);

  test('the store question comes only within 3 days of a good moment', () {
    bool ask({DateTime? happy, DateTime? asked, int plays = 5}) =>
        shouldAskForRating(finishedPlays: plays, askedAt: asked, now: now, happyAt: happy);
    expect(ask(), isFalse, reason: 'never out of the blue');
    expect(ask(happy: now.subtract(const Duration(hours: 2))), isTrue);
    expect(ask(happy: now.subtract(const Duration(days: 4))), isFalse);
    expect(ask(happy: now, plays: 2), isFalse, reason: 'after a few finished plays');
    expect(ask(happy: now, asked: now.subtract(const Duration(days: 10))), isFalse, reason: 'not twice in 60 days');
  });

  test('a play finished again is a good moment', () {
    final a = DateTime(2026, 10, 10);
    final b = DateTime(2026, 10, 12);
    expect(lastReplayAt([_done('x', a), _done('y', b)]), isNull);
    expect(lastReplayAt([_done('x', a), _done('y', a), _done('x', b)]), b);
  });
}
