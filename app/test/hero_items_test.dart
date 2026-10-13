import 'package:ak_core/ak_core.dart';
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
}
