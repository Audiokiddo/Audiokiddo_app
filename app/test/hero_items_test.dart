import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/alerts/alerts.dart' show daysUntil;
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:audiokiddo/features/catalog/home_screen.dart';
import 'package:audiokiddo/features/catalog/widgets/item_art.dart';
import 'package:audiokiddo/features/family/family.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Start shows every free play first, even one marked for older children', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: testOverrides(db));
    addTearDown(container.dispose);
    await container.read(familyProvider.future);
    await container
        .read(familyProvider.notifier)
        .saveChild(ChildProfile(id: 'z', name: 'Zosia', age: 4, startedOn: DateTime(2026)));
    final catalog = await container.read(catalogProvider.future);
    final covers = await container.read(coverAssetsProvider.future);
    container.listen(heroItemsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    final hero = container.read(heroItemsProvider);
    final free = [
      for (final i in catalog.items)
        if (i.isFree && (i.cover != null || covers.contains(coverAssetPath(i.id))) && i.id != 'prawda-czy-nie') i.id,
    ];
    expect(free, contains('zlodziej-naszyjnika'), reason: 'the 7+ free play of Detektyw');
    final firstIds = hero.take(free.length).map((i) => i.id);
    expect(firstIds, unorderedEquals(free), reason: 'all free plays open the row');
    expect(hero.skip(free.length).any((i) => i.isFree && i.id != 'prawda-czy-nie'), isFalse);
    expect(hero.where((i) => !i.isFree), isNotEmpty, reason: 'locked plays follow, marked on their cards');
  });

  test('"ZA DARMO" marks free plays, but not for subscribers', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    Future<bool> badge(List<Entitlement> entitlements) async {
      final c = ProviderContainer(overrides: [...testOverrides(db), entitlementsProvider.overrideWithValue(entitlements)]);
      addTearDown(c.dispose);
      final catalog = await c.read(catalogProvider.future);
      return c.read(showFreeBadgeProvider(catalog.items.firstWhere((i) => i.isFree)));
    }

    expect(await badge(const []), isTrue);
    expect(
      await badge(const [
        Entitlement(scope: Scopes.allContent, status: EntitlementStatus.active, source: EntitlementSource.appStore),
      ]),
      isFalse,
    );
  });

  test('after work, 16:30–19:30: about 25 minutes of no-prep plays, unheard first', () async {
    expect(isDinnerWindow(DateTime(2026, 10, 13, 16, 29)), isFalse);
    expect(isDinnerWindow(DateTime(2026, 10, 13, 16, 30)), isTrue);
    expect(isDinnerWindow(DateTime(2026, 10, 13, 19, 29)), isTrue);
    expect(isDinnerWindow(DateTime(2026, 10, 13, 19, 30)), isFalse);

    final db = memoryDatabase();
    addTearDown(db.close);
    final c = ProviderContainer(overrides: testOverrides(db));
    addTearDown(c.dispose);
    final catalog = await c.read(catalogProvider.future);
    final now = DateTime(2026, 10, 13, 17);
    final picks = dinnerPicks(catalog, age: 5, canPlay: (_) => true, heard: const {}, now: now);
    expect(picks, isNotEmpty);
    expect(picks.every((i) => i.requirements.isEmpty && i.ageMin <= 5), isTrue);
    final seconds = picks.fold(0, (s, i) => s + i.durationSec);
    expect(seconds - picks.last.durationSec, lessThan(25 * 60), reason: 'stops once about 25 minutes are lined up');
    final heardFirst = dinnerPicks(catalog, age: 5, canPlay: (_) => true, heard: {picks.first.id}, now: now);
    expect(heardFirst.first.id, isNot(picks.first.id), reason: 'unheard plays come first');
    expect(dinnerPicks(catalog, age: 5, canPlay: (_) => false, heard: const {}, now: now), isEmpty);
  });

  test('the favourite is the play finished most often, at least twice', () {
    ActivityResult done(String item, int day, {String child = 'z'}) =>
        ActivityResult(childId: child, itemId: item, at: DateTime(2026, 10, day), seconds: 300);
    expect(favoritePlayId([done('a', 1), done('b', 2)], 'z'), isNull, reason: 'once is not a favourite');
    expect(favoritePlayId([done('a', 1), done('a', 2), done('b', 3), done('b', 4), done('b', 5)], 'z'), 'b');
    expect(favoritePlayId([done('a', 1), done('a', 2), done('b', 3), done('b', 4)], 'z'), 'b', reason: 'latest wins a tie');
    expect(favoritePlayId([done('a', 1, child: 'x'), done('a', 2, child: 'x')], 'z'), isNull);
  });

  test('the premiere countdown says days plainly', () {
    final now = DateTime(2026, 10, 13, 21);
    expect(daysUntil(DateTime(2026, 10, 14), now), 'Jutro');
    expect(daysUntil(DateTime(2026, 10, 15), now), 'Pojutrze');
    expect(daysUntil(DateTime(2026, 10, 18), now), 'Za 5 dni');
  });

  test('Dobranoc zawsze działa: bedtime plays keep playing until midnight on the day the library ended', () async {
    final db = memoryDatabase();
    addTearDown(db.close);
    final c = ProviderContainer(overrides: testOverrides(db));
    addTearDown(c.dispose);
    final catalog = await c.read(catalogProvider.future);
    final bedtime = catalog.items.firstWhere((i) => !i.isFree && i.situations.contains(Situation.przedSnem));
    final other = catalog.items.firstWhere((i) => !i.isFree && !i.situations.contains(Situation.przedSnem));
    final now = DateTime(2026, 10, 13, 20);
    Entitlement ended(DateTime at, [EntitlementStatus s = EntitlementStatus.expired]) =>
        Entitlement(scope: Scopes.allContent, status: s, source: EntitlementSource.appStore, validUntil: at);
    expect(bedtimeGrace([ended(DateTime(2026, 10, 13, 9))], bedtime, now), isTrue);
    expect(bedtimeGrace([ended(DateTime(2026, 10, 13, 9))], other, now), isFalse);
    expect(bedtimeGrace([ended(DateTime(2026, 10, 12, 23))], bedtime, now), isFalse, reason: 'ended yesterday');
    expect(bedtimeGrace([ended(DateTime(2026, 10, 13, 9), EntitlementStatus.refunded)], bedtime, now), isFalse);
  });
}
