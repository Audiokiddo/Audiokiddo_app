import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/stickers/stickers.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityResult _done(DateTime at, {bool completed = true}) =>
    ActivityResult(childId: 'z', itemId: 'x', at: at, seconds: 600, completed: completed);

void main() {
  final now = DateTime(2026, 10, 7, 18);

  test('every sticker has a milestone, quick at first and rarer later', () {
    expect(stickerMilestones, hasLength(stickerAlbum.length));
    for (var i = 1; i < stickerMilestones.length; i++) {
      expect(stickerMilestones[i], greaterThan(stickerMilestones[i - 1]));
    }
  });

  test('a finished play on a milestone brings a new sticker, right after it', () {
    final three = [for (var i = 3; i > 0; i--) _done(now.subtract(Duration(minutes: i)))];
    final p = stickerProgress(three, now);
    expect((p.finished, p.unlocked, p.justEarned, p.toNext), (3, 3, true, 2));
    expect(stickerProgress(three, now.add(const Duration(hours: 1))).justEarned, isFalse);
  });

  test('unfinished plays do not count; between milestones nothing new', () {
    final p = stickerProgress([
      for (var i = 0; i < 4; i++) _done(now.subtract(Duration(minutes: i))),
      _done(now, completed: false),
    ], now);
    expect((p.finished, p.unlocked, p.justEarned, p.toNext), (4, 3, false, 1));
  });
}
