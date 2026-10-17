import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audiokiddo/features/catalog/all_plays.dart';
import 'package:audiokiddo/features/home/start_cards.dart';

import 'session_test.dart' show loadCatalog;
import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final catalog = loadCatalog();
  final now = DateTime(2030);
  test('pack name search finds its released items', () {
    final item = catalog.items.firstWhere((i) => i.packId != null);
    final name = catalog.pack(item.packId!)!.title;
    expect(allPlays(catalog, now: now, query: name).map((i) => i.id), contains(item.id));
  });
  test('shortest and newest sorting are monotonic', () {
    final shortest = allPlays(catalog, now: now, sort: AllSort.shortest);
    for (var i = 1; i < shortest.length; i++) {
      expect(shortest[i].durationSec, greaterThanOrEqualTo(shortest[i - 1].durationSec));
    }
    final newest = allPlays(catalog, now: now, sort: AllSort.newest);
    for (var i = 1; i < newest.length; i++) {
      expect(
        (newest[i].releasedOn ?? DateTime(2000)).isAfter(newest[i - 1].releasedOn ?? DateTime(2000)),
        false,
      );
    }
  });
  test('hidden card persists after provider recreation and can be restored', () async {
    final db = memoryDatabase();
    final a = ProviderContainer(overrides: testOverrides(db));
    await a.read(hiddenStartCardsProvider.future);
    await a.read(hiddenStartCardsProvider.notifier).set('dinner', hidden: true);
    a.dispose();
    final b = ProviderContainer(overrides: testOverrides(db));
    expect(await b.read(hiddenStartCardsProvider.future), contains('dinner'));
    await b.read(hiddenStartCardsProvider.notifier).set('dinner', hidden: false);
    b.dispose();
    final c = ProviderContainer(overrides: testOverrides(db));
    expect(await c.read(hiddenStartCardsProvider.future), isNot(contains('dinner')));
    c.dispose();
    await db.close();
  });
}
