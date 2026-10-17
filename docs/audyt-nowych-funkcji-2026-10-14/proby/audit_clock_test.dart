import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/catalog/catalog_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ContentItem item({DateTime? release}) => ContentItem(
  id: 'audit', kind: ContentKind.audioGame, title: 'Audit', parentDescription: '',
  ageMin: 3, durationSec: 60, access: ContentAccess.paid, audio: const [], releasedOn: release,
);

void main() {
  test('access should expire while the same provider remains alive', () async {
    var now = DateTime(2026, 10, 14, 10);
    final container = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(() => now),
      entitlementsProvider.overrideWithValue([
        Entitlement(scope: Scopes.allContent, status: EntitlementStatus.active,
          source: EntitlementSource.appStore, validUntil: DateTime(2026, 10, 14, 11)),
      ]),
      leaseStateProvider.overrideWithValue(LeaseState.valid),
    ]);
    addTearDown(container.dispose);
    final play = item();
    expect(container.read(itemAccessProvider(play)), ItemAccess.playable);
    now = DateTime(2026, 10, 14, 12);
    await pumpEventQueue();
    expect(container.read(itemAccessProvider(play)), ItemAccess.locked);
  });

  test('a scheduled release should appear after midnight without restarting', () async {
    var now = DateTime(2026, 10, 14, 23, 59);
    final container = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(() => now),
      fullCatalogProvider.overrideWith((ref) async => Catalog(version: 1, packs: const [],
        items: [item(release: DateTime(2026, 10, 15))], shelves: const [])),
    ]);
    addTearDown(container.dispose);
    expect((await container.read(catalogProvider.future)).items, isEmpty);
    now = DateTime(2026, 10, 15, 0, 1);
    await pumpEventQueue();
    expect((await container.read(catalogProvider.future)).items, hasLength(1));
  });
}
