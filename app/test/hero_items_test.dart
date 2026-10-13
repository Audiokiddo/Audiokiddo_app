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
}
