import 'dart:io';

import 'package:audiokiddo/features/rewards/adventure_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chests: two secrets, then a card sheet; every reward has its file', () {
    final kinds = [for (var c = 1; c <= 6; c++) rewardForChest(c).kind];
    expect(kinds, [
      RewardKind.secret,
      RewardKind.secret,
      RewardKind.cards,
      RewardKind.secret,
      RewardKind.secret,
      RewardKind.cards,
    ]);
    expect(rewardForChest(1).number, 1);
    expect(rewardForChest(2).number, 2);
    expect(rewardForChest(3).number, 1);
    expect(rewardForChest(4).number, 3);
    expect(rewardForChest(6).number, 2);
    final secrets = <int>{};
    final sheets = <int>{};
    for (var c = 1; c <= 200; c++) {
      final r = rewardForChest(c);
      if (r.kind == RewardKind.secret) {
        secrets.add(r.number);
        expect(File(secretAsset(r.number)).existsSync(), isTrue, reason: secretAsset(r.number));
      } else {
        sheets.add(r.number);
        expect(File(cardsAsset(r.number)).existsSync(), isTrue, reason: cardsAsset(r.number));
      }
    }
    expect(secrets.length, secretCount);
    expect(sheets.length, cardSheets.length);
  });

  test('the next chest comes every three finished plays', () {
    expect(adventureOf('Zosia', 0).toNextChest, 3);
    expect(adventureOf('Zosia', 2).toNextChest, 1);
    expect(adventureOf('Zosia', 3).chests, 1);
    expect(adventureOf('Zosia', 7).chests, 2);
  });
}
